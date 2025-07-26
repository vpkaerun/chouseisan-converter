param(
    [string]$CsvPath,
    [string]$IcsPath,
    [System.Text.Encoding]$CsvEncoding,
    [switch]$IgnoreOthers,
    [switch]$ExcludeNG,
    [switch]$Debug
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"


# --- デバッグ関数 ---
function Write-DebugLog {
    param([string]$Message)
    if ($Debug) {
        Write-Host "DEBUG: $Message" -ForegroundColor Yellow
    }
}

# --- スクリプト開始 ---
Write-DebugLog "スクリプトを開始します。"
Write-DebugLog "入力CSV: $CsvPath"
Write-DebugLog "出力ICS: $IcsPath"
# Write-DebugLog "CSVエンコーディング: $($CsvEncoding.WebName)"

# 1. 入力ファイル存在チェック
if (-not (Test-Path $CsvPath)) {
    Write-Error "指定されたCSVファイルが見つかりません: $CsvPath"
    exit 1
}

# 2. CSVファイル読み込み
# Write-DebugLog "CSVファイルを指定されたエンコーディング ($($CsvEncoding.WebName)) で読み込みます。"
$csvContent = Get-Content $CsvPath -Encoding $CsvEncoding
Write-DebugLog "CSVファイル読み込み完了。行数: $($csvContent.Length)"

if ($csvContent.Length -lt 4) {
    Write-Warning "CSVファイルにヘッダー行またはデータ行がありません。処理を終了します。"
    exit 0
}

# 3. 件名とヘッダーの取得
$summary = $csvContent[0]
# CSVの2行目が空行であるためスキップし、3行目をヘッダーとして取得
$headerLine = $csvContent[2]
$dataRows = $csvContent[3..($csvContent.Length - 1)]

Write-DebugLog "イベント件名: $summary"
Write-DebugLog "ヘッダー行: $headerLine"

# CSVのヘッダーを動的に取得
$headers = $headerLine.Split(',')

# 4. ICSファイル初期化
$ics = @(
    "BEGIN:VCALENDAR"
    "VERSION:2.0"
    "PRODID:-//GeminiCli//ChouseisanToIcs//JA"
    "CALSCALE:GREGORIAN"
)

# 5. データ行ループとイベント生成
foreach ($row in $dataRows) {
    if ([string]::IsNullOrWhiteSpace($row)) {
        Write-DebugLog "空行をスキップしました。"
        continue
}

    $fields = $row.Split(',')
    $dateString = $fields[0]
    if ($fields.Length -gt 1) {
        $statuses = $fields[1..($fields.Length - 1)]
    } else {
        $statuses = @()
    }

    Write-DebugLog "処理中の行: $row"

    # --- フィルタリングロジック ---
    # 1. ExcludeNG: '×' があれば無条件でスキップ
    if ($ExcludeNG -and $statuses -contains '×') {
        Write-DebugLog "フィルタ(ExcludeNG): '×'が含まれるためスキップします。"
        continue
    }

    # 2. 対象となるステータスを決定
    $targetStatuses = $statuses
    if ($IgnoreOthers) {
        $targetStatuses = @($statuses[0]) # 最初の参加者のみ
        Write-DebugLog "フィルタ(IgnoreOthers): 最初の参加者のみを評価します。"
    }

    # 3. 参加可否を判断 ('◯'または'△'があればOK)
    $isCandidate = $targetStatuses | Where-Object { $_ -eq '◯' -or $_ -eq '△' }
    if (-not $isCandidate) {
        Write-DebugLog "フィルタ: 参加可能な予定（◯/△）が見つからないためスキップします。"
        continue
    }

    # --- 日付解析とイベント生成 ---
    try {
        # 年が省略されている場合も考慮した正規表現
        if ($dateString -match '((?:\d{1,4}/)?\d{1,2}/\d{1,2})(?:.*)?\s*(\d{2}:\d{2})(?:.*)?') {
            $datePart = $matches[1]
            $timePart = $matches[2]

            # 年が省略されている場合（例: 7/18）は現在の年を補完
            if ($datePart -notmatch '^\d{4}/\d{1,2}/\d{1,2}$') {
                $currentYear = (Get-Date).Year
                $datePart = "$currentYear/$datePart"
                $startDateTime = [datetime]::Parse("$datePart $timePart", [System.Globalization.CultureInfo]::InvariantCulture)

                # 解析された日付が現在よりも過去の場合、年を1年進める
                if ($startDateTime -lt (Get-Date).Date) {
                    $startDateTime = $startDateTime.AddYears(1)
                }
            } else {
                # 年が指定されている場合はそのまま解析
                $format = "yyyy/MM/dd HH:mm"
                $startDateTime = [datetime]::ParseExact("$datePart $timePart", $format, [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::AssumeLocal)
            }
            $endDateTime = $startDateTime.AddHours(1)

            Write-DebugLog "解析された開始日時: $startDateTime"

            # ICSイベント生成
            $dtstamp = (Get-Date).ToUniversalTime().ToString("yyyyMMddTHHmmssZ")
            $uid = [guid]::NewGuid()

            $ics += "BEGIN:VEVENT"
            $ics += "UID:$uid"
            $ics += "DTSTAMP:$dtstamp"
            $ics += "SUMMARY:$summary"
            $ics += "DTSTART;TZID=Asia/Tokyo:" + $startDateTime.ToString("yyyyMMddTHHmmss")
            $ics += "DTEND;TZID=Asia/Tokyo:" + $endDateTime.ToString("yyyyMMddTHHmmss")
            $ics += "STATUS:TENTATIVE"
            $ics += "END:VEVENT"
        } else {
            Write-Warning "日付フォーマットを解析できませんでした。スキップします: $dateString"
        }
    } catch {
        Write-Warning "行の処理中にエラーが発生しました。スキップします: $row. エラー: $_"
    }
}

# 6. ICSファイル書き出し
$ics += "END:VCALENDAR"

Write-DebugLog "ICSファイルをUTF-8で書き出します: $IcsPath"
$ics | Out-File -FilePath $IcsPath -Encoding UTF8

Write-Host "ICSファイルの生成が完了しました: $IcsPath" -ForegroundColor Green