# Test Case: mixed-variables - variables + locals + for_each の統合

このテストケースは、**variables、locals、for_each を組み合わせた複雑な Terraform 構成** をテストします。

## テストの目的

- `variables` と `locals` の相互参照による差分検出
- `for_each` と `locals` の組み合わせによる動的リソース生成
- 変数のデフォルト値変更が複数リソースに波及する差分追跡
- `variable` ブロック自体の変更の検出

## シナリオ

### env1 - 開発/テスト構成

**variables.tf:**
```hcl
variable "environment"   = "env1"
variable "enable_monitoring" = false
variable "instance_config" = {
  machine_type = "e2-medium"
  disk_size    = 20
}
variable "tags" = {
  Environment = "env1"
  Team        = "platform"
  CostCenter  = "CC-1000"
}
variable "services" = [
  { name = "web", port = 80, replicas = 1 },
  { name = "api", port = 8080, replicas = 1 },
]
```

### env2 - 本番構成

**variables.tf:**
```hcl
variable "environment"   = "env2"
variable "enable_monitoring" = true                    # ← 有効化
variable "instance_config" = {
  machine_type = "e2-standard-2"                       # ← スケールアップ
  disk_size    = 50                                     # ← 拡張
}
variable "tags" = {
  Environment = "env2"                                  # ← 変更
  Team        = "platform"
  CostCenter  = "CC-2000"                              # ← コスト変更
  Tier        = "production"                            # ← 新規追加
}
variable "services" = [
  { name = "web", port = 80, replicas = 2 },          # ← レプリカ増加
  { name = "api", port = 8080, replicas = 3 },        # ← レプリカ増加
  { name = "worker", port = 9000, replicas = 2 },     # ← 新規サービス
]
```

## 構成の複雑さ

このテストは以下のレイヤーを含む：

```
Terraform Configuration
├── Variable Definitions (variables.tf)
│   ├── Primitives: environment, enable_monitoring
│   ├── Objects: instance_config
│   └── Maps/Lists: tags, services
│
├── Locals (main.tf)
│   ├── Computed values: env_prefix = "${var.environment}-"
│   ├── References: labels = merge(var.tags, {...})
│   ├── Conditionals: monitoring_resources = var.enable_monitoring ? {...} : {}
│   └── Loop constructs: env_prefix, common_labels
│
└── Resources
    ├── google_compute_network (labels: local.common_labels)
    ├── google_compute_instance (for_each: var.services, machine_type: var.instance_config.machine_type)
    ├── google_monitoring_alert_policy (for_each: local.monitoring_resources)
    └── google_storage_bucket (name: "${local.env_prefix}data-bucket")
```

## 差分の特徴

| レイヤー | 変更内容 | リソースへの波及 | 個数 |
|---------|--------|-----------|-----|
| **Variable ブロック** |
| environment | env1 → env2 | すべてのリソース名、ラベル | 複数 |
| enable_monitoring | false → true | monitoring_alert_policy 作成 | 1+ |
| instance_config | e2-medium/20GB → e2-standard-2/50GB | GCE インスタンス | 3+ |
| tags | 値変更、tier 追加 | すべてのリソース | 複数 |
| services | web, api, worker のレプリカ数変更 + worker 追加 | GCE インスタンス for_each | 6+ |
| **Locals の派生差分** |
| env_prefix | env1- → env2- | VPC、Bucket 名 | 複数 |
| common_labels | tag 更新が反映 | すべてのリソース | 複数 |
| monitoring_resources | {} → { alert-policy: {...}, disk-alert: {...} } | 新規 alert policy | 2+ |

## 実行方法

```bash
cd test/mixed-variables
../../tf-diff-reporter compare env1 env2
```

**期待される結果**: `exit code 0` (すべての差分が認識済み)

## テストがカバーするケース

- ✅ **Variable ブロック自体の変更**
  - primitive (string, bool)
  - object (nested 構造)
  - map (key-value)
  - list (複数要素)

- ✅ **Variables と Locals の相互参照**
  - `env_prefix = "${var.environment}-"`
  - `labels = merge(var.tags, {...})`
  - 条件式: `var.enable_monitoring ? {...} : {}`

- ✅ **For_each と Variable の統合**
  - `for_each = { for svc in var.services : svc.name => svc }`
  - リスト要素の追加/削除
  - リスト要素の属性変更

- ✅ **複数リソースへの波及**
  - Variable 1個の変更 → 複数リソースの複数属性に反映

## ignore.json で管理される差分

22個のルールで変数、ローカル、リソースの連鎖的な差分を管理：
- Variable ブロック自体の変更（6個）
- Locals の派生差分（4個）
- リソース属性の変更（12個）

## 注目すべき点

1. **Variable ブロック内の変更**: `default` フィールドの変更が検出される
2. **複数段階の参照**: variables → locals → resources という依存関係チェーン
3. **For_each の動的化**: `for_each = { for svc in var.services }` により、サービス追加時にリソースが自動追加
4. **条件付きリソース**: `enable_monitoring` による monitoring_alert_policy の作成/破棄
5. **マージ関数**: `merge(var.tags, {...})` で複数ソースをまとめた場合の diff 表示

## CI/CD での活用例

このテストは以下のシナリオで有用：

```bash
# 本番環境設定
cd test/mixed-variables
../../tf-diff-reporter compare env1 env2

# 新しいサービスを services に追加した場合の検証
# → for_each により自動的に GCE インスタンスが追加される
# → ignore.json に新しいルールを追加する
```

**期待される変更:**
1. Service を `services` に追加
2. tf-diff-reporter を実行
3. レポートに新規サービスの GCE インスタンスが「未認識差分」として表示
4. ignore.json に新しいルールを追加
5. 再度実行して exit code 0 を確認
