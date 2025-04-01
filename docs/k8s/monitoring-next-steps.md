# モニタリング環境：次のステップと改善点

このドキュメントでは、現在のモニタリング環境をさらに改善するための次のステップと検討事項をまとめています。

## 現在の課題

1. **コンテナの起動問題**
   - Grafanaのコンテナ（3つ中2つのみ起動）
   - Prometheusのコンテナ（2つ中1つのみ起動）

2. **リソース制約**
   - kind環境のリソース制限によるコンテナ起動の問題
   - 永続ボリュームの設定に関する課題

## 改善のための次のステップ

### 1. リソース設定の最適化

Prometheusのリソース設定を調整：

```yaml
prometheus:
  prometheusSpec:
    resources:
      requests:
        memory: "1Gi"  # 512Mi から 1Gi に増加
        cpu: "200m"    # 100m から 200m に増加
      limits:
        memory: "2Gi"  # 1Gi から 2Gi に増加
        cpu: "500m"    # 400m から 500m に増加
```

Grafanaの設定も同様に見直し：

```yaml
grafana:
  resources:
    requests:
      memory: "512Mi"  # 256Mi から 512Mi に増加
      cpu: "200m"      # 100m から 200m に増加
    limits:
      memory: "1Gi"    # 512Mi から 1Gi に増加
      cpu: "300m"      # 200m から 300m に増加
```

### 2. ヘルスチェック待機時間の延長

Prometheusのヘルスチェック設定を調整：

```yaml
prometheus:
  prometheusSpec:
    readinessProbeInitialDelay: 60  # 30秒から60秒に延長
    livenessProbeInitialDelay: 120  # 60秒から120秒に延長
```

Grafanaのヘルスチェック設定も同様に：

```yaml
grafana:
  readinessProbe:
    initialDelaySeconds: 60        # 0秒から60秒に延長
  livenessProbe:
    initialDelaySeconds: 120       # 60秒から120秒に延長
```

### 3. PersistentVolume設定の最適化

NFS StorageClassの設定を見直し、アクセスモードをReadWriteManyに変更することも検討：

```yaml
prometheus:
  prometheusSpec:
    storageSpec:
      volumeClaimTemplate:
        spec:
          accessModes: ["ReadWriteMany"]  # ReadWriteOnceからReadWriteManyに変更
```

### 4. ダッシュボードのカスタマイズ

Grafanaが正常に動作したら、以下のダッシュボードをインポートして環境に合わせてカスタマイズ：

1. **Node Exporter Dashboard (ID: 1860)**
   - サーバーのリソース使用状況やパフォーマンスを監視
   - CPU、メモリ、ディスク、ネットワークの詳細メトリクス

2. **Kubernetes Cluster Overview (ID: 15661)**
   - クラスター全体の健全性と使用状況
   - ノード、Pod、Deploymentの状態

3. **Kubernetes API Server (ID: 15761)**
   - API Serverのパフォーマンスと健全性
   - リクエスト数、レイテンシ、エラーレート

4. **Kubernetes / Compute Resources / Namespace (Pods) (ID: 13770)**
   - 名前空間ごとのリソース使用状況
   - Podのリソース使用率と制限

### 5. アラート設定の詳細化

基本アラートルールをさらに拡張し、環境に合わせた閾値とルーティング設定：

1. **サービス固有のアラート**
   - gbc-appサービスのエラーレートとレスポンスタイム
   - データベース接続エラーの検知

2. **環境リソースのアラート**
   - ディスク容量の予測使用量
   - メモリリーク検知

3. **ビジネスメトリクスのアラート**
   - ユーザーアクティビティの異常検知
   - トランザクション成功率の低下

## 長期的な改善計画

1. **メトリクス収集の最適化**
   - 収集頻度とサンプリングレートの調整
   - 長期保存データの圧縮設定

2. **アラート通知チャネルの拡張**
   - Slack統合
   - メール通知の設定
   - PagerDutyなどのオンコールサービスとの統合

3. **高可用性の検討**
   - Prometheus連携モードの設定
   - リモートストレージとの統合

4. **セキュリティ強化**
   - Grafanaアクセス制御の詳細設定
   - APIアクセスのTLS設定
   - Prometheus WebUIのセキュリティ設定

## 次のアクション

1. リソース設定を調整し、Helmリリースをアップグレード
2. すべてのコンポーネントが正常に起動するまで待機
3. Grafana UIにアクセスしてダッシュボードをインポート
4. アラートルールをテストして調整
5. 長期的な改善計画のロードマップを作成

これらのステップを実施することで、より安定したモニタリング環境の構築と、効果的なアラート通知の実現を目指します。 