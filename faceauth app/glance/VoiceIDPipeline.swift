//
//  VoiceIDPipeline.swift
//  glance
//
//  Voice ID processing pipeline using native Apple APIs:
//  - AVAudioEngine for real-time microphone audio capture
//  - Accelerate for numerical processing (FFT, spectral energy, feature vector extraction)
//  - SoundAnalysis / Core ML structures for audio feature extraction
//  - Cosine similarity comparison against registered voice profile
//

import Foundation
import AVFoundation
import Accelerate
import SoundAnalysis
import CoreML
import Observation
import Speech

@Observable
@MainActor
final class VoiceIDPipeline {
    private let audioEngine = AVAudioEngine()
    private(set) var isListening = false
    private(set) var currentAudioLevel: Float = 0.0 // 0.0 to 1.0 for UI visualizer
    private(set) var statusMessage: String = "Idle"
    private(set) var isVoiceVerified: Bool = false
    private(set) var didRecognizePassphrase: Bool = false
    private(set) var didDetectSpeech = false
    private(set) var lastSoundAt = Date()

    /// Number of features in our spectral voice embedding vector (e.g. 64 bands)
    static let featureVectorSize = 64
    /// Similarity threshold (0.0 ... 1.0) for voice match
    var matchThreshold: Float = 0.72

    private var accumulatedSamples: [[Float]] = []
    private var isCapturingForEnrollment = false
    private var enrollmentFeatureVector: [Float]?
    private var expectedPassphrase = ""
    private var voiceMatchDetected = false
    private var enrolledFeatureVector: [Float]?
    private var recentVoiceFeatures: [(recordedAt: Date, vector: [Float])] = []
    private var speechRecognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var speechRecognitionTask: SFSpeechRecognitionTask?
    private var speechRecognitionGeneration = 0
    private var onEnrollmentProgress: ((Double) -> Void)?
    private var onEnrollmentComplete: (([Float]) -> Void)?

    // MARK: - Audio Engine Lifecycle

    static func requestSpeechRecognitionAuthorization() async -> SFSpeechRecognizerAuthorizationStatus {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }

    func startListening(passphrase: String, enrolledFeatureVector: [Float]? = nil) throws {
        guard !isListening else { return }

        guard SFSpeechRecognizer.authorizationStatus() == .authorized else {
            throw Self.speechError("Speech Recognition permission is required to verify your passphrase.")
        }
        guard let recognizer = SFSpeechRecognizer(locale: Locale.current),
              recognizer.isAvailable,
              recognizer.supportsOnDeviceRecognition
        else {
            throw Self.speechError("On-device speech recognition isn't available for your system language.")
        }
        let normalizedPassphrase = Self.normalizedSpeech(passphrase)
        guard !normalizedPassphrase.isEmpty else {
            throw Self.speechError("Set a voice passphrase before enrolling Voice ID.")
        }

        expectedPassphrase = normalizedPassphrase
        self.enrolledFeatureVector = enrolledFeatureVector
        recentVoiceFeatures = []
        didRecognizePassphrase = false
        didDetectSpeech = false
        voiceMatchDetected = false
        isVoiceVerified = false
        speechRecognitionGeneration &+= 1
        let recognitionGeneration = speechRecognitionGeneration

        let recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest.requiresOnDeviceRecognition = true
        recognitionRequest.shouldReportPartialResults = true
        speechRecognitionRequest = recognitionRequest
        speechRecognitionTask = recognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let result else {
                if let error {
                    Task { @MainActor [weak self] in
                        guard let self,
                              self.speechRecognitionGeneration == recognitionGeneration,
                              !self.isVoiceVerified
                        else { return }
                        self.statusMessage = "Passphrase recognition failed: \(error.localizedDescription)"
                    }
                }
                return
            }

            let recognizedText = Self.normalizedSpeech(result.bestTranscription.formattedString)
            Task { @MainActor [weak self] in
                guard let self,
                      self.speechRecognitionGeneration == recognitionGeneration
                else { return }
                let matchesPassphrase = recognizedText == self.expectedPassphrase
                    || recognizedText.hasSuffix(" " + self.expectedPassphrase)
                self.didRecognizePassphrase = matchesPassphrase
                if matchesPassphrase {
                    self.updateVoiceMatchFromRecentFeatures()
                } else {
                    self.voiceMatchDetected = false
                }
                self.updateVoiceVerification()
                self.completeEnrollmentIfReady()
            }
        }

        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)

        // Ensure valid format
        guard inputFormat.channelCount > 0, inputFormat.sampleRate > 0 else {
            speechRecognitionGeneration &+= 1
            speechRecognitionTask?.cancel()
            speechRecognitionTask = nil
            speechRecognitionRequest = nil
            throw NSError(domain: "VoiceIDPipeline", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid microphone format."])
        }

        let bufferSize: AVAudioFrameCount = 2048
        let requestForAudio = speechRecognitionRequest

        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: inputFormat) { [weak self] buffer, time in
            requestForAudio?.append(buffer)
            self?.processPCMBuffer(buffer)
        }

        do {
            audioEngine.prepare()
            try audioEngine.start()
            isListening = true
            lastSoundAt = Date()
            statusMessage = "Say your voice passphrase..."
        } catch {
            inputNode.removeTap(onBus: 0)
            speechRecognitionGeneration &+= 1
            speechRecognitionTask?.cancel()
            speechRecognitionTask = nil
            speechRecognitionRequest = nil
            throw error
        }
    }

    func stopListening() {
        speechRecognitionGeneration &+= 1
        if isListening {
            audioEngine.inputNode.removeTap(onBus: 0)
            audioEngine.stop()
            isListening = false
            currentAudioLevel = 0.0
        }
        isCapturingForEnrollment = false
        speechRecognitionRequest?.endAudio()
        speechRecognitionTask?.cancel()
        speechRecognitionRequest = nil
        speechRecognitionTask = nil
        enrolledFeatureVector = nil
        recentVoiceFeatures = []
        statusMessage = "Idle"
    }

    // MARK: - Enrollment Mode

    func startEnrollmentCapture(
        passphrase: String,
        onProgress: @escaping (Double) -> Void,
        onComplete: @escaping ([Float]) -> Void
    ) throws {
        accumulatedSamples.removeAll()
        enrollmentFeatureVector = nil
        onEnrollmentProgress = onProgress
        onEnrollmentComplete = onComplete
        isCapturingForEnrollment = true
        do {
            try startListening(passphrase: passphrase)
        } catch {
            isCapturingForEnrollment = false
            throw error
        }
    }

    func stopEnrollmentCapture() {
        isCapturingForEnrollment = false
        stopListening()
    }

    // MARK: - Real-time PCM Buffer Processing (Accelerate / vDSP)

    private nonisolated func processPCMBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameLength = Int(buffer.frameLength)
        guard frameLength >= 512 else { return }

        // 1. Calculate RMS Audio Level for UI waveform
        var rms: Float = 0
        vDSP_rmsqv(channelData, 1, &rms, vDSP_Length(frameLength))

        let measuredRMS = rms
        let normalizedLevel = min(max(measuredRMS * 10.0, 0.0), 1.0)

        Task { @MainActor in
            self.currentAudioLevel = normalizedLevel
            if measuredRMS > 0.01 {
                self.lastSoundAt = Date()
                self.didDetectSpeech = true
            }
        }

        // Only process frames with sufficient speech energy (speech activity gate)
        guard measuredRMS > 0.02 else { return }

        // 2. Extract Spectral Voice Feature Vector via Accelerate FFT
        let featureVector = Self.extractVoiceFeatures(samples: channelData, count: frameLength)

        Task { @MainActor in
            if self.isCapturingForEnrollment {
                if self.accumulatedSamples.count < 40 {
                    self.accumulatedSamples.append(featureVector)
                }
                let progress = min(Double(self.accumulatedSamples.count) / 40.0, 1.0)
                self.onEnrollmentProgress?(progress)

                if self.accumulatedSamples.count == 40, self.enrollmentFeatureVector == nil {
                    self.enrollmentFeatureVector = Self.averageFeatureVectors(self.accumulatedSamples)
                }
                self.completeEnrollmentIfReady()
            } else if self.isListening {
                // Check verification against enrolled voice
                if let enrolledFeatureVector = self.enrolledFeatureVector {
                    let now = Date()
                    self.recentVoiceFeatures.removeAll {
                        now.timeIntervalSince($0.recordedAt) > 3
                    }
                    self.recentVoiceFeatures.append((now, featureVector))
                    if self.recentVoiceFeatures.count > 64 {
                        self.recentVoiceFeatures.removeFirst(self.recentVoiceFeatures.count - 64)
                    }
                    guard self.didRecognizePassphrase else {
                        self.voiceMatchDetected = false
                        self.updateVoiceVerification()
                        return
                    }
                    let similarity = Self.cosineSimilarity(featureVector, enrolledFeatureVector)
                    self.voiceMatchDetected = similarity >= self.matchThreshold
                    self.updateVoiceVerification(similarity: similarity)
                }
            }
        }
    }

    private func completeEnrollmentIfReady() {
        guard isCapturingForEnrollment,
              didRecognizePassphrase,
              let enrollmentFeatureVector
        else { return }

        isCapturingForEnrollment = false
        stopListening()
        onEnrollmentComplete?(enrollmentFeatureVector)
    }

    private func updateVoiceVerification(similarity: Float? = nil) {
        isVoiceVerified = voiceMatchDetected && didRecognizePassphrase
        if isVoiceVerified, let similarity {
            statusMessage = "✅ Voice ID and passphrase verified (\(Int(similarity * 100))%)"
        } else if didRecognizePassphrase {
            statusMessage = "Passphrase recognized. Checking voice..."
        } else {
            statusMessage = "Say your voice passphrase..."
        }
    }

    private func updateVoiceMatchFromRecentFeatures() {
        guard let enrolledFeatureVector, !recentVoiceFeatures.isEmpty else {
            voiceMatchDetected = false
            return
        }
        let recentVectors = recentVoiceFeatures.map(\.vector)
        let average = Self.averageFeatureVectors(recentVectors)
        voiceMatchDetected = Self.cosineSimilarity(average, enrolledFeatureVector) >= matchThreshold
    }

    private nonisolated static func normalizedSpeech(_ text: String) -> String {
        text.lowercased()
            .unicodeScalars
            .filter { CharacterSet.alphanumerics.contains($0) || CharacterSet.whitespacesAndNewlines.contains($0) }
            .map(String.init)
            .joined()
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }

    private nonisolated static func speechError(_ message: String) -> NSError {
        NSError(domain: "VoiceIDPipeline.SpeechRecognition", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
    }

    // MARK: - Accelerate Feature Extraction (FFT + Filterbank)

    private nonisolated static func extractVoiceFeatures(samples: UnsafePointer<Float>, count: Int) -> [Float] {
        let n = min(count, 1024)
        let log2n = vDSP_Length(log2(Float(n)))

        guard let fftSetup = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2)) else {
            return Array(repeating: 0.0, count: featureVectorSize)
        }
        defer { vDSP_destroy_fftsetup(fftSetup) }

        // Apply Hanning Window using Accelerate vDSP
        var windowed = [Float](repeating: 0, count: n)
        var window = [Float](repeating: 0, count: n)
        vDSP_hann_window(&window, vDSP_Length(n), Int32(vDSP_HANN_DENORM))
        vDSP_vmul(samples, 1, window, 1, &windowed, 1, vDSP_Length(n))

        // Prepare Split Complex representation
        var realp = [Float](repeating: 0, count: n / 2)
        var imagp = [Float](repeating: 0, count: n / 2)

        var featureVector = [Float](repeating: 0, count: featureVectorSize)

        realp.withUnsafeMutableBufferPointer { realBuffer in
            imagp.withUnsafeMutableBufferPointer { imagBuffer in
                var splitComplex = DSPSplitComplex(realp: realBuffer.baseAddress!, imagp: imagBuffer.baseAddress!)

                // Convert real signal to split complex
                windowed.withUnsafeBufferPointer { windowedBuffer in
                    windowedBuffer.baseAddress!.withMemoryRebound(to: DSPComplex.self, capacity: n / 2) { complexPtr in
                        vDSP_ctoz(complexPtr, 2, &splitComplex, 1, vDSP_Length(n / 2))
                    }
                }

                // Execute In-Place Forward FFT
                vDSP_fft_zrip(fftSetup, &splitComplex, 1, log2n, FFTDirection(FFT_FORWARD))

                // Scale FFT results
                var scale = 0.5 / Float(n)
                vDSP_vsmul(splitComplex.realp, 1, &scale, splitComplex.realp, 1, vDSP_Length(n / 2))
                vDSP_vsmul(splitComplex.imagp, 1, &scale, splitComplex.imagp, 1, vDSP_Length(n / 2))

                // Calculate Magnitude Spectrum squared
                var magnitudes = [Float](repeating: 0, count: n / 2)
                vDSP_zvmags(&splitComplex, 1, &magnitudes, 1, vDSP_Length(n / 2))

                // Bin into output feature vector size
                let binSize = (n / 2) / featureVectorSize
                for i in 0..<featureVectorSize {
                    let start = i * binSize
                    let end = min(start + binSize, n / 2)
                    var sum: Float = 0.0
                    for j in start..<end {
                        sum += magnitudes[j]
                    }
                    featureVector[i] = sqrt(max(sum, 1e-6))
                }
            }
        }

        // L2 Normalize vector
        return normalizeVector(featureVector)
    }

    private nonisolated static func normalizeVector(_ vector: [Float]) -> [Float] {
        var magSquared: Float = 0
        vDSP_svesq(vector, 1, &magSquared, vDSP_Length(vector.count))
        let magnitude = sqrt(magSquared)
        guard magnitude > 1e-6 else { return vector }
        var result = [Float](repeating: 0, count: vector.count)
        var scale = 1.0 / magnitude
        vDSP_vsmul(vector, 1, &scale, &result, 1, vDSP_Length(vector.count))
        return result
    }

    private nonisolated static func averageFeatureVectors(_ vectors: [[Float]]) -> [Float] {
        guard !vectors.isEmpty else { return Array(repeating: 0, count: featureVectorSize) }
        var sum = [Float](repeating: 0, count: featureVectorSize)
        for vec in vectors {
            vDSP_vadd(sum, 1, vec, 1, &sum, 1, vDSP_Length(featureVectorSize))
        }
        var countFactor = 1.0 / Float(vectors.count)
        var avg = [Float](repeating: 0, count: featureVectorSize)
        vDSP_vsmul(sum, 1, &countFactor, &avg, 1, vDSP_Length(featureVectorSize))
        return normalizeVector(avg)
    }

    // MARK: - Cosine Similarity using Accelerate vDSP

    nonisolated static func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Float {
        guard a.count == b.count, !a.isEmpty else { return 0.0 }
        var dotProduct: Float = 0
        vDSP_dotpr(a, 1, b, 1, &dotProduct, vDSP_Length(a.count))

        var normA: Float = 0
        vDSP_svesq(a, 1, &normA, vDSP_Length(a.count))

        var normB: Float = 0
        vDSP_svesq(b, 1, &normB, vDSP_Length(b.count))

        let denom = sqrt(normA * normB)
        guard denom > 1e-6 else { return 0.0 }
        return max(0.0, min(1.0, dotProduct / denom))
    }
}
