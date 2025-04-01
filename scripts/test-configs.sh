#!/bin/bash

# テスト環境変数が設定されていない場合は、デフォルトの環境を使用
ENVIRONMENT=${ENVIRONMENT:-dev}

echo "環境: $ENVIRONMENT の設定をテストします..."

# Pod名を取得
POD_NAME=$(kubectl get pods -l app=gbc-app -o jsonpath="{.items[0].metadata.name}")

if [ -z "$POD_NAME" ]; then
  echo "エラー: gbc-appのPodが見つかりません！"
  exit 1
fi

echo "Pod: $POD_NAME を使用してテストを実行します"

# ConfigMapから設定された環境変数をテスト
echo "1. ConfigMapから設定された環境変数のテスト:"
echo "--------------------------------------------"
kubectl exec $POD_NAME -- env | grep APP_PORT
kubectl exec $POD_NAME -- env | grep APP_HOST
kubectl exec $POD_NAME -- env | grep LOG_LEVEL
kubectl exec $POD_NAME -- env | grep DEBUG_MODE
kubectl exec $POD_NAME -- env | grep ENVIRONMENT

# Secretから設定された環境変数をテスト（値を表示せず存在確認のみ）
echo ""
echo "2. Secretから設定された環境変数の存在確認:"
echo "--------------------------------------------"
kubectl exec $POD_NAME -- bash -c '[ ! -z "$DB_USERNAME" ] && echo "DB_USERNAME: 設定されています" || echo "DB_USERNAME: 未設定"'
kubectl exec $POD_NAME -- bash -c '[ ! -z "$DB_PASSWORD" ] && echo "DB_PASSWORD: 設定されています" || echo "DB_PASSWORD: 未設定"'
kubectl exec $POD_NAME -- bash -c '[ ! -z "$API_KEY" ] && echo "API_KEY: 設定されています" || echo "API_KEY: 未設定"'
kubectl exec $POD_NAME -- bash -c '[ ! -z "$JWT_SECRET" ] && echo "JWT_SECRET: 設定されています" || echo "JWT_SECRET: 未設定"'

# マウントされたConfigMapファイルの確認
echo ""
echo "3. マウントされたConfigMapファイルの確認:"
echo "--------------------------------------------"
kubectl exec $POD_NAME -- ls -la /app/config/

# マウントされたSecretファイルの確認
echo ""
echo "4. マウントされたSecretファイルの確認:"
echo "--------------------------------------------"
kubectl exec $POD_NAME -- ls -la /app/certs/

# ConfigMapの内容確認（JSONファイル）
echo ""
echo "5. マウントされたJSONファイルの内容確認:"
echo "--------------------------------------------"
kubectl exec $POD_NAME -- cat /app/config/app-environment.json

echo ""
echo "テスト完了！" 