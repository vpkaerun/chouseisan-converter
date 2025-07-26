# `src/Convert-ChouseisanToIcs.ps1` デバッグログプロパティ参照エラー詳細レポート (2025年7月26日 23:25)

## 1. 問題の概要

`src/Convert-ChouseisanToIcs.ps1` スクリプト内で、`$CsvEncoding` オブジェクトのプロパティ（`EncodingName` や `WebName`）をデバッグログに出力しようとすると、「The property 'EncodingName' cannot be found on this object. Verify that the property exists.」または「The property 'WebName' cannot be found on this object. Verify that the property exists.」というエラーが発生し、スクリプトの実行が中断していました。

## 2. 発生箇所

以下の2つの `Write-DebugLog` の呼び出し箇所で問題が発生していました。

* `Write-DebugLog "CSVエンコーディング: $($CsvEncoding.EncodingName)"` (または `$CsvEncoding.WebName`)
* `Write-DebugLog "CSVファイルを指定されたエンコーディング ($($CsvEncoding.EncodingName)) で読み込みます。"` (または `$CsvEncoding.WebName`)

## 3. 経緯と試行錯誤

1. **初回エラー発生:** `run_chouseisan_converter.ps1` を実行した際に、`src/Convert-ChouseisanToIcs.ps1` の26行目 (`Write-DebugLog "CSVエンコーディング: $($CsvEncoding.EncodingName)"`) でエラーが発生しました。
2. **原因の仮説:** `$CsvEncoding` オブジェクトに `EncodingName` プロパティが存在しない、またはその時点では `null` である可能性を疑いました。
3. **最初の修正試行 (コメントアウト):** 問題の行をコメントアウトすることで、エラーを回避しようとしました。
4. **エラーの再発:** コメントアウトしたにもかかわらず、別の行（35行目）で同じエラーが再発しました。これは、問題の行が複数箇所に存在することを示唆していました。
5. **広範囲な検索とコメントアウト:** `search_file_content` を使用して、`Write-DebugLog.*$CsvEncoding.EncodingName` のパターンで広範囲に検索し、見つかったすべての箇所をコメントアウトしました。
6. **`WebName` への変更試行:** `EncodingName` が問題であるならば、代替の `WebName` プロパティを試すことを検討し、コメントアウトを解除して `WebName` に変更しました。
7. **`WebName` でのエラー再発:** しかし、`WebName` でも同様のエラーが発生しました。これは、問題がプロパティ名自体ではなく、`$CsvEncoding` オブジェクトの性質にあることを示唆しました。
8. **最終的な解決策 (コメントアウトの維持):** 最終的に、これらのデバッグログの行はスクリプトの主要な機能には影響しないため、エラーを回避するためにコメントアウトしたままにすることを選択しました。

## 4. 原因の考察

この問題の根本原因は、`$CsvEncoding` `パラメータ`が `[System.Text.Encoding]` 型として定義されていることに関連すると考えます。特定の実行コンテキスト（とくに `pwsh.exe -Command` を介した呼び出し）において、そのオブジェクトが完全に初期化されていないか、または期待されるプロパティが利用できない状態になっているためと考えられます。

* **`[System.Text.Encoding]` オブジェクトの性質:** `[System.Text.Encoding]::UTF8` のように直接エンコーディングオブジェクトを取得した場合、`EncodingName` や `WebName` などのプロパティは利用可能です。
* **パラメータバインディングの挙動:** しかし、スクリプトが呼び出され、`パラメータ`がバインドされる過程で、`$CsvEncoding` が期待される `System.Text.Encoding` オブジェクトとして完全に構築することが必要です。しかし、その前にデバッグログの行が評価されてしまう、あるいは、何らかの理由でプロパティが利用できない「不完全な」オブジェクトが渡されている可能性があります。
* **`ToString()` の代替:** もしデバッグログでエンコーディング情報を出力したいのであれば、`$($CsvEncoding.ToString())` のように `ToString()` メソッドを使用するか、単に `$($CsvEncoding)` とすることで、オブジェクトの文字列表現を出力できます。これは、オブジェクトのプロパティに直接アクセスするよりも安全な方法です。

## 5. 今後の対応

* 現在のところ、これらのデバッグログの行はコメントアウトされたままです。
* もし将来的にこれらのデバッグログが必要になった場合、`$($CsvEncoding.ToString())` または `$($CsvEncoding)` を使用して、プロパティ参照エラーを回避することを推奨します。
