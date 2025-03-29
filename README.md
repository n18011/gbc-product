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

## ローリングアップデート

アプリケーションの新しいバージョンをデプロイする場合：

```bash
# イメージを更新
kubectl set image deployment/gbc-app gbc-app=新しいイメージ:タグ

# デプロイメントのステータスを確認
kubectl rollout status deployment/gbc-app
``` 