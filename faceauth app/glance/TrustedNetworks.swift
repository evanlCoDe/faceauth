//
//  TrustedNetworks.swift
//  glance
//
//  Provides a fail-closed Wi-Fi identity check for FaceAuth's automatic
//  password injection. SSID/BSSID matching is not cryptographic proof.
//

import Foundation
import CoreWLAN

nonisolated struct TrustedWiFiNetwork: Codable, Identifiable, Hashable, Sendable {
    var id: String { "\(normalizedSSID)|\(normalizedBSSID)" }
    let ssid: String
    let bssid: String

    var normalizedSSID: String { ssid.trimmingCharacters(in: .whitespacesAndNewlines) }
    var normalizedBSSID: String { bssid.lowercased() }

    init?(ssid: String?, bssid: String?) {
        guard let ssid = ssid?.trimmingCharacters(in: .whitespacesAndNewlines),
              !ssid.isEmpty,
              let bssid = bssid?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
              !bssid.isEmpty
        else { return nil }
        self.ssid = ssid
        self.bssid = bssid
    }
}

nonisolated enum TrustedNetworkManager {
    static func availableNetworks() throws -> [TrustedWiFiNetwork] {
        guard let interface = CWWiFiClient.shared().interface() else {
            throw networkError("No Wi-Fi interface is available.")
        }
        let networks = try interface.scanForNetworks(withName: nil)
        return Set(networks.compactMap {
            TrustedWiFiNetwork(ssid: $0.ssid, bssid: $0.bssid)
        })
        .sorted {
            if $0.normalizedSSID == $1.normalizedSSID {
                return $0.normalizedBSSID < $1.normalizedBSSID
            }
            return $0.normalizedSSID.localizedCaseInsensitiveCompare($1.normalizedSSID) == .orderedAscending
        }
    }

    static func currentNetwork() throws -> TrustedWiFiNetwork {
        guard let interface = CWWiFiClient.shared().interface() else {
            throw networkError("No Wi-Fi interface is available.")
        }
        guard let identity = TrustedWiFiNetwork(ssid: interface.ssid(), bssid: interface.bssid())
        else {
            throw networkError("The current Wi-Fi network identity is unavailable.")
        }
        return identity
    }

    static func authorizationResult(
        isEnabled: Bool,
        trustedNetworks: [TrustedWiFiNetwork]
    ) -> Result<Void, Error> {
        guard isEnabled else { return .success(()) }
        guard !trustedNetworks.isEmpty else {
            return .failure(networkError("Trusted Networks is on, but no Wi-Fi networks are configured."))
        }

        do {
            let current = try currentNetwork()
            guard trustedNetworks.contains(where: {
                $0.normalizedSSID == current.normalizedSSID
                    && $0.normalizedBSSID == current.normalizedBSSID
            }) else {
                return .failure(networkError("This Wi-Fi network isn't in your Trusted Networks list. Use Touch ID or your Mac password."))
            }
            return .success(())
        } catch {
            return .failure(error)
        }
    }

    private static func networkError(_ description: String) -> NSError {
        NSError(
            domain: "TrustedNetworkManager",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: description]
        )
    }
}
