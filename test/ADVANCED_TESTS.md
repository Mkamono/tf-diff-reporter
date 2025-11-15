# Advanced Terraform Syntax Test Cases

`tf-diff-reporter` の **高度な Terraform 構文カバレッジ** を検証するための6つの新しいテストケースです。

既存の `test/realistic-cloud-env/` が「実践的なマルチ環境シミュレーション」をテストするのに対し、このテストスイートは **Terraform プログラミング機能** と **ファイル構成パターン** をテストします。

## テストケース一覧

| テストケース | Terraform 機能/パターン | カバーする差分パターン |
|------------|-------------|-------------------|
| **foreach-basics** | `for_each` メタ引数 | イテレーションキーの追加/削除、要素値の変更 |
| **count-iteration** | `count` メタ引数 | 条件分岐（0個/N個リソース）とインデックス変更 |
| **dynamic-blocks** | `dynamic` ブロック | ネストされたブロックの動的生成 |
| **mixed-variables** | variables + locals + for_each | 複雑な依存関係チェーン（locals の波及効果も含む） |
| **multifile-hcl** | 複数 `.tf` ファイル | ファイル分割構成の統合比較 |

## クイックスタート

### すべてのテストを実行

```bash
cd test

# foreach-basics
cd foreach-basics && ../../tf-diff-reporter compare env1 env2 && cd ..

# count-iteration
cd count-iteration && ../../tf-diff-reporter compare env1 env2 && cd ..

# dynamic-blocks
cd dynamic-blocks && ../../tf-diff-reporter compare env1 env2 && cd ..

# mixed-variables
cd mixed-variables && ../../tf-diff-reporter compare env1 env2 && cd ..

# multifile-hcl
cd multifile-hcl && ../../tf-diff-reporter compare env1 env2 && cd ..
```

**期待される結果**: すべてのテストが `exit code 0`

### 個別実行例

```bash
# for_each のテスト
cd test/foreach-basics
../../tf-diff-reporter compare env1 env2
cat .tfdr/reports/comparison-report.md

# locals のテスト
../../tf-diff-reporter compare env1 env2
cat .tfdr/reports/comparison-report.md
```

## テストケース詳細

### 1. test/foreach-basics - for_each での動的リソース生成

**テスト対象:**
- `for_each` でのキーの追加/削除
- イテレーション値の変更
- イテレーション単位での属性差異

**シナリオ:**
```
env1: 3つのストレージバケット (logs, data, backup)
env2: 4つのストレージバケット (logs, data, backup, archive) ← archive 新規追加
      storage_class の変更 (NEARLINE → STANDARD) など
```

**差分数:** 21個のルール

```bash
cd test/foreach-basics
../../tf-diff-reporter compare env1 env2
```

詳細は `test/foreach-basics/README.md` を参照

### 2. test/count-iteration - 条件分岐と反復処理

**テスト対象:**
- 条件式による 0個/N個リソース
- 条件式の真偽値変更
- count インデックスの追加/削除

**シナリオ:**
```
env1: enable_backup=false, enable_https=false, replica_count=1
      → Backup DB なし、HTTPS なし、レプリカ 1個

env2: enable_backup=true, enable_https=true, replica_count=2
      → Backup DB あり、HTTPS あり、レプリカ 2個 ← 条件式変更により新規リソース作成
```

**差分数:** 14個のルール

```bash
cd test/count-iteration
../../tf-diff-reporter compare env1 env2
```

詳細は `test/count-iteration/README.md` を参照

### 3. test/dynamic-blocks - 動的ブロック生成

**テスト対象:**
- `dynamic` ブロックによるネストされた要素の生成
- リスト型 `locals` の拡張/縮小
- 複数 `dynamic` ブロックの組合せ

**シナリオ:**
```
env1: Firewall (2個の ingress ルール) + Cloud Run (基本的な環境変数)
env2: Firewall (3個の ingress ルール) + Cloud Run (拡張された環境変数)
      → HTTPS ルール追加、環境変数追加など
```

**差分数:** 13個のルール

```bash
cd test/dynamic-blocks
../../tf-diff-reporter compare env1 env2
```

詳細は `test/dynamic-blocks/README.md` を参照

### 4. test/mixed-variables - 統合パターン

**テスト対象:**
- `variables` ブロック自体の変更
- `variables` と `locals` の相互参照
- `for_each` と `variables` の統合
- 複数リソースへの波及効果

**シナリオ:**
```
env1: 基本的なサービス構成
      services = [web, api] (各1レプリカ)
      enable_monitoring = false
      instance_config = e2-medium/20GB

env2: 本番構成
      services = [web, api, worker] (2-3レプリカ) ← worker 新規追加
      enable_monitoring = true ← monitoring_alert_policy 作成
      instance_config = e2-standard-2/50GB ← スケール
      tags に tier を追加
```

**差分数:** 22個のルール

```bash
cd test/mixed-variables
../../tf-diff-reporter compare env1 env2
```

詳細は `test/mixed-variables/README.md` を参照

### 5. test/multifile-hcl - 複数HCLファイル構成

**テスト対象:**
- 複数の `.tf` ファイルの統合処理
- ファイル分割されたリソース定義の差分検出
- モジュール分割パターンの比較

**ファイル構成:**
```
env1/
├── main.tf          # provider と VPC ネットワーク
├── compute.tf       # GCE インスタンス
└── database.tf      # Cloud SQL とファイアウォール

env2/
├── main.tf          # provider と VPC ネットワーク
├── compute.tf       # GCE インスタンス (スケールアップ)
└── database.tf      # Cloud SQL とファイアウォール (拡張)
```

**シナリオ:**
```
env1: GCE e2-medium (20GB), DB f1-micro, ファイアウォール (80)
env2: GCE e2-standard-2 (50GB) + app サーバー追加、DB custom-2, ファイアウォール (80, 443) + app ルール
      → 複数ファイルにまたがる一貫した変更
```

**差分数:** 24個のルール

```bash
cd test/multifile-hcl
../../tf-diff-reporter compare env1 env2
```

詳細は `test/multifile-hcl/README.md` を参照

## テストの実行と検証

### 基本的な実行方法

```bash
cd test/<testcase-name>
../../tf-diff-reporter compare env1 env2
```

### レポート確認

```bash
cat .tfdr/reports/comparison-report.md
```

### 終了コード確認

```bash
../../tf-diff-reporter compare env1 env2
echo $?  # 0 = 成功（すべての差分が認識済み）
```

### デバッグ：hcl2json と jd の出力確認

```bash
# JSON 変換の確認
hcl2json env1/main.tf > /tmp/env1.json
hcl2json env2/main.tf > /tmp/env2.json

# jd で差分確認
jd -f patch /tmp/env1.json /tmp/env2.json
```

## テストがカバーする Terraform 構文

### for_each
- ✅ `for_each` でのキー追加/削除
- ✅ イテレーション値の属性変更
- ✅ `toset()` の使用
- ✅ `{ for key => value in list }`

### locals
- ✅ プリミティブ型の値変更
- ✅ `locals` 内での `locals` 参照
- ✅ `merge()` による動的ラベル生成
- ✅ 複数リソースへの wave 効果

### count
- ✅ 条件式 `count = var.enable ? 1 : 0`
- ✅ `count = var.count` での反復
- ✅ `count.index` の使用
- ✅ 配列インデックスの変化

### dynamic
- ✅ `dynamic "block_name"`
- ✅ `for_each` での複数要素生成
- ✅ ネストされた `dynamic` ブロック
- ✅ `dynamic` での値参照

### variables
- ✅ Variable ブロック自体の変更
- ✅ `default` 値の変更
- ✅ Object/Map/List 型の変更
- ✅ Variables と Locals の相互参照

## ignore.json の役割と学び

各テストケースは `.tfdr/ignore.json` で差分を定義します。

```json
[
  {
    "path": "/resource/google_storage_bucket/app_buckets/archive",
    "comment": "New archive bucket added in env2"
  },
  {
    "path": "/resource/google_storage_bucket/app_buckets/data/0/storage_class",
    "comment": "Data bucket storage class changed: NEARLINE -> STANDARD"
  }
]
```

このファイルから学べること：
1. **RFC 6902 パスフォーマット**: `/resource/type/name/key/attribute`
2. **for_each での配列化**: `app_buckets/archive` は for_each キー
3. **ネストレベルの表現**: `/0/attribute` は配列要素、`/key/attribute` はマップキー

## 期待される動作

### 正常系（exit code 0）

```bash
$ cd test/foreach-basics && ../../tf-diff-reporter compare env1 env2
$ echo $?
0  # すべての差分が認識済み
```

レポート例：
```markdown
## サマリー
| | |
| --- | --- |
| 基準環境 | env1 |
| 未認識差分 (−) | 0 |
| 認識済み差分 (✓) | 21 |
```

### 異常系（exit code 1）

`ignore.json` を削除した場合：
```bash
$ cd test/foreach-basics && rm .tfdr/ignore.json && ../../tf-diff-reporter compare env1 env2
$ echo $?
1  # 未認識差分が存在

# レポート内容：
# 未認識差分 (−): 21
```

## トラブルシューティング

### hcl2json not found

```bash
brew install hcl2json
# または
go install github.com/tmccombs/hcl2json@latest
```

### jd not found

```bash
brew install jd
# または
go install github.com/josephbismark/jd@latest
```

### テスト失敗時のデバッグ

```bash
# 1. JSON 変換が成功しているか確認
cd test/foreach-basics/env1
hcl2json main.tf | head -20

# 2. jd の差分出力を確認
hcl2json ../env1/main.tf > /tmp/e1.json
hcl2json ../env2/main.tf > /tmp/e2.json
jd -f patch /tmp/e1.json /tmp/e2.json | head -20

# 3. tf-diff-reporter の実行
cd ..
../../tf-diff-reporter compare env1 env2

# 4. レポートを確認
cat .tfdr/reports/comparison-report.md
```

## CI/CD 統合

GitHub Actions での使用例：

```yaml
name: Terraform Configuration Tests

on: [push, pull_request]

jobs:
  test-advanced-syntax:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Install tools
        run: |
          go install github.com/tmccombs/hcl2json@latest
          go install github.com/josephbismark/jd@latest

      - name: Build tf-diff-reporter
        run: go build -o tf-diff-reporter ./cmd/cli

      - name: Test for_each
        run: |
          cd test/foreach-basics
          ../../tf-diff-reporter compare env1 env2
          test $? -eq 0

      - name: Test locals
        run: |
          ../../tf-diff-reporter compare env1 env2
          test $? -eq 0

      - name: Test count
        run: |
          cd test/count-iteration
          ../../tf-diff-reporter compare env1 env2
          test $? -eq 0

      - name: Test dynamic blocks
        run: |
          cd test/dynamic-blocks
          ../../tf-diff-reporter compare env1 env2
          test $? -eq 0

      - name: Test mixed variables
        run: |
          cd test/mixed-variables
          ../../tf-diff-reporter compare env1 env2
          test $? -eq 0
```

## テスト管理

### テスト追加時のチェックリスト

新しいテストケースを追加する際：

- [ ] `env1/` と `env2/` ディレクトリを作成
- [ ] `main.tf`（と必要に応じて `variables.tf`）を実装
- [ ] `.tfdr/ignore.json` で差分ルールを定義
- [ ] `README.md` で目的とシナリオを記述
- [ ] `../../tf-diff-reporter compare env1 env2` で `exit code 0` を確認
- [ ] `.tfdr/reports/comparison-report.md` でレポートを確認

### テストの更新

既存テストを変更した場合：

1. `env1/main.tf` と `env2/main.tf` を編集
2. `../../tf-diff-reporter compare env1 env2` で差分を確認
3. 未認識差分が出た場合、`ignore.json` に新しいルールを追加
4. 再度実行して `exit code 0` を確認

## 参考資料

- [Terraform for_each Documentation](https://www.terraform.io/language/meta-arguments/for_each)
- [Terraform locals](https://www.terraform.io/language/values/locals)
- [Terraform count](https://www.terraform.io/language/meta-arguments/count)
- [Terraform dynamic](https://www.terraform.io/language/expressions/dynamic)
- [Terraform variables](https://www.terraform.io/language/values/variables)
- [RFC 6902 - JSON Patch](https://tools.ietf.org/html/rfc6902)
- [jd - JSON Diff Tool](https://github.com/josephbismark/jd)
- [hcl2json](https://github.com/tmccombs/hcl2json)

## サマリー

| テストケース | 構文特性 | 複雑性 | 差分数 |
|------------|--------|-------|--------|
| foreach-basics | 反復処理 | ⭐⭐ | 21 |
| locals-management | 値管理、波及効果 | ⭐⭐ | 19 |
| count-iteration | 条件分岐、反復 | ⭐⭐⭐ | 14 |
| dynamic-blocks | ネストされたブロック | ⭐⭐⭐ | 13 |
| mixed-variables | 統合パターン | ⭐⭐⭐⭐ | 22 |

合計: **5つのテストケース、89個の差分ルール**

これにより、tf-diff-reporter が **Terraform の主要な動的構文をすべてカバーできる** ことを検証できます。
