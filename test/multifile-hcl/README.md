# Test Case: multifile-hcl - 複数HCLファイルの統合

このテストケースは、**複数のHCLファイルが存在する場合** に tf-diff-reporter がすべてのファイルを正しく統合・比較できるかを検証します。

## テストの目的

- 複数の `.tf` ファイルの統合処理（`hcl2json` による）
- ファイル分割されたリソース定義の正確な比較
- モジュール分割パターンの差分検出

## シナリオ

実際のプロジェクト構成では、リソースを機能別にファイルを分割することが多いです。このテストでは以下のパターンを検証します。

### ディレクトリ構成

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

### 各ファイルの役割

**main.tf**
- Terraform ブロック（バージョン要件）
- Provider 定義
- ネットワークリソース（共通基盤）

**compute.tf**
- GCE インスタンス定義
- コンピュート関連のラベル

**database.tf**
- Cloud SQL インスタンス
- ファイアウォール ルール

## env1 vs env2 の差分

| ファイル | リソース | env1 | env2 | 変更内容 |
|---------|---------|------|------|---------|
| compute.tf | web | e2-medium, 20GB | e2-standard-2, 50GB | スケールアップ |
| compute.tf | app | - | 新規作成 | app サーバー追加 |
| database.tf | 許可ポート | 80 のみ | 80, 443 | HTTPS 追加 |
| database.tf | ターゲットタグ | env1, web | env2, web, app | app タグ追加 |
| database.tf | allow_app ルール | - | 新規作成 | app 向けルール追加 |
| 全体 | tier ラベル | なし | production | tier ラベル追加 |

## テストの重要性

### 複数ファイル統合の検証

`hcl2json` コマンドは、ディレクトリ内の複数 `.tf` ファイルをすべて読み込んで統合します：

```bash
# env1 の全ファイルを JSON に統合
hcl2json env1/main.tf env1/compute.tf env1/database.tf

# または
cd env1 && hcl2json *.tf
```

このテストケースは以下を確認します：

1. **ファイル統合の完全性**
   - 複数ファイルが正しく統合されるか
   - リソース間の参照（例：`google_compute_network.main.name`）が保持されるか

2. **リソース識別の正確性**
   - ファイル分割されたリソースが正しく識別されるか
   - RFC 6902 パスが正確に生成されるか

3. **実世界シナリオのカバー**
   - 実際のプロジェクト構成を反映
   - `terraform validate` では問題ないが、環境差分検出に失敗するパターンを検証

## 実行方法

```bash
cd test/multifile-hcl
../../tf-diff-reporter compare env1 env2
```

**期待される結果**: `exit code 0` (すべての差分が認識済み)

## レポート確認

```bash
cat .tfdr/reports/comparison-report.md
```

### レポートの特徴

複数ファイル構成では、レポートに以下のパターンが出現します：

```markdown
| 属性パス | env1 → env2 |
| :--- | :--- |
| /resource/google_compute_instance/web/0/machine_type | ~ e2-medium → e2-standard-2 |
| /resource/google_compute_instance/app | + [{ ... }] |
| /resource/google_compute_firewall/allow_http/0/allow/0/ports/1 | + 443 |
| /resource/google_compute_firewall/allow_app | + [{ ... }] |
```

各リソースのパスは、どのファイルに定義されているかに関わらず、同じ形式で表示されます。

## ignore.json の管理

24個のルールで複数ファイル構成の差分を管理：

```json
{
  "path": "/resource/google_compute_instance/app",
  "comment": "New app server instance created in env2 only"
},
{
  "path": "/resource/google_compute_firewall/allow_http/0/allow/0/ports/1",
  "comment": "HTTPS port added to firewall rule in env2"
}
```

### 注目すべき点

- **ファイル名は不要**: RFC 6902 パスにはファイル名が含まれない
- **リソース識別は一意**: リソース名が一意であれば、ファイル分割の影響を受けない
- **複数リソースの波及**: 1つのファイル変更が複数ファイルのリソースに影響する場合も検出される

## デバッグ：ファイル統合の確認

```bash
# env1 の統合 JSON を確認
cd env1
hcl2json main.tf compute.tf database.tf | jq . | head -50

# または（環境によって異なる）
hcl2json *.tf | jq .

# env2 との差分を確認
hcl2json ../env1/*.tf > /tmp/env1.json
hcl2json ../env2/*.tf > /tmp/env2.json
jd -f patch /tmp/env1.json /tmp/env2.json
```

## テストがカバーするケース

- ✅ 複数 `.tf` ファイルの統合
- ✅ ファイル分割されたリソース定義の差分検出
- ✅ クロスファイルの参照（例：compute.tf の GCE が main.tf の VPC を参照）
- ✅ 新規リソースのファイル追加
- ✅ 既存リソースのスケーリング（複数ファイル間）

## 実践的なシナリオ

### シナリオ 1: モジュール構造への移行

```
# 前: main.tf に全リソース
main.tf (800行)

# 後: ファイル分割
main.tf (provider)
network.tf (VPC)
compute.tf (GCE)
database.tf (Cloud SQL)
```

このテストは、ファイル分割による構造変更後も diff が正確に検出されることを保証します。

### シナリオ 2: チーム開発での並列編集

複数チームメンバーが異なるファイル（compute.tf と database.tf）を並列編集した場合：

```
env2/compute.tf: GCE インスタンス追加、マシンタイプ変更
env2/database.tf: DB ティア変更、ファイアウォール拡張
```

すべての変更が統合され、正確に diff が検出されます。

## 今後の拡張案

- [ ] Terraform モジュール使用時のカバレッジ
- [ ] `terraform` ブロックの `required_providers` バージョン変更
- [ ] ファイル削除後の差分検出
- [ ] 大規模プロジェクト（100+ ファイル）での性能確認
