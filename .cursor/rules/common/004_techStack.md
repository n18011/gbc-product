## このプロジェクトで使用している技術スタック

- フロントエンド: SvelteKit
- バックエンド: SvelteKit (Server)
- データベース: PostgreSQL
- ORM: Prisma
- コンテナオーケストレーション: Kubernetes
- 開発言語: TypeScript

### 開発ツール

## 開発環境のセットアップ

### 必要なツール

1. **Node.js のインストール**

  - bun のインストール

2. **環境変数の設定**

   - `.env.example` をコピーして `.env` ファイルを作成
   - 必要な環境変数を設定

3. **プロジェクトのセットアップ**

### セットアップ手順
1. 依存関係のインストール
```bash
bun install
```

2. 開発サーバーの起動
```bash
bun run dev
```

3. データベースのセットアップ
```bash
bunx prisma generate
bunx prisma migrate dev
```

4. Kubernetesクラスタの準備
```bash
kind create cluster
kubectl apply -f k8s/
```

### 開発ガイドライン
- コードスタイル: Prettier + ESLint
- テスト: Vitest + Playwright
- Git: Conventional Commits
- CI/CD: GitHub Actions

### 開発ワークフロー

1. **フロントエンド開発**


2. **バックエンド開発**


3. **データベース操作**

   ```bash
   # マイグレーションの作成
   npx prisma migrate dev --name [マイグレーション名]

   # スキーマの生成
   npx prisma generate

   # データベースのシード
   yarn seed
   ```

4. **APIクライアント生成**


5. **リントとフォーマット**

   ```bash
   # リント
   bun run lint

   ```

## 技術的制約

1. **フロントエンドの制約**

   - データフェッチング戦略の選択

2. **バックエンドの制約**

   - SvelteKit のモジュール構造に従う必要性
   - Prisma スキーマの制約
   - API設計の一貫性

3. **パフォーマンスの制約**
   - 大量のデータ処理時のメモリ使用量
   - APIレスポンスタイムの最適化
   - フロントエンドのレンダリングパフォーマンス

## 依存関係

### 主要な依存関係

1. **フロントエンド**

2. **バックエンド**

3. **共通**
   - typescript: 型システム

### 依存関係管理

1. **SvelteKit**

   - src/routes: フロントエンド
   - src/routes/api: バックエンド
   - src/prisma: データベーススキーマ

2. **パッケージ管理**
