#!/bin/bash

# 環境変数が設定されていない場合は、デフォルトの環境を使用
ENVIRONMENT=${ENVIRONMENT:-dev}

echo "環境: $ENVIRONMENT を適用します..."

# 共通ConfigMapを適用
kubectl apply -f k8s/configmap.yaml

# 環境固有のConfigMapを適用
if [ "$ENVIRONMENT" = "dev" ]; then
  echo "開発環境用のConfigMapを適用します..."
  kubectl apply -f k8s/configmap-dev.yaml
elif [ "$ENVIRONMENT" = "prod" ]; then
  echo "本番環境用のConfigMapを適用します..."
  kubectl apply -f k8s/configmap-prod.yaml
else
  echo "警告: 未知の環境 '$ENVIRONMENT' が指定されました。デフォルトのConfigMapのみを適用します。"
fi

# 基本Secretを適用
kubectl apply -f k8s/secrets.yaml

# 環境固有のSecretを適用
if [ "$ENVIRONMENT" = "dev" ]; then
  echo "開発環境用のSecretを適用します..."
  kubectl apply -f k8s/secrets-dev.yaml
elif [ "$ENVIRONMENT" = "prod" ]; then
  echo "本番環境用のSecretを適用します..."
  kubectl apply -f k8s/secrets-prod.yaml
else
  echo "警告: 未知の環境 '$ENVIRONMENT' が指定されました。デフォルトのSecretのみを適用します。"
fi

# デプロイメントを適用
echo "デプロイメントを適用します..."
kubectl apply -f k8s/base-deployment.yaml

echo "完了しました！" 