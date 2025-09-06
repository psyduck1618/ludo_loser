import Foundation
import AudioToolbox

/// Lightweight system-sound wrapper. Uses built-in sound IDs to avoid bundling assets.
enum Sound {
    private static func play(id: SystemSoundID) {
        guard Settings.sfxEnabled else { return }
        AudioServicesPlaySystemSound(id)
    }
    static func dice() { play(id: 1104) }      // Tock
    static func step() { play(id: 1157) }      // Tick
    static func capture() { play(id: 1057) }   // Chord
    static func home() { play(id: 1111) }      // Pop
    static func boost() { play(id: 1001) }     // Beep
    static func trap() { play(id: 1006) }      // Error
}
