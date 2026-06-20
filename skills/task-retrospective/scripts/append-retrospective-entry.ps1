<#
    append-retrospective-entry.ps1

    PowerShell sibling of append-retrospective-entry.sh. Same behavior,
    same exit codes, same output format.

    Prepends a new entry to .context/retrospectives.md and prunes the oldest
    entries when the current count reaches the cap (10).

    Usage:
      append-retrospective-entry.ps1 <retro-file> [<entry-source>]

      retro-file    Path to .context/retrospectives.md
      entry-source  Path to a file containing the new entry text, or '-' to
                    read from stdin. Defaults to stdin.

    Entry text must begin with a '### ' heading line.

    Behavior:
      1. Counts '### ' entry blocks from the top of the file.
      2. If count >= EntryCap (10), drops the oldest entries until the
         post-insert count equals EntryCap (converges to cap regardless of
         how far above cap the file starts — not one-prune-per-call).
      3. Prepends the new entry at the top, making it the newest.
      4. Preserves the trailing HTML comment (a paragraph starting with '<!--').
      5. Writes atomically (temp file in same dir -> Move-Item -Force).

    Exit codes:
      0  Success — file updated
      1  Usage or validation error
      2  File access error (missing, unreadable, or not writable)
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$RetroFile,

    [Parameter(Position = 1)]
    [string]$EntrySource = '-'
)

$ErrorActionPreference = 'Stop'

$ScriptName = Split-Path -Leaf $PSCommandPath
$EntryCap = 10

function Write-Err {
    param([string]$Msg)
    [Console]::Error.WriteLine("${ScriptName}: error: $Msg")
}

function Write-Usage {
    [Console]::Error.WriteLine(@"
Usage: $ScriptName <retro-file> [<entry-source>]

  retro-file    Path to .context/retrospectives.md (must exist and be writable)
  entry-source  Path to a file containing the new entry text, or '-' for stdin.
                Omit to read from stdin.

The new entry is prepended at the top of the file, becoming the newest entry.
If the file already contains $EntryCap or more entries, the oldest entry is
removed before insertion, keeping the log capped at $EntryCap entries.

Entry text must begin with a '### ' heading line, e.g.:
  ### MKT-0045: Short description
  - **Avoid**: ...
  - **Repeat**: ...
  - **Updated**: ...

Exit codes:
  0  Success
  1  Usage or validation error
  2  File access error
"@)
}

# ---------- argument validation ----------

if ([string]::IsNullOrEmpty($RetroFile) -or $RetroFile -in @('-h', '--help')) {
    Write-Usage
    exit 1
}

# ---------- file validation (retro-file) ----------

if (-not (Test-Path -LiteralPath $RetroFile)) {
    Write-Err "retro-file not found: $RetroFile"
    exit 2
}

$retroItem = Get-Item -LiteralPath $RetroFile
if ($retroItem.PSIsContainer) {
    Write-Err "retro-file is not a regular file: $RetroFile"
    exit 2
}

# Readable — attempt read via Get-Content; Test-Path doesn't distinguish ACLs.
try {
    $null = [System.IO.File]::OpenRead($retroItem.FullName).Close()
} catch {
    Write-Err "retro-file is not readable: $RetroFile"
    exit 2
}

# Writable — attempt a zero-byte append-open.
try {
    $testStream = [System.IO.File]::Open($retroItem.FullName, 'Open', 'Write')
    $testStream.Close()
} catch {
    Write-Err "retro-file is not writable: $RetroFile"
    exit 2
}

# ---------- read new entry ----------

if ($EntrySource -eq '-') {
    $newEntry = [Console]::In.ReadToEnd()
} else {
    if (-not (Test-Path -LiteralPath $EntrySource)) {
        Write-Err "entry-source not found: $EntrySource"
        exit 1
    }
    $srcItem = Get-Item -LiteralPath $EntrySource
    if ($srcItem.PSIsContainer) {
        Write-Err "entry-source is not a regular file: $EntrySource"
        exit 1
    }
    try {
        $newEntry = [System.IO.File]::ReadAllText($srcItem.FullName)
    } catch {
        Write-Err "entry-source is not readable: $EntrySource"
        exit 1
    }
}

# Trim trailing whitespace (match bash sub(/[[:space:]]+$/, "", new_entry)).
$newEntry = $newEntry -replace '\s+$', ''

# Validate first line starts with '### '.
$firstLine = ($newEntry -split '\r?\n', 2)[0]
if ($firstLine -notmatch '^### ') {
    Write-Err "entry text must begin with a '### ' heading line (got: $firstLine)"
    exit 1
}

# ---------- parse existing file ----------

$raw = [System.IO.File]::ReadAllText($retroItem.FullName)

# Match awk's RS="" paragraph mode: tolerate leading blank lines before the
# first record. Without this strip, a file beginning with "\n### entry..."
# would not split and the first entry would be silently discarded.
$raw = $raw.TrimStart("`r", "`n", " ", "`t")

# Split on blank lines (one or more CR?LF pairs back-to-back).
# Matches awk's RS="" paragraph mode, which treats runs of empty lines as
# record separators.
$paragraphs = [System.Text.RegularExpressions.Regex]::Split($raw, '(?:\r?\n){2,}')

$entries = New-Object System.Collections.Generic.List[string]
$suffix = ''

foreach ($p in $paragraphs) {
    $para = $p -replace '\s+$', ''
    if ([string]::IsNullOrEmpty($para)) { continue }
    if ($para -match '^### ') {
        $entries.Add($para)
    } elseif ($para -match '^<!--') {
        $suffix = $para
    }
}

# Pruned entries are archived here (uncapped, append-only) rather than being
# silently destroyed. The main file is still written atomically below; the
# archive is appended directly — an accepted tradeoff, since the archive is
# non-authoritative historical overflow, not the live log.
$archiveFile = Join-Path (Split-Path -Parent $retroItem.FullName) 'retrospectives-archive.md'

$oldCount = $entries.Count
$pruned = 0
if ($oldCount -ge $EntryCap) {
    # Trim down to cap-1 entries so the post-insert count equals cap.
    # The prior implementation removed only one entry per call, which
    # kept a file already above cap stuck above cap forever — one prune
    # per insert balanced one insert per call, never converging back down.
    $keep = $EntryCap - 1
    $pruned = $oldCount - $keep

    # Archive the entries that WOULD be dropped (entries[keep .. end]) before
    # truncating, so historical lessons are preserved instead of destroyed.
    # Write a one-time header if the archive does not yet exist.
    if (-not (Test-Path -LiteralPath $archiveFile)) {
        [System.IO.File]::AppendAllText($archiveFile, "# Retrospectives Archive`n`nEntries pruned from .context/retrospectives.md when it exceeded its cap. Append-only; newest at the bottom. Not loaded into context — read on demand for historical lessons.`n")
    }
    for ($i = $keep; $i -lt $entries.Count; $i++) {
        [System.IO.File]::AppendAllText($archiveFile, "`n" + $entries[$i] + "`n")
    }

    while ($entries.Count -gt $keep) {
        $entries.RemoveAt($entries.Count - 1)
    }
}

# ---------- assemble output ----------

$builder = New-Object System.Text.StringBuilder
[void]$builder.Append($newEntry)
[void]$builder.Append("`n")
foreach ($e in $entries) {
    [void]$builder.Append("`n")
    [void]$builder.Append($e)
    [void]$builder.Append("`n")
}
if (-not [string]::IsNullOrEmpty($suffix)) {
    [void]$builder.Append("`n")
    [void]$builder.Append($suffix)
    [void]$builder.Append("`n")
}
$outContent = $builder.ToString()

# ---------- atomic write ----------

$retroDir = Split-Path -Parent $retroItem.FullName
$tmpPath = Join-Path $retroDir (".retro_tmp_" + [Guid]::NewGuid().ToString('N').Substring(0, 8) + ".md")

try {
    [System.IO.File]::WriteAllText($tmpPath, $outContent)
    Move-Item -LiteralPath $tmpPath -Destination $retroItem.FullName -Force
} catch {
    if (Test-Path -LiteralPath $tmpPath) {
        Remove-Item -LiteralPath $tmpPath -Force
    }
    Write-Err ("failed to write {0}: {1}" -f $RetroFile, $_.Exception.Message)
    exit 2
}

# ---------- report ----------

$newRaw = [System.IO.File]::ReadAllText($retroItem.FullName)
$newCount = ([System.Text.RegularExpressions.Regex]::Matches($newRaw, '(?m)^### ')).Count
$entryWord = if ($newCount -eq 1) { 'entry' } else { 'entries' }

if ($pruned -gt 0) {
    $pruneWord = if ($pruned -eq 1) { 'entry' } else { 'entries' }
    Write-Output ("Updated {0}: {1} -> {2} {3}, pruned {4} oldest {5} (cap {6})" -f $RetroFile, $oldCount, $newCount, $entryWord, $pruned, $pruneWord, $EntryCap)
} else {
    Write-Output ("Updated {0}: {1} -> {2} {3}" -f $RetroFile, $oldCount, $newCount, $entryWord)
}

exit 0
