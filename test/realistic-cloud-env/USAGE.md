# tf-diff-reporter テストスイート - クイックガイド

## 概要

このテストスイートは **tf-diff-reporter の実践的な使用例** です。

- **3環境比較**: dev, stg, prd
- **57個のルール**: 意図した環境差分を定義
- **6種類のdev-only リソース**: 開発環境固有のテストリソース
- **自動テストスクリプト**: CI/CD統合用

## 最速実行方法

```bash
cd test/realistic-cloud-env
./test.sh
```

**期待される結果**: すべてのテストが `exit code 0` で成功

## テストケース

### 1. 自動検出（dev基準）
```bash
../../tf-diff-reporter compare
```
- dev → stg, prd の差分を比較
- 49個の認識済み差分を検出

### 2. prd基準（dev-only リソース検証）
```bash
../../tf-diff-reporter compare prd dev stg
```
- dev にだけあるテストリソース 6種類を認識
- 57個の認識済み差分を検出

### 3. 段階的スケールアップ確認
```bash
../../tf-diff-reporter compare dev stg prd
```
- dev → stg → prd への段階的リソース増強を追跡
- GKE: 1 → 2 → 3 ノード
- DB: micro → custom-2 → custom-4
- Redis: 1GB basic → 2GB standard → 5GB standard

## レポートの読み方

生成されるレポート: `.tfdr/reports/comparison-report.md`

### サマリー部分の見方
```
未認識差分 (−): 0   ← 0 = OK、> 0 = エラー
認識済み差分 (✓): 57 ← ignore.json で許可された差分の数
```

### 差分内容の見方
```
属性パス: /resource/google_container_cluster/primary/0/initial_node_count
prd → dev:    ~ 3 → 1
prd → stg:    ~ 3 → 2
理由: GKE node count increases: 1 (dev) -> 2 (stg) -> 3 (prd)
```

- `~` = 値が変更
- `+` = リソースが新規追加
- `−` = 当該環境では存在しない

## 開発用リソース（Dev-only）

dev にだけ含まれるリソース（自動的に許可されます）：

1. **debug_logs** - デバッグ用ログバケット
2. **dev_test_vm** - テスト用VM
3. **dev_repo** - ビルド用アーティファクトレジストリ
4. **dev_local** - テスト用サービスアカウント
5. **dev_custom_metric** - テスト用カスタムメトリクス
6. **dev_debug_sink** - デバッグ用ログシンク

## CI/CD統合

```yaml
# GitHub Actions の例
- name: Check Terraform Diffs
  run: |
    cd test/realistic-cloud-env
    ../../tf-diff-reporter compare prd dev stg
    test $? -eq 0  # exit code 0 で続行
```

## よくあるシナリオ

### シナリオ1: Dev環境にテストリソースを追加
```bash
# 1. dev/main.tf に新しいリソースを追加
# 2. テスト実行
../../tf-diff-reporter compare prd dev stg
# 3. 未認識差分が出たら ignore.json に追加
```

### シナリオ2: 本番環境のスペックを変更
```bash
# 1. prd/main.tf でスペック変更
# 2. テスト実行
../../tf-diff-reporter compare
# 3. 認識済み差分として自動検出
```

## トラブル解決

| 問題 | 原因 | 解決方法 |
|------|------|--------|
| `exit code 1` | 予期しない差分検出 | レポートを確認して ignore.json に追加 |
| `jd: command not found` | jd 未インストール | `brew install jd` または `go install github.com/josephbismark/jd@latest` |
| `hcl2json: command not found` | hcl2json 未インストール | `brew install hcl2json` |
| レポートが生成されない | ディレクトリ不足 | `mkdir -p .tfdr/reports` |

## ファイル一覧

```
dev/main.tf              - 開発環境リソース（+6つの dev-only リソース）
stg/main.tf              - ステージング環境リソース
prd/main.tf              - 本番環境リソース
.tfdr/ignore.json        - 57個の許可ルール定義
test.sh                  - 自動テストスクリプト
README.md                - 詳細ドキュメント
USAGE.md                 - このファイル
```

## 詳細は README.md を参照

- **各環境のスペック比較**: リソースタイプ別テーブル
- **ignore.json ルール分類**: 57個のルールの詳細
- **CI/CD 統合例**: 実装サンプル
- **拡張シナリオ**: マルチリージョン、セキュリティテストなど

---

**このテストスイートで学べること：**
1. 複数環境の Terraform 構成管理
2. 意図した差分と意図しない差分の区別
3. CI/CD パイプラインでの自動検証
4. RFC 6902 JSON Patch フォーマット
