import AppKit

@MainActor
final class InteractionSoundPlayer {
    private let volume: Float = 0.22

    func playStart() {
        let sounds = resolvedSounds(for: currentPreset())
        play(named: sounds.start)
    }

    func playEnd() {
        let sounds = resolvedSounds(for: currentPreset())
        play(named: sounds.end)
    }

    func playPreview(preset: InteractionSoundPreset) {
        let sounds = resolvedSounds(for: preset)
        play(named: sounds.start)
    }

    private func currentPreset() -> InteractionSoundPreset {
        let raw = UserDefaults.standard.string(forKey: AppPreferenceKey.interactionSoundPreset) ?? ""
        return InteractionSoundPreset(rawValue: raw) ?? .soft
    }

    private func resolvedSounds(for preset: InteractionSoundPreset) -> (start: String, end: String) {
        switch preset {
        case .soft:
            return ("Pop", "Tink")
        case .glass:
            return ("Ping", "Ping")
        case .funk:
            return ("Morse", "Morse")
        case .submarine:
            return ("Submarine", "Submarine")
        }
    }

    private func play(named name: String) {
        let sound = NSSound(named: name) ?? NSSound(named: "Pop") ?? NSSound(named: "Tink")
        sound?.stop()
        sound?.volume = volume
        sound?.play()
    }
}
