#!/bin/bash

# =============================================================================
# Realistic Cloud Environment Test Suite
# =============================================================================
# このスクリプトは、dev/stg/prd 環境の差分をテストします
# 本スクリプトは実際の GCP リソースをプロビジョニングしません
# HCL ファイルの差分検出機能をテストする目的です

set -euo pipefail

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# スクリプトのディレクトリ
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPORTER_BIN="${SCRIPT_DIR}/../../tf-diff-reporter"

# 関数定義
print_header() {
  echo -e "\n${BLUE}========================================${NC}"
  echo -e "${BLUE}$1${NC}"
  echo -e "${BLUE}========================================${NC}\n"
}

print_success() {
  echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
  echo -e "${RED}✗ $1${NC}"
}

print_info() {
  echo -e "${YELLOW}ℹ $1${NC}"
}

check_command() {
  if ! command -v "$1" &> /dev/null; then
    print_error "$1 command not found"
    echo "Please install $1 to run this test suite"
    return 1
  fi
  print_success "$1 is available"
}

# 前提条件チェック
print_header "前提条件チェック"

check_command "hcl2json" || exit 1
check_command "jd" || exit 1

if [ ! -f "$REPORTER_BIN" ]; then
  print_error "tf-diff-reporter not found at $REPORTER_BIN"
  echo "Please build tf-diff-reporter first:"
  echo "  cd ../../"
  echo "  go build -o tf-diff-reporter ./cmd/cli"
  exit 1
fi
print_success "tf-diff-reporter is available"

# テストケース 1: 自動検出
print_header "テスト 1: 環境自動検出 (dev を基準に stg, prd と比較)"

cd "$SCRIPT_DIR"
echo "実行コマンド: $REPORTER_BIN compare"
echo "現在のディレクトリ: $(pwd)"
echo "環境: $(ls -d */ | tr '\n' ' ')"

if $REPORTER_BIN compare; then
  print_success "テスト 1 完了: 意図されない差分は検出されませんでした"
  exit_code_1=0
else
  exit_code_1=$?
  if [ $exit_code_1 -eq 1 ]; then
    print_info "テスト 1 完了: 意図されない差分が検出されました (exit code: 1)"
  else
    print_error "テスト 1 失敗: 予期しないエラー (exit code: $exit_code_1)"
    exit 1
  fi
fi

# テストケース 2: 明示的指定 (dev vs stg)
print_header "テスト 2: dev vs stg 比較"

echo "実行コマンド: $REPORTER_BIN compare dev stg"

if $REPORTER_BIN compare dev stg; then
  print_success "テスト 2 完了: 意図されない差分は検出されませんでした"
  exit_code_2=0
else
  exit_code_2=$?
  if [ $exit_code_2 -eq 1 ]; then
    print_info "テスト 2 完了: 意図されない差分が検出されました (exit code: 1)"
  else
    print_error "テスト 2 失敗: 予期しないエラー (exit code: $exit_code_2)"
    exit 1
  fi
fi

# テストケース 3: stg vs prd
print_header "テスト 3: stg vs prd 比較"

echo "実行コマンド: $REPORTER_BIN compare stg prd"

if $REPORTER_BIN compare stg prd; then
  print_success "テスト 3 完了: 意図されない差分は検出されませんでした"
  exit_code_3=0
else
  exit_code_3=$?
  if [ $exit_code_3 -eq 1 ]; then
    print_info "テスト 3 完了: 意図されない差分が検出されました (exit code: 1)"
  else
    print_error "テスト 3 失敗: 予期しないエラー (exit code: $exit_code_3)"
    exit 1
  fi
fi

# レポート確認
print_header "生成されたレポート"

if [ -f .tfdr/reports/comparison-report.md ]; then
  print_success "レポートが生成されました"
  echo ""
  echo "レポートの内容（最初の 50 行）:"
  echo "---"
  head -50 .tfdr/reports/comparison-report.md
  echo "..."
  echo "---"
  echo ""
  print_info "完全なレポート: .tfdr/reports/comparison-report.md"
else
  print_error "レポートが生成されませんでした"
  exit 1
fi

# テスト結果サマリー
print_header "テスト結果サマリー"

echo "テスト 1 (自動検出): exit code $exit_code_1"
echo "テスト 2 (dev vs stg): exit code $exit_code_2"
echo "テスト 3 (stg vs prd): exit code $exit_code_3"

if [ $exit_code_1 -eq 0 ] || [ $exit_code_1 -eq 1 ]; then
  print_success "すべてのテストが正常に完了しました"
  exit 0
else
  print_error "テストが失敗しました"
  exit 1
fi
