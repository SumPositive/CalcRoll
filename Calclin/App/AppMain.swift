//
//  AppMain.swift
//  Calclin
//
//  Created by sumpo/azukid on 2025/06/29. SwiftUI練習のためにCalcRoll移植を開始
//

import SwiftUI

import FirebaseCore
import FirebaseAnalytics
import FirebaseCrashlytics
import GoogleMobileAds  // iOSのみ、MacやVisionには対応せずエラーになる


@main
struct AppMain: App {
    //NG//@StateObject private var setting: SettingViewModel ここに置くと変化の都度、ContentViewが再生成されることになる

    @Environment(\.scenePhase) private var scenePhase

    init() {
        // Firebaseの初期化を最優先で行い、CrashlyticsとAnalyticsの収集を起動しておく
        FirebaseApp.configure()
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)
        // 解析のサンプリングや同意設定が今後入っても良いように、開始を明示しておく
        Analytics.setAnalyticsCollectionEnabled(true)
        // アプリ起動をAnalyticsへ明示的に通知し、流入経路の把握に備える
        Analytics.logEvent(AnalyticsEventAppOpen, parameters: nil)

        // AdMob SDKを初期化する（fastlane snapshot 撮影中は初期化しない＝スクショに広告を絡めない）
        #if DEBUG
        if !SnapshotSupport.isRunningSnapshot {
            MobileAds.shared.start()
        }
        #else
        MobileAds.shared.start()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
//        .onChange(of: scenePhase) { oldPhase, newPhase in
//            switch newPhase {
//                case .background:
//                case .active:
//                case .inactive:
//                default:
//                    break
//            }
//        }
    }

}


// MARK: - fastlane snapshot 判定
//
// fastlane snapshot（App Store スクショ自動撮影）実行中かどうかを判定するヘルパー。
// SnapshotHelper が起動引数 -FASTLANE_SNAPSHOT YES を付けるので、それを読む。
// 撮影時だけ操作モードを達人にしたり、電卓/数式のサンプル計算を流し込むために使う。
// ※ 撮影フックは DEBUG ビルドかつ撮影中のみ有効（本番挙動には影響しない）。
//
// 注意: 独立ファイルにすると Xcode16 の同期フォルダで本体ターゲットへの
//       所属登録漏れ（Cannot find in scope）を起こしやすいので、
//       確実に本体ターゲットに含まれる AppMain.swift 内に同居させている。
enum SnapshotSupport {
    /// fastlane snapshot による撮影中なら true。
    /// SnapshotHelper が UserDefaults 経由で -FASTLANE_SNAPSHOT YES をセットする。
    static var isRunningSnapshot: Bool {
        #if DEBUG
        return UserDefaults.standard.bool(forKey: "FASTLANE_SNAPSHOT")
        #else
        return false
        #endif
    }

    /// 撮影カット番号。UITest が起動引数 -SNAPSHOT_CUT <n> で渡す。
    /// 1=01Calculator（index0=電卓・1面）/ 2=02Formula（index1=数式・1面）/
    /// 3=03TwoPanels（index0+1=電卓+数式・2連）。未指定時は 1。
    /// これに応じて CalcRollView の初期表示ページ・列数を固定し、UI操作なしで狙った状態を撮る。
    static var snapshotCut: Int {
        #if DEBUG
        let n = UserDefaults.standard.integer(forKey: "SNAPSHOT_CUT")
        return n == 0 ? 1 : n
        #else
        return 1
        #endif
    }
}



