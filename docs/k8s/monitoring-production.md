# モニタリング環境：本番環境への移行ガイド

このドキュメントでは、現在のkind環境でのモニタリング設定を本番環境に移行する際の要件と注意点について説明します。

## 前提条件

- Kubernetesクラスタがすでに稼働していること
- StorageClassが利用可能であること
- Helmがインストールされていること
- 必要に応じてIngress Controllerが設定されていること

## リソース要件

### 1. 推奨ハードウェアリソース

開発環境では最小構成でセットアップしていますが、本番環境では以下のリソースを確保することを推奨します：

| コンポーネント | メモリ要求 | CPU要求 | メモリ上限 | CPU上限 | ストレージ |
|------------|----------|---------|----------|---------|----------|
| Prometheus | 4Gi      | 500m    | 8Gi      | 1000m   | 50Gi     |
| Grafana    | 1Gi      | 200m    | 2Gi      | 500m    | 10Gi     |
| AlertManager | 256Mi  | 100m    | 512Mi    | 200m    | 5Gi      |
| Node Exporter | 128Mi | 100m    | 256Mi    | 200m    | -        |
| kube-state-metrics | 256Mi | 100m | 512Mi   | 200m    | -        |
| Prometheus Operator | 512Mi | 200m | 1Gi     | 500m    | -        |

### 2. ストレージ構成

本番環境では、以下の点に注意してストレージを構成してください：

- **ストレージタイプ**: Prometheusには高速なSSDベースのストレージを使用してください
- **アクセスモード**: 可能であれば`ReadWriteMany`をサポートするストレージクラスを使用してください
- **バックアップ**: 定期的なバックアップ戦略を実装してください

### 3. ネットワーク要件

- **帯域幅**: 監視対象のノード数に応じて十分な帯域幅を確保してください（最低100Mbps）
- **レイテンシ**: Prometheusサーバーと監視対象ノード間のレイテンシを最小化してください（理想的には5ms以下）
- **ポート**: 以下のポートが利用可能であることを確認してください：
  - Prometheus: 9090/TCP
  - Alertmanager: 9093/TCP
  - Grafana: 3000/TCP
  - Node Exporter: 9100/TCP

## セキュリティ設定

### 1. 認証と認可

- Grafanaには強力なパスワードポリシーを設定してください
- 可能であれば、以下の外部認証を設定してください：
  - LDAP/Active Directory
  - OAuth/OIDC（Google、GitHub、Oktaなど）
  - SAML

### 2. 通信の暗号化

- 全てのコンポーネント間の通信をTLS/SSLで暗号化してください
- 自己署名証明書ではなく、信頼できる認証局の証明書を使用してください

### 3. ネットワークポリシー

- Prometheusコンポーネント間の通信のみを許可するネットワークポリシーを設定してください
- 監視コンポーネントへのアクセスを必要な管理ネットワークからのみ許可してください

## 高可用性設定

本番環境では、単一障害点を排除するために以下の高可用性設定を検討してください：

### 1. Prometheusの冗長化

- 複数のPrometheusレプリカを異なるノードに分散させる
- Thanos SidecarまたはCortexを使用して長期データストレージと高可用性を実現する

### 2. AlertManagerの冗長化

- AlertManagerをクラスタモードで実行し、複数のレプリカを設定する
- 通知チャネルの冗長化（例：SlackとEmailの両方）

### 3. Grafanaの冗長化

- 複数のGrafanaインスタンスを配置する
- ダッシュボード設定の永続化とバックアップを確実に行う

## スケーリング戦略

### 1. 垂直スケーリング

- 監視対象メトリクス数の増加に応じてPrometheusのリソースを増加させる
- 高カーディナリティのメトリクスがある場合は特に注意が必要

### 2. 水平スケーリング

- より大規模な環境では、機能シャーディングを検討する（例：アプリケーションメトリクス用とシステムメトリクス用の別々のPrometheusインスタンス）
- マルチクラスタ監視のためにThanosまたはCortexの使用を検討する

## パフォーマンスチューニング

### 1. サンプル保持期間

```yaml
prometheus:
  prometheusSpec:
    retention: "15d"  # 本番環境では15日間のデータ保持を推奨
```

### 2. スクレイプ間隔の最適化

```yaml
prometheus:
  prometheusSpec:
    scrapeInterval: "30s"  # 本番環境では30秒間隔を推奨
    evaluationInterval: "30s"
```

### 3. メモリ管理

```yaml
prometheus:
  prometheusSpec:
    resources:
      requests:
        memory: "4Gi"
      limits:
        memory: "8Gi"
    tsdb:
      maxExemplars: 100000  # オブザーバビリティのために増加
```

## 本番デプロイチェックリスト

- [ ] ストレージクラスとPVプロビジョナーが正しく設定されている
- [ ] リソース制限と要求が適切に設定されている
- [ ] TLS/SSL証明書が設定されている
- [ ] バックアップと復元の手順が確立されている
- [ ] アラート通知チャネルがテストされている
- [ ] 監視対象のすべてのサービスが適切にモニタリングされている
- [ ] ダッシュボードが必要なすべての情報を表示している
- [ ] 認証と認可の設定が適切に行われている
- [ ] 高可用性設定がテストされている
- [ ] パフォーマンスベースラインが確立されている

## デプロイ後のベストプラクティス

- 定期的なモニタリングシステム自体のヘルスチェック
- アラートの閾値とルールの定期的な見直し
- 新しいサービスのデプロイ時に適切なモニタリング設定を追加
- 容量計画と予測分析の定期的な実施
- 監視データの定期的なバックアップと復元テスト
- モニタリングチームのトレーニングと知識共有

## 参考資料

- [Prometheus本番運用ベストプラクティス](https://prometheus.io/docs/practices/instrumentation/)
- [Grafana高可用性ガイド](https://grafana.com/docs/grafana/latest/setup-grafana/set-up-for-high-availability/)
- [kube-prometheus-stack公式ドキュメント](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)
- [Kubernetes監視のベストプラクティス](https://kubernetes.io/docs/tasks/debug-application-cluster/resource-usage-monitoring/) 