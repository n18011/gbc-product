#!/bin/bash

# 永続ボリュームの動作確認スクリプト

echo "=== リソース作成確認 ==="
echo "StorageClassの確認:"
kubectl get sc

echo -e "\nPersistentVolumeの確認:"
kubectl get pv

echo -e "\nPersistentVolumeClaimの確認:"
kubectl get pvc

echo -e "\nPodの確認:"
kubectl get pod

# gbc-appのPod名を取得
POD_NAME=$(kubectl get pods -l app=gbc-app -o jsonpath='{.items[0].metadata.name}')

if [ -z "$POD_NAME" ]; then
  echo "エラー: gbc-appのPodが見つかりません"
  exit 1
fi

echo -e "\n=== ボリュームマウント確認 ==="
echo "Podのディスク使用状況:"
kubectl exec -it $POD_NAME -- df -h

echo -e "\nマウントディレクトリの確認:"
kubectl exec -it $POD_NAME -- ls -la /app/logs /app/data

echo -e "\n=== データ永続化テスト ==="
echo "テスト用ファイルを作成しています..."
kubectl exec -it $POD_NAME -- sh -c "echo 'テストデータ - $(date)' > /app/data/test.txt"
kubectl exec -it $POD_NAME -- sh -c "echo 'ログデータ - $(date)' > /app/logs/test.log"

echo "作成したファイルの内容確認:"
kubectl exec -it $POD_NAME -- cat /app/data/test.txt
kubectl exec -it $POD_NAME -- cat /app/logs/test.log

echo -e "\nPodを再起動しています..."
kubectl rollout restart deployment gbc-app
sleep 5
echo "Podの状態確認中..."
kubectl get pods -l app=gbc-app -w
sleep 10

# 新しいPod名を取得
NEW_POD_NAME=$(kubectl get pods -l app=gbc-app -o jsonpath='{.items[0].metadata.name}')

echo -e "\n新しいPod ($NEW_POD_NAME) でデータが残っているか確認:"
kubectl exec -it $NEW_POD_NAME -- cat /app/data/test.txt
kubectl exec -it $NEW_POD_NAME -- cat /app/logs/test.log

echo -e "\n=== 永続ボリューム確認完了 ===" 