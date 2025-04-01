# 永続ボリュームテスト実施手順書

このドキュメントでは、`scripts/pv-test.sh` スクリプトを使用して、Kubernetes 永続ボリュームの機能テストを実施する手順を説明します。

## 前提条件

以下の環境が準備されていることを確認してください：

1. 動作中の Kubernetes クラスタ（kind, minikube, または本番クラスタ）
2. kubectl コマンドラインツールのインストールと設定
3. 以下のリソースがデプロイされていること：
   - `local-storage` StorageClass
   - 永続ボリューム (PV) と永続ボリューム要求 (PVC)
   - `gbc-app` Deployment

## テスト環境のセットアップ

### 1. kind クラスタの作成（まだ作成していない場合）

```bash
# kind クラスタの作成
kind create cluster --config kind-config.yaml

# クラスタの状態確認
kubectl cluster-info
kubectl get nodes
```

### 2. 永続ボリュームのデプロイ

```bash
# StorageClass の作成
kubectl apply -f k8s/local-storage.yaml

# 基本デプロイメント（PV、PVC、Deployment を含む）
kubectl apply -f k8s/base-deployment.yaml

# リソースの確認
kubectl get sc,pv,pvc
kubectl get pods
```

## テストの実行

### テストスクリプトの実行

```bash
# スクリプトに実行権限を付与（まだ付与していない場合）
chmod +x scripts/pv-test.sh

# テストスクリプトの実行
./scripts/pv-test.sh
```

スクリプトは以下のテストを自動的に実行します：

1. **環境セットアップの確認**
   - Kubernetes クラスタの動作確認
   - StorageClass の確認
   - PV と PVC の確認
   - Pod の実行状態確認

2. **ボリュームマウントの検証**
   - Pod のボリュームマウント情報の確認
   - マウントパスの存在確認
   - ファイル書き込み/読み取りテスト

3. **ポッド再起動時のデータ保持確認**
   - テストデータの作成
   - Pod の削除と再作成
   - 新しい Pod でのデータ保持確認

4. **パフォーマンステスト**
   - 読み書きの基本的な I/O パフォーマンステスト

5. **エラーケースのテスト**
   - ストレージ容量の確認
   - エラー発生シミュレーション

## テスト結果の記録

テスト結果を以下の形式で記録してください：

```
# テスト実施日時：[日付と時間]
# 実施環境：[kind/minikube/本番など]
# 実施者：[名前]

## 結果サマリー
- 全体結果：[成功/一部失敗/失敗]
- 問題点：[発見された問題の簡潔な説明]

## 詳細結果
[テスト出力のログや重要なポイントをここに貼り付け]

## 所見
[テスト中に気づいた点や改善提案]
```

この記録を Issue #10 にコメントとして追加してください。

## トラブルシューティング

テスト実行中に問題が発生した場合：

1. **Pod が起動しない場合**
   ```bash
   kubectl describe pod [pod名]
   ```
   
2. **ボリュームマウントの問題**
   ```bash
   # ホストパスの確認
   ls -la /tmp/k8s-data/gbc-app/logs
   ls -la /tmp/k8s-data/gbc-app/db
   
   # パーミッションの修正（必要な場合）
   sudo chmod -R 777 /tmp/k8s-data
   ```

3. **スクリプトエラー**
   ```bash
   # スクリプトの個別関数をデバッグ実行
   source scripts/pv-test.sh
   check_environment
   ```

## 次のステップ

テストが成功した場合：
1. Issue #10 にテスト結果を報告
2. Issue #2 の「永続ボリュームの追加」セクションのテスト計画の項目にチェックを入れる

テストが失敗した場合：
1. 問題を特定し、修正するための PR を作成
2. 修正後、再度テストを実行 