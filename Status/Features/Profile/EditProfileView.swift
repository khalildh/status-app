import SwiftUI
import PhotosUI
import FirebaseFirestore

struct EditProfileView: View {
    @Environment(AuthService.self) private var auth
    @Environment(StorageService.self) private var storageService
    @Environment(\.dismiss) private var dismiss

    @State private var displayName: String = ""
    @State private var bio: String = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var avatarImage: UIImage?
    @State private var isSaving = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                // Avatar section
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            if let image = avatarImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 80, height: 80)
                                    .clipShape(Circle())
                            } else if let user = auth.currentUser {
                                AvatarView(user: user, size: 80)
                            }

                            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                                Text("Change Photo")
                                    .font(.subheadline)
                            }
                        }
                        Spacer()
                    }
                }
                .listRowBackground(Color.clear)

                // Info section
                Section("Profile") {
                    TextField("Display Name", text: $displayName)
                        .textContentType(.name)
                    TextField("Bio", text: $bio, axis: .vertical)
                        .lineLimit(3...6)
                }

                if let error {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await save() }
                    }
                    .disabled(isSaving || displayName.isEmpty)
                }
            }
            .onChange(of: selectedPhoto) {
                Task { await loadPhoto() }
            }
            .onAppear {
                if let user = auth.currentUser {
                    displayName = user.displayName
                    bio = user.bio ?? ""
                }
            }
        }
    }

    private func loadPhoto() async {
        guard let item = selectedPhoto,
              let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }
        avatarImage = image
    }

    private func save() async {
        guard let user = auth.currentUser else { return }
        isSaving = true
        error = nil

        do {
            var updates: [String: Any] = [
                "displayName": displayName,
                "bio": bio.isEmpty ? NSNull() : bio
            ]

            // Upload avatar if changed
            if let image = avatarImage {
                let url = try await storageService.uploadAvatar(userId: user.id, image: image)
                updates["avatarURL"] = url
            }

            let db = Firestore.firestore()
            try await db.collection("users").document(user.id).updateData(updates)
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }

        isSaving = false
    }
}
