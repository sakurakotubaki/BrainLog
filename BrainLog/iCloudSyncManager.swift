import Foundation

@Observable
class iCloudSyncManager {
    static let shared = iCloudSyncManager()

    private let enabledKey = "iCloudSyncEnabled"

    var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: enabledKey)
        }
    }

    private init() {
        self.isEnabled = UserDefaults.standard.bool(forKey: enabledKey)
    }
}
