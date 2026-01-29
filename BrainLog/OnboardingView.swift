import SwiftUI

struct OnboardingView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var currentPage = 0
    @State private var languageManager = LanguageManager.shared
    @Binding var hasCompletedOnboarding: Bool

    private let totalPages = 4

    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    OnboardingPageView(
                        imageName: "think",
                        title: "onboarding_title_1".localized(),
                        description: "onboarding_desc_1".localized()
                    )
                    .tag(0)

                    OnboardingPageView(
                        imageName: "without",
                        title: "onboarding_title_2".localized(),
                        description: "onboarding_desc_2".localized()
                    )
                    .tag(1)

                    OnboardingPageView(
                        imageName: "work",
                        title: "onboarding_title_3".localized(),
                        description: "onboarding_desc_3".localized()
                    )
                    .tag(2)

                    OnboardingPageView(
                        imageName: "mirror",
                        title: "onboarding_title_4".localized(),
                        description: "onboarding_desc_4".localized(),
                        subDescription: "onboarding_subdesc_4".localized()
                    )
                    .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Page Indicator
                HStack(spacing: 8) {
                    ForEach(0..<totalPages, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? accentColor : Color.gray.opacity(0.5))
                            .frame(width: 8, height: 8)
                            .animation(.easeInOut(duration: 0.2), value: currentPage)
                    }
                }
                .padding(.bottom, 24)

                // Buttons
                HStack(spacing: 16) {
                    if currentPage > 0 {
                        Button(action: {
                            withAnimation {
                                currentPage -= 1
                            }
                        }) {
                            Text("onboarding_back".localized())
                                .font(.headline)
                                .foregroundStyle(secondaryTextColor)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(secondaryButtonBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }

                    Button(action: {
                        if currentPage < totalPages - 1 {
                            withAnimation {
                                currentPage += 1
                            }
                        } else {
                            completeOnboarding()
                        }
                    }) {
                        Text(currentPage < totalPages - 1 ? "onboarding_next".localized() : "onboarding_start".localized())
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(accentColor)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }

    private func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        withAnimation {
            hasCompletedOnboarding = true
        }
    }

    private var backgroundColor: Color {
        colorScheme == .dark ? Color(hex: "0d1117") : Color(hex: "ffffff")
    }

    private var accentColor: Color {
        colorScheme == .dark ? Color(hex: "238636") : Color(hex: "1a7f37")
    }

    private var secondaryTextColor: Color {
        colorScheme == .dark ? Color(hex: "8b949e") : Color(hex: "57606a")
    }

    private var secondaryButtonBackground: Color {
        colorScheme == .dark ? Color(hex: "21262d") : Color(hex: "f6f8fa")
    }
}

struct OnboardingPageView: View {
    @Environment(\.colorScheme) private var colorScheme

    let imageName: String
    let title: String
    let description: String
    var subDescription: String? = nil

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 280, maxHeight: 280)
                .clipShape(RoundedRectangle(cornerRadius: 20))

            VStack(spacing: 12) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(primaryTextColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Text(description)
                    .font(.body)
                    .foregroundStyle(secondaryTextColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                if let subDesc = subDescription {
                    Text(subDesc)
                        .font(.caption)
                        .foregroundStyle(tertiaryTextColor)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.top, 8)
                }
            }

            Spacer()
            Spacer()
        }
    }

    private var primaryTextColor: Color {
        colorScheme == .dark ? .white : .black
    }

    private var secondaryTextColor: Color {
        colorScheme == .dark ? Color(hex: "8b949e") : Color(hex: "57606a")
    }

    private var tertiaryTextColor: Color {
        colorScheme == .dark ? Color(hex: "6e7681") : Color(hex: "6e7681")
    }
}

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
}
