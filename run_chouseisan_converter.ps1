# 調整さんCSV to ICS コンバーター実行スクリプト

# このスクリプトは、プロジェクトルートにある chouseisan.csv を chouseisan.ics に変換します。
# 変換オプションを対話的に選択できます。

# メインの変換スクリプトのパス
# $PSScriptRoot は現在のスクリプトが置かれているディレクトリのパスを返します。
$mainScriptPath = Join-Path $PSScriptRoot "src\Convert-ChouseisanToIcs.ps1"

# デフォルトの入力CSVと出力ICS
$csvPath = Join-Path $PSScriptRoot "chouseisan_utf-8-dont-erase.csv"
$icsPath = Join-Path $PSScriptRoot "chouseisan.ics"

Write-Host "調整さんCSV to ICS コンバーターを実行します。" -ForegroundColor Cyan
Write-Host "入力ファイル: $csvPath" -ForegroundColor Cyan
Write-Host "出力ファイル: $icsPath" -ForegroundColor Cyan
Write-Host ""

# IgnoreOthers オプションの確認
$useIgnoreOthers = Read-Host "最初の参加者（CSVの3列目）の出欠のみを考慮しますか？ (y/N)"
if ($useIgnoreOthers -eq 'y' -or $useIgnoreOthers -eq 'Y') {
    $ignoreOthersParam = "-IgnoreOthers"
    Write-Host "-> '最初の参加者のみ考慮' オプションを有効にします。" -ForegroundColor Green
} else {
    $ignoreOthersParam = ""
    Write-Host "-> '最初の参加者のみ考慮' オプションは無効です。" -ForegroundColor DarkYellow
}

# ExcludeNG オプションの確認
$useExcludeNG = Read-Host "誰か一人でも「×」を付けている日程を除外しますか？ (y/N)"
if ($useExcludeNG -eq 'y' -or $useExcludeNG -eq 'Y') {
    $excludeNGParam = "-ExcludeNG"
    Write-Host "-> '×が付いている日程を除外' オプションを有効にします。" -ForegroundColor Green
} else {
    $excludeNGParam = ""
    Write-Host "-> '×が付いている日程を除外' オプションは無効です。" -ForegroundColor DarkYellow
}

Write-Host ""

# CSVエンコーディングの確認
$csvEncodingInput = Read-Host "入力CSVファイルのエンコーディングを選択してください (1: UTF-8, 2: Shift-JIS) [デフォルト: 1]"
$csvEncodingParam = ""
switch ($csvEncodingInput) {
    "2" {
        $csvEncodingString = "shift_jis"
        Write-Host "-> CSVエンコーディング: Shift-JIS" -ForegroundColor Green
    }
    default {
        $csvEncodingString = "utf-8"
        Write-Host "-> CSVエンコーディング: UTF-8" -ForegroundColor Green
    }
}

# 文字列のエンコーディング名を System.Text.Encoding オブジェクトに変換
$csvEncodingObject = [System.Text.Encoding]::GetEncoding($csvEncodingString)

Write-Host ""
Write-Host "変換を開始します..." -ForegroundColor Cyan

# メインスクリプトの実行
# & 演算子を使ってスクリプトを直接呼び出す
& $mainScriptPath -CsvPath $csvPath -IcsPath $icsPath -CsvEncoding $csvEncodingObject $ignoreOthersParam $excludeNGParam

Write-Host ""
Write-Host "処理が完了しました。'$icsPath' が生成されました。" -ForegroundColor Green
