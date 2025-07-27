# 開発ガイドライン

## 1. プロジェクトの目的と概要

このドキュメントは、調整さんCSV to ICSコンバータープロジェクトにおける開発者向けのガイドライン、コーディング規約、および過去のデバッグから得られた重要な教訓と再発防止策をまとめたものです。プロジェクトの目的は、調整さんからエクスポートしたCSV形式の出欠表を、Outlookなどのカレンダーアプリにインポート可能なiCalendar（.ics）形式のファイルに変換するPowerShellスクリプトを開発することです。

## 2. ファイルおよび`フォルダ`構成ルール

プロジェクトの整合性を保つため、以下のファイルおよび`フォルダ`構成ルールを適用します。

### 2.1. ルート構成

```plaintext
/ (project_root)
├── .gitignore
├── chouseisan_shift-jis-dont-erase.csv
├── chouseisan_utf-8-dont-erase.csv
├── chouseisan.csv
├── chouseisan.ics
├── README.md
├── reflection.md
├── run_chouseisan_converter.ps1
├── test-chouseisan-converter.ps1
├── test.ps1
├── .git/
├── archive/
│   ├── 20250717_0857-log-調整さんcsv-ics-conv-powershell-tools-dev.md
│   ├── chouseisan_utf8.csv
│   ├── chouseisan.csv
│   ├── chouseisan.csv_utf8.csv
│   ├── chouseisan.ics
│   ├── Convert-ChouseisanToIcs_20250725.ps1.txt
│   ├── debug_report_20250725.md.txt
│   ├── get_powershell_info.ps1
│   ├── normal.ics
│   ├── reflection.txt
│   ├── terminal.txt
│   ├── test_20250725.ps1.txt
│   └── test.ps1.txt
├── docs/
│   ├── 20250717_0900-requirements-chouseisan_tool.md
│   ├── 20250717_0900-rule-folders_and_files.md
│   ├── 20250717_0930-log-dev-history.md
│   ├── 20250717_0945-guide-powershell_execution.md
│   ├── csv_specification.md
│   ├── debug_hints_from_gemini-2.5-flash_20250726_0532.md
│   ├── debug_hints_from_gemini-2.5-pro_20250726_0520.md
│   ├── debug_report_20250725_final.md
│   ├── debug_report_20250725.md
│   ├── debug_report_20250726_2310_date_parsing_error.md
│   ├── debug_report_20250726_2315_date_parsing_error.md
│   ├── debug_report_20250726_2325_date_parsing_error.md
│   ├── debug_report_20250726_2330_minimal_feature_set_completed.md
│   ├── debug_report_20250727_0005_encoding_property_error.md
│   ├── environment.md
│   ├── project_handbook.md
│   ├── requirements.md
│   ├── usage.md
│   └── development/
│       ├── coding_guidelines.md  <-- これを development_guidelines.md にリネーム
│       ├── plan_20250725_minimal_feature_set.md
│       ├── plan_20250726_2335_document_reorganization.md
│       └── plan_20250726_2340_document_reorganization.md
├── src/
│   └── Convert-ChouseisanToIcs.ps1
├── test_output/
│   ├── actual_normal.ics
│   ├── actual_year_omitted.ics
│   ├── Date_Formats_Test.ics
│   ├── debug_chouseisan_output.ics
│   ├── debug_empty.ics
│   ├── debug_error_format.ics
│   ├── debug_normal_output.ics
│   ├── debug_shiftjis.ics
│   ├── EmptyCsv_stderr.txt
│   ├── EmptyCsv_stdout.txt
│   ├── ErrorFormatCsv.ics
│   ├── expected_combined.ics
│   ├── expected_empty.ics
│   ├── expected_exclude_ng.ics
│   ├── expected_ignore_others.ics
│   ├── expected_normal.ics
│   ├── expected_shiftjis.ics
│   ├── Normal_ShiftJIS_NoOptions_stderr.txt
│   ├── Normal_ShiftJIS_NoOptions_stdout.txt
│   ├── Normal_ShiftJIS_NoOptions.ics
│   ├── Normal_UTF8_ExcludeNG_IgnoreOthers.ics
│   ├── Normal_UTF8_ExcludeNG.ics
│   ├── Normal_UTF8_IgnoreOthers.ics
│   ├── Normal_UTF8_NoOptions_stderr.txt
│   ├── Normal_UTF8_NoOptions_stdout.txt
│   ├── Normal_UTF8_NoOptions.ics
│   ├── normal.ics
│   ├── SimpleWarningTest_stderr.txt
│   ├── SimpleWarningTest_stdout.txt
│   ├── SimpleWarningTest.ics
│   └── temp_shiftjis.csv
└── testdata/
    ├── date_formats.csv
    ├── empty.csv
    └── normal.csv
```

### 2.2. バックアップおよびアーカイブルール

*   **`archive/` `フォルダ`:**
    *   過去のファイルや一時ファイルを保存するための場所です。
    *   **AIエージェントは、原則としてこの`フォルダ`内のファイルを通常業務の対象外とします。**
    *   **ファイル管理ルール:** 一時ファイルや不要になったファイルは、削除するのではなく、日付をつけて `archive/` ディレクトリに移動することを必須ルールとします。
    *   **アーカイブ先:** `archive/docs_archive/YYYYMMDD/` のような新しいサブディレクトリを作成し、そこに移動します。

### 2.3. ファイル命名規則

**コアドキュメント（常時参照されるもの）:**

*   ファイル名: `descriptive_name.md`
    *   例: `project_handbook.md`, `development_guidelines.md`, `csv_specification.md`
    *   特徴: 小文字、スネークケースを使用し、内容を簡潔に表します。日付は含めません（内容が更新されるため）。

**日付付きレポート/ログ:**

*   ファイル名: `YYYYMMDD_descriptive_name.md`
    *   例: `20250726_debug_report_minimal_feature_set_completed.md`
    *   特徴: `YYYYMMDD` 形式で日付をプレフィックスとして付与し、その後に内容を簡潔に表します。

## 3. コーディング規約とベストプラクティス

### 3.1. PowerShell スクリプト開発

#### 3.1.1. `param()` ブロックの配置

*   **ルール:** `param()` ブロックは、スクリプトの**最先頭**に配置してください。
*   **理由:** PowerShellは `param()` ブロックをスクリプトの先頭で解析します。これより前に他のコード（変数宣言、関数定義、`Set-StrictMode` など）があると、解析エラーが発生する可能性があります。
*   **再発防止:** このルールを破ると、`ParserError` が発生する可能性があります。

#### 3.1.2. `パラメータ`の型指定とデフォルト値

*   **ルール:** スクリプトの`パラメータ`には、可能な限り厳密な型指定を行ってください。デフォルト値がない場合は、その旨を明記するか、`必須パラメータ`であることを明確にしてください。
*   **理由:** 型の不一致によるエラー（例: 文字列から `System.Text.Encoding` への変換エラー）を防ぎます。
*   **再発防止:** `run_chouseisan_converter.ps1` で発生した `CsvEncoding` `パラメータ`のエラーは、このルールの重要性を示しています。

#### 3.1.3. 出力ストリームのハンドリング

*   **ルール:** スクリプトの出力をキャプチャする際は、成功ストリームだけでなく、エラー、警告、デバッグストリームも考慮し、適切にリダイレクト（`*>&1`）およびフィルタリングしてください。
*   **理由:** エラーや警告を見逃さず、テストの信頼性を高めるためです。
*   **再発防止:** `test-chouseisan-converter.ps1` での警告メッセージキャプチャ問題は、ストリームハンドリングの重要性を示しています。`@($variable).Length` のような配列キャストも有効な手段です。

#### 3.1.4. `replace` ツールの使用法

*   **ルール:** `replace` ツールを使用する際は、`old_string` がターゲットファイル内の内容と**完全に一致する**ことを確認してください。これには、空白、インデント、改行コード、特殊文字も含まれます。
*   **理由:** 不一致による置換失敗を防ぐためです。
*   **再発防止:** 操作前に `read_file` で最新の内容を確認し、`old_string` を正確にコピーして使用してください。変更範囲は最小限に留め、`expected_replacements` `パラメータ`を適切に指定してください。

#### 3.1.5. デバッグログの安全性

*   **ルール:** デバッグログでオブジェクトのプロパティにアクセスする際は、プロパティが存在しない場合のエラーを避けるため、`$($Object.ToString())` や `$($Object)` のように、オブジェクトの文字列表現を出力する方法を優先してください。
*   **理由:** スクリプトの実行中に予期せぬエラーが発生するのを防ぐためです。
*   **再発防止:** `$CsvEncoding.EncodingName` のようなプロパティアクセスは、オブジェクトのライフサイクルによっては失敗する可能性があるため、注意が必要です。

#### 3.1.6. 複雑なロジックの単体テスト

*   **ルール:** 正規表現、日付解析、複雑なフィルタリングロジックなど、複雑な処理は、本体コードに組み込む前に、**専用の最小限の `test.ps1` スクリプトで単体テストを徹底**してください。
*   **理由:** 問題の早期発見と、修正の検証を効率化するためです。
*   **再発防止:** 今回の正規表現の単体テスト成功が、このアプローチの有効性を示しました。

## 4. デバッグで得られた重要な教訓と再発防止策

### 4.1. PowerShell の `param()` ブロック解析エラーの再発と解決

*   **問題:** `param()` ブロックがスクリプトの先頭にないと解析エラーが発生する。
*   **解決策:** `param()` ブロックをスクリプトの最先頭に配置する。
*   **教訓:** PowerShellの構文規則は厳密であり、`param()` ブロックの配置は非常に重要です。

### 4.2. `Normal_UTF8_NoOptions` テストの時刻解析エラーと解決

*   **問題:** 時刻解析で `[datetime]::Parse()` が期待通りに動作せず、時刻がずれる。
*   **解決策:** `[datetime]::ParseExact()` を使用し、フォーマット文字列を `HH:mm` に変更する。
*   **教訓:** 日付/時刻の解析には、`ParseExact` を使用し、フォーマット文字列を正確に指定することが重要です。

### 4.3. `EmptyCsv` テストの警告メッセージキャプチャ問題と解決

*   **問題:** 警告メッセージが `$result` 変数に正しくキャプチャされない。
*   **解決策:** `Invoke-Command` で `*>&1` を使用し、すべてのストリームをキャプチャ。キャプチャされた変数は `@(...)` で配列にキャストしてからプロパティにアクセスする。
*   **教訓:** PowerShellのストリーム処理とオブジェクトの型安全な操作を理解することが重要です。

### 4.4. デバッグログの `EncodingName` プロパティ問題と解決

*   **問題:** デバッグログで `$CsvEncoding.EncodingName` にアクセスするとエラーが発生する。
*   **解決策:** `$CsvEncoding.WebName` を使用するか、`$($CsvEncoding.ToString())` で出力する。
*   **教訓:** オブジェクトのプロパティは、実行コンテキストによって利用できない場合があるため、安全な出力方法を検討する。

### 4.5. `run_chouseisan_converter.ps1` の `CsvEncoding` `パラメータ`型変換エラー

*   **問題:** 文字列のエンコーディング名を `System.Text.Encoding` オブジェクトに変換せずに渡していた。
*   **解決策:** `[System.Text.Encoding]::GetEncoding（）` を使用して文字列をオブジェクトに変換してから渡す。
*   **教訓:** `パラメータ`の型を厳密に合わせることが重要です。

### 4.6. `chouseisan_utf-8-dont-erase.csv` の日付解析正規表現の不備

*   **問題:** 年が省略された日付形式 (`MM/DD`) が正規表現で正しく解析されない。
*   **解決策:** 正規表現を `'((?:\d{1,4}/)?\d{1,2}/\d{1,2})(?:.*)?\s*(\d{2}:\d{2})(?:.*)?'` に修正する。
*   **教訓:** 複雑なパターンマッチングは、事前に単体テストで検証することが不可欠です。

## 5. 今後の開発における注意点

*   **ドキュメントの更新:** 新しい機能追加や仕様変更があった場合は、関連するドキュメント（`project_handbook.md`, `development_guidelines.md`, `csv_specification.md` など）を速やかに更新する。
*   **テストの追加:** 新機能や修正には、必ず対応するテストケースを追加し、既存のテストスイートを維持・強化する。
*   **ファイル管理:** 一時ファイルや不要なファイルは、削除せずに `archive/` ディレクトリに日付をつけて移動するルールを遵守する。
*   **WSL 環境での文字化け:** PowerShellの出力における文字化けは、表示上の問題として認識し、スクリプトの機能に影響しない限り、許容する。ただし、デバッグログの出力方法には注意を払う。

## 6. ドキュメント命名規則と整理計画

### 6.1. ドキュメント命名規則

**コアドキュメント（常時参照されるもの）:**

*   ファイル名: `descriptive_name.md`
    *   例: `project_handbook.md`, `development_guidelines.md`, `csv_specification.md`
    *   特徴: 小文字、スネークケースを使用し、内容を簡潔に表します。日付は含めません（内容が更新されるため）。

**日付付きレポート/ログ:**

*   ファイル名: `YYYYMMDD_descriptive_name.md`
    *   例: `20250726_debug_report_minimal_feature_set_completed.md`
    *   特徴: `YYYYMMDD` 形式で日付をプレフィックスとして付与し、その後に内容を簡潔に表します。

### 6.2. ドキュメント整理計画

**1. 主要ドキュメントの統合と再構築:**

*   **`docs/project_handbook.md` の新規作成:**
    *   プロジェクトの全体像、目的、主要機能、使い方、必須環境をまとめる。
    *   `README.md`、`usage.md`、`environment.md`、`requirements.md` の内容を統合。
*   **`docs/development/development_guidelines.md` への名称変更と強化:**
    *   既存の `docs/development/coding_guidelines.md` をリネーム。
    *   コーディング規約、ベストプラクティス、デバッグの教訓（再発防止策）を統合。
    *   `docs/20250717_0900-rule-folders_and_files.md` の内容を統合。
    *   新しいドキュメント命名規則に関するセクションを追加。
*   **`docs/debug_history.md` の新規作成:**
    *   これまでの全ての `debug_report_*.md` および `debug_hints_*.md` ファイルの内容を時系列で簡潔に要約。
    *   主要な問題、解決策、教訓を一覧化し、詳細レポートへのリンクを記載。

**2. ファイルのアーカイブ:**

*   **アーカイブ先ディレクトリの作成:** `archive/docs_archive/YYYYMMDD/` (例: `archive/docs_archive/20250726/`) を新規作成。
*   **アーカイブ対象ファイル:**
    *   `README.md` (project_handbook.md に統合)
    *   `docs/requirements.md`
    *   `docs/usage.md`
    *   `docs/environment.md`
    *   `docs/20250717_0900-requirements-chouseisan_tool.md`
    *   `docs/20250717_0900-rule-folders_and_files.md`
    *   `docs/20250717_0930-log-dev-history.md`
    *   `docs/20250717_0945-guide-powershell_execution.md`
    *   `docs/debug_report_20250725.md`
    *   `docs/debug_report_20250725_final.md`
    *   `docs/debug_report_20250726_2310_date_parsing_error.md`
    *   `docs/debug_report_20250726_2315_date_parsing_error.md`
    *   `docs/debug_report_20250726_2325_date_parsing_error.md`
    *   `docs/debug_report_20250726_2330_minimal_feature_set_completed.md`
    *   `docs/debug_report_20250727_0005_encoding_property_error.md`
    *   `docs/debug_hints_from_gemini-2.5-flash_20250726_0532.md`
    *   `docs/debug_hints_from_gemini-2.5-pro_20250726_0520.md`
    *   `docs/development/plan_20250725_minimal_feature_set.md`
    *   `reflection.md`
    *   `archive/` ディレクトリ内の既存の `.txt` ファイル（`test_output` 内を除く）
*   **アーカイブ方法:** ファイルを削除せず、日付をつけて移動する。

**2.3. 既存ファイルへの参照の更新**

*   新しいドキュメント構造に合わせて、コード内のコメントや他のドキュメントからの参照パスを更新する。

**3. 実施順序**

1.  `docs/project_handbook.md` の新規作成。
2.  `docs/development/development_guidelines.md` への名称変更と内容更新。
3.  `docs/debug_history.md` の新規作成。
4.  アーカイブ対象ファイルの移動。
5.  参照パスの更新。