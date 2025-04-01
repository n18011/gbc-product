#!/bin/bash
# モニタリング環境（Prometheus、Grafana、AlertManager）をセットアップするスクリプト

set -e

# カラー表示用の設定
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# ヘルムがインストールされているか確認
if ! command -v helm &> /dev/null; then
    echo -e "${RED}Helmがインストールされていません。${NC}"
    echo "インストール方法は https://helm.sh/docs/intro/install/ を参照してください。"
    exit 1
fi

# kubectlがインストールされているか確認
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}kubectlがインストールされていません。${NC}"
    echo "インストール方法は https://kubernetes.io/docs/tasks/tools/ を参照してください。"
    exit 1
fi

# kindクラスターが起動しているか確認
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}Kubernetesクラスターが起動していません。${NC}"
    echo "kindクラスターを起動するには ./setup.sh を実行してください。"
    exit 1
fi

echo -e "${GREEN}モニタリング環境のセットアップを開始します...${NC}"

# モニタリング用のディレクトリが存在するか確認
if [ ! -d "k8s/monitoring" ]; then
    echo -e "${RED}モニタリング設定ディレクトリが存在しません。${NC}"
    echo "リポジトリのルートディレクトリで実行してください。"
    exit 1
fi

# Helmリポジトリの追加
echo -e "${YELLOW}Helmリポジトリを追加中...${NC}"
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# NFSストレージクラスが存在するか確認
if ! kubectl get storageclass nfs-storage &> /dev/null; then
    echo -e "${YELLOW}NFSストレージクラスが見つかりません。セットアップを実行します...${NC}"
    kubectl apply -f k8s/nfs-storage-class.yaml
    kubectl apply -f k8s/nfs-server.yaml
    kubectl apply -f k8s/nfs-pvc.yaml
    
    # NFSサーバーが起動するまで待機
    echo -e "${YELLOW}NFSサーバーが起動するまで待機中...${NC}"
    kubectl wait --for=condition=Ready pod -l app=nfs-server --timeout=120s
fi

# kube-prometheus-stackのインストール
echo -e "${YELLOW}kube-prometheus-stackをインストール中...${NC}"
helm install monitoring prometheus-community/kube-prometheus-stack -f k8s/monitoring/prometheus-values.yaml || {
    echo -e "${RED}kube-prometheus-stackのインストールに失敗しました。${NC}"
    exit 1
}

# ServiceMonitorとPrometheusRuleの適用
echo -e "${YELLOW}ServiceMonitorとアラートルールを適用中...${NC}"
kubectl apply -f k8s/monitoring/service-monitors.yaml
kubectl apply -f k8s/monitoring/prometheus-rules.yaml

# Podの状態確認
echo -e "${YELLOW}Podの状態を確認中...${NC}"
kubectl get pods | grep monitoring

echo -e "${GREEN}モニタリング環境のセットアップが完了しました！${NC}"
echo -e "${YELLOW}Grafana UIにアクセスするには、以下のURLを使用してください：${NC}"
echo -e "${GREEN}http://monitoring.localhost/${NC}"
echo -e "${YELLOW}初期ログイン情報：${NC}"
echo -e "${GREEN}ユーザー名: admin${NC}"
echo -e "${GREEN}パスワード: admin${NC}"
echo ""
echo -e "${YELLOW}注意: ローカル環境でアクセスするには、/etc/hostsファイルに以下の行を追加してください：${NC}"
echo -e "${GREEN}127.0.0.1 monitoring.localhost${NC}" 