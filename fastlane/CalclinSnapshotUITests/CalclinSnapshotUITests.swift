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
//  遷移の考え方（フック固定方式）:
//   - UI操作でのページ送りは空振りしやすいので使わない。
//   - カットごとにアプリを起動し直し、起動引数 -SNAPSHOT_CUT <n> を渡す。
//   - アプリ側（CalcRollView.init）が n に応じて初期表示ページ・列数を固定する:
//       1 → index0(電卓) 1面 / 2 → index1(数式) 1面 / 3 → index0+1 の2連。
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

        // 01: 電卓モード（index0・1面）
        launch(app, cut: 1)
        snapshot("01Calculator")

        // 02: 数式モード（index1・1面）
        launch(app, cut: 2)
        snapshot("02Formula")

        // 03: 2連表示（index0+1=電卓+数式）
        launch(app, cut: 3)
        snapshot("03TwoPanels")
    }

    /// カット番号を起動引数 -SNAPSHOT_CUT <n> で渡してアプリを起動する。
    /// setupSnapshot が付けた言語などの引数は保持し、SNAPSHOT_CUT だけ毎回付け替える。
    @MainActor
    private func launch(_ app: XCUIApplication, cut: Int) {
        // 前回分の -SNAPSHOT_CUT / 値 を取り除いてから付け直す
        var args = app.launchArguments
        while let i = args.firstIndex(of: "-SNAPSHOT_CUT") {
            let end = min(i + 2, args.count)
            args.removeSubrange(i..<end)
        }
        args.append(contentsOf: ["-SNAPSHOT_CUT", "\(cut)"])
        app.launchArguments = args
        app.launch()
        sleep(2)
    }
}
