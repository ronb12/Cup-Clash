import AVFoundation
import Foundation

enum SoundEffect: String, CaseIterable, Sendable {
    case button
    case throwRelease
    case tableBounce
    case rimHit
    case made
    case miss
    case turn
    case victory
    case defeat
    case coins
    case levelUp

    /// Required bundled filename without extension. Missing files are ignored.
    var filename: String {
        switch self {
        case .button: "sfx_button"
        case .throwRelease: "sfx_throw"
        case .tableBounce: "sfx_table"
        case .rimHit: "sfx_rim"
        case .made: "sfx_made"
        case .miss: "sfx_miss"
        case .turn: "sfx_turn"
        case .victory: "sfx_victory"
        case .defeat: "sfx_defeat"
        case .coins: "sfx_coins"
        case .levelUp: "sfx_levelup"
        }
    }
}

@MainActor
final class AudioManager {
    static let shared = AudioManager()

    var musicEnabled = true
    var effectsEnabled = true

    private var effectPlayers: [SoundEffect: AVAudioPlayer] = [:]
    private var musicPlayer: AVAudioPlayer?
    private var sessionConfigured = false

    func configure() {
        guard !sessionConfigured else { return }
        sessionConfigured = true
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            // Audio session failure is non-fatal.
        }
        preload()
    }

    func play(_ effect: SoundEffect) {
        guard effectsEnabled else { return }
        configure()
        guard let player = player(for: effect) else { return }
        player.currentTime = 0
        player.play()
    }

    func playAmbientIfAvailable() {
        guard musicEnabled else {
            musicPlayer?.stop()
            return
        }
        configure()
        if musicPlayer == nil {
            musicPlayer = makePlayer(named: "music_ambient")
            musicPlayer?.numberOfLoops = -1
            musicPlayer?.volume = 0.28
        }
        musicPlayer?.play()
    }

    func stopAmbient() {
        musicPlayer?.stop()
    }

    func apply(settings: GameSettings) {
        musicEnabled = settings.musicEnabled
        effectsEnabled = settings.soundEffectsEnabled
        if musicEnabled {
            playAmbientIfAvailable()
        } else {
            stopAmbient()
        }
    }

    private func preload() {
        for effect in SoundEffect.allCases {
            effectPlayers[effect] = makePlayer(named: effect.filename)
        }
    }

    private func player(for effect: SoundEffect) -> AVAudioPlayer? {
        if let existing = effectPlayers[effect] {
            return existing
        }
        let created = makePlayer(named: effect.filename)
        effectPlayers[effect] = created
        return created
    }

    private func makePlayer(named filename: String) -> AVAudioPlayer? {
        let extensions = ["caf", "wav", "mp3", "m4a"]
        for fileExtension in extensions {
            if let url = Bundle.main.url(forResource: filename, withExtension: fileExtension) {
                return try? AVAudioPlayer(contentsOf: url)
            }
        }
        return nil
    }
}
