# Test Case: count - 条件分岐と反復処理

このテストケースは、`count` メタ引数を使った **条件付きリソース作成と反復処理** をテストします。

## テストの目的

- `count` による条件分岐（0個 または N個のリソース）の差分検出
- リソース数の変更に伴う配列インデックスの変化
- 条件式の真偽値変更による、リソース作成/破棄の差分検出

## シナリオ

### env1 - 基本構成
```hcl
locals {
  enable_backup  = false    # ← バックアップ無効
  enable_https   = false    # ← HTTPS 無効
  replica_count  = 1        # ← レプリカ 1個
}
```

**作成されるリソース:**
- Primary DB (1個)
- Replica (1個) ← `count = local.replica_count` = 1
- Backup DB (0個) ← `count = local.enable_backup ? 1 : 0` = 0
- SSL Cert (0個) ← `count = local.enable_https ? 1 : 0` = 0
- Backup Bucket (0個) ← `count = local.enable_backup ? 1 : 0` = 0

### env2 - スケールアップ構成
```hcl
locals {
  enable_backup  = true     # ← バックアップ有効
  enable_https   = true     # ← HTTPS 有効
  replica_count  = 2        # ← レプリカ 2個
}
```

**作成されるリソース:**
- Primary DB (1個)
- Replica (2個) ← `count = local.replica_count` = 2
- Backup DB (1個) ← `count = local.enable_backup ? 1 : 0` = 1
- SSL Cert (1個) ← `count = local.enable_https ? 1 : 0` = 1
- Backup Bucket (1個) ← `count = local.enable_backup ? 1 : 0` = 1

## 差分の特徴

| リソース | env1 | env2 | 差分パターン |
|---------|------|------|----------|
| Primary DB | 1個 | 1個 | 属性変更のみ |
| Replica | 1個 | 2個 | count 値 1→2、インデックス追加 |
| Backup DB | 0個 → **なし** | 1個 → **新規作成** | 条件式変更 (false→true) |
| SSL Cert | 0個 → **なし** | 1個 → **新規作成** | 条件式変更 (false→true) |
| Backup Bucket | 0個 → **なし** | 1個 → **新規作成** | 条件式変更 (false→true) |

## 実行方法

```bash
cd test/count-iteration
../../tf-diff-reporter compare env1 env2
```

**期待される結果**: `exit code 0` (すべての差分が認識済み)

## テストがカバーするケース

- ✅ `count` による条件分岐（0個 と 1個）
- ✅ `count` による反復処理（1個 → 2個）
- ✅ 条件式（三項演算子）による動的 count 値
- ✅ リソース数変更に伴う配列インデックスの追加/削除
- ✅ 無条件リソースと条件付きリソースの混在

## ignore.json で管理される差分

14個のルールで条件分岐と反復の差分を管理：
- ローカル変数の条件値変更（4個）
  - `enable_backup`: false → true
  - `enable_https`: false → true
  - `replica_count`: 1 → 2
- Primary DB の属性変更（1個）
- Replica インスタンスの新規作成とスケーリング（3個）
- Backup DB、SSL Cert、Backup Bucket の新規作成（3個）
- ストレージクラス変更（1個）
- ラベル環境差異（2個）

## 注目すべき点

1. **条件式による 0個作成**: env1 では Backup DB が「存在しない」のではなく「count=0」で排除される
2. **配列インデックスの追加**: Replica が 1個 → 2個 になると、index 1 が新規追加される
3. **属性変更 vs リソース作成**: Primary DB は値が変わるが、Backup DB は新規作成される（diff パターンが異なる）
4. **boolean ローカル変数の効果**: `enable_backup` 一つの変更により、複数リソース（Backup DB、SSL Cert、Bucket）が新規作成される

## CI/CD での活用例

このテストは以下のシナリオで有用：
- 開発環境のみバックアップ無効化
- 本番環境のみ HTTPS 有効化
- 環境によってレプリカ数を動的に変更
