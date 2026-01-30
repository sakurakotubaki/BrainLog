import SwiftUI

struct SettingsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var languageManager = LanguageManager.shared

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundColor
                    .ignoresSafeArea()

                List {
                    // Language Section
                    Section {
                        Picker("settings_language".localized(), selection: $languageManager.appLanguage) {
                            Text("language_system".localized()).tag("system")
                            Text("English").tag("en")
                            Text("日本語").tag("ja")
                        }
                    } header: {
                        Text("settings_section_general".localized())
                    }

                    // Legal Section
                    Section {
                        Link(destination: URL(string: "https://pacific-sandalwood-6de.notion.site/2f8a1df91a0780d09697d13cdc7f7fcd")!) {
                            HStack {
                                Text("settings_terms".localized())
                                    .foregroundStyle(primaryTextColor)
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Link(destination: URL(string: "https://pacific-sandalwood-6de.notion.site/2f8a1df91a0780f7b85cdbba9abdbbab")!) {
                            HStack {
                                Text("settings_privacy".localized())
                                    .foregroundStyle(primaryTextColor)
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } header: {
                        Text("settings_section_legal".localized())
                    }

                    // About Section
                    Section {
                        HStack {
                            Text("settings_version".localized())
                                .foregroundStyle(primaryTextColor)
                            Spacer()
                            Text(appVersion)
                                .foregroundStyle(.secondary)
                        }
                    } header: {
                        Text("settings_section_about".localized())
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("settings_title".localized())
        }
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    private var backgroundColor: Color {
        colorScheme == .dark ? Color(hex: "0d1117") : Color(hex: "ffffff")
    }

    private var primaryTextColor: Color {
        colorScheme == .dark ? .white : .black
    }
}

#Preview {
    SettingsView()
}
