# モニタリング環境のセットアップ

このドキュメントでは、Kubernetes環境にPrometheus、Grafana、AlertManagerを使用したモニタリング環境をセットアップする手順を説明します。

## 前提条件

- 動作中のKubernetes（kind）クラスター
- Helmがインストールされていること
- kubectl CLIツールがインストールされていること
- NFS StorageClassが設定されていること（永続ボリューム用）

## セットアップ手順

### 1. Helmリポジトリの追加

```bash
# Prometheus Operatorのリポジトリを追加
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```

### 2. kube-prometheus-stackのインストール

カスタム値ファイルを使用して、Prometheus、Grafana、AlertManagerを含むkube-prometheus-stackをインストールします。

```bash
# カスタム値ファイルを使用してインストール
helm install monitoring prometheus-community/kube-prometheus-stack -f k8s/monitoring/prometheus-values.yaml -n default
```

### 3. リソースの確認

すべてのコンポーネントが正常にデプロイされたことを確認します。

```bash
# Podの状態を確認
kubectl get pods | grep monitoring

# PVCの状態を確認
kubectl get pvc | grep monitoring

# Serviceの確認
kubectl get svc | grep monitoring
```

### 4. アプリケーションのServiceMonitor設定

アプリケーションのメトリクスを収集するためのServiceMonitorを適用します。

```bash
kubectl apply -f k8s/monitoring/service-monitors.yaml
```

### 5. アラートルールの設定

基本的なアラートルールを適用します。

```bash
kubectl apply -f k8s/monitoring/prometheus-rules.yaml
```

### 6. Grafana IngressのDNS設定

ローカル環境で`monitoring.localhost`にアクセスできるように、`/etc/hosts`ファイルを編集します。

```bash
# /etc/hostsファイルに以下の行を追加
127.0.0.1 monitoring.localhost
```

### 7. Grafana UIへのアクセス

以下のURLでGrafana UIにアクセスできます：

```
http://monitoring.localhost/
```

初期ログイン情報：
- ユーザー名: admin
- パスワード: admin

### 8. ダッシュボードのインポート

Grafana UIにログイン後、以下の人気のあるダッシュボードをインポートすることができます：

1. Node Exporter Dashboard (ID: 1860)
2. Kubernetes Cluster Overview (ID: 15661)
3. Kubernetes API Server (ID: 15761)
4. Kubernetes / Compute Resources / Namespace (Pods) (ID: 13770)

インポート手順：
1. Grafana UIの左側メニューから「+」ボタンをクリック
2. 「Import」を選択
3. ダッシュボードIDを入力
4. データソースとして「Prometheus」を選択
5. 「Import」ボタンをクリック

## トラブルシューティング

### 永続ボリュームの問題

永続ボリュームが正しく作成されていない場合：

```bash
# PVとPVCの状態を確認
kubectl get pv,pvc

# PVCのイベントを確認
kubectl describe pvc <pvc-name>
```

### Prometheusが起動しない場合

```bash
# Prometheusのログを確認
kubectl logs -l app=prometheus -c prometheus

# Prometheusの設定を確認
kubectl get secret monitoring-prometheus -o jsonpath="{.data['prometheus\.yaml']}" | base64 -d
```

### Grafanaにアクセスできない場合

```bash
# Ingressの設定を確認
kubectl get ingress grafana-ingress
kubectl describe ingress grafana-ingress

# Grafanaのサービス状態を確認
kubectl get svc monitoring-grafana
```

## 設定のカスタマイズ

### Prometheusのストレージサイズ変更

`k8s/monitoring/prometheus-values.yaml`ファイルを編集して、ストレージサイズを変更します：

```yaml
prometheus:
  prometheusSpec:
    storageSpec:
      volumeClaimTemplate:
        spec:
          resources:
            requests:
              storage: "10Gi"  # サイズを変更
```

変更後、Helmリリースをアップグレードします：

```bash
helm upgrade monitoring prometheus-community/kube-prometheus-stack -f k8s/monitoring/prometheus-values.yaml
```

### Grafanaのパスワード変更

`k8s/monitoring/prometheus-values.yaml`ファイルを編集して、Grafanaのパスワードを変更します：

```yaml
grafana:
  adminPassword: "新しいパスワード"
```

変更後、Helmリリースをアップグレードします：

```bash
helm upgrade monitoring prometheus-community/kube-prometheus-stack -f k8s/monitoring/prometheus-values.yaml
```

## リソースの削除

モニタリングスタック全体を削除するには：

```bash
helm uninstall monitoring
kubectl delete pvc -l app=prometheus
kubectl delete pvc -l app=grafana
kubectl delete pvc -l app=alertmanager
``` 