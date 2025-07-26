# 調整さんCSV to ICS コンバーター 統合テストスクリプト

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$OutputEncoding = [System.Text.Encoding]::UTF8 # テストスクリプト自体の出力エンコーディングを設定

# メインスクリプトのパス
$mainScriptPath = Join-Path "C:\Temp\CHOSEISAN-Tools" "src\Convert-ChouseisanToIcs.ps1"

# テストデータディレクトリのパス
$testDataPath = Join-Path "C:\Temp\CHOSEISAN-Tools" "testdata"

# テスト出力ディレクトリの作成
$testOutputDir = Join-Path "C:\Temp\CHOSEISAN-Tools" "test_output"
if (-not (Test-Path $testOutputDir)) {
    New-Item -ItemType Directory -Path $testOutputDir | Out-Null
}

# --- テストヘルパー関数 ---
function Run-Test {
    param(
        [string]$TestName,
        [string]$CsvFilePath,
        [string]$ExpectedIcsFilePath = $null, # 期待されるICSファイルのパス (比較用)
        [string]$CsvEncoding = "utf-8", # デフォルトをutf-8に変更
        [switch]$IgnoreOthers,
        [switch]$ExcludeNG,
        [switch]$ExpectWarning,
        [switch]$ExpectError,
        [string]$ExpectedOutputContains = $null # 標準出力に含まれるべき文字列
    )

    Write-Host "`n--- テスト開始: $TestName ---" -ForegroundColor Cyan

    $outputIcsPath = Join-Path $testOutputDir "$($TestName).ics"
    
    $scriptParams = @{
        CsvPath = $CsvFilePath
        IcsPath = $outputIcsPath
        CsvEncoding = ([System.Text.Encoding]::GetEncoding($CsvEncoding))
        Debug = $true
    }
    if ($IgnoreOthers.IsPresent) { $scriptParams.IgnoreOthers = $true }
    if ($ExcludeNG.IsPresent) { $scriptParams.ExcludeNG = $true }

    $result = Invoke-Command -ScriptBlock {
        param(
            [string]$MainScriptPath,
            [hashtable]$Params
        )
        & $MainScriptPath @Params *>&1
    } -ArgumentList $mainScriptPath, $scriptParams -ErrorAction SilentlyContinue

    #. $MainScriptPath @scriptParams

    $testPassed = $true
    $messages = @()

    # エラー/警告のチェック
    $errors = $result | Where-Object { $_ -is [System.Management.Automation.ErrorRecord] }
    $warnings = $result | Where-Object { $_ -is [System.Management.Automation.WarningRecord] }

    if ($ExpectError) {
        if ($errors -ne $null -and $errors.Length -gt 0) {
            $messages += "[OK] エラーが期待通り発生しました。"
        } else {
            $messages += "[NG] エラーが期待されましたが発生しませんでした。"
            $testPassed = $false
        }
    } elseif ($ExpectWarning) {
        if (@($warnings).Length -gt 0) {
            $messages += "[OK] 警告が期待通り発生しました。"
        } else {
            $messages += "[NG] 警告が期待されましたが発生しませんでした。"
            $testPassed = $false
        }
    } else {
        if (($errors -ne $null -and $errors.Length -gt 0) -or ($warnings -ne $null -and $warnings.Length -gt 0)) {
            $messages += "[NG] 予期しないエラーまたは警告が発生しました。"
            $errors | ForEach-Object { $messages += "  エラー: $($_.Exception.Message)" }
            $warnings | ForEach-Object { $messages += "  警告: $($_.Message)" }
            $testPassed = $false
        } else {
            $messages += "[OK] エラーや警告は発生しませんでした。"
        }
    }

    # 出力ICSファイルの存在チェックと内容比較
    if ($ExpectedIcsFilePath) {
        if (Test-Path $outputIcsPath) {
            Start-Sleep -Milliseconds 500 # ファイル書き込み完了を待機
            $messages += "[OK] 出力ICSファイルが存在します: $outputIcsPath"
            
            $outputContent = Get-Content $outputIcsPath -Raw -Encoding UTF8
            $expectedContent = Get-Content $ExpectedIcsFilePath -Raw -Encoding UTF8
            
            # Normalize newlines to LF for consistent comparison
            $outputContent = $outputContent -replace "`r`n", "`n"
            $expectedContent = $expectedContent -replace "`r`n", "`n"

            # 期待される内容を正規表現パターンに変換 (UIDとDTSTAMPはワイルドカード)
            $expectedPatternLines = @()
            foreach ($line in ($expectedContent -split "`n")) {
                if ($line -match "^UID:.*$") {
                    $expectedPatternLines += "^UID:.*$"
                } elseif ($line -match "^DTSTAMP:.*$") {
                    $expectedPatternLines += "^DTSTAMP:.*$"
                } else {
                    $expectedPatternLines += [regex]::Escape($line)
                }
            }
            $expectedPattern = "(?m)\A" + ($expectedPatternLines -join "`n") + "\Z"

            # 実際の出力と期待されるパターンを比較
            if ($outputContent -match $expectedPattern) {
                $messages += "[OK] 出力ICSファイルの内容が期待通りです。"
            } else {
                $messages += "[NG] 出力ICSファイルの内容が期待と異なります。"
                $messages += "--- 実際の出力 ---"
                $messages += $outputContent.Split("`n")
                $messages += "--- 期待されるパターン ---"
                $messages += $expectedPattern.Split("`n")
                $testPassed = $false
            }
        } else {
            $messages += "[NG] 出力ICSファイルが存在しません。"
            $testPassed = $false
        }
    }

    # 標準出力のチェック
    if ($ExpectedOutputContains) {
        $stdout = $result | Out-String
        if ($stdout -match $ExpectedOutputContains) {
            $messages += "[OK] 標準出力に期待する文字列が含まれています。"
        } else {
            $messages += "[NG] 標準出力に期待する文字列が含まれていません。"
            $testPassed = $false
        }
    }

    if ($testPassed) {
        Write-Host "--- テスト成功: $TestName ---" -ForegroundColor Green
    } else {
        Write-Host "--- テスト失敗: $TestName ---" -ForegroundColor Red
        $messages | ForEach-Object { Write-Host $_ }
    }
    return $testPassed
}

# --- テストケース --- 
$overallSuccess = $true

# 1. 正常系テスト (UTF-8) - testdata/normal.csvを使用
# 期待されるICSファイルの内容 (normal.csv)
$expectedNormalIcsContent = @"
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//GeminiCli//ChouseisanToIcs//JA
CALSCALE:GREGORIAN
BEGIN:VEVENT
UID:*
DTSTAMP:*
SUMMARY:イベントA
DTSTART;TZID=Asia/Tokyo:20250801T100000
DTEND;TZID=Asia/Tokyo:20250801T110000
STATUS:TENTATIVE
END:VEVENT
BEGIN:VEVENT
UID:*
DTSTAMP:*
SUMMARY:イベントA
DTSTART;TZID=Asia/Tokyo:20250802T110000
DTEND;TZID=Asia/Tokyo:20250802T120000
STATUS:TENTATIVE
END:VEVENT
BEGIN:VEVENT
UID:*
DTSTAMP:*
SUMMARY:イベントA
DTSTART;TZID=Asia/Tokyo:20250803T120000
DTEND;TZID=Asia/Tokyo:20250803T130000
STATUS:TENTATIVE
END:VEVENT
END:VCALENDAR
"@

$expectedNormalIcsFilePath = Join-Path $testOutputDir "expected_normal.ics"
$expectedNormalIcsContent | Out-File -FilePath $expectedNormalIcsFilePath -Encoding UTF8

$overallSuccess = $overallSuccess -and (Run-Test -TestName "Normal_UTF8_NoOptions" `
    -CsvFilePath (Join-Path $testDataPath "normal.csv") `
    -CsvEncoding "utf-8" `
    -ExpectedIcsFilePath $expectedNormalIcsFilePath)

# 2. 正常系テスト (Shift-JIS) - chouseisan_shift-jis-dont-erase.csvを使用
# chouseisan_shift-jis-dont-erase.csv の内容に合わせた期待されるICSファイル
#$expectedShiftJISIcsContent = @"
#BEGIN:VCALENDAR
#VERSION:2.0
#PRODID:-//GeminiCli//ChouseisanToIcs//JA
#CALSCALE:GREGORIAN
#BEGIN:VEVENT
#UID:*
#DTSTAMP:*
#SUMMARY:AIセミナープロジェクトミーティング
#DTSTART;TZID=Asia/Tokyo:20250718T200000
#DTEND;TZID=Asia/Tokyo:20250718T210000
#STATUS:TENTATIVE
#END:VEVENT
#BEGIN:VEVENT
#UID:*
#DTSTAMP:*
#SUMMARY:AIセミナープロジェクトミーティング
#DTSTART;TZID=Asia/Tokyo:20250719T200000
#DTEND;TZID=Asia/Tokyo:20250719T210000
#STATUS:TENTATIVE
#END:VEVENT
#BEGIN:VEVENT
#UID:*
#DTSTAMP:*
#SUMMARY:AIセミナープロジェクトミーティング
#DTSTART;TZID=Asia/Tokyo:20250720T200000
#DTEND;TZID=Asia/Tokyo:20250720T210000
#STATUS:TENTATIVE
#END:VEVENT
#BEGIN:VEVENT
#UID:*
#DTSTAMP:*
#SUMMARY:AIセミナープロジェクトミーティング
#DTSTART;TZID=Asia/Tokyo:20250721T200000
#DTEND;TZID=Asia/Tokyo:20250721T210000
#STATUS:TENTATIVE
#END:VEVENT
#BEGIN:VEVENT
#UID:*
#DTSTAMP:*
#SUMMARY:AIセミナープロジェクトミーティング
#DTSTART;TZID=Asia/Tokyo:20250722T200000
#DTEND;TZID=Asia/Tokyo:20250722T210000
#STATUS:TENTATIVE
#END:VEVENT
#BEGIN:VEVENT
#UID:*
#DTSTAMP:*
#SUMMARY:AIセミナープロジェクトミーティング
#DTSTART;TZID=Asia/Tokyo:20250723T200000
#DTEND;TZID=Asia/Tokyo:20250723T210000
#STATUS:TENTATIVE
#END:VEVENT
#BEGIN:VEVENT
#UID:*
#DTSTAMP:*
#SUMMARY:AIセミナープロジェクトミーティング
#DTSTART;TZID=Asia/Tokyo:20250724T200000
#DTEND;TZID=Asia/Tokyo:20250724T210000
#STATUS:TENTATIVE
#END:VEVENT
#BEGIN:VEVENT
#UID:*
#DTSTAMP:*
#SUMMARY:AIセミナープロジェクトミーティング
#DTSTART;TZID=Asia/Tokyo:20250725T200000
#DTEND;TZID=Asia/Tokyo:20250725T210000
#STATUS:TENTATIVE
#END:VEVENT
#BEGIN:VEVENT
#UID:*
#DTSTAMP:*
#SUMMARY:AIセミナープロジェクトミーティング
#DTSTART;TZID=Asia/Tokyo:20250726T200000
#DTEND;TZID=Asia/Tokyo:20250726T210000
#STATUS:TENTATIVE
#END:VEVENT
#BEGIN:VEVENT
#UID:*
#DTSTAMP:*
#SUMMARY:AIセミナープロジェクトミーティング
#DTSTART;TZID=Asia/Tokyo:20250727T200000
#DTEND;TZID=Asia/Tokyo:20250727T210000
#STATUS:TENTATIVE
#END:VEVENT
#BEGIN:VEVENT
#UID:*
#DTSTAMP:*
#SUMMARY:AIセミナープロジェクトミーティング
#DTSTART;TZID=Asia/Tokyo:20250728T200000
#DTEND;TZID=Asia/Tokyo:20250728T210000
#STATUS:TENTATIVE
#END:VEVENT
#BEGIN:VEVENT
#UID:*
#DTSTAMP:*
#SUMMARY:AIセミナープロジェクトミーティング
#DTSTART;TZID=Asia/Tokyo:20250729T200000
#DTEND;TZID=Asia/Tokyo:20250729T210000
#STATUS:TENTATIVE
#END:VEVENT
#BEGIN:VEVENT
#UID:*
#DTSTAMP:*
#SUMMARY:AIセミナープロジェクトミーティング
#DTSTART;TZID=Asia/Tokyo:20250730T200000
#DTEND;TZID=Asia/Tokyo:20250730T210000
#STATUS:TENTATIVE
#END:VEVENT
#BEGIN:VEVENT
#UID:*
#DTSTAMP:*
#SUMMARY:AIセミナープロジェクトミーティング
#DTSTART;TZID=Asia/Tokyo:20250731T200000
#DTEND;TZID=Asia/Tokyo:20250731T210000
#STATUS:TENTATIVE
#END:VEVENT
#END:VCALENDAR
#"@

#$expectedShiftJISIcsFilePath = Join-Path $testOutputDir "expected_shiftjis.ics"
#$expectedShiftJISIcsContent | Out-File -FilePath $expectedShiftJISIcsFilePath -Encoding UTF8

#$overallSuccess = $overallSuccess -and (Run-Test -TestName "Normal_ShiftJIS_NoOptions" `
#    -CsvFilePath "C:\Temp\CHOSEISAN-Tools\chouseisan_shift-jis-dont-erase.csv" `
#    -CsvEncoding "shift_jis" `
#    -ExpectedIcsFilePath $expectedShiftJISIcsFilePath)

# 3. 空ファイルテスト (testdata/empty.csvを使用)
$overallSuccess = $overallSuccess -and (Run-Test -TestName "EmptyCsv" `
    -CsvFilePath (Join-Path $testDataPath "empty.csv") `
    -ExpectWarning `
    -ExpectedOutputContains "CSVファイルにヘッダー行またはデータ行がありません。")

# 4. 不正フォーマットテスト (testdata/error_format.csvを使用)
$overallSuccess = $overallSuccess -and (Run-Test -TestName "ErrorFormatCsv" `
    -CsvFilePath (Join-Path $testDataPath "error_format.csv") `
    -ExpectWarning `
    -ExpectedOutputContains "日付フォーマットを解析できませんでした。")

# 5. ExcludeNG オプションテスト (testdata/normal.csvを使用)
# normal.csvには×が含まれる行があるので、ExcludeNGを適用するとイベントが減るはず
# 期待されるICSファイルの内容 (normal.csv + ExcludeNG)
$expectedExcludeNGIcsContent = @"
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//GeminiCli//ChouseisanToIcs//JA
CALSCALE:GREGORIAN
BEGIN:VEVENT
UID:*
DTSTAMP:*
SUMMARY:イベントA
DTSTART;TZID=Asia/Tokyo:20250802T110000
DTEND;TZID=Asia/Tokyo:20250802T120000
STATUS:TENTATIVE
END:VEVENT
BEGIN:VEVENT
UID:*
DTSTAMP:*
SUMMARY:イベントA
DTSTART;TZID=Asia/Tokyo:20250803T120000
DTEND;TZID=Asia/Tokyo:20250803T130000
STATUS:TENTATIVE
END:VEVENT
END:VCALENDAR
"@

$expectedExcludeNGIcsFilePath = Join-Path $testOutputDir "expected_exclude_ng.ics"
$expectedExcludeNGIcsContent | Out-File -FilePath $expectedExcludeNGIcsFilePath -Encoding UTF8

$overallSuccess = $overallSuccess -and (Run-Test -TestName "Normal_UTF8_ExcludeNG" `
    -CsvFilePath (Join-Path $testDataPath "normal.csv") `
    -CsvEncoding "utf-8" `
    -ExcludeNG `
    -ExpectedIcsFilePath $expectedExcludeNGIcsFilePath)

# 6. IgnoreOthers オプションテスト (testdata/normal.csvを使用)
# normal.csvの最初の参加者（田中）の出欠のみを考慮
# 期待されるICSファイルの内容 (normal.csv + IgnoreOthers)
$expectedIgnoreOthersIcsContent = @"
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//GeminiCli//ChouseisanToIcs//JA
CALSCALE:GREGORIAN
BEGIN:VEVENT
UID:*
DTSTAMP:*
SUMMARY:イベントA
DTSTART;TZID=Asia/Tokyo:20250801T100000
DTEND;TZID=Asia/Tokyo:20250801T110000
STATUS:TENTATIVE
END:VEVENT
BEGIN:VEVENT
UID:*
DTSTAMP:*
SUMMARY:イベントA
DTSTART;TZID=Asia/Tokyo:20250802T110000
DTEND;TZID=Asia/Tokyo:20250802T120000
STATUS:TENTATIVE
END:VEVENT
BEGIN:VEVENT
UID:*
DTSTAMP:*
SUMMARY:イベントA
DTSTART;TZID=Asia/Tokyo:20250803T120000
DTEND;TZID=Asia/Tokyo:20250803T130000
STATUS:TENTATIVE
END:VEVENT
END:VCALENDAR
"@

$expectedIgnoreOthersIcsFilePath = Join-Path $testOutputDir "expected_ignore_others.ics"
$expectedIgnoreOthersIcsContent | Out-File -FilePath $expectedIgnoreOthersIcsFilePath -Encoding UTF8

$overallSuccess = $overallSuccess -and (Run-Test -TestName "Normal_UTF8_IgnoreOthers" `
    -CsvFilePath (Join-Path $testDataPath "normal.csv") `
    -CsvEncoding "utf-8" `
    -IgnoreOthers `
    -ExpectedIcsFilePath $expectedIgnoreOthersIcsFilePath)

# 7. ExcludeNG と IgnoreOthers の組み合わせテスト (testdata/normal.csvを使用)
# 期待されるICSファイルの内容 (normal.csv + ExcludeNG + IgnoreOthers)
$expectedCombinedIcsContent = @"
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//GeminiCli//ChouseisanToIcs//JA
CALSCALE:GREGORIAN
BEGIN:VEVENT
UID:*
DTSTAMP:*
SUMMARY:イベントA
DTSTART;TZID=Asia/Tokyo:20250802T110000
DTEND;TZID=Asia/Tokyo:20250802T120000
STATUS:TENTATIVE
END:VEVENT
BEGIN:VEVENT
UID:*
DTSTAMP:*
SUMMARY:イベントA
DTSTART;TZID=Asia/Tokyo:20250803T120000
DTEND;TZID=Asia/Tokyo:20250803T130000
STATUS:TENTATIVE
END:VEVENT
END:VCALENDAR
"@

$expectedCombinedIcsFilePath = Join-Path $testOutputDir "expected_combined.ics"
$expectedCombinedIcsContent | Out-File -FilePath $expectedCombinedIcsFilePath -Encoding UTF8

$overallSuccess = $overallSuccess -and (Run-Test -TestName "Normal_UTF8_ExcludeNG_IgnoreOthers" `
    -CsvFilePath (Join-Path $testDataPath "normal.csv") `
    -CsvEncoding "utf-8" `
    -ExcludeNG `
    -IgnoreOthers `
    -ExpectedIcsFilePath $expectedCombinedIcsFilePath)

# --- テスト結果のまとめ ---
Write-Host "`n--- 全体テスト結果 ---" -ForegroundColor White
if ($overallSuccess) {
    Write-Host "すべてのテストが成功しました！" -ForegroundColor Green
    exit 0
} else {
    Write-Host "一部のテストが失敗しました。詳細を確認してください。" -ForegroundColor Red
    exit 1
}

# 8. 年が省略された日付のテスト (UTF-8) - chouseisan_utf-8-dont-erase.csvを使用
$expectedYearOmittedIcsContent = @"
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//GeminiCli//ChouseisanToIcs//JA
CALSCALE:GREGORIAN
BEGIN:VEVENT
UID:*
DTSTAMP:*
SUMMARY:AIセミナープロジェクトミーティング
DTSTART;TZID=Asia/Tokyo:20260718T200000
DTEND;TZID=Asia/Tokyo:20260718T210000
STATUS:TENTATIVE
END:VEVENT
BEGIN:VEVENT
UID:*
DTSTAMP:*
SUMMARY:AIセミナープロジェクトミーティング
DTSTART;TZID=Asia/Tokyo:20260719T200000
DTEND;TZID=Asia/Tokyo:20260719T210000
STATUS:TENTATIVE
END:VEVENT
BEGIN:VEVENT
UID:*
DTSTAMP:*
SUMMARY:AIセミナープロジェクトミーティング
DTSTART;TZID=Asia/Tokyo:20260720T200000
DTEND;TZID=Asia/Tokyo:20260720T210000
STATUS:TENTATIVE
END:VEVENT
BEGIN:VEVENT
UID:*
DTSTAMP:*
SUMMARY:AIセミナープロジェクトミーティング
DTSTART;TZID=Asia/Tokyo:20260721T200000
DTEND;TZID=Asia/Tokyo:20260721T210000
STATUS:TENTATIVE
END:VEVENT
BEGIN:VEVENT
UID:*
DTSTAMP:*
SUMMARY:AIセミナープロジェクトミーティング
DTSTART;TZID=Asia/Tokyo:20260722T200000
DTEND;TZID=Asia/Tokyo:20260722T210000
STATUS:TENTATIVE
END:VEVENT
BEGIN:VEVENT
UID:*
DTSTAMP:*
SUMMARY:AIセミナープロジェクトミーティング
DTSTART;TZID=Asia/Tokyo:20260723T200000
DTEND;TZID=Asia/Tokyo:20260723T210000
STATUS:TENTATIVE
END:VEVENT
BEGIN:VEVENT
UID:*
DTSTAMP:*
SUMMARY:AIセミナープロジェクトミーティング
DTSTART;TZID=Asia/Tokyo:20260724T200000
DTEND;TZID=Asia/Tokyo:20260724T210000
STATUS:TENTATIVE
END:VEVENT
BEGIN:VEVENT
UID:*
DTSTAMP:*
SUMMARY:AIセミナープロジェクトミーティング
DTSTART;TZID=Asia/Tokyo:20260725T200000
DTEND;TZID=Asia/Tokyo:20260725T210000
STATUS:TENTATIVE
END:VEVENT
BEGIN:VEVENT
UID:*
DTSTAMP:*
SUMMARY:AIセミナープロジェクトミーティング
DTSTART;TZID=Asia/Tokyo:20260726T200000
DTEND;TZID=Asia/Tokyo:20260726T210000
STATUS:TENTATIVE
END:VEVENT
BEGIN:VEVENT
UID:*
DTSTAMP:*
SUMMARY:AIセミナープロジェクトミーティング
DTSTART;TZID=Asia/Tokyo:20250727T200000
DTEND;TZID=Asia/Tokyo:20250727T210000
STATUS:TENTATIVE
END:VEVENT
BEGIN:VEVENT
UID:*
DTSTAMP:*
SUMMARY:AIセミナープロジェクトミーティング
DTSTART;TZID=Asia/Tokyo:20250728T200000
DTEND;TZID=Asia/Tokyo:20250728T210000
STATUS:TENTATIVE
END:VEVENT
BEGIN:VEVENT
UID:*
DTSTAMP:*
SUMMARY:AIセミナープロジェクトミーティング
DTSTART;TZID=Asia/Tokyo:20250729T200000
DTEND;TZID=Asia/Tokyo:20250729T210000
STATUS:TENTATIVE
END:VEVENT
BEGIN:VEVENT
UID:*
DTSTAMP:*
SUMMARY:AIセミナープロジェクトミーティング
DTSTART;TZID=Asia/Tokyo:20250730T200000
DTEND;TZID=Asia/Tokyo:20250730T210000
STATUS:TENTATIVE
END:VEVENT
BEGIN:VEVENT
UID:*
DTSTAMP:*
SUMMARY:AIセミナープロジェクトミーティング
DTSTART;TZID=Asia/Tokyo:20250731T200000
DTEND;TZID=Asia/Tokyo:20250731T210000
STATUS:TENTATIVE
END:VEVENT
END:VCALENDAR
"@

$expectedYearOmittedIcsFilePath = Join-Path $testOutputDir "expected_year_omitted.ics"
$expectedYearOmittedIcsContent | Out-File -FilePath $expectedYearOmittedIcsFilePath -Encoding UTF8

$overallSuccess = $overallSuccess -and (Run-Test -TestName "Normal_UTF8_YearOmitted" `
    -CsvFilePath "C:\Temp\CHOSEISAN-Tools\chouseisan_utf-8-dont-erase.csv" `
    -CsvEncoding "utf-8" `
    -ExpectedIcsFilePath $expectedYearOmittedIcsFilePath)