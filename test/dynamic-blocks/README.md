# Test Case: dynamic - 動的ブロック生成

このテストケースは、`dynamic` ブロックを使った **ネストされたブロックの動的生成** をテストします。

## テストの目的

- `dynamic` ブロックで生成されたネストされた設定の差分検出
- リスト型 `locals` の変更による `dynamic` ブロックの拡張/縮小
- `for_each` 内での `for_each` など複雑な反復構造の差分追跡

## シナリオ

### env1 - 基本的なセキュリティルール

```hcl
locals {
  ingress_rules = [
    { protocol = "tcp", ports = ["22"], sources = ["0.0.0.0/0"] },
    { protocol = "tcp", ports = ["80"], sources = ["0.0.0.0/0"] },
  ]
  egress_rules = [
    { protocol = "tcp", ports = ["443"] },
  ]
  env_vars = {
    LOG_LEVEL = "info"
    DEBUG     = "false"
  }
}
```

### env2 - セキュリティ強化版

```hcl
locals {
  ingress_rules = [
    { protocol = "tcp", ports = ["22"], sources = ["10.0.0.0/8"] },     # ← SSH を内部のみに
    { protocol = "tcp", ports = ["80"], sources = ["0.0.0.0/0"] },
    { protocol = "tcp", ports = ["443"], sources = ["0.0.0.0/0"] },    # ← HTTPS 追加
  ]
  egress_rules = [
    { protocol = "tcp", ports = ["443"] },
    { protocol = "tcp", ports = ["3306"] },                             # ← MySQL 追加
  ]
  env_vars = {
    LOG_LEVEL   = "debug"
    DEBUG       = "true"
    API_VERSION = "v2"                                                   # ← バージョン追加
  }
}
```

## 差分の特徴

| 要素 | env1 | env2 | 差分 |
|-----|------|------|-----|
| **Ingress Rules** |
| SSH ルール | ソース: 0.0.0.0/0 | ソース: 10.0.0.0/8 | 送信元が限定 |
| HTTPS ルール | なし | あり | 新規追加 |
| **Egress Rules** |
| HTTPS | あり | あり | 変更なし |
| MySQL | なし | あり | 新規追加 |
| **環境変数** |
| LOG_LEVEL | info | debug | 変更 |
| DEBUG | false | true | 変更 |
| API_VERSION | なし | v2 | 新規追加 |
| **リソース属性** |
| Cloud Run イメージ | v1 | v2 | コンテナイメージ変更 |
| リソース制限 | 1CPU/512Mi | 2CPU/1Gi | スケールアップ |

## 実行方法

```bash
cd test/dynamic-blocks
../../tf-diff-reporter compare env1 env2
```

**期待される結果**: `exit code 0` (すべての差分が認識済み)

## テストがカバーするケース

- ✅ `dynamic` ブロック内でのリスト要素の追加/削除
- ✅ リスト要素の属性変更（ソース CIDR の変更など）
- ✅ マップ型 `locals` の要素追加/削除（環境変数）
- ✅ `dynamic` ブロック生成による複数ネストレベルの変更
- ✅ ファイアウォール、Cloud Run など複数リソース種での `dynamic` 使用

## ignore.json で管理される差分

13個のルールで `dynamic` ブロックの差分を管理：
- ローカル変数リストの変更（3個）
  - `ingress_rules` の拡張と内容変更
  - `egress_rules` の拡張
  - `env_vars` の拡張
- Firewall ルールの変更（4個）
  - ingress allow ルール
  - ingress source_ranges
  - egress allow ルール
- Cloud Run サービスの変更（4個）
  - 環境変数の拡張
  - コンテナイメージのバージョン変更
  - リソース制限（CPU/メモリ）の変更
- リソース名の環境別差異（2個）

## 注目すべき点

1. **ネストされた dynamic**: `dynamic "allow"` と `dynamic "source_ranges"` が別々に生成される
2. **リスト順序の重要性**: Terraform の `dynamic` では順序が保証されるため、配列インデックスが固定的
3. **マップの動的展開**: 環境変数などはマップで管理し、`for_each` で展開される
4. **複数 dynamic の組合せ**: 同一リソース内で複数の `dynamic` ブロックが存在する場合、各々の差分が独立して検出される

## ネストレベルの複雑さ

```
Firewall リソース
├─ dynamic "allow"
│  └─ for_each: ingress_rules
│     └─ protocol, ports（リスト）
├─ dynamic "source_ranges"
│  └─ for_each: ingress_rules
│     └─ sources[0]（配列要素）

Cloud Run サービス
├─ template > spec > containers[0]
│  └─ dynamic "env"
│     └─ for_each: env_vars（マップ）
│        └─ name, value
```

このように複数レベルでネストされた構造を、tf-diff-reporter が正確に差分抽出できることを検証します。
