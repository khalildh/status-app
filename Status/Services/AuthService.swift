import Foundation
@preconcurrency import FirebaseAuth
@preconcurrency import FirebaseFirestore

@MainActor
@Observable
final class AuthService {
    var currentUser: User?
    var isAuthenticated: Bool { currentUser != nil }
    var isLoading = false
    var error: String?

    private var authHandle: AuthStateDidChangeListenerHandle?
    private var userListener: ListenerRegistration?
    @ObservationIgnored private var _db: Firestore? = nil
    private var db: Firestore { if _db == nil { _db = Firestore.firestore() }; return _db! }

    init() {
        #if DEBUG
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" ||
           ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
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
                    self.userListener?.remove()
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
            let user = User(
                id: result.user.uid,
                username: username,
                displayName: username,
                joinedAt: .now,
                statusBalance: User.weeklyFreePoints,
                weeklyRefillAmount: User.weeklyFreePoints,
                lastRefillDate: .now,
                totalStatusReceived: 0,
                broadcastsToday: 0
            )
            try db.collection("users").document(user.id).setData(from: user)
            currentUser = user
            listenToUserDocument(userId: user.id)
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
        userListener?.remove()
        try? Auth.auth().signOut()
        currentUser = nil
    }

    private func fetchOrCreateUser(firebaseId: String, email: String?) async {
        do {
            let doc = try await db.collection("users").document(firebaseId).getDocument()
            if doc.exists {
                currentUser = try doc.data(as: User.self)
            } else {
                let user = User(
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
                try db.collection("users").document(firebaseId).setData(from: user)
                currentUser = user
            }
            listenToUserDocument(userId: firebaseId)
        } catch {
            self.error = error.localizedDescription
        }
    }

    /// Real-time listener on the current user's document so balance/status updates sync live.
    private func listenToUserDocument(userId: String) {
        userListener?.remove()
        userListener = db.collection("users").document(userId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self, let snapshot, snapshot.exists else { return }
                self.currentUser = try? snapshot.data(as: User.self)
            }
    }

    // MARK: - Preview helper
    static var preview: AuthService {
        let service = AuthService()
        service.currentUser = .mock
        return service
    }
}
