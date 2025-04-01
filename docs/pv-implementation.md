# 永続ボリューム実装の詳細

この文書では、Issue #3「永続ボリューム追加の詳細タスク（最小限構成）」の実装内容について説明します。

## 実装内容

### 1. 要件定義と設計

#### 1.1 永続化対象の詳細定義
- ✅ **ログ保存用ボリューム**
  - サイズ: 500Mi
  - アクセスモード: ReadWriteOnce
  - マウントパス: `/app/logs`
- ✅ **DBデータ保存用ボリューム**
  - サイズ: 1Gi
  - アクセスモード: ReadWriteOnce 
  - マウントパス: `/app/data`

#### 1.2 kind環境での永続化方式選定
- ✅ StorageClassの確認と選択
- ✅ hostPathベースの永続ボリュームを実装

### 2. 実装内容

#### 2.1 StorageClass定義
- ✅ `local-storage.yaml` に定義済み

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: local-storage
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
```

#### 2.2 永続ボリューム(PV)とPersistentVolumeClaim(PVC)の定義
- ✅ `base-deployment.yaml` に追加済み

```yaml
# PV部分
apiVersion: v1
kind: PersistentVolume
metadata:
  name: gbc-app-logs-pv
spec:
  capacity:
    storage: 500Mi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: local-storage
  hostPath:
    path: /tmp/k8s-data/gbc-app/logs
    type: DirectoryOrCreate
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: gbc-app-db-pv
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: local-storage
  hostPath:
    path: /tmp/k8s-data/gbc-app/db
    type: DirectoryOrCreate
```

```yaml
# PVC部分
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: gbc-app-logs-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 500Mi
  storageClassName: local-storage
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: gbc-app-db-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: local-storage
```

#### 2.3 Deploymentの修正
- ✅ gbc-appのDeploymentに永続ボリューム設定を追加

```yaml
# Deployment部分のvolumes設定
volumes:
  - name: logs-volume
    persistentVolumeClaim:
      claimName: gbc-app-logs-pvc
  - name: db-volume
    persistentVolumeClaim:
      claimName: gbc-app-db-pvc

# Containers部分のvolumeMounts設定
volumeMounts:
  - mountPath: /app/logs
    name: logs-volume
  - mountPath: /app/data
    name: db-volume
```

### 3. ユーティリティスクリプト

#### 3.1 ホストパスディレクトリの準備スクリプト
- ✅ `scripts/prepare-pv-dirs.sh` スクリプトを作成

```bash
#!/bin/bash

# 永続ボリューム用のディレクトリを作成する
echo "ホストパスディレクトリを作成しています..."
mkdir -p /tmp/k8s-data/gbc-app/logs
mkdir -p /tmp/k8s-data/gbc-app/db
chmod -R 777 /tmp/k8s-data  # 権限設定（開発環境用）

echo "永続ボリューム用のディレクトリが作成されました:"
echo "- ログ用: /tmp/k8s-data/gbc-app/logs"
echo "- DB用: /tmp/k8s-data/gbc-app/db"
```

#### 3.2 動作確認スクリプト
- ✅ `scripts/verify-pv.sh` スクリプトを作成

## 実装・検証の手順

1. StorageClassとPV/PVCを作成：
```bash
kubectl apply -f k8s/local-storage.yaml
kubectl apply -f k8s/base-deployment.yaml
```

2. ホストパスディレクトリを準備：
```bash
./scripts/prepare-pv-dirs.sh
```

3. 動作確認：
```bash
./scripts/verify-pv.sh
```

## 制限事項・注意点

1. この永続ボリューム実装はkind環境での最小限構成です。本番環境では適切なストレージプロバイダを使用すべきです。
2. kind環境でのhostPathはノード再起動時にデータが失われる可能性があります。
3. マルチノード環境では、ReadWriteMany対応のストレージソリューション（例：NFS）を検討する必要があります。 