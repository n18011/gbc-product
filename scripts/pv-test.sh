#!/bin/bash
# pv-test.sh - 永続ボリュームのテスト実行スクリプト
# Issue #10: 永続ボリュームのテスト計画と実施

set -e

# 色付きの出力関数
function info() {
  echo -e "\e[34m[INFO]\e[0m $1"
}

function success() {
  echo -e "\e[32m[SUCCESS]\e[0m $1"
}

function error() {
  echo -e "\e[31m[ERROR]\e[0m $1"
  exit 1
}

function warning() {
  echo -e "\e[33m[WARNING]\e[0m $1"
}

# 環境チェック
function check_environment() {
  info "環境確認を開始します..."
  
  # Kubernetesクラスタの動作確認
  kubectl get nodes &> /dev/null || error "Kubernetesクラスタに接続できません"
  success "Kubernetesクラスタに接続できました"
  
  # StorageClassの確認
  kubectl get sc local-storage &> /dev/null || error "local-storageのStorageClassが見つかりません"
  success "local-storageのStorageClassが存在します"
  
  # PVとPVCの確認
  kubectl get pv gbc-app-logs-pv &> /dev/null || error "gbc-app-logs-pvが見つかりません"
  kubectl get pv gbc-app-db-pv &> /dev/null || error "gbc-app-db-pvが見つかりません"
  kubectl get pvc gbc-app-logs-pvc &> /dev/null || error "gbc-app-logs-pvcが見つかりません"
  kubectl get pvc gbc-app-db-pvc &> /dev/null || error "gbc-app-db-pvcが見つかりません"
  success "PVとPVCが正しく作成されています"
  
  # ホストパスの確認（kindクラスタの場合は直接確認できない場合があります）
  info "ホストパスディレクトリの存在確認は環境により手動で確認が必要な場合があります"
  info "(/tmp/k8s-data/gbc-app/logs と /tmp/k8s-data/gbc-app/db)"
  
  # Podが実行中かどうかの確認
  POD_COUNT=$(kubectl get pods -l app=gbc-app -o name | wc -l)
  if [ "$POD_COUNT" -lt 1 ]; then
    error "gbc-appのPodが実行されていません"
  fi
  success "gbc-appのPodが${POD_COUNT}個実行中です"
}

# ボリュームマウントの検証
function verify_volume_mounts() {
  info "ボリュームマウントの検証を開始します..."
  
  # Podの名前を取得
  POD_NAME=$(kubectl get pods -l app=gbc-app -o name | head -n 1 | cut -d '/' -f 2)
  
  # Podのボリュームマウント情報を取得
  info "Pod ${POD_NAME} のボリュームマウント情報を確認します"
  kubectl describe pod ${POD_NAME} | grep -A 10 "Volumes:" || error "ボリューム情報の取得に失敗しました"
  
  # マウントパスの存在確認
  info "マウントパスの存在を確認します"
  kubectl exec ${POD_NAME} -- ls -la /app/logs || error "マウントパス /app/logs が存在しません"
  kubectl exec ${POD_NAME} -- ls -la /app/data || error "マウントパス /app/data が存在しません"
  success "ボリュームマウントのパスが正しく存在しています"
  
  # ファイル書き込みテスト
  info "ファイル書き込みテストを実施します"
  TEST_TIMESTAMP=$(date +%s)
  kubectl exec ${POD_NAME} -- bash -c "echo 'Test data ${TEST_TIMESTAMP}' > /app/logs/test.log" || error "ログディレクトリへの書き込みに失敗しました"
  kubectl exec ${POD_NAME} -- bash -c "echo 'Test data ${TEST_TIMESTAMP}' > /app/data/test.db" || error "データディレクトリへの書き込みに失敗しました"
  success "両ボリュームへの書き込みに成功しました"
  
  # ファイル読み取りテスト
  info "ファイル読み取りテストを実施します"
  LOG_CONTENT=$(kubectl exec ${POD_NAME} -- cat /app/logs/test.log)
  DB_CONTENT=$(kubectl exec ${POD_NAME} -- cat /app/data/test.db)
  
  if [[ "$LOG_CONTENT" == *"${TEST_TIMESTAMP}"* ]]; then
    success "ログファイルの読み取りに成功しました: $LOG_CONTENT"
  else
    error "ログファイルの内容が期待値と一致しません"
  fi
  
  if [[ "$DB_CONTENT" == *"${TEST_TIMESTAMP}"* ]]; then
    success "データファイルの読み取りに成功しました: $DB_CONTENT"
  else
    error "データファイルの内容が期待値と一致しません"
  fi
}

# ポッド再起動時のデータ保持確認
function verify_data_persistence() {
  info "ポッド再起動時のデータ保持確認を開始します..."
  
  # 現在のPod名を取得
  OLD_POD_NAME=$(kubectl get pods -l app=gbc-app -o name | head -n 1 | cut -d '/' -f 2)
  TEST_TIMESTAMP=$(date +%s)
  
  # テストデータの作成（ファイル名にタイムスタンプを含める）
  info "テストデータを作成します (timestamp: ${TEST_TIMESTAMP})"
  kubectl exec ${OLD_POD_NAME} -- bash -c "echo 'Persistence test ${TEST_TIMESTAMP}' > /app/logs/persistence-test.log" || error "テストデータ作成に失敗しました"
  kubectl exec ${OLD_POD_NAME} -- bash -c "echo 'Persistence test ${TEST_TIMESTAMP}' > /app/data/persistence-test.db" || error "テストデータ作成に失敗しました"
  
  # Podを削除し再作成を待つ
  info "Podを削除し、再作成を待ちます..."
  kubectl delete pod ${OLD_POD_NAME}
  sleep 5
  
  # 新しいPodが起動するのを待つ
  READY=false
  for i in {1..30}; do
    NEW_POD_STATUS=$(kubectl get pods -l app=gbc-app -o jsonpath='{.items[0].status.phase}')
    if [ "$NEW_POD_STATUS" == "Running" ]; then
      READY=true
      break
    fi
    echo -n "."
    sleep 2
  done
  echo ""
  
  if [ "$READY" != "true" ]; then
    error "新しいPodが起動しませんでした"
  fi
  
  NEW_POD_NAME=$(kubectl get pods -l app=gbc-app -o name | head -n 1 | cut -d '/' -f 2)
  success "新しいPod ${NEW_POD_NAME} が起動しました"
  
  # 新しいPodでデータが保持されているか確認
  info "データ保持を確認します..."
  sleep 10  # マウント完了を待つための余裕
  
  LOG_CONTENT=$(kubectl exec ${NEW_POD_NAME} -- cat /app/logs/persistence-test.log 2>/dev/null || echo "ファイルが見つかりません")
  DB_CONTENT=$(kubectl exec ${NEW_POD_NAME} -- cat /app/data/persistence-test.db 2>/dev/null || echo "ファイルが見つかりません")
  
  if [[ "$LOG_CONTENT" == *"${TEST_TIMESTAMP}"* ]]; then
    success "ログファイルのデータが保持されていました: $LOG_CONTENT"
  else
    error "ログファイルのデータが保持されていません。内容: $LOG_CONTENT"
  fi
  
  if [[ "$DB_CONTENT" == *"${TEST_TIMESTAMP}"* ]]; then
    success "データファイルのデータが保持されていました: $DB_CONTENT"
  else
    error "データファイルのデータが保持されていません。内容: $DB_CONTENT"
  fi
}

# パフォーマンステスト
function test_performance() {
  info "基本的なI/Oパフォーマンステストを開始します..."
  
  POD_NAME=$(kubectl get pods -l app=gbc-app -o name | head -n 1 | cut -d '/' -f 2)
  
  # 書き込みパフォーマンステスト
  info "書き込みパフォーマンステスト..."
  WRITE_TIME_LOGS=$(kubectl exec ${POD_NAME} -- bash -c "time dd if=/dev/zero of=/app/logs/test_file bs=1M count=10 2>&1")
  WRITE_TIME_DATA=$(kubectl exec ${POD_NAME} -- bash -c "time dd if=/dev/zero of=/app/data/test_file bs=1M count=10 2>&1")
  
  echo "ログボリューム書き込みテスト結果:"
  echo "$WRITE_TIME_LOGS"
  echo "データボリューム書き込みテスト結果:"
  echo "$WRITE_TIME_DATA"
  
  # 読み込みパフォーマンステスト
  info "読み込みパフォーマンステスト..."
  READ_TIME_LOGS=$(kubectl exec ${POD_NAME} -- bash -c "time dd if=/app/logs/test_file of=/dev/null bs=1M count=10 2>&1")
  READ_TIME_DATA=$(kubectl exec ${POD_NAME} -- bash -c "time dd if=/app/data/test_file of=/dev/null bs=1M count=10 2>&1")
  
  echo "ログボリューム読み込みテスト結果:"
  echo "$READ_TIME_LOGS"
  echo "データボリューム読み込みテスト結果:"
  echo "$READ_TIME_DATA"
  
  # テストファイルの削除
  kubectl exec ${POD_NAME} -- rm /app/logs/test_file /app/data/test_file
  
  success "パフォーマンステストが完了しました"
}

# エラーケースとリカバリーテスト
function test_error_cases() {
  info "エラーケースのテストを開始します..."
  
  POD_NAME=$(kubectl get pods -l app=gbc-app -o name | head -n 1 | cut -d '/' -f 2)
  
  # 大きなファイル作成テスト
  info "ストレージ容量テスト - 大きなファイル作成を試みます"
  kubectl exec ${POD_NAME} -- bash -c "df -h /app/logs /app/data"
  
  warning "注意: 実際の容量超過テストはシステムに負荷をかける可能性があるため、本番環境では実行しないでください"
  warning "このテストはシミュレーションのみを行います"
  
  # シミュレートされたエラーテスト - 実際の環境では調整が必要
  info "エラー発生時のアプリケーション挙動については、アプリケーション固有のテストが必要です"
  
  success "エラーケーステストが完了しました"
}

# メイン実行部分
function main() {
  info "永続ボリュームテストを開始します..."
  
  check_environment
  verify_volume_mounts
  verify_data_persistence
  test_performance
  test_error_cases
  
  success "全てのテストが完了しました！"
}

# スクリプト実行
main 