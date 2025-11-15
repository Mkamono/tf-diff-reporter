# tf-diff-reporter 🧾

Terraform で管理される複数の環境（ディレクトリ）の HCL コードを直接比較し、`.tfdr/ignore.json` に基づいて「意図した差分」と「意図しない差分」を分類する CI/CD 向けツール。差分を JSON Pointer (RFC 6902) 形式で統合レポート（Markdown）として生成します。

## 💡 なぜこのツールが必要か？

Terraform で `dev`, `stg`, `prd` などの環境を運用する際、HCL コードには**意図した差分**が必ず存在します。

  * `prd` のDBインスタンスタイプは `m5.large` だが、`dev` は `t3.small` にしたい
  * `prd` のみ Multi-AZ を有効にしたい

これらの差分は正しいものです。しかし、Pull Request でコードを変更した際、`diff` や `plan` 結果が大量に表示されると、**「本当に意図しない差分（例: 本番環境にだけ設定し忘れたセキュリティルール）」**を見逃す危険性があります。

`tf-diff-reporter` は、`.tfdr/ignore.json` というファイルで「意図した差分」を管理できるようにします。CI/CD でこのツールを実行することで、「認知されていない（意図しない）差分」だけを検知し、安全な運用をサポートします。

## ✨ 特徴

  * **HCL コード直接比較**: `hcl2json` と `jd` ツールを活用し、HCL ファイルを JSON に変換して差分を検出。Terraform state に依存しません。
  * **完全なコード比較**: 外部リソース状態に依存しない、純粋なコード比較により、オフライン環境や CI/CD での実行をサポート。
  * **マルチ環境対応**: 複数の環境（ディレクトリ）を一度に比較し、1つの統合レポートを生成。
  * **自動検出**: 引数を省略すると、配下のディレクトリを自動でスキャンして比較対象とします。アルファベット順でソートされ、最初の環境が基準になります。
  * **比較方向の反転**: `-r/--reverse` フラグで、比較方向を反転（env → base instead of base → env）。
  * **集中管理された無視リスト**: `.tfdr/ignore.json` で全環境の「意図した差分」を一元管理。JSON Pointer (RFC 6902) 形式のパスで指定。
  * **CI/CD フレンドリー**: 認知されていない差分が 1 件でもあれば、exit code 1 を返します。
  * **Markdown レポート出力**: レポートは Markdown 形式で `.tfdr/reports/comparison-report.md` に出力。GitHub や CI/CD 環境で直接レンダリング可能。

-----

## 🔧 実行メカニズム

`tf-diff-reporter` は HCL コードの直接比較により、Terraform state に依存しない安全な差分検出を実現しています：

### ステップ 1: HCL → JSON 変換

```bash
hcl2json env1/main.tf > /tmp/env1.json
```

各環境のディレクトリ内の `.tf` ファイルを `hcl2json` で JSON に変換します。複数ファイルの場合は自動的にマージされます。

### ステップ 2: JSON 差分検出 (jd)

```bash
jd -f patch /tmp/env1.json /tmp/env2.json
```

`jd` ツールで JSON ファイルの差分を RFC 6902 (JSON Patch) 形式で取得します。

### ステップ 3: 差分の分類と統合

Go 内部で差分を処理し、以下の処理を行います：

- `remove` + `add` 操作を `replace` 操作に統合
- `.tfdr/ignore.json` のルールに基づいて「意図した差分」と「意図しない差分」に分類
- 複数の比較環境の結果を統合

### ステップ 4: Markdown レポート生成

統合された差分情報を Markdown 形式でレポートに出力します。

### 外部ツール依存

このツールは以下の外部ツールに依存しています：

- **`hcl2json`**: HCL ファイルを JSON に変換
- **`jd`**: JSON ファイルの差分を RFC 6902 形式で抽出

これらがインストールされていることを前提として動作します。

-----

## 💿 インストール

### Go を使う場合 (推奨)

```bash
go install github.com/Mkamono/tf-diff-reporter/cmd/tfdr@latest
```

### バイナリ

[Releases ページ](https://github.com/Mkamono/tf-diff-reporter/releases) から、ご使用のOS/アーキテクチャに合った最新のバイナリをダウンロードしてください。

### 外部ツール

以下のツールが必要です：

```bash
# hcl2json をインストール
go install github.com/tmccombs/hcl2json@latest

# jd をインストール
go install github.com/josephburnett/jd@latest
```

### ソースからビルド

```bash
git clone https://github.com/Mkamono/tf-diff-reporter.git
cd tf-diff-reporter
go build -o tfdr ./cmd/tfdr
```

-----

## 📖 使い方 (Usage)

`tf-diff-reporter` は、特定のディレクトリ構造を前提として動作します。

### Step 1. 前提となるディレクトリ構造

プロジェクトのルートに、環境ごとのサブディレクトリ（`dev`, `prd` など）が配置されている必要があります。`.tfdr/` ディレクトリには ignore ルールと出力レポートを配置します。

```
/my-terraform-project  <-- ここでコマンドを実行
├── .git/
├── .tfdr/
│   ├── ignore.json     <-- 差分を管理するファイル
│   └── reports/        <-- レポートの出力先
├── dev/
│   └── main.tf         <-- HCL ファイル（複数可）
├── prd/
│   └── main.tf
└── stg/
    └── main.tf
```

> **Note:** ディレクトリ内の HCL ファイルは自動的に検出・変換されます。`terraform.tfvars` などは無視されます。

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
tfdr compare [OPTIONS] [DIR_1 (基準)] [DIR_2] [DIR_3] ...
```

**オプション (Flags):**

  * `-i, --ignore FILE`: 差分を管理する ignore ファイルのパス。（デフォルト: `.tfdr/ignore.json`）
  * `-o, --output-dir DIR`: レポートの出力先ディレクトリ。（デフォルト: `.tfdr/reports`）
  * `-r, --reverse`: 比較方向を反転。`env → base` の形式で表示（通常は `base → env`）

-----

#### 実行例 1: 環境を明示的に指定する

`dev` を基準として、`prd` と `stg` を比較し、統合レポートを生成します。

```bash
# dev を基準に指定
tfdr compare dev prd stg
```

**生成されるレポート:**
  * `dev → prd` の差分
  * `dev → stg` の差分

#### 実行例 2: 比較方向を反転

```bash
# dev を基準に保ったまま、prd と stg から dev への比較方向に反転
tfdr compare -r dev prd stg
```

**生成されるレポート:**
  * `prd → dev` の差分
  * `stg → dev` の差分

#### 実行例 3: 引数なしで自動検出する

```bash
tfdr compare
```

  * **実行される動作:**
    1.  配下のディレクトリをスキャンします (例: `dev`, `prd`, `stg`)。
    2.  ディレクトリ名を**アルファベット順にソート**します (例: `[dev, prd, stg]`)。
    3.  ソート後の1番目 (`dev`) が「基準」として自動選択されます。
    4.  `prd` と `stg` を `dev` と比較し、統合レポートを生成

#### 実行例 4: カスタム ignore ファイルと出力ディレクトリ

```bash
tfdr compare -i custom-ignore.json -o ./my-reports dev prd stg
```

> **Note:**
> CI/CD での安定した運用のため、**実行例1または2（環境を明示的に指定）** の方法を推奨します。

-----

## 📊 出力例 (`.tfdr/reports/comparison-report.md`)

`tfdr compare dev prd stg` を実行した場合、以下のようなレポートが `.tfdr/reports/comparison-report.md` に生成されます。

### レポート構成

```markdown
# Terraform 環境間差分レポート (基準: dev)

## 📊 サマリー

| | |
| --- | --- |
| 基準環境 | `dev` |
| 未認識差分 (−) | 5 |
| 認識済み差分 (✓) | 12 |

## 認識済み差分 (ignore.json)

| 属性パス | dev → prd | dev → stg | 理由 |
| :--- | :--- | :--- | :--- |
| /resource/google_compute_instance/web/0/machine_type | ~ e2-medium<br>→ e2-standard-2 | − | Machine type scaled: e2-medium -> e2-standard-2 |
| /resource/google_sql_database_instance/main/0/settings/0/tier | ~ db-f1-micro<br>→ db-custom-2-8192 | ~ db-f1-micro<br>→ db-custom-2-8192 | Database tier scaled up in prd and stg |
```

### 特徴

- **属性パス表示**: JSON Pointer (RFC 6902) 形式で、どの設定が異なるかを明確に表示
- **操作記号**:
  - `+` = リソース追加
  - `−` = リソース削除
  - `~` = リソース変更
- **マルチライン値対応**: 複数行の値は `<br>` で改行表示（Markdown レンダリング時に整形）
- **理由の表示**: 認知済み差分には `ignore.json` のコメントを表示
- **単一ファイル出力**: すべての比較結果を1つのレポートにマージ
- **複数環境対応**: 2つ以上の比較環境がある場合、複数列で並べて表示

## 🤝 コントリビューション

バグ報告、機能リクエスト、Pull Request を歓迎します。

## 📜 ライセンス

[MIT License](./LICENSE)
