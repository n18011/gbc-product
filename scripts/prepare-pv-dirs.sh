#!/bin/bash

# 永続ボリューム用のディレクトリを作成するスクリプト

# kind ノードの名前（クラスター名に基づく）
NODE_NAME="gbc-product-control-plane"

echo "=== KindクラスターのノードにPV用ディレクトリを作成します ==="

# kindノードへのコンテナ接続と必要なディレクトリ作成
echo "ディレクトリを作成: /tmp/k8s-data/gbc-app/logs"
docker exec $NODE_NAME mkdir -p /tmp/k8s-data/gbc-app/logs

echo "ディレクトリを作成: /tmp/k8s-data/gbc-app/db"
docker exec $NODE_NAME mkdir -p /tmp/k8s-data/gbc-app/db

# 権限設定（開発環境用）
echo "権限を設定: chmod -R 777 /tmp/k8s-data"
docker exec $NODE_NAME chmod -R 777 /tmp/k8s-data

echo "=== 作成済みディレクトリを確認 ==="
docker exec $NODE_NAME ls -la /tmp/k8s-data/gbc-app

echo "=== 完了 ===" 