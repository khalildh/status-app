import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var currentPage = 0

    private let pages: [(icon: String, title: String, body: String)] = [
        (
            "arrow.up.circle.fill",
            "Give Status",
            "You get 5 status points per week. Give them to people you respect. Buy more if you want."
        ),
        (
            "bubble.left.and.bubble.right.fill",
            "Unlock Messaging",
            "Message anyone with less status than you. Or give status to someone connected to who you want to reach."
        ),
        (
            "antenna.radiowaves.left.and.right",
            "Broadcast Daily",
            "One broadcast per day. It reaches everyone who gave you status — and disappears in 24 hours."
        ),
        (
            "chart.bar.fill",
            "Climb the Leaderboard",
            "Your rank is based on how much weighted status you've received. Higher rank = bigger audience."
        ),
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    VStack(spacing: 24) {
                        Spacer()

                        Image(systemName: page.icon)
                            .font(.system(size: 72))
                            .foregroundStyle(.primary)

                        Text(page.title)
                            .font(.title.weight(.bold))

                        Text(page.body)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)

                        Spacer()
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            // Bottom button
            Button {
                if currentPage < pages.count - 1 {
                    withAnimation {
                        currentPage += 1
                    }
                } else {
                    hasSeenOnboarding = true
                }
            } label: {
                Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(.primary)
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
    }
}
