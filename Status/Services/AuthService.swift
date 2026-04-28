import Foundation
import FirebaseAuth

@Observable
final class AuthService {
    var currentUser: User?
    var isAuthenticated: Bool { currentUser != nil }
    var isLoading = false
    var error: String?

    private var authHandle: AuthStateDidChangeListenerHandle?

    init() {
        #if DEBUG
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            currentUser = .mock
            return
        }
        #endif
        listenForAuthChanges()
    }

    private func listenForAuthChanges() {
        authHandle = Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            guard let self else { return }
            if let firebaseUser {
                Task { @MainActor in
                    await self.fetchOrCreateUser(firebaseId: firebaseUser.uid, email: firebaseUser.email)
                }
            } else {
                Task { @MainActor in
                    self.currentUser = nil
                }
            }
        }
    }

    func signUp(email: String, password: String, username: String) async {
        isLoading = true
        error = nil
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            await createUserProfile(firebaseId: result.user.uid, email: email, username: username)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func signIn(email: String, password: String) async {
        isLoading = true
        error = nil
        do {
            try await Auth.auth().signIn(withEmail: email, password: password)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func signOut() {
        try? Auth.auth().signOut()
        currentUser = nil
    }

    private func fetchOrCreateUser(firebaseId: String, email: String?) async {
        // In production: fetch from Firestore
        // For now, create a local user
        currentUser = User(
            id: firebaseId,
            username: email?.components(separatedBy: "@").first ?? "user",
            displayName: email?.components(separatedBy: "@").first ?? "User",
            joinedAt: .now,
            statusBalance: User.weeklyFreePoints,
            weeklyRefillAmount: User.weeklyFreePoints,
            lastRefillDate: .now,
            totalStatusReceived: 0,
            broadcastsToday: 0
        )
    }

    private func createUserProfile(firebaseId: String, email: String, username: String) async {
        currentUser = User(
            id: firebaseId,
            username: username,
            displayName: username,
            joinedAt: .now,
            statusBalance: User.weeklyFreePoints,
            weeklyRefillAmount: User.weeklyFreePoints,
            lastRefillDate: .now,
            totalStatusReceived: 0,
            broadcastsToday: 0
        )
    }

    // MARK: - Preview helper
    static var preview: AuthService {
        let service = AuthService()
        service.currentUser = .mock
        return service
    }
}
