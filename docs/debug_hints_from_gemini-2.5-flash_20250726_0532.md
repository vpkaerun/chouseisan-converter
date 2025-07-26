Certainly, I can help you with the PowerShell code. It looks like you're working on a script to convert "Chouseisan" CSV files to iCalendar (.ics) format and have developed a comprehensive testing script for it. I'll focus on your "EmptyCsv" test failure and offer guidance on capturing warning messages.

Here's an analysis of the issue and potential solutions:

### Understanding the `EmptyCsv` Test Failure

You mentioned that the "EmptyCsv" test fails because the expected warning message "CSVファイルにヘッダー行またはデータ行がありません。" is not captured by `$result` when using `Invoke-Command` with `2>&1`.

[cite\_start]The `Run-Test` function in `test-chouseisan-converter.ps1` uses `Invoke-Command -ScriptBlock { & $MainScriptPath @Params } -ArgumentList $mainScriptPath, $scriptParams -ErrorAction SilentlyContinue 2>&1` to execute your main script. [cite: 16]

The `2>&1` redirect aims to merge the error stream (stream 2) into the success stream (stream 1). However, `Write-Warning` outputs to the warning stream (stream 3), not the error stream. This is why `2>&1` isn't capturing your warning.

### Proposed Solutions for Capturing Warning Messages

To reliably capture warning messages from `Write-Warning` when invoking a script, you need to redirect the warning stream.

Here are a few approaches:

#### 1\. Redirect All Streams to Success Stream (`*>&1`)

This is often the most straightforward way to capture all output, including success, error, warning, verbose, and debug streams, into the success stream.

**Modification in `test-chouseisan-converter.ps1`:**

Change this line in `Run-Test`:

```powershell
$result = Invoke-Command -ScriptBlock {
    param(
        [string]$MainScriptPath,
        [hashtable]$Params
    )
    & $MainScriptPath @Params
} -ArgumentList $mainScriptPath, $scriptParams -ErrorAction SilentlyContinue 2>&1
```

to:

```powershell
$result = Invoke-Command -ScriptBlock {
    param(
        [string]$MainScriptPath,
        [hashtable]$Params
    )
    & $MainScriptPath @Params *>&1 # Redirect all streams to success
} -ArgumentList $mainScriptPath, $scriptParams -ErrorAction SilentlyContinue
```

By redirecting all streams (`*>&1`), any output from `Write-Warning` will be included in the `$result` variable. [cite\_start]You can then filter `$result` for `System.Management.Automation.WarningRecord` objects to check for the expected warning message. [cite: 18, 19]

#### 2\. Explicitly Redirect Warning Stream (`3>&1`)

If you only want to capture the warning stream specifically, you can redirect stream 3 (warning) to stream 1 (success).

**Modification in `test-chouseisan-converter.ps1`:**

Change this line in `Run-Test`:

```powershell
$result = Invoke-Command -ScriptBlock {
    param(
        [string]$MainScriptPath,
        [hashtable]$Params
    )
    & $MainScriptPath @Params
} -ArgumentList $mainScriptPath, $scriptParams -ErrorAction SilentlyContinue 2>&1
```

to:

```powershell
$result = Invoke-Command -ScriptBlock {
    param(
        [string]$MainScriptPath,
        [hashtable]$Params
    )
    & $MainScriptPath @Params 3>&1 # Redirect warning stream to success
} -ArgumentList $mainScriptPath, $scriptParams -ErrorAction SilentlyContinue
```

Similar to `*>&1`, the warning messages will then be part of `$result`.

#### 3\. Capture Warning Stream to a Separate Variable (More Advanced)

While `*>&1` or `3>&1` are generally sufficient for testing, if you need to separate warnings from other output types directly, you can use the `-WarningVariable` parameter on `Invoke-Command` or redirect to a specific stream variable. However, for an `Invoke-Command -ScriptBlock` scenario where the script being invoked (`$MainScriptPath`) is generating the warning, capturing it directly from the outer `Invoke-Command`'s output is usually simpler.

[cite\_start]Given your existing `Where-Object` filters for `$errors` and `$warnings`[cite: 18, 19], using `*>&1` or `3>&1` is the most straightforward solution.

### Additional Recommendations

  * [cite\_start]**Review `Set-StrictMode` and `$ErrorActionPreference`:** In `Convert-ChouseisanToIcs.ps1`, you have `Set-StrictMode -Version Latest` and `$ErrorActionPreference = "Stop"`. [cite: 1] [cite\_start]In `test-chouseisan-converter.ps1`, you also have `$ErrorActionPreference = "Stop"` [cite: 13] [cite\_start]and then `Invoke-Command` uses `-ErrorAction SilentlyContinue`. [cite: 16] Ensure these settings align with your testing strategy. If the main script is expected to *write a warning* (not necessarily stop execution), then `$ErrorActionPreference = "Stop"` in the main script is fine, as `Write-Warning` bypasses this setting. The `-ErrorAction SilentlyContinue` on `Invoke-Command` ensures that errors from the invoked script don't terminate your test script prematurely, allowing you to inspect `$result`.

  * **Debugging Stream Output:** If you're still having trouble, you can temporarily add `Write-Host $result | Get-Member` and `Write-Host $result | Format-List *` inside your `Run-Test` function to inspect the exact types of objects returned in `$result` when a warning is expected. This can help confirm if the warning object is indeed present and what its properties are.

By implementing one of the redirection strategies, particularly `*>&1`, you should be able to successfully capture the warning message from your "EmptyCsv" test.