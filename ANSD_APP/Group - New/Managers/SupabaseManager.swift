import Foundation
import Supabase
import Auth

class SupabaseManager {
    
    // 1. Singleton Instance
    static let shared = SupabaseManager()
    
    // 2. Client Initialization with iOS 26+ Auth configuration
    let client = SupabaseClient(
        supabaseURL: URL(string: "https://ipiurathexblvbhelgic.supabase.co")!,
        supabaseKey: "sb_publishable_AvEDotm41iGrJobKBaJAHA_Nb7pCYce",
        options: SupabaseClientOptions(
            auth: .init(
                emitLocalSessionAsInitialSession: true
            )
        )
    )
    
    private init() {}
    
    // MARK: - Auth Helpers
    
    func isUserAuthenticated() async -> Bool {
        do {
            let session = try await client.auth.session
            return !session.isExpired
        } catch {
            return false
        }
    }
    
    /// This resolves the "no member" error
    func signInAnonymously() async throws {
        try await client.auth.signInAnonymously()
    }
    
    // MARK: - Email Auth
    
    func signUp(email: String, password: String, metadata: [String: Any]) async throws {
        // Fix for Decodable/Encodable errors: Map types to AnyJSON
        var jsonMetadata: [String: AnyJSON] = [:]
        
        for (key, value) in metadata {
            if let s = value as? String { jsonMetadata[key] = .string(s) }
            else if let i = value as? Int { jsonMetadata[key] = .integer(i) }
            else if let d = value as? Double { jsonMetadata[key] = .double(d) }
            else if let b = value as? Bool { jsonMetadata[key] = .bool(b) }
        }
        
        try await client.auth.signUp(email: email, password: password, data: jsonMetadata)
    }

    func signIn(email: String, password: String) async throws {
        try await client.auth.signIn(email: email, password: password)
    }

    func signOut() async throws {
        try await client.auth.signOut()
    }
}
