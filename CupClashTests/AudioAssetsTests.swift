import XCTest
import AVFoundation
@testable import CupClash

final class AudioAssetsTests: XCTestCase {
    private func bundledURL(_ name: String) -> URL? {
        ["caf", "wav", "mp3", "m4a"].lazy.compactMap { Bundle.main.url(forResource: name, withExtension: $0) }.first
    }

    func testEverySoundEffectIsBundledAndPlayable() throws {
        for effect in SoundEffect.allCases {
            let url = try XCTUnwrap(bundledURL(effect.filename), "Missing audio file for \(effect)")
            let player = try AVAudioPlayer(contentsOf: url)
            XCTAssertGreaterThan(player.duration, 0.03, "\(effect) is too short")
            XCTAssertLessThan(player.duration, 3, "\(effect) is too long for an effect")
        }
    }

    func testAmbientMusicIsBundled() throws {
        let url = try XCTUnwrap(bundledURL("music_ambient"))
        XCTAssertGreaterThan(try AVAudioPlayer(contentsOf: url).duration, 5)
    }
}
