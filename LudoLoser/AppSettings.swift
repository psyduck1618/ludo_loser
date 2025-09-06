import Foundation

enum Settings {
    private static let kWood = "woodTheme"
    private static let kSFX = "sfxEnabled"

    static var woodTheme: Bool {
        get { UserDefaults.standard.object(forKey: kWood) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: kWood) }
    }

    static var sfxEnabled: Bool {
        get { UserDefaults.standard.object(forKey: kSFX) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: kSFX) }
    }
}

