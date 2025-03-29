#!/bin/bash
set -e

echo "Kubernetesクラスター(kind)をセットアップしています..."

# kindクラスターを作成
kind create cluster --name gbc-product --config=kind-config.yaml

# コンテキストの確認
kubectl cluster-info --context kind-gbc-product

# NGINXのIngressコントローラーをデプロイ
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

# Ingressコントローラーが準備できるのを待つ
echo "Ingressコントローラーが準備できるのを待っています..."
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=600s

# アプリケーションをデプロイ
kubectl apply -f k8s/base-deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/ingress.yaml

echo "セットアップが完了しました！"
echo "アプリケーションへは http://localhost/ でアクセスできます" 