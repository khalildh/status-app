import Foundation
import FirebaseStorage
import UIKit

@MainActor
@Observable
final class StorageService {
    var isUploading = false
    var uploadProgress: Double = 0

    @ObservationIgnored private var _storage: Storage?
    private var storage: Storage { if _storage == nil { _storage = Storage.storage() }; return _storage! }

    func uploadAvatar(userId: String, image: UIImage) async throws -> String {
        guard let data = image.jpegData(compressionQuality: 0.7) else {
            throw StorageError.invalidImage
        }

        isUploading = true
        uploadProgress = 0

        let ref = storage.reference().child("avatars/\(userId).jpg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        let _ = try await ref.putDataAsync(data, metadata: metadata)
        let url = try await ref.downloadURL()

        isUploading = false
        uploadProgress = 1.0
        return url.absoluteString
    }

    static var preview: StorageService {
        StorageService()
    }
}

enum StorageError: LocalizedError {
    case invalidImage

    var errorDescription: String? {
        switch self {
        case .invalidImage: "Could not process the selected image."
        }
    }
}
