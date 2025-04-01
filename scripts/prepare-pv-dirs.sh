#!/bin/bash

# 永続ボリューム用のディレクトリを作成する
echo "ホストパスディレクトリを作成しています..."
mkdir -p /tmp/k8s-data/gbc-app/logs
mkdir -p /tmp/k8s-data/gbc-app/db
chmod -R 777 /tmp/k8s-data  # 権限設定（開発環境用）

echo "永続ボリューム用のディレクトリが作成されました:"
echo "- ログ用: /tmp/k8s-data/gbc-app/logs"
echo "- DB用: /tmp/k8s-data/gbc-app/db" 