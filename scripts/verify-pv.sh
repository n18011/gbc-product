#!/bin/bash

# 永続ボリュームの検証を行うスクリプト

echo "=== StorageClass確認 ==="
kubectl get sc

echo "=== PersistentVolume確認 ==="
kubectl get pv

echo "=== PersistentVolumeClaim確認 ==="
kubectl get pvc

echo "=== Pod確認 ==="
kubectl get pod

# Podが実行中であることを確認
POD_NAME=$(kubectl get pod -l app=gbc-app -o jsonpath="{.items[0].metadata.name}")

if [ -z "$POD_NAME" ]; then
  echo "エラー: gbc-appのPodが見つかりません。"
  exit 1
fi

echo "=== マウント確認 ($POD_NAME) ==="
kubectl exec -it $POD_NAME -- df -h | grep -E "(/app/logs|/app/data)"
kubectl exec -it $POD_NAME -- ls -la /app/logs /app/data

echo "=== データ永続化テスト ==="
echo "テストファイル作成: /app/data/test.txt"
kubectl exec -it $POD_NAME -- sh -c "echo 'テストデータ $(date)' > /app/data/test.txt"
kubectl exec -it $POD_NAME -- sh -c "echo 'ログテスト $(date)' > /app/logs/test.log"

echo "=== テストファイル確認 ==="
kubectl exec -it $POD_NAME -- cat /app/data/test.txt
kubectl exec -it $POD_NAME -- cat /app/logs/test.log

echo "=== Podを再起動 ==="
kubectl rollout restart deployment gbc-app

# Podの再起動を待機
echo "Podの再起動を待機中..."
sleep 5
kubectl rollout status deployment gbc-app

# 新しいPod名を取得
NEW_POD_NAME=$(kubectl get pod -l app=gbc-app -o jsonpath="{.items[0].metadata.name}")

echo "=== 再起動後のデータ確認 ($NEW_POD_NAME) ==="
kubectl exec -it $NEW_POD_NAME -- cat /app/data/test.txt
kubectl exec -it $NEW_POD_NAME -- cat /app/logs/test.log

echo "=== テスト完了 ===" 