# test.ps1 (日付解析正規表現の単体テスト)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$OutputEncoding = [System.Text.Encoding]::UTF8

# テスト対象の正規表現
$regexPattern = '((?:\d{1,4}/)?\d{1,2}/\d{1,2})(?:.*)?\s*(\d{2}:\d{2})(?:.*)?'

# テストケース
$testCases = @(
    @{ Input = "2025/07/25(金) 10:00〜"; ExpectedDate = "2025/07/25"; ExpectedTime = "10:00"; Name = "Full_Date_Time" },
    @{ Input = "7/25(金) 10:00〜"; ExpectedDate = "7/25"; ExpectedTime = "10:00"; Name = "Year_Omitted_Date_Time" },
    @{ Input = "2025/07/25 10:00"; ExpectedDate = "2025/07/25"; ExpectedTime = "10:00"; Name = "Full_Date_Time_No_Suffix" },
    @{ Input = "7/25 10:00"; ExpectedDate = "7/25"; ExpectedTime = "10:00"; Name = "Year_Omitted_Date_Time_No_Suffix" }
)

$overallSuccess = $true

foreach ($testCase in $testCases) {
    Write-Host "`n--- テスト開始: $($testCase.Name) ---" -ForegroundColor Cyan
    $inputString = $testCase.Input
    $testPassed = $true
    $messages = @()

    if ($inputString -match $regexPattern) {
        $capturedDate = $matches[1]
        $capturedTime = $matches[2]

        if ($capturedDate -eq $testCase.ExpectedDate) {
            $messages += "[OK] 日付部分が期待通りにキャプチャされました: '$capturedDate'"
        } else {
            $messages += "[NG] 日付部分が期待と異なります。期待: '$($testCase.ExpectedDate)', 実際: '$capturedDate'"
            $testPassed = $false
        }

        if ($capturedTime -eq $testCase.ExpectedTime) {
            $messages += "[OK] 時刻部分が期待通りにキャプチャされました: '$capturedTime'"
        } else {
            $messages += "[NG] 時刻部分が期待と異なります。期待: '$($testCase.ExpectedTime)', 実際: '$capturedTime'"
            $testPassed = $false
        }
    } else {
        $messages += "[NG] 正規表現が入力文字列にマッチしませんでした: '$inputString'"
        $testPassed = $false
    }

    if ($testPassed) {
        Write-Host "--- テスト成功: $($testCase.Name) ---" -ForegroundColor Green
    } else {
        Write-Host "--- テスト失敗: $($testCase.Name) ---" -ForegroundColor Red
        $messages | ForEach-Object { Write-Host $_ }
        $overallSuccess = $false
    }
}

Write-Host "`n--- 全体テスト結果 ---" -ForegroundColor White
if ($overallSuccess) {
    Write-Host "すべての正規表現テストが成功しました！" -ForegroundColor Green
    exit 0
} else {
    Write-Host "一部の正規表現テストが失敗しました。詳細を確認してください。" -ForegroundColor Red
    exit 1
}