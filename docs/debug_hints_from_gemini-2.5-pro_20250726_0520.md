拝見したデバッグレポートと添付のスクリプトに基づき、`EmptyCsv` テストが失敗する原因と、その解決策についてアドバイスします。

### `EmptyCsv` テスト失敗の原因と解決策

`EmptyCsv` テストが失敗する主な原因は、**`Write-Warning` が出力する警告メッセージの扱い方**にあります。テストスクリプト側で、この警告を正しくキャプチャし、検証する方法に改善の余地があります。

結論から言うと、`*>&1` を使ってリダイレクトするアプローチは正しいですが、キャプチャされた警告は単なる文字列ではなく、**`WarningRecord` というオブジェクト**であるため、そのオブジェクトのプロパティを検証する必要があります。

---

#### 根本原因：PowerShellのストリームとオブジェクト

PowerShellには、標準出力（成功ストリーム）以外に、エラー、警告、詳細、デバッグなどの複数の「ストリーム」が存在します。

*   `Write-Warning` は**警告ストリーム (ストリーム番号 3)** に出力します。
*   `2>&1` は**エラー ストリーム (2)** を成功ストリーム (1) にリダイレクトしますが、警告ストリームは対象外です。
*   `*>&1` は**すべてのストリーム**を成功ストリームにリダイレクトするため、警告もキャプチャできます。しかし、このとき警告は**`[System.Management.Automation.WarningRecord]` 型のオブジェクト**としてキャプチャされます。

テストで失敗しているのは、おそらくキャプチャした変数 (`$result`) を単純に文字列として比較しようとしているため、期待する文字列が見つからない、という状況だと考えられます。

#### 解決策：`WarningRecord` オブジェクトを正しく検証する

スクリプトの実行結果を `*>&1` で変数に格納した後、その変数の中から `WarningRecord` 型のオブジェクトを抽出し、その `Message` プロパティが期待する警告文と一致するかを検証します。

以下に、`EmptyCsv` テストのための具体的なテストコードの改善案を示します。

**テストスクリプトの修正案 (`test.ps1` 内、またはテストを実行するロジック内)**

```powershell
# --- テストの準備 ---
$testName = "EmptyCsv Test"
Write-Host "--- Running test: $testName ---"

# テスト用の空のCSVファイルを作成
$testDataDir = "C:\Temp\CHOSEISAN-Tools\testdata"
$outputDir = "C:\Temp\CHOSEISAN-Tools\test_output"
$emptyCsvPath = Join-Path $testDataDir "empty.csv"
$emptyIcsPath = Join-Path $outputDir "empty.ics"
# ファイルが存在してもしなくても確実に空のファイルを作成
New-Item -Path $emptyCsvPath -ItemType File -Force | Out-Null

$mainScriptPath = "C:\Temp\CHOSEISAN-Tools\src\Convert-ChouseisanToIcs.ps1"
$expectedWarningMessage = "CSVファイルにヘッダー行またはデータ行がありません。" # 部分一致で確認するため、メッセージの一部でも可

# --- スクリプトの実行と全ストリームのキャプチャ ---
# スクリプトを呼び出し、すべてのストリーム(*>&1)を変数 $result に格納します。
# -ErrorAction Stop を付けて、予期せぬエラー発生時にテストを停止させます。
$result = & $mainScriptPath -CsvPath $emptyCsvPath -IcsPath $emptyIcsPath -CsvEncoding ([System.Text.Encoding]::UTF8) -ErrorAction Stop *>&1

# --- 結果の検証 ---
# 1. $result の中から WarningRecord 型のオブジェクトを抽出する
$warnings = $result | Where-Object { $_ -is [System.Management.Automation.WarningRecord] }

# 2. 抽出した警告オブジェクトの Message プロパティに、期待するメッセージが含まれているか確認する
$foundWarning = $warnings | Where-Object { $_.Message -like "*$expectedWarningMessage*" }

if ($foundWarning) {
    Write-Host "✅ TEST PASSED: $testName" -ForegroundColor Green
    Write-Host "   - 理由: 期待通りの警告メッセージがキャプチャされました。"
    Write-Host "   - メッセージ: $($foundWarning.Message)"
} else {
    Write-Host "❌ TEST FAILED: $testName" -ForegroundColor Red
    Write-Host "   - 理由: 期待される警告メッセージがキャプチャされませんでした。"
    Write-Host "   - 期待したメッセージ(部分一致): '$expectedWarningMessage'"
    Write-Host "   - 実際の出力全体:"
    $result | ForEach-Object { Write-Host "     - $($_.ToString()) (Type: $($_.GetType().FullName))" }
}

# --- クリーンアップ ---
Remove-Item $emptyCsvPath -Force
if (Test-Path $emptyIcsPath) {
    Remove-Item $emptyIcsPath -Force
}
```

**このコードのポイント：**

1.  **`*>&1` で全キャプチャ:** スクリプト呼び出し時に `*>&1` を付け、出力されるすべての情報（成功、警告、エラーなど）を `$result` 変数に配列として格納します。
2.  **`Where-Object { $_ -is [Type] }`:** `$result` の中身を型でフィルタリングします。これにより、`WarningRecord` オブジェクトだけを確実に取り出すことができます。
3.  **`.Message` プロパティの確認:** `WarningRecord` オブジェクトが持つ `Message` プロパティと、期待する警告文を比較します。`-like` 演算子を使えば、部分一致での比較も簡単です。

---

### その他の問題に関する所見

デバッグレポートに記載されている他の問題についても、現在の判断は非常に合理的であると考えます。

*   **永続的な文字化け問題:**
    *   ご認識の通り、WSLとWindowsホストの `pwsh.exe` 間でのエンコーディングの相互作用は非常に複雑です。スクリプトのコア機能（ICSファイル生成）に影響がないのであれば、この表示上の問題を一旦保留とする判断は適切です。
*   **`Normal_ShiftJIS_NoOptions` テストの延期:**
    *   Shift-JISの扱いは、文字エンコーディングそのものの問題と、それに起因する日付解析の正規表現のマッチング問題が絡み合うため、難易度が高い課題です。主要なユースケースであるUTF-8のテストが成功している状況で、これを「ファーザースタディ」として切り分けるのは、開発を進める上で賢明な判断です。

今回提案した警告ストリームのキャプチャ方法を試すことで、`EmptyCsv` テストが成功に転じる可能性が高いです。頑張ってください。