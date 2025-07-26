# スクリプトの使い方

## 基本的な使い方

スクリプトと同じディレクトリに `chouseisan.csv` を置いて、以下のコマンドを実行します。
`output.ics` というファイルが生成されます。

```powershell
./src/Convert-ChouseisanToIcs.ps1
```

## パラメータ一覧

| パラメータ         | 型      | 説明                                                                  |
| ------------------ | ------- | --------------------------------------------------------------------- |
| `-CsvPath <path>`  | string  | 入力するCSVファイルのパスを指定します。                                 |
| `-IcsPath <path>`  | string  | 出力するICSファイルのパスを指定します。                                 |
| `-IgnoreOthers`    | switch  | 最初の参加者（CSVの3列目）の出欠のみを考慮します。                      |
| `-ExcludeNG`       | switch  | いずれかの参加者が「×」を付けている日程を除外します。                  |
| `-Debug`           | switch  | 処理の詳細なデバッグログをコンソールに出力します。                      |

## 実行例

**例1: 入力と出力のパスを明示的に指定する**

```powershell
./src/Convert-ChouseisanToIcs.ps1 -CsvPath ./testdata/normal.csv -IcsPath ./my-schedule.ics
```

**例2: 「×」が付いている日を除外して生成する**

```powershell
./src/Convert-ChouseisanToIcs.ps1 -ExcludeNG
```

**例3: 最初の参加者の予定だけを抽出し、デバッグログも表示する**

```powershell
./src/Convert-ChouseisanToIcs.ps1 -IgnoreOthers -Debug
```
