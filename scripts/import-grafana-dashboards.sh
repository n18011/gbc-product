#!/bin/bash

# Grafanaダッシュボードをインポートするスクリプト
# monitoring-next-steps.mdで推奨されているダッシュボードをインポートします

# スクリプトの場所を取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

# Grafanaの設定
GRAFANA_URL="http://localhost:3000"
GRAFANA_USER="admin"
GRAFANA_PASSWORD="admin"

# 一時フォルダの作成
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

# ダッシュボードIDのリスト（monitoring-next-steps.mdから抽出）
DASHBOARD_IDS=(
  1860    # Node Exporter Dashboard
  15661   # Kubernetes Cluster Overview
  15761   # Kubernetes API Server
  13770   # Kubernetes / Compute Resources / Namespace (Pods)
)

# ダッシュボードの名前マッピング
declare -A DASHBOARD_NAMES
DASHBOARD_NAMES[1860]="Node Exporter Dashboard"
DASHBOARD_NAMES[15661]="Kubernetes Cluster Overview"
DASHBOARD_NAMES[15761]="Kubernetes API Server"
DASHBOARD_NAMES[13770]="Kubernetes Compute Resources Namespace"

# Grafana APIにアクセスするための認証ヘッダー
AUTH_HEADER="Authorization: Basic $(echo -n ${GRAFANA_USER}:${GRAFANA_PASSWORD} | base64)"

# ポートフォワーディングが実行中かチェック
if ! nc -z localhost 3000 >/dev/null 2>&1; then
  echo "Grafanaへのポートフォワーディングが見つかりません。"
  echo "次のコマンドを実行してください: kubectl port-forward svc/monitoring-grafana 3000:80"
  exit 1
fi

echo "Grafanaダッシュボードのインポートを開始します..."

# 各ダッシュボードをインポート
for id in "${DASHBOARD_IDS[@]}"; do
  name="${DASHBOARD_NAMES[$id]}"
  echo "ダッシュボードをインポート中: $name (ID: $id)..."
  
  # Grafana UIを使用してダッシュボードをインポートするための指示を表示
  echo "1. ブラウザでGrafana UI (${GRAFANA_URL}) にアクセスしてください"
  echo "2. ログイン: ユーザー名=${GRAFANA_USER}, パスワード=${GRAFANA_PASSWORD}"
  echo "3. サイドメニューから [+] > [Import] をクリックしてください"
  echo "4. 「Import via grafana.com」の欄に「${id}」と入力してください"
  echo "5. [Load] をクリックしてください"
  echo "6. データソースとして「Prometheus」を選択してください"
  echo "7. [Import] をクリックしてください"
  
  # 次のダッシュボードに進む前に確認する
  read -p "このダッシュボードのインポートが完了したら Enter キーを押してください..." key
  
  echo "ダッシュボード $name (ID: $id) のインポートが完了しました"
  echo "--------------------------------------------------------------"
done

echo "すべてのダッシュボードのインポートが完了しました"
echo "Grafana UI: ${GRAFANA_URL} (ユーザー名: ${GRAFANA_USER}, パスワード: ${GRAFANA_PASSWORD})" 