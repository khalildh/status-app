import SwiftUI

struct LocationGateView: View {
    @Environment(LocationGate.self) private var locationGate

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            if locationGate.isChecking {
                ProgressView()
                    .scaleEffect(1.5)
                Text("Checking your location...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else if locationGate.denied {
                Image(systemName: "location.slash.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.secondary)
                Text("Location Access Needed")
                    .font(.title2.weight(.bold))
                Text("Status is currently only available in New York City. Enable location access to verify you're in the area.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.primary)
            } else {
                Image(systemName: "mappin.slash")
                    .font(.system(size: 56))
                    .foregroundStyle(.secondary)
                Text("Not Available Yet")
                    .font(.title2.weight(.bold))
                Text("Status is currently only available in New York City. We're expanding soon.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                Button("Check Again") {
                    locationGate.checkLocation()
                }
                .buttonStyle(.borderedProminent)
                .tint(.primary)
            }

            Spacer()
        }
    }
}
