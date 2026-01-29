//
//  LanguageManager.swift
//  BrainLog
//
//  Created by 橋本純一 on 2026/01/30.
//

import SwiftUI
import Observation

@Observable
class LanguageManager {
    static let shared = LanguageManager()

    var appLanguage: String {
        didSet {
            UserDefaults.standard.set(appLanguage, forKey: "appLanguage")
        }
    }

    private init() {
        self.appLanguage = UserDefaults.standard.string(forKey: "appLanguage") ?? "system"
    }

    func localizedString(_ key: String) -> String {
        let languageCode: String
        switch appLanguage {
        case "en":
            languageCode = "en"
        case "ja":
            languageCode = "ja"
        default:
            languageCode = Locale.current.language.languageCode?.identifier ?? "en"
        }

        guard let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return NSLocalizedString(key, comment: "")
        }

        return NSLocalizedString(key, bundle: bundle, comment: "")
    }
}

extension String {
    func localized() -> String {
        LanguageManager.shared.localizedString(self)
    }
}
