# GBC Product - Kubernetes インフラ

このプロジェクトは、Kubernetes（kind）を使用した最小限のインフラ構築を提供します。

## 前提条件

以下のツールがインストールされている必要があります：

- Docker
- Kind (Kubernetes in Docker)
- kubectl

## 環境構築

以下のコマンドを実行してください：

```bash
./setup.sh
```

このスクリプトは以下を実行します：
- kindを使用して3ノード（1コントロールプレーン、2ワーカー）のKubernetesクラスターを作成
- NGINX Ingressコントローラーをデプロイ
- サンプルアプリケーション（nginx）をデプロイ
- サービスとIngressリソースを設定

## アクセス方法

セットアップ完了後、以下のURLでアプリケーションにアクセスできます：

http://localhost/

## クラスターの削除

クラスターを削除するには：

```bash
kind delete cluster --name gbc-product
```

または以下のスクリプトを使用：

```bash
./cleanup.sh
```

## ローリングアップデート

アプリケーションの新しいバージョンをデプロイする場合：

```bash
# イメージを更新
kubectl set image deployment/gbc-app gbc-app=新しいイメージ:タグ

# デプロイメントのステータスを確認
kubectl rollout status deployment/gbc-app
```

## CI/CD パイプライン連携

このプロジェクトには、GitHub Actionsを使用したCI/CDパイプラインが実装されています。

### CI/CDフロー

1. コードをプッシュすると、自動的にパイプラインが起動
2. テスト実行
3. Dockerイメージのビルドとプッシュ（GitHub Container Registry）
4. ブランチ名に基づいた環境へのデプロイ
   - `main` ブランチ: 本番環境
   - `develop` ブランチ: 開発環境

### 必要な設定

GitHub Actions を使用するには、以下のシークレットを設定してください：

- `KUBE_CONFIG`: kubeconfigファイルの内容（Base64エンコード不要）

### ローカルでのビルドとデプロイ

ローカルでイメージをビルドしてデプロイする場合：

```bash
# イメージのビルド
./scripts/build-image.sh [環境名] [コミットハッシュ]

# デプロイ
./scripts/deploy.sh [環境名] [コミットハッシュ] [ネームスペース]
```

例：
```bash
# 開発環境向けにビルド
./scripts/build-image.sh development

# 開発環境にデプロイ
./scripts/deploy.sh development
```

### マニュアルデプロイ

GitHub Actionsコンソールから「CI/CD Pipeline」ワークフローを手動で実行することもできます。 