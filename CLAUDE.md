# CLAUDE.md

このファイルはClaudeコード（claude.ai/code）がこのリポジトリで作業する際のガイダンスを提供します。

## プロジェクト概要

**tf-diff-reporter** は、Go言語で書かれたシンプルなTerraform環境比較ツールです。複数のTerraform環境（dev、staging、prod）を比較し、統合差分レポートを生成します。

**コア価値提案：** `.tfdr/ignore.json` で意図した差分を管理し、意図しない差分との区別をつけることで、CI/CD統合を実現します。

### 主な特徴
- **言語：** Go 1.25+
- **外部依存：** 標準ライブラリ + 外部ツール（`hcl2json`、`jd`）
- **テスト環境：** `test/simple/` に4つのローカルプロバイダー環境
- **CLI形式：** `compare` サブコマンド＋自動ディレクトリ検出
- **出力形式：** Markdownのみ（Terraform plan 互換形式）
- **終了コード：** 0（未認識差分なし）、1（未認識差分あり）
- **コード行数：** 約795行（シンプル化済み）

---

## アーキテクチャ概要

### モジュール構成（5パッケージ、795行）

```
cmd/cli/
├── main.go (165行)
│   └─ runCompare(): CLI実行とオーケストレーション
│   └─ 環境の自動検出と絶対パス正規化
│   └─ ディレクトリ群の順序処理

internal/
├── tools/
│   ├── checker.go (15行)          ← 外部ツール確認
│   │   └─ CheckRequiredTools(): hcl2json、jd の確認
│   └── executor.go (56行)         ← 外部コマンド実行
│       └─ ExecuteHCL2JSON(): hcl2json 実行（JSON返却）
│       └─ ExecuteJD(): jd 実行（RFC 6902 パース）
│       └─ remove+add の自動統合 → replace に変換
│
├── hcl/
│   └── converter.go (48行)        ← HCL → JSON 変換
│       └─ ConvertDirectory(): 複数 .tf ファイルを統合JSON生成
│       └─ mergeJSON(): ネストされたマップをマージ
│
├── diff/
│   ├── comparator.go (34行)       ← 差分分類
│   │   └─ ClassifyDiffs(): jd 出力をパース＆ignore適用
│   │   └─ (unknown/acknowledged に分類)
│   └── ignore.go (88行)           ← ignore.json 管理
│       └─ LoadFromFile(): .tfdr/ignore.json をパース
│       └─ IsIgnored()、GetReason(): ルール照会
│
├── model/
│   └── types.go (33行)            ← データ構造
│       └─ Difference, EnvironmentDiff, MergedComparisonResult
│       └─ IgnoreRule
│
└── report/
    ├── formatter.go (3行)         ← （空、Markdown のみ）
    └── markdown.go (375行)        ← Markdown レポート生成
        └─ FormatMerged(): 統合レポート出力
        └─ formatMergedDiffTableWithOp(): テーブル生成
        └─ formatDiffCell(): 記号（+/-/~）+ 値 フォーマット
        └─ formatValue(): Markdown エスケープ処理
```

### データフロー（シンプル版）

```
1. CLI引数をパース
   ↓
2. ディレクトリを自動検出またはロード
   ↓ （ReadDir → "." プレフィックスフィルタ → ソート）
   ↓ （最初=基準、残り=比較対象）
3. 絶対パスに変換
   ↓
4. 無視ルール（ignore.json）をロード
   ↓
5. 基準環境を HCL → JSON に変換（hcl2json）
   ↓
6. 各比較対象環境を HCL → JSON に変換
   ↓
7. jd で JSON 差分を抽出（RFC 6902 形式）
   ↓ （remove+add の自動統合 → replace）
8. 差分を分類（ignore.json で acknowledged/unknown に）
   ↓
9. Markdown レポート生成＆書き込み
   ↓
10. 終了コード判定（未認識差分 > 0 なら 1）
```

---

## 重要な実装詳細

### 1. 外部コマンド活用モデル

Go プログラムは **CLIオーケストレーション層** に特化し、複雑な処理は外部ツールに委譲：

```
hcl2json: HCL ファイルを JSON に変換
  - ディレクトリ内の複数 .tf ファイルを個別変換
  - Go で JSON マージ（ConvertDirectory）

jd: JSON 差分を RFC 6902 形式で出力
  - Base JSON と Target JSON を比較
  - Patch フォーマット（-f patch）出力
  - Go で "test" 操作をフィルタ
  - Go で remove+add を replace に統合（ExecuteJD）
```

### 2. Terraform plan 互換出力形式

Markdown テーブル形式で、以下の記号で操作を表現：

```markdown
| 属性パス | env1 → env2 |
| :--- | :--- |
| /resource/item | + 新規追加された値 |
| /resource/item | − 削除された値 |
| /resource/item | ~ 旧値<br>→ 新値 |
```

**特徴：**
- `+` = 新規追加（add）
- `−` = 削除（remove）
- `~` = 変更（replace = remove + add の統合）
- 矢印（→）の前後で改行（`<br>`）で見やすく表示
- 複数環境の場合は列で並べて比較

### 3. 自動ディレクトリ検出

```bash
# 自動検出: 環境ディレクトリを自動で見つける
tf-diff-reporter compare

# 明示的指定: 基準と比較対象を指定
tf-diff-reporter compare env1 env2 env3
```

検出ロジック：
1. カレントディレクトリを ReadDir
2. "." プレフィックス（.tfdr、.git など）をフィルタ
3. 残りを sort → アルファベット順
4. 最初 = base、残り = compare 対象

### 4. RFC 6902 Patch フォーマットの統合

jd は同じパスの `remove` + `add` を別々の操作で出力。ExecuteJD() でこれを自動統合：

```json
// jd 出力（パッチ形式）
[
  {"op":"test","path":"/key","value":1},
  {"op":"remove","path":"/key","value":1},
  {"op":"add","path":"/key","value":2}
]

// ExecuteJD() 後
[
  {"op":"replace","path":"/key","from":1,"value":2}
]
```

---

## よく使う開発タスク

### ビルド
```bash
go build -o tf-diff-reporter ./cmd/cli
```

### テスト実行
```bash
cd test/simple

# 自動検出（env1, env2, env3, env4, test）
../../tf-diff-reporter compare

# 明示的指定
../../tf-diff-reporter compare env1 env2

# カスタム ignore ファイル
../../tf-diff-reporter -i custom-ignore.json compare env1 env2
```

### レポート確認
```bash
cat .tfdr/reports/comparison-report.md
```

### 終了コード確認
```bash
../../tf-diff-reporter compare
echo $?  # 0 = 未認識差分なし、1 = あり
```

### コードフォーマット＆検査
```bash
go fmt ./...
go vet ./...
```

---

## テスト環境

`test/simple/` に 4 つの環境が含まれます：

### ディレクトリ構成
- **env1/** (本番類似): リソース定義セット A
- **env2/** (ステージング類似): リソース定義セット B（一部異なる）
- **env3/** (開発類似): リソース定義セット C（拡張）
- **env4/** (変更テスト用): env1 と同一構造で値のみ異なる
- **test/** (削除テスト用): 最小限のリソース定義

### 無視ルール
`.tfdr/ignore.json` のサンプルルール：
```json
[
  {"path": "/resource/local_file/app_config/0/content", "comment": "環境固有設定"},
  {"path": "/resource/local_file/database_config/0/content", "comment": "環境固有DB設定"}
]
```

---

## 重要なファイル＆責務

| ファイル | 行数 | 責務 |
|---------|------|------|
| cmd/cli/main.go | 165 | CLI オーケストレーション、ディレクトリ検出 |
| internal/tools/executor.go | 56 | hcl2json、jd 実行、パース |
| internal/hcl/converter.go | 48 | HCL → JSON 変換、マージ |
| internal/diff/comparator.go | 34 | 差分分類（unknown/acknowledged） |
| internal/diff/ignore.go | 88 | ignore.json 管理 |
| internal/model/types.go | 33 | データ構造定義 |
| internal/report/markdown.go | 375 | Markdown レポート生成 |

---

## よくある実装パターン

### 新しい出力形式を追加

**現状：** Markdown のみ対応
**今後対応が必要な場合：**

1. `internal/report/` に新フォーマッター作成（例: json2.go）
2. `report.NewFormatter()` を呼び出す関数を追加
3. main.go の `-f` フラグで選択可能に
4. ただし、`FormatMerged()` メソッドが必須（CSV/JSON は単一比較のみ）

### 無視ルール機能の拡張

**現状：** 完全パスマッチング
**拡張案：**
- ワイルドカード対応（例: `/resource/*/timeout`）
- 正規表現対応（例: `/resource/.*/timeout`）
- 環境別ルール（例: 特定環境でのみ無視）

---

## デバッグのコツ

### jd 出力を確認
```bash
# JSON ファイルで jd の出力を確認
hcl2json env1/main.tf > /tmp/env1.json
hcl2json env2/main.tf > /tmp/env2.json
jd -f patch /tmp/env1.json /tmp/env2.json
```

### 生成されたレポートを確認
```bash
cat .tfdr/reports/comparison-report.md
```

### ディレクトリ検出をテスト
```bash
# コマンド実行時にどの環境が選ばれるか確認
ls -d */ | sort  # 手動で確認
```

---

## 既知の制限＆今後の改善

### 現在の制限
- **出力形式固定：** Markdown のみ（CSV/JSON は実装あるが非推奨）
- **無視ルール：** 完全パスマッチングのみ（ワイルドカード未対応）
- **テスト：** 手動統合テストのみ（自動テストスイートなし）

### 潜在的な改善
- ユニットテスト追加（各パッケージ用 `*_test.go`）
- 無視ルール拡張（ワイルドカード、正規表現）
- マルチ環境実行の並列化
- 出力言語の選択可能化（現在：日本語固定）

---

## 参考資料

- `test/simple/` - 統合テスト環境＆サンプル設定
- `.tfdr/ignore.json` - 無視ルール設定ファイル
- `.tfdr/reports/comparison-report.md` - 生成レポート
