# tf-diff-reporter 🧾

Terraform で管理される複数の環境（ディレクトリ）をスキャンし、`terraform plan` の「あるべき姿」を自動で比較。`.tfdr/ignore.json` に基づいて「意図した差分」と「意図しない差分」を分類し、統合されたレポートを生成する CI/CD 向けラッパーツールです。

## 💡 なぜこのツールが必要か？

Terraform で `dev`, `stg`, `prd` などの環境を運用する際、HCL コードには**意図した差分**が必ず存在します。

  * `prd` のDBインスタンスタイプは `m5.large` だが、`dev` は `t3.small` にしたい
  * `prd` のみ Multi-AZ を有効にしたい

これらの差分は正しいものです。しかし、Pull Request でコードを変更した際、`diff` や `plan` 結果が大量に表示されると、**「本当に意図しない差分（例: 本番環境にだけ設定し忘れたセキュリティルール）」**を見逃す危険性があります。

`tf-diff-reporter` は、`.tfdr/ignore.json` というファイルで「意図した差分」を管理できるようにします。CI/CD でこのツールを実行することで、「認知されていない（意図しない）差分」だけを検知し、安全な運用をサポートします。

## ✨ 特徴

  * **オールインワン実行**: `terraform init`, `plan`, `show` の実行をラップし、レポート生成までを単一コマンドで行います。
  * **非破壊的な実行**: 一時ディレクトリで処理を行うため、ユーザーの環境に影響を与えません。
  * **外部依存なし**: `terraform show -json` の出力を Go 内部で直接パースします。`jq` や YAML ライブラリ不要。
  * **HCL コード比較**: `-backend=false` と `-refresh=false` により、外部状態に依存しない純粋なコード比較が実現できます。
  * **マルチ環境対応**: 複数の環境（ディレクトリ）を一度に比較し、1つの統合レポートを生成します。
  * **自動検出**: 引数を省略すると、配下のディレクトリを自動でスキャンして比較対象とします。
  * **集中管理された無視リスト**: `.tfdr/ignore.json` で全環境の「意図した差分」を一元管理。
  * **CI/CD フレンドリー**: 認知されていない差分が 1 件でもあれば、exit code 1 を返します。
  * **複数の出力形式**: Markdown、CSV、JSON に対応（拡張性重視の設計）。

-----

## 🔧 実行メカニズム

`tf-diff-reporter` は安全な比較を実現するため、以下の工夫を行っています：

### 一時ディレクトリでの処理

各環境のディレクトリ内容を **一時ディレクトリ** にコピーし、その中で `terraform init` と `terraform plan` を実行します。

- **メリット**: ユーザーの環境に `.terraform/` ディレクトリやロック ファイルが生成されない
- **クリーンアップ**: 処理終了後、一時ディレクトリは自動的に削除される

### バックエンド設定を無視

```bash
terraform init -backend=false
```

- バックエンド設定（S3、Terraform Cloud など）を無視して初期化
- **目的**: 状態ファイル（state）に依存しない、純粋な HCL コード比較

### リフレッシュを無効化

```bash
terraform plan -refresh=false
```

- 既存のリモートリソースの状態確認をスキップ
- **目的**: オフライン環境や CI/CD での実行をサポート

### スキップされるファイル

コピー時に以下が除外されます：

- `.git/`, `.terraform/` などの隠しディレクトリ
- バックエンド設定ファイル（`backend.tf` など）

これにより、ユーザーが後で通常の `terraform plan` を実行する際に、改めて `terraform init` をする必要がありません。

-----

## 💿 インストール

### バイナリ (推奨)

[Releases ページ](https://www.google.com/search?q=https://github.com/YOUR_USER/tf-plan-reporter/releases) から、ご使用のOS/アーキテクチャに合った最新のバイナリをダウンロードしてください。

### Go を使う場合

```bash
go install github.com/YOUR_USER/tf-plan-reporter@latest
```

### ソースからビルド

```bash
git clone https://github.com/YOUR_USER/tf-plan-reporter.git
cd tf-plan-reporter
go build .
```

-----

## 📖 使い方 (Usage)

`tf-plan-reporter` は、特定のディレクトリ構造を前提として動作します。

### Step 1. 前提となるディレクトリ構造

プロジェクトのルートに、環境ごとのサブディレクトリ（`dev`, `prd` など）が配置されている必要があります。`.tfdr/` ディレクトリには ignore ルールと出力レポートを配置します。

```
/my-terraform-project  <-- ここでコマンドを実行
├── .git/
├── .tfdr/
│   ├── ignore.json     <-- 差分を管理するファイル
│   └── reports/        <-- レポートの出力先
├── dev/
│   ├── main.tf
│   └── terraform.tfvars
├── prd/
│   ├── main.tf
│   └── terraform.tfvars
└── stg/
    ├── main.tf
    └── terraform.tfvars
```

### Step 2. `.tfdr/ignore.json` の定義

「意図した差分」を管理するための `.tfdr/ignore.json` を作成します。
**JSON Pointer (RFC 6902) 形式** のパスと、差分を許容する理由を記述します。

**`.tfdr/ignore.json` (例):**

```json
[
  {
    "path": "/aws_db_instance.my_db/instance_class",
    "comment": "環境間でスペックが異なるのは意図通り (例: devはsmall, prdはlarge)"
  },
  {
    "path": "/aws_db_instance.my_db/multi_az",
    "comment": "環境によってMulti-AZ設定が異なるのは意図通り (prd/stgのみ有効)"
  },
  {
    "path": "/aws_iam_role.dev_only_role",
    "comment": "dev環境固有のテスト用IAMロール"
  }
]
```

### Step 3. `compare` コマンドの実行

`compare` サブコマンドは、**引数の1番目**を「基準 (Base)」とし、2番目以降の環境を「基準」と比較します。

**コマンドの書式:**

```bash
./tf-plan-reporter compare [OPTIONS] [DIR_1 (基準)] [DIR_2] [DIR_3] ...
```

**オプション (Flags):**

  * `--ignore FILE`, `-i FILE`: 差分を管理する ignore ファイルのパス。（デフォルト: `.tfdr/ignore.json`）
  * `--output-dir DIR`, `-o DIR`: レポートの出力先ディレクトリ。（デフォルト: `.tfdr/reports`）
  * `--format FORMAT`, `-f FORMAT`: 出力形式。`markdown`（デフォルト）、`csv`、`json` から選択可能。

-----

#### 実行例 1: 環境を明示的に指定する

`prd` を基準として、`dev` と `stg` を比較し、統合レポートを生成します。

```bash
# prd を基準に指定
./tf-diff-reporter compare prd dev stg
```

  * **実行される動作:**
    1.  `prd` を基準として、`dev` と `stg` の Terraform plan を実行
    2.  すべての環境の差分を収集・比較
    3.  1つの統合レポートを `.tfdr/reports/comparison-report.md` に生成

#### 実行例 2: 引数なしで自動検出する

```bash
./tf-diff-reporter compare
```

  * **実行される動作:**
    1.  配下のディレクトリをスキャンします (例: `dev`, `prd`, `stg`)。
    2.  ディレクトリ名を**アルファベット順にソート**します (例: `[dev, prd, stg]`)。
    3.  ソート後の1番目 (`dev`) が「基準」として自動選択されます。
    4.  `prd` と `stg` を `dev` と比較し、統合レポートを生成

#### 実行例 3: 出力形式を指定する

```bash
./tf-diff-reporter compare -f csv prd dev stg
```

  * **生成されるレポート:**
    - `.tfdr/reports/comparison-report.csv` (CSV 形式)

> **Note:**
> CI/CD での安定した運用のため、**実行例1（環境を明示的に指定）** の方法を推奨します。

-----

## 📊 出力例 (`.tfdr/reports/comparison-report.md`)

`compare prd dev stg` を実行した場合、以下のようなレポートが `.tfdr/reports/comparison-report.md` に生成されます。

### レポート構成

```
# Terraform 環境間差分レポート (基準: prd)

## 📊 概要

**基準環境:** `prd`

**比較環境:** 2 個

| 指標 | 件数 |
| --- | --- |
| 認知されていない差分 | 5 |
| 認知済みの差分 | 12 |

## 🚨 認知されていない差分 (確認推奨)

以下の差分は `ignore.json` で管理されていません。

| 属性パス | prd | dev | stg |
| :--- | :--- | :--- | :--- |
| /aws_lambda_function.my_function/timeout | 60 | 30 | 45 |
```

### 特徴

- **すべての環境が横一列**: 属性パスごとに、基準環境と比較環境の値が並んで表示
- **マルチライン値対応**: 複数行の値は `<br>` で改行表示（Markdown レンダリング時に整形）
- **理由の表示**: 認知済み差分には `ignore.json` のコメントを表示
- **単一ファイル出力**: すべての比較結果を1つのレポートにマージ

## 🤝 コントリビューション

バグ報告、機能リクエスト、Pull Request を歓迎します。

## 📜 ライセンス

[MIT License](https://www.google.com/search?q=LICENSE)
