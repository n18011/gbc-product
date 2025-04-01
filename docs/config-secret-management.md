# ConfigMapとSecretの管理ガイド

このドキュメントでは、GBC Productにおける設定値と機密情報の管理方法について説明します。

## 目次

1. [概要](#概要)
2. [ConfigMapの管理](#configmapの管理)
3. [Secretの管理](#secretの管理)
4. [環境ごとの設定切り替え](#環境ごとの設定切り替え)
5. [CI/CDパイプラインでの管理](#cicdパイプラインでの管理)
6. [参考情報](#参考情報)

## 概要

GBC Productでは以下の原則に基づいて設定管理を行います：

- 非機密設定は**ConfigMap**で管理
- 機密情報は**Secret**で管理
- 環境ごとに異なる設定は環境固有のConfigMapとSecretを使用

## ConfigMapの管理

### ConfigMapの構造

プロジェクトには以下の3種類のConfigMapが存在します：

1. **gbc-app-config** (k8s/configmap.yaml): 基本設定
2. **gbc-app-config-dev** (k8s/configmap-dev.yaml): 開発環境固有の設定
3. **gbc-app-config-prod** (k8s/configmap-prod.yaml): 本番環境固有の設定

各ConfigMapには以下のカテゴリの設定が含まれています：

- アプリケーション基本設定（ポート番号、ホスト名など）
- サービス接続設定（タイムアウト、リトライ回数など）
- システム設定（最大接続数など）
- 環境設定（環境名、APIエンドポイントなど）
- HTMLテンプレート用のJSON設定

### ConfigMapの更新方法

ConfigMapを更新する場合は、対応するYAMLファイルを編集し、以下のコマンドで適用します：

```bash
kubectl apply -f k8s/configmap.yaml
```

環境固有の設定を一括で適用する場合は、以下のスクリプトを使用します：

```bash
ENVIRONMENT=dev ./scripts/apply-configs.sh
# または
ENVIRONMENT=prod ./scripts/apply-configs.sh
```

## Secretの管理

### Secretの構造

プロジェクトには以下の3種類のSecretが存在します：

1. **gbc-app-secrets** (k8s/secrets.yaml): 基本機密情報
2. **gbc-app-secrets-dev** (k8s/secrets-dev.yaml): 開発環境固有の機密情報
3. **gbc-app-secrets-prod** (k8s/secrets-prod.yaml): 本番環境固有の機密情報

各Secretには以下のカテゴリの機密情報が含まれています：

- データベース接続情報（ホスト、ポート、データベース名、ユーザー名、パスワード）
- APIキー
- JWT Secret
- SSL証明書と秘密鍵

### Secretの更新方法

Secret値の更新には、以下のステップを実施します：

1. 値をbase64エンコードする
   ```bash
   echo -n "実際の値" | base64
   ```

2. エンコードした値をYAMLファイルに記載

3. Secretを適用する
   ```bash
   kubectl apply -f k8s/secrets.yaml
   ```

**注意**: YAMLファイルに直接機密情報を保存することは本番環境では推奨されません。CI/CDパイプラインでの管理方法については後述します。

## 環境ごとの設定切り替え

環境を切り替えるには、以下のスクリプトを使用します：

```bash
./scripts/switch-environment.sh dev
# または
./scripts/switch-environment.sh prod
```

このスクリプトは、以下の操作を実行します：
1. 環境固有のConfigMapを適用
2. 環境固有のSecretを適用
3. デプロイメントを再起動して新しい設定を適用

## CI/CDパイプラインでの管理

### 推奨アプローチ

本番環境でのSecretの管理には、以下のアプローチを推奨します：

1. **外部シークレット管理システムの利用**
   - HashiCorp Vault
   - AWS Secrets Manager
   - Google Secret Manager
   - Azure Key Vault

2. **Kubernetes External Secretsの利用**
   - 外部のシークレット管理システムと連携し、Kubernetes Secretsを自動生成

3. **GitOpsパイプラインでのSecret暗号化**
   - SOPS (Secrets OPerationS)
   - Sealed Secrets
   - Argo CD Vault Plugin

### サンプル実装: SOPSを使用したSecret暗号化

1. SOPSをインストール
   ```bash
   # MacOS
   brew install sops
   
   # Linux
   wget https://github.com/mozilla/sops/releases/download/v3.7.3/sops-v3.7.3.linux.amd64 -O sops
   chmod +x sops
   sudo mv sops /usr/local/bin/
   ```

2. GPGキーで暗号化
   ```bash
   # GPGキーを生成
   gpg --gen-key
   
   # キーIDを取得
   gpg --list-keys
   
   # Secretを暗号化
   sops --encrypt --pgp <キーID> k8s/secrets-prod.yaml > k8s/secrets-prod.enc.yaml
   ```

3. CI/CDパイプラインでの復号化
   ```yaml
   # GitHubActionsサンプル
   jobs:
     deploy:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v3
         
         - name: Import GPG key
           uses: crazy-max/ghaction-import-gpg@v5
           with:
             gpg_private_key: ${{ secrets.GPG_PRIVATE_KEY }}
             passphrase: ${{ secrets.GPG_PASSPHRASE }}
         
         - name: Decrypt secrets
           run: |
             sops --decrypt k8s/secrets-prod.enc.yaml > k8s/secrets-prod.yaml
         
         - name: Apply resources
           run: |
             kubectl apply -f k8s/secrets-prod.yaml
   ```

## 参考情報

- [Kubernetes ConfigMap公式ドキュメント](https://kubernetes.io/docs/concepts/configuration/configmap/)
- [Kubernetes Secret公式ドキュメント](https://kubernetes.io/docs/concepts/configuration/secret/)
- [SOPS GitHub](https://github.com/mozilla/sops)
- [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets)
- [Kubernetes External Secrets](https://github.com/external-secrets/external-secrets) 