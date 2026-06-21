// CalclinUITestsLaunchTests.swift
// 起動画面の確認テスト

import XCTest

// UIテストはSwift Testing非対応のためXCTestで実行する
final class CalclinLaunchUITests: XCTestCase {

    // 起動後の画面を画像として取得できることを確認する
    @MainActor
    func testCapturesLaunchScreen() {
        let app = XCUIApplication()
        app.launch()
        defer { app.terminate() }

        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
        let screenshot = app.screenshot()
        XCTAssertFalse(screenshot.pngRepresentation.isEmpty)
    }
}
