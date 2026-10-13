//
//  SecureVoiceStore.swift
//  glance
//
//  Low-level encrypted persistence for enrolled voice profiles — AES-GCM under the same session key
//  SecureCredentialManager uses for the Mac password, alongside Keychain Services.
//

import Foundation
import Security

struct VoiceProfile: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    let featureVector: [Float]
    var passphrase: String?
    let createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        featureVector: [Float],
        passphrase: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.featureVector = featureVector
        self.passphrase = passphrase
        self.createdAt = createdAt
    }
}

enum SecureVoiceStoreError: LocalizedError {
    case sessionLocked
    case voiceNotRegistered

    var errorDescription: String? {
        switch self {
        case .sessionLocked:
            return "Session is locked. Authenticate to access enrolled voice data."
        case .voiceNotRegistered:
            return "No voice profile has been registered yet."
        }
    }
}

nonisolated enum SecureVoiceStore {
    private static let fileURL: URL = {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let directory = appSupport.appendingPathComponent("glance", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("voice-profiles.enc")
    }()

    static var exists: Bool {
        FileManager.default.fileExists(atPath: fileURL.path)
    }

    static func load() throws -> [VoiceProfile] {
        guard SecureCredentialManager.isSessionUnlocked else { throw SecureVoiceStoreError.sessionLocked }
        guard let ciphertext = try? Data(contentsOf: fileURL) else { return [] }
        let plaintext = try SecureCredentialManager.decrypt(ciphertext)
        return try JSONDecoder().decode([VoiceProfile].self, from: plaintext)
    }

    static func save(_ profiles: [VoiceProfile]) throws {
        guard SecureCredentialManager.isSessionUnlocked else { throw SecureVoiceStoreError.sessionLocked }
        let plaintext = try JSONEncoder().encode(profiles)
        let ciphertext = try SecureCredentialManager.encrypt(plaintext)
        try ciphertext.write(to: fileURL, options: .atomic)

        // Also update Keychain backup for Voice ID validation
        if let first = profiles.first {
            let keychainData = try JSONEncoder().encode(first)
            try? KeychainManager.save(account: "voice_profile_\(first.id.uuidString)", data: keychainData)
        }
    }

    static func deleteAll() {
        try? FileManager.default.removeItem(at: fileURL)
    }
}
