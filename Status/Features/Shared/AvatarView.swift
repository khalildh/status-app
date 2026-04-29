import SwiftUI

struct AvatarView: View {
    let user: User
    var size: CGFloat = 40

    var body: some View {
        Group {
            if let urlString = user.avatarURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }

    private var placeholder: some View {
        Circle()
            .fill(.quaternary)
            .overlay {
                Text(user.displayName.prefix(1).uppercased())
                    .font(.system(size: size * 0.4, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
    }
}

/// Avatar for when you only have an ID, not a full User
struct AvatarPlaceholder: View {
    let name: String
    var size: CGFloat = 40

    var body: some View {
        Circle()
            .fill(.quaternary)
            .frame(width: size, height: size)
            .overlay {
                Text(name.prefix(1).uppercased())
                    .font(.system(size: size * 0.4, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
    }
}
