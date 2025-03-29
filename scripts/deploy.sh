#!/bin/bash
set -e

# パラメータ取得
ENVIRONMENT=${1:-development}
COMMIT_HASH=${2:-$(git rev-parse --short HEAD)}
NAMESPACE=${3:-default}

echo "環境: $ENVIRONMENT"
echo "コミットハッシュ: $COMMIT_HASH"
echo "ネームスペース: $NAMESPACE"

# イメージタグの構築
IMAGE_TAG="${COMMIT_HASH}"
if [ "$ENVIRONMENT" == "production" ]; then
  REGISTRY_PREFIX="ghcr.io/$(git config --get remote.origin.url | cut -d: -f2 | cut -d. -f1)"
else
  REGISTRY_PREFIX="ghcr.io/$(git config --get remote.origin.url | cut -d: -f2 | cut -d. -f1)"
fi

IMAGE_NAME="${REGISTRY_PREFIX}:${IMAGE_TAG}"
echo "デプロイするイメージ: $IMAGE_NAME"

# マニフェストの準備（一時ファイルに保存）
TMP_DIR=$(mktemp -d)
cp -r k8s/* "$TMP_DIR/"

# 環境固有の設定
if [ "$ENVIRONMENT" == "production" ]; then
  # 本番用設定（必要に応じて調整）
  REPLICAS=3
else
  # 開発用設定
  REPLICAS=1
fi

# マニフェストの更新
sed -i "s|image: nginx:latest|image: $IMAGE_NAME|g" "$TMP_DIR/base-deployment.yaml"
sed -i "s|replicas: 2|replicas: $REPLICAS|g" "$TMP_DIR/base-deployment.yaml"

# デプロイ実行
echo "Kubernetesにデプロイしています..."
kubectl apply -f "$TMP_DIR/base-deployment.yaml" --namespace="$NAMESPACE"
kubectl apply -f "$TMP_DIR/service.yaml" --namespace="$NAMESPACE"
kubectl apply -f "$TMP_DIR/ingress.yaml" --namespace="$NAMESPACE"

# デプロイ状態の確認
echo "デプロイのステータスを確認しています..."
kubectl rollout status deployment/gbc-app --namespace="$NAMESPACE"

# 一時ディレクトリの削除
rm -rf "$TMP_DIR"

echo "デプロイが完了しました！" 