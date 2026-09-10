# 資格更新ノート

専門医資格の更新期限・取得単位・必須条件・参加証をまとめて確認するためのFlutter製アプリです。

FlutterのiPhone/Webアプリに加えて、Vercel Functions、Neon Postgres、Private Vercel Blobを使う利用者データ同期と公式資料更新パイプラインを含みます。Web版はホーム画面へ追加できるPWAで、オフライン起動とWeb Pushに対応します。

## 確認できる画面

- ホーム：期限順の資格カード、現在ポイント、参加予定ポイント、不足条件
- 資格詳細：現在・予定・見込みポイント、期限、学会会員ID、会員サイト、根拠資料
- 参加証登録：画像・PDF添付または手入力、複数資格へのポイント割当、登録結果
- 参加予定：開催日、予定ポイント、単位区分、学会URLを登録し、参加後に確定ポイントへ移行
- 実績：検索、参加予定・確定・下書きの状態フィルター
- 設定：クラウド同期、Web Push、バックアップ・復元、アカウント削除

画像・PDFの参加証は、iOSではVision、AndroidではML Kitを使って端末内OCRし、認証済みAPIからOpenAI Responses APIの構造化出力を使って研修名・開催日・主催者・単位・区分・対象資格を自動入力します。端末内OCRテキストは、氏名・会員番号などラベル付きの個人情報を除外してからOpenAIへ送ります。端末内OCRが使えないWeb版、またはOCRに失敗した場合だけ、3MB以下のPDF/JPEG/PNG/WebPをOpenAIへ送ります。スマートフォンで撮った写真はこの上限を超えることが多いため、送信前に長辺2600px・JPEGへ自動で縮小します。Web版の画像選択は `image_picker` の maxWidth を無視するため、デコードした実寸法から同じ長辺制限をかけます（端末内OCRには縮小前の原本を使います）。自動入力は誤る可能性があるため、保存前の確認は必須です。OpenAI未設定時は決定論的な文字列抽出へフォールバックします。

学会の資格番号と会員IDは分けて保存できます。会員サイトURLを登録するとアプリから開けますが、パスワードは保存せず、会員サイトとの自動データ連携は学会ごとの公式API・利用規約を確認して段階的に対応します。

## 起動

```bash
flutter run
```

Webで確認する場合：

```bash
flutter run -d chrome
```

## アカウントログイン設定

Googleアカウントのログイン画面とログアウト機能を実装しています。Appleログインのコードも実装済みですが、Apple Developer側の設定が完了するまでは非表示です。認証にはFirebase Authenticationを使用します。Firebase未設定の環境ではアプリはクラッシュせず、ログイン画面に設定案内を表示します。

### 1. Firebaseプロジェクトを接続

Firebase Consoleでプロジェクトを作り、Authentication → ログイン方法から「Google」と「Apple」を有効にします。iOS/Androidアプリの識別子はどちらも `jp.sachikosaga.medlicense` です。

公式CLIを使ってiOS・Androidの設定ファイルを生成します。

```bash
firebase login
dart pub global activate flutterfire_cli
flutterfire configure --platforms=ios,android
```

AndroidではFirebase Consoleに開発用・本番用署名のSHA-1を登録してください。iOSの「Sign in with Apple」エンタイトルメントは追加済みですが、Apple DeveloperのApp IDでも同機能を有効にし、Firebase ConsoleへService ID・Team ID・Key ID・秘密鍵を登録する必要があります。

iOSでGoogleログインを使う場合は、生成された `GoogleService-Info.plist` の `REVERSED_CLIENT_ID` をXcodeの Runner → Info → URL Typesへ追加します。

Apple DeveloperとFirebaseの設定が完了した後、ビルド設定の `APPLE_SIGN_IN_ENABLED` を `true` にするとAppleログインボタンが表示されます。デフォルトは `false` です。

### 2. Web設定

サンプルをコピーし、Firebase ConsoleのWebアプリ設定に表示される値へ置き換えます。

```bash
cp config/firebase.web.example.json config/firebase.web.json
flutter run -d chrome --dart-define-from-file=config/firebase.web.json
```

本番Webビルドでも同じ `--dart-define-from-file` を付けます。また、Firebase Authenticationの「承認済みドメイン」に本番ドメインを追加してください。`config/firebase.web.json` はGit管理対象外です。

WebリリースビルドではFlutter標準のService Workerを無効にし、このリポジトリのオフライン・Push対応版だけを使用します。

```bash
flutter build web --release --pwa-strategy=none \
  --dart-define-from-file=config/firebase.web.json
```

ネイティブアプリからVercel APIへ接続する場合は、同時に `--dart-define=APP_API_BASE_URL=https://公開URL` を渡します。Web版は同一オリジンの `/api` を自動使用します。

## 利用者データ、招待、PWA

- Firebase IDトークンをサーバーで署名・発行元・対象プロジェクト・有効期限まで検証
- Firebaseでメール確認済みのUIDを `app_users` に自動登録（`REQUIRE_INVITE_CODE=true` の場合だけ招待制）
- 資格・実績・設定をリビジョン付きスナップショットとしてNeonへ同期
- PDF/JPEG/PNG/WebP/HEIC/HEIFをPrivate Vercel Blobへ保存（1ファイル3MBまで、超える写真は自動縮小）
- 最新20件のクラウドバックアップを一覧・復元
- Push購読情報を利用者単位で保存し、期限180・90・30・7日前にVercel Cronから通知
- アカウント削除時にスナップショット、参加証、バックアップ、Push購読、Firebaseユーザーを削除

参加証とバックアップは公開URLをクライアントへ渡さず、Firebase認証済みAPIを経由して取得します。通信はHTTPSですが、現在は利用者自身だけが復号できるエンドツーエンド暗号化ではありません。

### ホーム画面への追加

本番HTTPS URLをSafariまたはChromeで開き、共有・インストールメニューからホーム画面へ追加します。一度オンラインで起動すると、アプリシェルとCanvasKitがキャッシュされ、通信断でも起動できます。同期に失敗した変更は端末へ残り、次回の手動操作または更新時に再同期されます。

iPhone/iPadのWeb Pushはホーム画面からPWAとして開き、設定画面の「この端末でWeb通知を有効化」を利用者が押して許可する必要があります。ブラウザの通常タブではiOSのPush設定は完了しません。

## 公式資料更新バックエンド

役割は次のとおりです。

- Private Vercel Blob: 取得した公式HTML・PDFの原本を改変せず保存
- Neon Postgres: 資格、認定団体、制度区分、取得年度範囲、更新条件、出典、確認日を版管理
- Vercel Functions: アプリ向け公開API、確認用管理API、定期取得API
- Vercel Cron / GitHub Actions: 毎週の変更確認

新しく抽出した条件は必ず `pending_review` になります。確認前のデータをアプリへ配信することはありません。
原本ハッシュだけが変わり、正規化した抽出本文が同一だった場合は重複する確認候補を作りません。

### 管理画面

本番URLの `/admin` を開き、`SYNC_ADMIN_TOKEN` を入力します。確認待ちの候補について、公式資料の抽出本文と構造化結果に加え、前回版からの重要差分、重要度、確認ポイントを並べて確認できます。

- 制度区分・取得年度範囲・更新周期・総単位を修正
- 区分別単位・必須条件を追加、修正、削除
- 必須事項・その他条件・確認メモを記録
- 承認した条件だけを公開APIへ反映
- 誤った候補は原本を残したまま却下

管理用トークンはブラウザのタブ内にだけ一時保存され、タブを閉じると削除されます。

### 利用者アプリへの自動表示

資格詳細を開くと、資格名に一致する承認済み更新条件を公開APIから自動取得します。更新周期、必要総単位、区分別・必須条件、その他条件、出典URLと確認日が表示されます。まだ承認済み条件がない場合はその旨を表示し、確認待ちデータを利用者へ誤配信しません。

### 初回セットアップ

VercelプロジェクトへNeonとPrivate Blobを接続し、環境変数の接頭辞をそれぞれ `DATABASE` と `BLOB` にします。その後、VercelのProject Settings → Environment Variablesで次を追加します。

- `CRON_SECRET`: 16文字以上のランダム文字列
- `SYNC_ADMIN_TOKEN`: `CRON_SECRET` とは異なるランダム文字列
- `FIREBASE_PROJECT_ID`: FirebaseプロジェクトID（Web設定の値と一致させる）
- `REQUIRE_INVITE_CODE`: 招待制へ戻す場合だけ `true`（未設定時は自動登録）
- `WEB_PUSH_PUBLIC_KEY`: VAPID公開鍵
- `WEB_PUSH_PRIVATE_KEY`: VAPID秘密鍵
- `WEB_PUSH_SUBJECT`: `mailto:管理者メールアドレス` または管理サイトのHTTPS URL
- `OPENAI_API_KEY`: 参加証の構造化と公式資料の差分要約に使うOpenAI APIキー（未設定時は決定論的抽出）
- `OPENAI_MODEL`: 任意。Responses APIの構造化出力に使うモデル名（既定 `gpt-5.6-luna`）

OpenAIへのリクエストは `store: false` で送信します。参加証は氏名・会員番号などラベル付き個人情報をOCRテキストから除外してから送信し、AIの出力は保存・公開前にアプリまたは管理画面で確認します。

秘密情報はGitHubやソースコードに保存しません。

```bash
npm install
vercel link
vercel env pull .env.local
npm run db:setup
npm run sync:sources
```

VAPID鍵は次のコマンドで生成できます。秘密鍵はクライアントやGitへ入れません。

```bash
npx web-push generate-vapid-keys
```

`db:setup` は利用者データ用テーブルも含むマイグレーションを適用し、Flutter内の資格候補と公式取得元を登録します。繰り返し実行しても既存データは壊しません。

### データ移行の運用

- `npm run db:status`: DBを書き換えず、適用済み・未適用のマイグレーションを確認
- `npm run db:migrate`: 未適用の `db/migrations/NNN_description.sql` を番号順に一括適用
- `npm run db:seed`: 資格候補と公式取得元をupsertし、初期データと既存データを最新化
- `npm run db:setup`: マイグレーション成功後に初期データを同期

マイグレーションは排他ロックを取得した単一トランザクションで実行され、成功時だけ `schema_migrations` にファイル名とSHA-256を記録します。失敗時は未適用分をすべてロールバックします。本番適用済みSQLは編集せず、変更は次の連番ファイルとして追加してください。初回の履歴導入時も既存の001〜005は再実行可能なSQLのため、既存テーブルとデータを保持したまま履歴へ登録されます。本番作業前にはNeonのバックアップまたはブランチを作成してください。

参加証PDFは、サーバーで抽出したテキストを補助情報として使いつつ、元PDFもOpenAI Responses APIの `input_file`（高精細）として渡します。テキスト層のないスキャンPDFやサーバー側で解析できないPDFも、ページ画像を使った構造化へ進みます。`GET /api/health` の `openai` が `configured` であることも確認できます。

### 招待コードの発行

通常は招待コード不要です。`REQUIRE_INVITE_CODE=true` にして招待制を有効にした場合だけ、管理トークンを使って招待を発行します。`email` または `emailDomain` を指定すると利用対象を絞れます。省略時の有効期限は30日、利用回数は1回です。

```bash
curl -X POST https://公開URL/api/admin/invites \
  -H "Authorization: Bearer $SYNC_ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"email":"doctor@example.jp","expiresInDays":14,"maxUses":1}'
```

応答に含まれる `code` はこのときだけ平文で返ります。DBにはハッシュだけを保存します。発行済み招待の確認は `GET /api/admin/invites`、失効は `DELETE /api/admin/invites?hash=...` です。

### API

- `GET /api/health`: DBとBlob設定の疎通確認
- `GET /api/v1/qualifications?q=外科`: 資格候補の前方・部分検索
- `GET /api/v1/qualifications?id=...&systemType=...&acquiredYear=2024`: 公開済み更新条件と出典
- `GET|POST /api/v1/access`: 利用者の自動登録・招待制有効時のコード消費
- `GET|PUT /api/v1/me`: 利用者スナップショットの取得・同期
- `GET|POST|DELETE /api/v1/attachments`: 非公開参加証の保存・取得・削除
- `POST /api/v1/certificate-extraction`: 認証済み利用者のOCRテキストまたは参加証を構造化
- `GET|POST /api/v1/backups`: バックアップの一覧・作成・復元用取得
- `GET /api/v1/push-config`, `POST|DELETE /api/v1/push-subscriptions`: Web Push設定
- `DELETE /api/v1/account`: 利用者のクラウドデータ削除
- `GET|POST|DELETE /api/admin/invites`: 招待管理（管理トークン必須）
- `GET /api/admin/rules`: 確認待ち条件（`Authorization: Bearer SYNC_ADMIN_TOKEN` が必要）
- `POST /api/admin/rules`: 修正後の条件を添えて `publish`、または `reject`
- `GET /api/cron/sync`: 公式資料を取得（`Authorization: Bearer CRON_SECRET` が必要）

### GitHub Actions（任意の予備経路）

Repository Settings → Secrets and variables → Actionsで次を設定します。

- Variable `SYNC_ENDPOINT`: `https://公開URL/api/cron/sync`
- Secret `CRON_SECRET`: Vercelと同じ値

Vercel CronとGitHub Actionsが近い時間に動いても、取得間隔と文書ハッシュによって二重保存を防ぎます。

### 検証

```bash
npm run check:server
npm run test:server
flutter analyze
flutter test
flutter build web --release --pwa-strategy=none \
  --dart-define-from-file=config/firebase.web.json
```
