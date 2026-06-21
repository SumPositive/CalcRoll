// CalclinUITests.swift
// 基本的な起動UIテスト

import XCTest

// UIテストはSwift Testing非対応のためXCTestで実行する
final class CalclinUITests: XCTestCase {

    // アプリを起動して前面表示できることを確認する
    @MainActor
    func testLaunchesApplication() {
        let app = XCUIApplication()
        app.launch()
        defer { app.terminate() }

        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
    }

    // アプリを規定時間内に起動できることを確認する
    @MainActor
    func testLaunchesWithinExpectedDuration() {
        let app = XCUIApplication()
        let clock = ContinuousClock()
        let start = clock.now
        app.launch()
        defer { app.terminate() }

        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
        let elapsed = start.duration(to: clock.now)
        XCTAssertLessThan(elapsed, .seconds(10))
    }
}
