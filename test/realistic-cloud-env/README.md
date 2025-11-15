# Realistic Cloud Environment Test Suite

本テストスイートは、Google Cloud を使用した実践的な3環境構成（dev/stg/prd）のシミュレーションです。

**このテストは tf-diff-reporter の本来の用途を実証します：**
- 複数環境の Terraform 構成を比較
- 意図した環境差分と意図しない差分を自動区別
- CI/CD パイプラインで自動チェック

## ディレクトリ構成

```
realistic-cloud-env/
├── dev/                          # 開発環境
│   ├── main.tf                   # リソース定義 + dev-only リソース
│   └── test.sh                   # テストスクリプト
│
├── stg/                          # ステージング環境
│   └── main.tf                   # リソース定義
│
├── prd/                          # 本番環境
│   └── main.tf                   # リソース定義
│
├── .tfdr/
│   ├── ignore.json               # 意図した差分の定義（57ルール）
│   └── reports/                  # 生成レポート
│
├── test.sh                       # 統合テストスクリプト
└── README.md                     # このファイル
```

### 各 main.tf の内容

シンプル化された実装：各環境は単一の `main.tf` ファイルで管理され、プロバイダー設定とリソース定義が一体化しています。

**Dev環境の特徴：** 開発用の追加リソースを含む
- 開発用ストレージバケット（デバッグログ）
- テスト用VM（統合テスト）
- 開発用アーティファクトレジストリ
- テスト用サービスアカウント
- テスト用カスタムメトリクス
- デバッグログ用シンク

## 各環境の違い（段階的スケールアップ）

### VPC ネットワーク
| 項目 | dev | stg | prd |
|------|-----|-----|-----|
| VPC名 | myapp-vpc-dev | myapp-vpc-stg | myapp-vpc-prd |
| ルーティングモード | REGIONAL | REGIONAL | REGIONAL |

### Cloud SQL（データベース）
| 項目 | dev | stg | prd |
|------|-----|-----|-----|
| インスタンス名 | myapp-db-instance-dev | myapp-db-instance-stg | myapp-db-instance-prd |
| ティア | db-f1-micro | db-custom-2-8192 | db-custom-4-16384 |
| 可用性タイプ | REGIONAL | REGIONAL | REGIONAL |
| ディスクサイズ | 100GB | 100GB | 100GB |

### Redis（キャッシュ）
| 項目 | dev | stg | prd |
|------|-----|-----|-----|
| インスタンス名 | myapp-redis-dev | myapp-redis-stg | myapp-redis-prd |
| メモリサイズ | 1GB | 2GB | 5GB |
| ティア | basic | standard | standard |
| Redis バージョン | 7.0 | 7.0 | 7.0 |

### GKE（Kubernetes）
| 項目 | dev | stg | prd |
|------|-----|-----|-----|
| クラスタ名 | myapp-gke-cluster-dev | myapp-gke-cluster-stg | myapp-gke-cluster-prd |
| 初期ノード数 | 1 | 2 | 3 |
| マシンタイプ | e2-medium | e2-standard-2 | n1-standard-2 |

### Cloud Run（API）
| 項目 | dev | stg | prd |
|------|-----|-----|-----|
| サービス名 | myapp-api-dev | myapp-api-stg | myapp-api-prd |
| イメージタグ | dev-latest | stg-release | release |
| CPU リソース | 1 | 1 | 2 |
| メモリ | 512Mi | 512Mi | 1Gi |
| 最小スケール | 1 | 2 | 5 |
| 最大スケール | 10 | 20 | 50 |

### Cloud Storage
| 項目 | dev | stg | prd |
|------|-----|-----|-----|
| アプリデータバケット | myapp-data-dev-prod | myapp-data-stg-prod | myapp-data-prd-prod |
| ストレージクラス | STANDARD | STANDARD | NEARLINE |

## テストの実行

### 前提条件
- `tf-diff-reporter` がビルド済み
- `hcl2json` と `jd` コマンドがインストール済み
- GCP認証情報が設定済み（本来のテスト時は不要）

### 推奨：テストスクリプトを使用
```bash
cd test/realistic-cloud-env
./test.sh
```

このスクリプトは以下の3つのテストを自動実行します：
1. **環境自動検出テスト** - dev基準で stg, prd と比較
2. **dev vs stg 比較** - 明示的環境指定
3. **stg vs prd 比較** - 段階的スケールアップの検証

### 手動テスト - 自動検出で実行
```bash
cd test/realistic-cloud-env
../../tf-diff-reporter compare
```

このコマンドは dev を基準とし、stg と prd と比較します。

**期待される結果：** `exit code 0`（すべての差分が認識済み）

### 手動テスト - 本番環境を基準に
```bash
cd test/realistic-cloud-env
../../tf-diff-reporter compare prd dev stg
```

このコマンドは prd を基準とし、dev のみにある開発用リソースを含めて比較します。

**期待される結果：** `exit code 0`（dev-only リソースが ignore.json で認識）

### 手動テスト - 特定の環境対比
```bash
# dev vs stg
../../tf-diff-reporter compare dev stg

# stg vs prd
../../tf-diff-reporter compare stg prd
```

## テストケースの構成

このテストスイートは以下のシナリオをカバーしています：

### 1. 環境間の段階的リソーススケーリング
- **GKE ノード**: 1 (dev) → 2 (stg) → 3 (prd)
- **マシンタイプ**: e2-medium → e2-standard-2 → n1-standard-2
- **Cloud SQL**: db-f1-micro → db-custom-2-8192 → db-custom-4-16384
- **Redis キャパシティ**: 1GB (basic) → 2GB (standard) → 5GB (standard)
- **Cloud Run リソース**: 1CPU/512Mi → 1CPU/512Mi → 2CPU/1Gi
- **Cloud Run スケーリング**: min=1,max=10 → min=2,max=20 → min=5,max=50

### 2. 環境別リソース名のバリエーション
各リソースは環境によって異なる名前を持ちます（例：`myapp-api-dev` vs `myapp-api-prd`）

### 3. 開発環境のみのリソース（Dev-only）
dev には以下の開発用リソースが存在し、stg/prd には存在しません：

- **google_storage_bucket/debug_logs** - デバッグログ用バケット（7日後に自動削除）
- **google_compute_instance/dev_test_vm** - 統合テスト用VM
- **google_artifact_registry_repository/dev_repo** - 開発用ビルドレジストリ
- **google_service_account/dev_local** - 開発用サービスアカウント
- **google_monitoring_metric_descriptor/dev_custom_metric** - テスト用カスタムメトリクス
- **google_logging_project_sink/dev_debug_sink** - デバッグログ用シンク

### 4. 認識済み差分と未認識差分
- **認識済み差分（57個）**: ignore.json で定義された意図した差分
  - リソース名の環境別サフィックス
  - スケールアップの段階的増加
  - コンテナイメージタグの変更
  - Dev-only リソース

- **未認識差分（0個）**: テスト成功時は未認識差分がゼロになります
  - 予期しないリソース削除があれば検出 → `exit code 1`
  - 意図しないスペック変更があれば検出 → `exit code 1`
  - セキュリティ設定の予期しない変更があれば検出 → `exit code 1`

## ignore.json ルール定義

このテストスイートは **57個のignoreルール** を定義しています：

### ルール形式
```json
{
  "path": "/resource/google_container_cluster/primary/0/initial_node_count",
  "comment": "GKE node count increases: 1 (dev) -> 2 (stg) -> 3 (prd)"
}
```

- `path`: リソース差分のJSONパス（jd の RFC 6902 形式）
  - `/0/` はリソース配列のインデックスを表します
  - 例：`/resource/google_redis_instance/cache/0/memory_size_gb`
- `comment`: 差分が意図されている理由を説明

### ルール分類

#### 環境ラベル差分（20+個）
すべてのリソースの `environment` ラベルが環境によって異なります

#### 環境別リソース名（15+個）
```
/resource/google_compute_network/main/0/name
/resource/google_container_cluster/primary/0/name
/resource/google_sql_database_instance/main/0/name
# etc.
```

#### スケールアップの段階的増加（10+個）
```
GKEノード数: 1 -> 2 -> 3
Database tier: micro -> custom-2 -> custom-4
Redis: 1GB -> 2GB -> 5GB
```

#### コンテナ設定の段階的強化（5+個）
```
Cloud Run CPU: 1 -> 1 -> 2
Cloud Run Memory: 512Mi -> 512Mi -> 1Gi
Cloud Run Scaling: min=1,max=10 -> min=2,max=20 -> min=5,max=50
```

#### Dev-only リソース（7個）
```
/resource/google_storage_bucket/debug_logs
/resource/google_compute_instance
/resource/google_artifact_registry_repository
/resource/google_service_account
/resource/google_monitoring_metric_descriptor
/resource/google_logging_project_sink
```

## レポート出力

比較実行後、以下のファイルが生成されます：

```
.tfdr/reports/comparison-report.md
```

### レポートの構成

```markdown
# Terraform 環境間差分レポート (基準: prd)

## 📊 サマリー
| | |
| --- | --- |
| 基準環境 | `prd` |
| 未認識差分 (−) | 0 |
| 認識済み差分 (✓) | 57 |

## 認識済み差分 (ignore.json)
| 属性パス | prd → dev | prd → stg | 理由 |
| ... | ... | ... | ... |
```

### レポートの見方

**サマリーセクション**
- `未認識差分 (−)`: 0 = テスト成功 ✅ | > 0 = テスト失敗 ❌
- `認識済み差分 (✓)`: ignore.json で認可された差分の数

**認識済み差分テーブル**
- `属性パス`: リソース属性のJSONパス
- `prd → dev / prd → stg`: 比較対象環境との変更内容
  - `~` = 値が変更（replace）
  - `+` = リソースが新規追加
  - `−` = 当該環境では該当なし
- `理由`: ignore.json の comment フィールド

## トラブルシューティング

### 1. hcl2json コマンドが見つからない

```bash
# インストール（macOS の場合）
brew install hcl2json
```

### 2. jd コマンドが見つからない

```bash
# インストール（macOS の場合）
brew install jd
```

### 3. テスト実行時のエラー

```bash
# デバッグモード：JSON 変換を確認
cd dev
hcl2json main.tf

# jd で差分を確認
hcl2json dev/main.tf > /tmp/dev.json
hcl2json stg/main.tf > /tmp/stg.json
jd -f patch /tmp/dev.json /tmp/stg.json
```

## CI/CD での使用例

### GitHub Actions での統合
```yaml
name: Terraform Diff Check

on: [pull_request]

jobs:
  tf-diff:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Check Terraform Diffs
        run: |
          cd test/realistic-cloud-env
          ../../tf-diff-reporter compare prd dev stg
          if [ $? -ne 0 ]; then
            echo "Unexpected differences detected!"
            exit 1
          fi
```

### テスト結果の解釈

**`exit code 0`（成功）**
- すべての差分が意図されたもの
- 開発環境のみのリソースが正しく認識
- デプロイパイプライン継続可能

**`exit code 1`（失敗）**
- 予期しない差分が検出
- ignore.json に新しいルールを追加するか、HCLを修正
- デプロイパイプライン停止

## 実践例：新しい差分への対応

### シナリオ：新しいリソースをdev環境に追加

1. dev の main.tf に新しい dev-only リソースを追加
2. `tf-diff-reporter compare prd dev stg` を実行
3. レポートに「未認識差分」として表示される
4. ignore.json に新しいルールを追加
5. 再度実行して `exit code 0` を確認

### シナリオ：本番環境のスペック変更

1. prd の main.tf でリソーススペックを変更
2. `tf-diff-reporter compare` を実行
3. レポートの「認識済み差分」に表示（既存ルールがあれば）
4. ルールがなければ ignore.json に追加
5. レポートで変更内容を確認

## 今後の拡張案

### 1. さらに複雑なシナリオ
- マルチリージョン構成（asia-northeast1, us-central1, europe-west1）
- ディザスタリカバリー設定の差分
- ネットワークピアリング設定
- ハイブリッド環境（オンプレ + クラウド）

### 2. より詳細なセキュリティテスト
- RBAC（Role-Based Access Control）の差分
- ネットワークポリシーの詳細な検証
- IAM バインディングと権限の段階的な制限
- VPC Service Controls の設定差分

### 3. コスト最適化シナリオ
- リソース削除テスト（dev 環境の簡素化）
- インスタンスタイプのダウングレード検証
- ストレージクラス変更の段階的適用
- 予約インスタンスの利用パターン

## テストスイートのメトリクス

このテストスイートが検証する内容：

- **比較環境数**: 3 (dev, stg, prd)
- **コア リソースタイプ**: 8 (VPC, GKE, Cloud SQL, Redis, Cloud Run, Firestore, Storage, IAM)
- **リソースインスタンス数**: 15+（標準環境）+ 6（dev-only）
- **定義されたルール**: 57（ignore.json）
- **テストシナリオ**: 3（自動検出、dev vs stg、stg vs prd）+ 1（prd基準）

## テスト実行時間

- テストスクリプト（./test.sh）: 約 5-10 秒
- 各比較処理: 約 1-2 秒

## クイックスタート

### 初回実行
```bash
cd test/realistic-cloud-env
./test.sh
```

すべてのテストが成功（`exit code 0`）すれば、セットアップ完了です。

### レポート確認
```bash
cat .tfdr/reports/comparison-report.md
```

### 特定比較の実行
```bash
# Dev環境を基準に
../../tf-diff-reporter compare dev stg prd

# 本番環境を基準に（dev-only リソースを検証）
../../tf-diff-reporter compare prd dev stg
```

## トラブルシューティングガイド

### Q: `exit code 1` が返される

A: レポートの「未認識差分」セクションを確認し、以下を検討してください：

1. **意図された差分の場合**
   - ignore.json に新しいルールを追加
   - パスは `/resource/resource_type/resource_name/0/attribute` 形式

2. **意図しない差分の場合**
   - HCL ファイルに誤りがないか確認
   - 環境別設定が正しく適用されているか確認

### Q: `jd` がインストール時にエラーになる

A: Go言語がインストールされている場合、以下で直接インストール可能：
```bash
go install github.com/josephbismark/jd@latest
```

### Q: レポートが生成されない

A: `.tfdr/reports/` ディレクトリが存在するか確認：
```bash
mkdir -p .tfdr/reports
```

## 参考リソース

- [Google Cloud Provider - Terraform Registry](https://registry.terraform.io/providers/hashicorp/google/latest)
- [tf-diff-reporter - GitHub](https://github.com/anthropics/tf-diff-reporter)
- [RFC 6902 - JSON Patch](https://tools.ietf.org/html/rfc6902)
- [jd - JSON Diff Tool](https://github.com/josephbismark/jd)
- [hcl2json - HCL to JSON Converter](https://github.com/tmccombs/hcl2json)
