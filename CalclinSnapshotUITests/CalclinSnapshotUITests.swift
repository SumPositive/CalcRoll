//
//  CalclinSnapshotUITests.swift
//  CalclinSnapshotUITests  ← スクショ専用の UITest ターゲット
//
//  fastlane snapshot 用の UI テスト。
//  ※ 撮影専用ターゲットに置くことで、通常の Test 実行（Cmd+U / 既存 Calc26UITests）
//    では一切走らない。撮影は fastlane（capture_screenshots）からのみ起動する。
//
//  撮影カット（電卓の状態違い・達人モードで撮影）:
//    01Calculator … 電卓モード（左から順に計算）。パネル index0 に電卓サンプル。
//    02Formula    … 数式モード（優先順位あり）。パネル index1 に数式サンプル。
//    03TwoPanels  … 電卓＋数式パネルの2連表示。
//
//  アプリ側の仕込み（-FASTLANE_SNAPSHOT YES 時のみ・DEBUG限定）:
//    - 操作モードを達人（PlayMode.master）に固定
//    - index0=電卓モード＋電卓サンプル、index1=数式モード＋数式サンプルを CalcViewModel.load() で投入
//    - AdMob 初期化をスキップ
//
//  遷移の考え方:
//   - 起動直後は index0(電卓) を1面表示 → 01。
//   - インジケータ（calcPanel_indicator）を右タップ/右スワイプして index1(数式) へ → 02。
//   - インジケータを右ダブルタップ、または [+]ボタン（calcPanel_increase）で2連にする → 03。
//   - identifier での操作が空振り（hittable=false）する場合に備え、座標タップにフォールバックする。
//

import XCTest

final class CalclinSnapshotUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testTakeScreenshots() throws {
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launch()
        sleep(2)

        // 01: 電卓モード（起動直後・index0）
        snapshot("01Calculator")

        // 02: 数式モード（index1 へページ送り）
        goNextPage(app)
        sleep(1)
        snapshot("02Formula")

        // 03: 2連表示（電卓＋数式を横並び）
        makeTwoPanels(app)
        sleep(1)
        snapshot("03TwoPanels")
    }

    /// インジケータを操作して次ページ（index1=数式）へ送る。
    /// ① identifier のインジケータを右側タップ ② ダメなら右スワイプ ③ 最後は画面右寄りを座標タップ。
    @MainActor
    private func goNextPage(_ app: XCUIApplication) {
        let indicator = app.otherElements["calcPanel_indicator"]
        if indicator.waitForExistence(timeout: 5) {
            if indicator.isHittable {
                // インジケータの右側をタップ（onTapGesture が「右側=次ページ」）
                indicator.coordinate(withNormalizedOffset: CGVector(dx: 0.72, dy: 0.5)).tap()
                return
            }
        }
        // フォールバック: 画面中央あたりを左へスワイプしてページ送り
        let center = app.coordinate(withNormalizedOffset: CGVector(dx: 0.7, dy: 0.45))
        let target = app.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.45))
        center.press(forDuration: 0.05, thenDragTo: target)
    }

    /// 2連表示（showCount=2）にする。
    /// ① [+]ボタン（calcPanel_increase）をタップ ② ダメならインジケータを右ダブルタップ
    /// ③ 最後はパネル(calcPanel_0)を右ダブルタップ。
    @MainActor
    private func makeTwoPanels(_ app: XCUIApplication) {
        let plus = app.buttons["calcPanel_increase"]
        if plus.waitForExistence(timeout: 2), plus.isHittable {
            plus.tap()
            return
        }
        let indicator = app.otherElements["calcPanel_indicator"]
        if indicator.waitForExistence(timeout: 2) {
            // 右側でダブルタップ = showPlus（列を増やす）
            indicator.coordinate(withNormalizedOffset: CGVector(dx: 0.72, dy: 0.5))
                .doubleTap()
            return
        }
        // フォールバック: 先頭パネルの右半分をダブルタップ（右ダブルタップで2列化）
        let panel = app.otherElements["calcPanel_0"]
        if panel.waitForExistence(timeout: 2) {
            panel.coordinate(withNormalizedOffset: CGVector(dx: 0.75, dy: 0.35)).doubleTap()
            return
        }
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.75, dy: 0.35)).doubleTap()
    }
}
