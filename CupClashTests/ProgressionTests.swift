import XCTest
@testable import CupClash

final class ProgressionTests: XCTestCase {
    func testLevelOneStartsAtZero() {
        XCTAssertEqual(ProgressionMath.totalXP(toReach: 1), 0)
        XCTAssertEqual(ProgressionMath.level(forTotalXP: 0), 1)
    }

    func testLevelTwoRequires250() {
        XCTAssertEqual(ProgressionMath.xpRequired(from: 1), 250)
        XCTAssertEqual(ProgressionMath.level(forTotalXP: 249), 1)
        XCTAssertEqual(ProgressionMath.level(forTotalXP: 250), 2)
    }

    func testEachLevelAddsFiftyMore() {
        XCTAssertEqual(ProgressionMath.xpRequired(from: 2), 300)
        XCTAssertEqual(ProgressionMath.xpRequired(from: 3), 350)
        XCTAssertEqual(ProgressionMath.totalXP(toReach: 3), 550)
        XCTAssertEqual(ProgressionMath.level(forTotalXP: 550), 3)
    }

    func testProgressFraction() {
        let progress = ProgressionMath.progress(totalXP: 125)
        XCTAssertEqual(progress.level, 1)
        XCTAssertEqual(progress.intoLevel, 125)
        XCTAssertEqual(progress.needed, 250)
        XCTAssertEqual(progress.fraction, 0.5, accuracy: 0.001)
    }
}
