# App Store スクリーンショットの自動撮影・アップロード（Calclin / カルメモ）

`fastlane snapshot` でシミュレータからスクショを自動撮影し、`deliver` でアップロードします。

撮影カット（電卓の状態違い・**達人モード**で撮影）:
- `01Calculator` … 電卓モード（左から順に計算）。パネル index0 に電卓サンプル。
- `02Formula` … 数式モード（優先順位あり）。パネル index1 に数式サンプル。
- `03TwoPanels` … 電卓＋数式パネルの2連表示。

言語 = ja / en-US、デバイス = iPhone 17 Pro Max / iPad Pro 13-inch (M5)。

---

## ステップ 0: 用意済みファイル

- `fastlane/CalclinSnapshotUITests/SnapshotHelper.swift` … fastlane 公式ヘルパー（Xcode 26 対応版）
- `fastlane/CalclinSnapshotUITests/CalclinSnapshotUITests.swift` … 撮影用 UI テスト（3カット）
- `fastlane/Snapfile` … 撮影対象の言語・デバイス設定
- `fastlane/Fastfile` … レーン `screenshots` / `upload_screenshots` / `screenshots_and_upload`

`CalclinSnapshotUITests/` の 2 つの .swift は「置き場所」です。次のステップで
**スクショ専用の新規 UITest ターゲット**に取り込みます。

> ⚠️ 既存の `Calc26UITests` には入れません。専用ターゲットに分離することで、
> 通常の Test 実行（Cmd+U / CI）では撮影テストが一切走りません。

### アプリ側の撮影フック（実装済み・DEBUG限定・`-FASTLANE_SNAPSHOT YES` 時のみ）

- `Calclin/App/SnapshotSupport.swift` … 撮影中かどうかの判定（`SnapshotSupport.isRunningSnapshot`）
- `CalcViewModel.load()` … 撮影中は保存状態を無視し、`seedSnapshotSample()` で
  index0=電卓モード＋電卓サンプル、index1=数式モード＋数式サンプルを実際のキー入力で流し込む
- `SettingViewModel.loadPersistentSettings()` … 撮影中は `playMode = .master`（達人モード）に固定
- `AppMain.init()` … 撮影中は AdMob 初期化をスキップ

> これらは本番ビルド（Release）や通常起動には影響しません。

---

## ステップ 1: スクショ専用 UITest ターゲットを新設（← 手動 GUI 操作）

1. `Calclin.xcodeproj` を Xcode で開く
2. **File > New > Target…** → **UI Testing Bundle** を選択
3. 設定:
   - **Product Name**: `CalclinSnapshotUITests`
   - **Target to be Tested**: `Calclin`
   - Team / Organization は他ターゲットに合わせる（Team: 5C2UYK6F45）
4. 生成された `CalclinSnapshotUITests/` 内の雛形 .swift（`...UITests.swift` /
   `...LaunchTests.swift`）は不要なので **削除**（Move to Trash）

> Snapfile の `only_testing` は
> `CalclinSnapshotUITests/CalclinSnapshotUITests/testTakeScreenshots` を指しています。
> ターゲット名・クラス名・メソッド名がこの3つと一致している必要があります。

---

## ステップ 2: ファイルを専用ターゲットに紐付け

1. `fastlane/CalclinSnapshotUITests/CalclinSnapshotUITests.swift` を Xcode にドラッグして
   **CalclinSnapshotUITests ターゲットにのみ**追加（Target Membership をこのターゲットだけにチェック）
2. `fastlane/CalclinSnapshotUITests/SnapshotHelper.swift` も同様に
   **CalclinSnapshotUITests ターゲットにのみ**追加

> SnapshotHelper.swift はアプリ本体や既存 Calc26UITests には入れないこと（撮影専用）。
> `fastlane/CalclinSnapshotUITests/` を編集したら Xcode 側の実体にも反映すること（両方同期）。

### ⚠️ 既知のハマり: Bridging Header

新設ターゲットに空でない `SWIFT_OBJC_BRIDGING_HEADER` が付いているとビルドが失敗します。
新設ターゲットの **Build Settings > Objective-C Bridging Header を空**にしてください。

---

## ステップ 3: スキーム設定

1. Xcode の **Product > Scheme > Manage Schemes…**
2. `Calclin` スキームの **Shared** にチェックが入っていることを確認
3. **Edit Scheme… > Test** タブで、通常の Cmd+U で撮影を走らせたくない場合は
   `CalclinSnapshotUITests` のチェックを **外して** おく
   （fastlane は `only_testing` で明示指定するので影響しない）

---

## ステップ 4: 撮影して確認（アップロードしない）

```sh
cd /Users/sumpositive/GitLocal/Calclin
fastlane screenshots
```

- 出力先: `fastlane/screenshots/<言語>/<デバイス>-01Calculator.png` など
- `fastlane/screenshots/screenshots.html` をブラウザで開くと一覧できる
- 0 枚のときは Snapfile の `only_testing` とターゲット/クラス/メソッド名の一致を疑う

### シミュレータ起動失敗（Clone の launch-failed 等）が出たら

```sh
xcrun simctl shutdown all
sudo killall -9 com.apple.CoreSimulator.CoreSimulatorService
```
でクリーンにしてから再実行。Snapfile で `number_of_retries(3)` 済み。

---

## ステップ 5: アップロード（審査提出はしない）

```sh
fastlane upload_screenshots          # 撮影済みを ASC に反映（置き換え）
# または
fastlane screenshots_and_upload      # 撮影 → アップロードを一括
```

`submit_for_review(false)` なので App Store 審査には出さず、保存のみ。

> ⚠️ 既知の注意: 環境によっては `deliver` の overwrite が ja で効かず、
> スクショが累積・重複することがあります。重複したら App Store Connect 画面で
> 各ペアの片方を手動削除するか、他言語フォルダを一時退避して片言語ずつ上げ直してください。

---

## カット・サンプルを変えるとき

- サンプル計算は `CalcViewModel.swift` の `seedSnapshotSample()`（DEBUG限定）を編集。
  数字は "#1"〜"#9"/"#0"、演算子は Add/Sub/Mul/Div、小数点は Deci、= は Ans
  （キー code は `Calclin/KeyboardView/initKeyboard.json` 準拠）。
- カットの追加・遷移は `CalclinSnapshotUITests.swift` の `testTakeScreenshots` を編集。
  ページ送り/2連化は identifier（`calcPanel_indicator` / `calcPanel_increase` /
  `calcPanel_<index>`）タップ、空振り時は座標タップにフォールバックしている。
- 編集後は Xcode 側の実体にも反映すること。
