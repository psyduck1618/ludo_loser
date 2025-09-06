import SwiftUI

struct SettingsView: View {
    // AppStorage writes to UserDefaults automatically; no onChange needed.
    @AppStorage("woodTheme") private var woodTheme: Bool = Settings.woodTheme
    @AppStorage("sfxEnabled") private var sfxEnabled: Bool = Settings.sfxEnabled

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Appearance")) {
                    Toggle("Wood Board Theme", isOn: $woodTheme)
                }
                Section(header: Text("Effects")) {
                    Toggle("Haptics / SFX", isOn: $sfxEnabled)
                }
                Section(footer: Text("Variant: first to finish loses. Turns auto-end.")) {
                    EmptyView()
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview { SettingsView() }
