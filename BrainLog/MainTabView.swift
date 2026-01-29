//
//  MainTabView.swift
//  BrainLog
//
//  Created by 橋本純一 on 2026/01/30.
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var languageManager = LanguageManager.shared

    var body: some View {
        TabView {
            ContentView()
                .tabItem {
                    Label("tab_timeline".localized(), systemImage: "point.topleft.down.to.point.bottomright.curvepath")
                }

            SettingsView()
                .tabItem {
                    Label("tab_settings".localized(), systemImage: "gearshape")
                }
        }
        .tint(accentColor)
    }

    private var accentColor: Color {
        colorScheme == .dark ? Color(hex: "58a6ff") : Color(hex: "0969da")
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: Item.self, inMemory: true)
}
