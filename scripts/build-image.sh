#!/bin/bash
set -e

# パラメータ取得
ENVIRONMENT=${1:-development}
COMMIT_HASH=${2:-$(git rev-parse --short HEAD)}
BUILD_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

echo "環境: $ENVIRONMENT"
echo "コミットハッシュ: $COMMIT_HASH"
echo "ビルド時刻: $BUILD_TIME"

# テンプレート変数の置換
cp app/index.html app/index.html.template
sed -i "s|{{BUILD_TIME}}|$BUILD_TIME|g" app/index.html
sed -i "s|{{COMMIT_HASH}}|$COMMIT_HASH|g" app/index.html
sed -i "s|{{ENVIRONMENT}}|$ENVIRONMENT|g" app/index.html

# イメージタグの構築
IMAGE_TAG="${COMMIT_HASH}"
if [ "$ENVIRONMENT" == "production" ]; then
  REGISTRY_PREFIX="ghcr.io/$(git config --get remote.origin.url | cut -d: -f2 | cut -d. -f1)"
else
  REGISTRY_PREFIX="ghcr.io/$(git config --get remote.origin.url | cut -d: -f2 | cut -d. -f1)"
fi

IMAGE_NAME="${REGISTRY_PREFIX}:${IMAGE_TAG}"
echo "ビルドするイメージ: $IMAGE_NAME"

# Dockerイメージのビルド
docker build \
  --build-arg APP_ENV="$ENVIRONMENT" \
  -t "$IMAGE_NAME" \
  .

echo "イメージのビルドが完了しました: $IMAGE_NAME" 