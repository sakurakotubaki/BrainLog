import SwiftUI

struct SpotlightTutorialView: View {
    let targetFrame: CGRect
    let message: String
    let onDismiss: () -> Void

    @State private var opacity: Double = 0

    private let spotlightPadding: CGFloat = 8

    private var spotlightCenter: CGPoint {
        CGPoint(x: targetFrame.midX, y: targetFrame.midY)
    }

    private var spotlightRadius: CGFloat {
        max(targetFrame.width, targetFrame.height) / 2 + spotlightPadding
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 暗いオーバーレイ（スポットライト部分を切り抜き）
                Rectangle()
                    .fill(Color.black.opacity(0.8))
                    .reverseMask {
                        Circle()
                            .frame(width: spotlightRadius * 2, height: spotlightRadius * 2)
                            .position(spotlightCenter)
                    }
                    .ignoresSafeArea()

                // 説明メッセージ
                VStack(spacing: 16) {
                    Text(message)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    Button(action: {
                        withAnimation(.easeOut(duration: 0.2)) {
                            opacity = 0
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            onDismiss()
                        }
                    }) {
                        Text("tutorial_got_it".localized())
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .clipShape(Capsule())
                    }
                }
                .position(
                    x: geometry.size.width / 2,
                    y: spotlightCenter.y + spotlightRadius + 80
                )
            }
        }
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeIn(duration: 0.3)) {
                opacity = 1
            }
        }
        .onTapGesture {
            withAnimation(.easeOut(duration: 0.2)) {
                opacity = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                onDismiss()
            }
        }
    }
}

// MARK: - Reverse Mask Extension
extension View {
    @ViewBuilder
    func reverseMask<Mask: View>(@ViewBuilder _ mask: () -> Mask) -> some View {
        self.mask(
            Rectangle()
                .overlay(
                    mask()
                        .blendMode(.destinationOut)
                )
        )
    }
}

// MARK: - Tutorial Manager
@Observable
class TutorialManager {
    static let shared = TutorialManager()

    private let hasSeenTutorialKey = "hasSeenHelpButtonTutorial"

    var hasSeenTutorial: Bool {
        get { UserDefaults.standard.bool(forKey: hasSeenTutorialKey) }
        set { UserDefaults.standard.set(newValue, forKey: hasSeenTutorialKey) }
    }

    private init() {}

    func markTutorialAsSeen() {
        hasSeenTutorial = true
    }
}
