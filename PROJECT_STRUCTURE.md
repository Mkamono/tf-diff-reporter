# tf-diff-reporter プロジェクト構成

## ディレクトリ構造

```
tf-diff-reporter/
├── cmd/
│   └── cli/
│       └── main.go                    # CLIエントリーポイント
├── internal/
│   ├── model/
│   │   └── types.go                   # 共通データ構造 (Resource, Difference, ComparisonResult等)
│   ├── terraform/
│   │   ├── executor.go                # terraform init/plan/showの実行
│   │   └── parser.go                  # terraform show -jsonの出力をパース
│   ├── diff/
│   │   ├── ignore.go                  # ignore.jsonの読み込み・管理
│   │   └── comparator.go              # 環境間の比較ロジック
│   └── report/
│       ├── formatter.go               # 出力形式の基盤（インターフェース）
│       ├── markdown.go                # Markdownフォーマッター
│       ├── csv.go                     # CSVフォーマッター
│       └── json.go                    # JSONフォーマッター
├── go.mod                             # Go module定義
├── go.sum                             # 依存関係チェックサム
├── tf-diff-reporter                   # ビルド済みバイナリ
├── ignore.json.example                # ignore.jsonの例
└── README.md                          # プロジェクト説明
```

## モジュール設計

### `internal/model` - データモデル
共通的なデータ構造を定義:
- `Resource`: Terraformリソース
- `Difference`: 環境間の差分
- `ComparisonResult`: 比較結果全体
- `IgnoreRule`: ignore.jsonの一つのルール
- `TerraformPlan`: terraform showの出力構造

### `internal/terraform` - Terraform操作
- **Executor**: terraform init/plan/showを実行
- **Parser**: terraform show -jsonの出力をパースし、リソース抽出

### `internal/diff` - 差分管理・比較
- **IgnoreManager**: ignore.jsonから無視リールを読み込み、管理
- **Comparator**: 2つの環境のリソースを比較し、未認知差分と認知済み差分を分類

### `internal/report` - レポート生成
- **Formatter**: インターフェース（複数の出力形式に対応）
- **MarkdownFormatter**: Markdownテーブル形式
- **CSVFormatter**: CSV形式
- **JSONFormatter**: JSON形式

### `cmd/cli` - CLIエントリーポイント
- フラグパース（ignore, output-dir, format）
- ディレクトリの自動検出
- 環境ペアの比較実行
- レポート出力

## 特徴

### 拡張性
- **フォーマッター**: `Formatter`インターフェースを実装することで、新しい出力形式を簡単に追加可能
- **モジュール分離**: 各処理ロジックが独立しているため、テストや変更が容易

### 依存関係の最小化
- 標準ライブラリのみで実装
- 外部パッケージに依存しない

### マルチ環境対応
- 複数の環境を一度に比較可能
- ディレクトリの自動検出機能

## ビルド・実行

```bash
# ビルド
go build -o tf-diff-reporter ./cmd/cli

# 実行例
./tf-diff-reporter compare -i ignore.json -o reports -f markdown env1 env2
./tf-diff-reporter compare env1 env2 env3  # auto-detect

# ヘルプ表示
./tf-diff-reporter help
```
