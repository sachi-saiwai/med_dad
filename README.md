# 資格更新ノート

専門医資格の更新期限・取得単位・必須条件・参加証をまとめて確認するためのFlutter製アプリです。

FlutterのiPhone/Webアプリに加えて、Vercel Functions、Neon Postgres、Private Vercel Blobを使う公式資料更新パイプラインを含みます。公式ページ・PDFの原本と変更履歴を保存し、抽出した更新条件は確認後にだけアプリ向けAPIへ公開します。

## 確認できる画面

- ホーム：期限順の資格カード、不足条件、要確認実績
- 資格詳細：条件別の進捗、期限、根拠資料
- 参加証登録：入力方法選択、読み取り結果の修正、複数資格への割当、登録結果
- 実績：検索・状態フィルター、確定・下書き・要確認の見分け
- 設定：通知、バックアップ、CSV、端末ロックの配置

## 起動

```bash
flutter run
```

Webで確認する場合：

```bash
flutter run -d chrome
```

## 公式資料更新バックエンド

役割は次のとおりです。

- Private Vercel Blob: 取得した公式HTML・PDFの原本を改変せず保存
- Neon Postgres: 資格、認定団体、制度区分、取得年度範囲、更新条件、出典、確認日を版管理
- Vercel Functions: アプリ向け公開API、確認用管理API、定期取得API
- Vercel Cron / GitHub Actions: 毎週の変更確認

新しく抽出した条件は必ず `pending_review` になります。確認前のデータをアプリへ配信することはありません。

### 初回セットアップ

VercelプロジェクトへNeonとPrivate Blobを接続し、環境変数の接頭辞をそれぞれ `DATABASE` と `BLOB` にします。その後、VercelのProject Settings → Environment Variablesで次の2つを追加します。

- `CRON_SECRET`: 16文字以上のランダム文字列
- `SYNC_ADMIN_TOKEN`: `CRON_SECRET` とは異なるランダム文字列

秘密情報はGitHubやソースコードに保存しません。

```bash
npm install
vercel link
vercel env pull .env.local
npm run db:setup
npm run sync:sources
```

`db:setup` はFlutter内の資格候補をPostgresへ投入し、外科・内科・リハビリテーション科と日本専門医機構の公式取得元を登録します。繰り返し実行しても既存データは壊しません。

### API

- `GET /api/health`: DBとBlob設定の疎通確認
- `GET /api/v1/qualifications?q=外科`: 資格候補の前方・部分検索
- `GET /api/v1/qualifications?id=...&systemType=...&acquiredYear=2024`: 公開済み更新条件と出典
- `GET /api/admin/rules`: 確認待ち条件（`Authorization: Bearer SYNC_ADMIN_TOKEN` が必要）
- `POST /api/admin/rules`: `{ "ruleId": 1, "action": "publish" }` または `reject`
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
flutter test
```
# med_dad
