# 調整さんCSV to ICS コンバーター

## 1. 概要

「調整さん」からエクスポートしたCSV形式の出欠表を、Outlookなどのカレンダーアプリにインポート可能なiCalendar（.ics）形式のファイルに変換するPowerShellスクリプトです。

このツールを使えば、複数の候補日から参加可能な日時だけを抽出し、一括で「仮の予定」としてカレンダーに登録できます。

## 2. 主な機能

- **CSVからICSへの変換:** 調整さん形式のCSVを読み込み、ICSファイルを生成します。
- **件名の自動設定:** CSVの1行目をイベントの件名として自動で設定します。
- **参加可能日の抽出:** 出欠が「◯」または「△」の候補日のみを抽出します。
- **仮の予定として登録:** 生成されるカレンダーイベントは、すべて「仮の予定」(`TENTATIVE`) として登録されます。
- **デバッグモード:** `-Debug` スイッチで、処理の詳細な流れをコンソールで確認できます。
  * **注意:** `-ExcludeNG` および `-IgnoreOthers` オプションは現在開発中であり、今後のバージョンでサポートされる予定です。

## 3. 必須環境

- **PowerShell 7.5.2 以上**

本スクリプトは、`pwsh.exe` での実行を前提としています。Windows標準の `powershell.exe` (5.1以前) では動作しません。

### 実行ポリシーの設定

初めてスクリプトを実行する前に、PowerShellの実行ポリシーを緩和する必要があります。
**管理者として起動したPowerShell**で、以下のコマンドを一度だけ実行してください。

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
```

より詳細な実行環境と設定については、[実行環境と設定](docs/environment.md) を参照してください。

## 4. 使い方

### 基本的な使い方

スクリプトと同じディレクトリに `chouseisan.csv` を置いて、以下のコマンドを実行します。
`output.ics` というファイルが生成されます。

```powershell
./src/Convert-ChouseisanToIcs.ps1
```

### パラメータ一覧

| パラメータ         | 型      | 説明                                                                  |
| ------------------ | ------- | --------------------------------------------------------------------- |
| `-CsvPath <path>`  | string  | 入力するCSVファイルのパスを指定します。                                 |
| `-IcsPath <path>`  | string  | 出力するICSファイルのパスを指定します。                                 |
| `-CsvEncoding <encoding>` | string  | 入力するCSVファイルのエンコーディングを指定します（現在UTF-8のみ対応）。 |
| `-Debug`           | switch  | 処理の詳細なデバッグログをコンソールに出力します。                      |

### 実行例

**例1: 入力と出力のパスを明示的に指定する**

```powershell
./src/Convert-ChouseisanToIcs.ps1 -CsvPath ./testdata/normal.csv -IcsPath ./my-schedule.ics
```

## 5. 入力CSVの仕様

入力CSVファイルの形式については、[入力CSVファイルの仕様](docs/csv_specification.md) を参照してください。

---
*This tool is developed with the assistance of Gemini CLI.*
