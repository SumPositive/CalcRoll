# App Store メタデータの更新手順（Calclin / カルメモ）

説明文（description）・プロモーションテキスト（promotional_text）・キーワード（keywords）・
リリースノート（release_notes）を**2言語**まとめて App Store Connect に反映するための fastlane 設定です。

- 対象アプリ: `com.azukid.AzukiSoft.AzCalc`（App ID は未設定。bundle ID だけで動く）
- 更新される項目: `fastlane/metadata/<locale>/` に置いたテキストのみ
  （置いていない項目・空の項目は既存を上書きしません。スクショ・価格・バイナリは触りません）

対応ロケール（App Store Connect のコード）:
`ja` / `en-US`（Calclin アプリ本体が対応する 2 言語）

メタデータ元ネタ: `GitLocal/azukid.com/docs/{jp,en}/sumpo/Calclin/calclin.html`

各テキストのパス:
```
fastlane/metadata/<locale>/description.txt      (<= 4000 文字)
fastlane/metadata/<locale>/keywords.txt         (<= 100 文字・カンマ区切り)
fastlane/metadata/<locale>/promotional_text.txt (<= 170 文字)
fastlane/metadata/<locale>/release_notes.txt    (What's New)
```

---

## 1. 準備（初回のみ）

### 1-1. fastlane
この Mac では **Homebrew 版 fastlane**（`/opt/homebrew/bin/fastlane`）を使います。
システム Ruby は古いので `bundle exec` ではなく `fastlane <lane>` を直接呼びます。

### 1-2. App Store Connect API キー（.p8）
既存アプリ（Packlin / Condition）と同じキー `AuthKey_Y5FN28B9W6.p8` を使います。
`fastlane/` 直下に置いてあり `.gitignore` 済みです。ロールは `App Manager` 以上が必須
（`Developer` だと 403）。

### 1-3. .env を作成
```bash
cd /Users/sumpositive/GitLocal/Calclin
cp fastlane/.env.example fastlane/.env
# fastlane/.env を編集して ASC_KEY_ID / ASC_ISSUER_ID / ASC_KEY_PATH を実値に
#   ASC_KEY_ID=Y5FN28B9W6
#   ASC_ISSUER_ID=（App Store Connect の Issuer ID・UUID）
#   ASC_KEY_PATH=./fastlane/AuthKey_Y5FN28B9W6.p8
```
`.env` は `.gitignore` 済み。Calclin ディレクトリ内で fastlane を実行すると自動読込されます（export 不要）。

---

## 2. 実行

### 2-1. まず内容確認（送信前に確認プロンプトで停止）
```bash
cd /Users/sumpositive/GitLocal/Calclin
fastlane preview_metadata
```
`force: false` なので Preview.html を生成して y/n を尋ねます。

### 2-2. 反映（審査提出はしない）
```bash
fastlane upload_metadata
```
`submit_for_review: false` なので、メタデータが保存されるだけで**審査には出ません**。

---

## 3. テキストを直したいとき

該当ファイルを編集して、再度 `fastlane upload_metadata` を実行するだけです。

### 検証（アップロード前に必ず）
- 文字数: description <= 4000 / keywords <= 100 / promotional_text <= 170（実カウントで検証）
- 禁止記号: App Store Connect は `→ ⇒ ➜ ▶` などの矢印記号を許可しない
  （`Promotional Text can't contain ...` で upload が失敗する）。
  中黒・カンマ・「and」でつなぐこと。書いたら `grep -rn "→\|⇒\|➜\|▶" metadata/` で確認。

---

## 4. 補足

- `deliver` は「置いてあるファイルの項目だけ」を更新します。
- **release_notes（What's New）は配信済み(Ready for Sale)バージョンだと編集ロック**され
  更新できません。その場合は次バージョンを App Store Connect 側で用意してから反映します。
- App Store への送信を伴う対話実行（Preview.html の y/n）はユーザーの手元（Mac）で実行してください。
