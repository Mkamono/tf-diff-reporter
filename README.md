# tf-diff-reporter

Terraform 環境の HCL コードを直接比較し、意図した差分と意図しない差分を分類する CI/CD ツール。

## 概要

- **HCL コード直接比較**: Terraform state 不要
- **意図した差分を管理**: `.tfdr/ignore.json` で一元管理
- **マルチ環境対応**: 複数環境を一度に比較
- **Markdown レポート生成**: `.tfdr/reports/comparison-report.md` に出力

## インストール

### 1. tf-diff-reporter をインストール

**Homebrew**
```bash
brew install Mkamono/tap/tf-diff-reporter
```

**Go**
```bash
go install github.com/Mkamono/tf-diff-reporter/cmd/tfdr@latest
```

**mise**
```bash
mise use --global go:github.com/Mkamono/tf-diff-reporter/cmd/tfdr
```

**バイナリから**

[Releases ページ](https://github.com/Mkamono/tf-diff-reporter/releases) からダウンロード

### 2. 外部ツール（hcl2json, jd）をインストール

**Homebrew** (推奨 - macOS)
```bash
brew install hcl2json jd
```

**Go**
```bash
go install github.com/tmccombs/hcl2json@latest
go install github.com/josephburnett/jd/v2/jd@latest
```

**mise**
```bash
mise use --global hcl2json
mise use --global jd
```

**Linux (apt)**
```bash
# hcl2json はリポジトリによって異なるため、Releases ページからバイナリをダウンロード
# jd も同様
```

**Docker を使う場合**
```bash
alias hcl2json='docker run --rm -i -v "$PWD:$PWD" -w "$PWD" tmccombs/hcl2json'
alias jd='docker run --rm -i -v "$PWD:$PWD" -w "$PWD" josephburnett/jd'
```

## 使い方

### ディレクトリ構成

```
/my-terraform-project
├── .tfdr/
│   ├── ignore.json
│   └── reports/
├── dev/
│   └── main.tf
├── prd/
│   └── main.tf
└── stg/
    └── main.tf
```

### ignore.json の作成

`.tfdr/ignore.json` に意図した差分を記述：

```json
[
  {
    "path": "/aws_db_instance.my_db/instance_class",
    "comment": "dev は t3.small、prd は m5.large"
  },
  {
    "path": "/aws_db_instance.my_db/multi_az",
    "comment": "prd のみ Multi-AZ 有効"
  }
]
```

### コマンド実行

**環境を指定** (推奨)
```bash
tfdr compare dev prd stg
```

**自動検出** (アルファベット順、最初が基準)
```bash
tfdr compare
```

**オプション**
- `-i FILE`: ignore ファイル（デフォルト: `.tfdr/ignore.json`）
- `-o DIR`: 出力先（デフォルト: `.tfdr/reports`）
- `-r`: 比較方向反転（`env → base` 形式）

**例**
```bash
tfdr compare -r -i custom-ignore.json dev prd stg
```

## 出力例

レポートは `.tfdr/reports/comparison-report.md` に生成：

```markdown
# Terraform 環境間差分レポート (基準: dev)

## 📊 サマリー

| | |
| --- | --- |
| 基準環境 | `dev` |
| 未認識差分 | 5 |
| 認識済み差分 | 12 |

## 認識済み差分

| 属性パス | dev → prd | 理由 |
| :--- | :--- | :--- |
| /aws_db_instance/instance_class | ~ t3.small<br>→ m5.large | dev は t3.small、prd は m5.large |
```

**記号**
- `+` = リソース追加
- `−` = リソース削除
- `~` = リソース変更

## 🤝 コントリビューション

バグ報告、機能リクエスト、Pull Request を歓迎します。

## 📜 ライセンス

[MIT License](./LICENSE)
