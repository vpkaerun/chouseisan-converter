# 実行環境と設定

本スクリプトの実行には、特定のPowerShell環境と設定が必要です。

## 1. 必須環境

- **PowerShell 7.5.2 以上**

本スクリプトは、`pwsh.exe` での実行を前提としています。Windows標準の `powershell.exe` (5.1以前) では動作しません。

## 2. 実行ポリシーの設定

初めてスクリプトを実行する前に、PowerShellの実行ポリシーを緩和する必要があります。
**管理者として起動したPowerShell**で、以下のコマンドを一度だけ実行してください。

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
```

- この設定により、ローカルで作成されたスクリプト（本スクリプトを含む）と、信頼できる発行元によって署名されたスクリプトの実行が許可されます。
- `-Scope CurrentUser` により、この設定は現在ログインしているユーザーにのみ適用され、システム全体の設定には影響しません。

## 3. PowerShell実行時のエンコーディングに関する注意点

PowerShellスクリプトの実行環境、特にWindows Subsystem for Linux (WSL) や `cmd.exe` を介して `pwsh.exe` を呼び出す場合、文字コードの不一致による文字化けが発生することがあります。これを避けるためには、PowerShellプロセス自体のエンコーディングを明示的に設定することが重要です。

### `pwsh.exe` の呼び出しとエンコーディング

- **`-File` オプション:** スクリプトファイルを直接実行する場合に使用します。この場合、`-File` の後に続く引数はすべてスクリプトに渡される引数と見なされます。`pwsh.exe` 自体のエンコーディングを設定するには、`-File` の前にオプションを指定する必要がありますが、環境によっては正しく解釈されない場合があります。

- **`-Command` オプション:** PowerShellのコマンド文字列を実行する場合に使用します。この方法では、コマンド文字列内で `$OutputEncoding` などのPowerShell変数を設定し、その後にスクリプトを実行することで、より確実にエンコーディングを制御できます。

**推奨される呼び出し方 (WSL/cmd.exe からのUTF-8出力):**

```bash
pwsh.exe -NoProfile -ExecutionPolicy Bypass -Command "$OutputEncoding = [System.Text.Encoding]::UTF8; & 'C:\Path\To\Your\Script.ps1' -Param1 Value1"
```

- `-NoProfile`: PowerShellプロファイルを読み込まず、クリーンな環境で実行します。
- `-ExecutionPolicy Bypass`: 実行ポリシーを一時的にバイパスします。
- `-Command "..."`: 指定したコマンド文字列を実行します。
  - `$OutputEncoding = [System.Text.Encoding]::UTF8`: PowerShellの標準出力エンコーディングをUTF-8に設定します。
  - `& 'C:\Path\To\Your\Script.ps1'`: スクリプトを呼び出します。パスはWindows形式の絶対パスをシングルクォートで囲みます。
  - `-Param1 Value1`: スクリプトに渡すパラメータです。

## 4. 推奨される実行方法 (WSL環境)

WSL (Windows Subsystem for Linux) 環境から、Windows上にインストールされたPowerShell Core (`pwsh.exe`) のスクリプトを実行する場合、**`pwsh.exe` を直接呼び出す方法がもっとも安定しており、推奨されます。**

この方法は、`cmd.exe` を介することで発生する複雑な引用符のエスケープや、予期せぬエラー（`SecurityError` や `ParserError` など）を回避できます。

### 基本コマンド形式

```bash
pwsh.exe -ExecutionPolicy Bypass -File "<Windows形式のスクリプトパス>" -<パラメータ名> "<Windows形式のパラメータ値>"
```

- **`pwsh.exe`**: Windows側のPowerShell実行ファイルを直接指定します。
- **`-ExecutionPolicy Bypass`**: 実行ポリシーの問題を回避するために指定します。
- **`-File "<Windows形式のスクリプトパス>"`**: 実行するスクリプトを、`C:\Users\YourUser\...` のようなWindows形式の絶対パスで指定します。
- **`-<パラメータ名> "<Windows形式のパラメータ値>"`**: スクリプトに渡す`パラメータ`も、同様にWindows形式のパスで指定します。

### 実行例

```bash
# Convert-ChouseisanToIcs.ps1 を実行する例
pwsh.exe -ExecutionPolicy Bypass -File "C:\Temp\CHOSEISAN-Tools\src\Convert-ChouseisanToIcs.ps1" -CsvPath "C:\Temp\CHOSEISAN-Tools\testdata\normal.csv" -IcsPath "C:\Temp\CHOSEISAN-Tools\my-schedule.ics"
```

## 5. その他の実行方法

### Windows PowerShellコンソールから直接実行する場合

PowerShellコンソール (`pwsh.exe`) を直接開いて実行する場合の基本的なコマンドです。

```powershell
pwsh -File "<スクリプトのパス>" -<パラメータ名> "<パラメータの値>"
```

**実行例:**

```powershell
pwsh -File "C:\Temp\CHOSEISAN-Tools\src\Convert-ChouseisanToIcs.ps1" -CsvPath ".\testdata\normal.csv" -IcsPath ".\my-schedule.ics"
```

### 【非推奨】cmd.exe を経由する方法

**注意:** この方法は、過去のバージョンとの互換性や、特殊な環境下でのトラブルシューティングのために残されていますが、**現在は非推奨**です。引用符の扱いやエラーハンドリングが複雑になり、予期せぬ問題を引き起こす可能性があります。

```bash
cmd.exe /c "pwsh -File ""<Windows形式のスクリプトパス>"" -<パラメータ名> ""<Windows形式のパラメータ値>"" "
```

## 6. UNC パスに関する注意点

WSL環境からWindowsのファイルにアクセスする場合、パスの形式に注意してください。UNCパス (`\\wsl.localhost\...` や `\\wsl$\...`) はPowerShellで正しく解釈されない場合があるため、常にWindows側の絶対パス (`C:\...`) を使用することを推奨します。
