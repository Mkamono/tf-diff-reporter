# Test Case: for_each - 基本的な反復処理

このテストケースは、`for_each` メタ引数を使った **リソースの動的生成と環境別管理** をテストします。

## テストの目的

- `for_each` で複数リソースを管理する場合の差分検出
- イテレーション単位での環境別差異
- イテレーションキーの変更と新規追加の検出

## シナリオ

### env1
- **ストレージバケット**: logs(STANDARD), data(NEARLINE), backup(COLDLINE)
- **サービスアカウント**: api, worker, scheduler (3個)
- **計算インスタンス**: frontend-1, frontend-2 (2個)

### env2
- **ストレージバケット**: logs(STANDARD), data(**STANDARD**), backup(COLDLINE), **archive(ARCHIVE)** ← 新規追加
- **サービスアカウント**: api, worker, scheduler, **monitor** (4個) ← 新規追加
- **計算インスタンス**: frontend-1, frontend-2, **frontend-3** (3個) ← 新規追加

## 差分の特徴

| 要素 | 差分パターン | 個数 |
|-----|----------|-----|
| イテレーションキー追加 | `archive`, `monitor`, `frontend-3` のリソースが新規作成 | 3個 |
| イテレーション値変更 | `data` バケットの storage_class 変更、インスタンスの machine_type 変更 | 複数 |
| ラベル/名前の環境別差異 | 各リソースのラベルと名前に環境サフィックス | 複数 |

## 実行方法

```bash
cd test/foreach-basics
../../tf-diff-reporter compare env1 env2
```

**期待される結果**: `exit code 0` (すべての差分が認識済み)

## テストがカバーするケース

- ✅ for_each でのキーの追加と削除
- ✅ イテレーション値の変更（storage_class など）
- ✅ リソース属性の環境別差異（名前、ラベル）
- ✅ イテレーション要素のスケーリング（machine_type 変更）

## ignore.json で管理される差分

21個のルールで環境別差分を管理：
- 新規バケット (`archive`)
- 新規サービスアカウント (`monitor`)
- 新規計算インスタンス (`frontend-3`)
- ストレージクラス、マシンタイプの変更
- ラベルと名前の環境別差異
