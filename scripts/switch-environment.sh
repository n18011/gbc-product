#!/bin/bash

# 引数が提供されているかチェック
if [ "$#" -ne 1 ]; then
    echo "使用方法: $0 [dev|prod]"
    exit 1
fi

ENVIRONMENT=$1

# 有効な環境値かチェック
if [ "$ENVIRONMENT" != "dev" ] && [ "$ENVIRONMENT" != "prod" ]; then
    echo "エラー: 環境は 'dev' または 'prod' を指定してください"
    exit 1
fi

echo "環境を $ENVIRONMENT に切り替えています..."

# 基本ConfigMapと環境固有のConfigMapをマージする
echo "1. 環境固有のConfigMapを適用..."
if [ "$ENVIRONMENT" = "dev" ]; then
    # 開発環境ConfigMapを適用
    kubectl apply -f k8s/configmap-dev.yaml
    
    # 基本ConfigMapを環境固有のConfigMapで更新
    echo "   基本ConfigMapを開発環境の値で更新..."
    kubectl get configmap gbc-app-config-dev -o yaml | \
    sed 's/name: gbc-app-config-dev/name: gbc-app-config/' | \
    kubectl apply -f -
else
    # 本番環境ConfigMapを適用
    kubectl apply -f k8s/configmap-prod.yaml
    
    # 基本ConfigMapを環境固有のConfigMapで更新
    echo "   基本ConfigMapを本番環境の値で更新..."
    kubectl get configmap gbc-app-config-prod -o yaml | \
    sed 's/name: gbc-app-config-prod/name: gbc-app-config/' | \
    kubectl apply -f -
fi

# 環境固有のSecretを適用
echo "2. 環境固有のSecretを適用..."
if [ "$ENVIRONMENT" = "dev" ]; then
    kubectl apply -f k8s/secrets-dev.yaml
    
    # 基本Secretを環境固有のSecretで更新
    echo "   基本Secretを開発環境の値で更新..."
    kubectl get secret gbc-app-secrets-dev -o yaml | \
    sed 's/name: gbc-app-secrets-dev/name: gbc-app-secrets/' | \
    kubectl apply -f -
else
    kubectl apply -f k8s/secrets-prod.yaml
    
    # 基本Secretを環境固有のSecretで更新
    echo "   基本Secretを本番環境の値で更新..."
    kubectl get secret gbc-app-secrets-prod -o yaml | \
    sed 's/name: gbc-app-secrets-prod/name: gbc-app-secrets/' | \
    kubectl apply -f -
fi

# デプロイメントを更新して新しい設定を使用するようにする
echo "3. デプロイメントを再起動して新しい設定を適用..."
# デプロイメントをロールアウトリスタート
kubectl rollout restart deployment gbc-app

# ロールアウト完了を待機
echo "デプロイメントが完了するまで待機しています..."
kubectl rollout status deployment gbc-app

echo ""
echo "環境が $ENVIRONMENT に切り替わりました。"
echo "新しい設定でPodが実行されているか確認するには、scripts/test-configs.sh を実行してください。" 