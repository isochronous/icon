#!/usr/bin/env pwsh
# ============================================================
# context-graph.ps1 — .context/ knowledge-graph parser (ICON-0081)
# ============================================================
# PowerShell parity for context-graph.sh (ADR-004 / shell-portability §8.5).
# Same args, modes, adjacency-output shape, and fail-closed 0/1/2 exit
# contract. Verified against the SAME fixtures as the bash variant.
#
#   --emit  (default) : print "# NODES" then "# EDGES" (paths + edge tags
#                       ONLY, never file contents) to stdout.
#   --check           : report dangling references + orphan content docs to
#                       stderr; exit 0 clean / 1 violations / 2 parser error.
#
# Node/edge model: design.md §1. Exit contract: §8.1. Escape hatches: §8.4.
# Delegates rules-index completeness to check-rules-index (§8.2): rules-index
# rows are ingested as reachability edges only, never dangling-flagged here.
#
# Usage: pwsh -NoProfile -File context-graph.ps1 [--emit|--check]
#              [--include-tasks] [context_root]
# ============================================================
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Fail2([string]$msg) { [Console]::Error.WriteLine($msg); exit 2 }

# ------------------------------------------------------------
# Parse arguments
# ------------------------------------------------------------
$mode = 'emit'
$includeTasks = $false
$rootArg = ''
foreach ($a in $args) {
  switch -Exact ($a) {
    '--emit'          { $mode = 'emit' }
    '--check'         { $mode = 'check' }
    '--include-tasks' { $includeTasks = $true }
    '--'              { }
    default {
      if ($a.StartsWith('-')) { Fail2 "[context-graph] error: unknown flag: $a" }
      $rootArg = $a
    }
  }
}

# ------------------------------------------------------------
# Resolve the context directory
# ------------------------------------------------------------
if ([string]::IsNullOrEmpty($rootArg)) {
  $base = (& git rev-parse --show-toplevel).Trim()
} else {
  $base = $rootArg
}
if (Test-Path -LiteralPath (Join-Path $base '.context') -PathType Container) {
  $contextDir = (Join-Path $base '.context')
} else {
  $contextDir = $base
}
if (-not (Test-Path -LiteralPath $contextDir -PathType Container)) {
  Fail2 "[context-graph] error: context tree not found: $contextDir"
}
$contextFull = (Resolve-Path -LiteralPath $contextDir).Path

# ------------------------------------------------------------
# Accumulators
# ------------------------------------------------------------
$nodes     = [System.Collections.Generic.List[string]]::new()
$edges     = [System.Collections.Generic.List[string]]::new()
$content   = [System.Collections.Generic.List[string]]::new()
$dangling  = [System.Collections.Generic.List[string]]::new()
$reachable = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
$orphanok  = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)

function Sort-UniqueOrdinal([System.Collections.Generic.List[string]]$items) {
  $set = [System.Collections.Generic.SortedSet[string]]::new([System.StringComparer]::Ordinal)
  foreach ($i in $items) { [void]$set.Add($i) }
  return $set
}

# ------------------------------------------------------------
# classify <relpath> -> node kind, or '' if not a node
# ------------------------------------------------------------
function Classify([string]$rel) {
  switch -Wildcard ($rel) {
    'overview.md'         { return 'overview' }
    'projects.md'         { return 'projects' }
    'rules-index.md'      { return 'rules-index' }
    'iconrc.json'         { return 'config' }
    'retrospectives.md'   { return 'retrospective' }
    'tasks/*/plan.md'     { if ($includeTasks) { return 'task' } else { return '' } }
    'tasks/*'             { return '' }
    'README.md'           { return 'folder-index' }
    '*/README.md'         { return 'folder-index' }
    'decisions/*.md'      { return 'decision' }
    'domains/*.md'        { return 'domain' }
    'standards/*.md'      { return 'standard' }
    'workflows/*.md'      { return 'workflow' }
    'architecture/*.md'   { return 'architecture' }
    'testing/*.md'        { return 'testing' }
    'styling/*.md'        { return 'styling' }
    default               { return '' }
  }
}

function IsContentKind([string]$k) {
  return @('domain','standard','workflow','decision','architecture','testing','styling') -contains $k
}

# ------------------------------------------------------------
# NormalizeRel <combined> -> path relative to context root, or '' if it
# escapes the root (path-traversal safety, §4).
# ------------------------------------------------------------
function NormalizeRel([string]$combined) {
  if ($combined.StartsWith('/')) { $combined = $combined.Substring(1) }
  $stack = [System.Collections.Generic.List[string]]::new()
  foreach ($p in $combined.Split('/')) {
    if ($p -eq '' -or $p -eq '.') { continue }
    elseif ($p -eq '..') {
      if ($stack.Count -eq 0) { return '' }
      $stack.RemoveAt($stack.Count - 1)
    } else { $stack.Add($p) }
  }
  return [string]::Join('/', $stack)
}

# strip a link target of anchor/title; reject non-local schemes.
function CleanTarget([string]$t) {
  $h = $t.IndexOf('#'); if ($h -ge 0) { $t = $t.Substring(0, $h) }
  $sp = $t.IndexOf(' '); if ($sp -ge 0) { $t = $t.Substring(0, $sp) }
  if ([string]::IsNullOrEmpty($t)) { return '' }
  if ($t -match '://' -or $t.StartsWith('//') -or $t.StartsWith('mailto:') -or
      $t.StartsWith('tel:') -or $t.StartsWith('#')) { return '' }
  return $t
}

function ExistsUnderContext([string]$rel) {
  return (Test-Path -LiteralPath (Join-Path $contextFull ($rel -replace '/', [IO.Path]::DirectorySeparatorChar)))
}

# record a resolved-under-context link edge.
function RecordLinkEdge([string]$etype, [string]$src, [string]$tgt, [bool]$deadref) {
  switch ($etype) {
    'indexed-by' {
      $edges.Add("indexed-by`t$tgt`t$src")
      [void]$reachable.Add($tgt)
    }
    default {  # covers | references
      $edges.Add("$etype`t$src`t$tgt")
      [void]$reachable.Add($tgt)
      if ((-not $deadref) -and (-not (ExistsUnderContext $tgt))) {
        $dangling.Add("$etype`t$src`t$tgt")
      }
    }
  }
}

function ResolveAdr([string]$num) {
  $decDir = Join-Path $contextFull 'decisions'
  if (Test-Path -LiteralPath $decDir -PathType Container) {
    $hit = Get-ChildItem -LiteralPath $decDir -Filter "$num-*.md" -File | Select-Object -First 1
    if ($hit) { return "decisions/$($hit.Name)" }
  }
  return ''
}

# ------------------------------------------------------------
# ParseFile <relpath> <kind>
# ------------------------------------------------------------
function ParseFile([string]$rel, [string]$kind) {
  $abs = Join-Path $contextFull ($rel -replace '/', [IO.Path]::DirectorySeparatorChar)
  try { $lines = Get-Content -LiteralPath $abs -ErrorAction Stop }
  catch { Fail2 "[context-graph] error: unreadable node file: $rel" }

  $srcdir = if ($rel.Contains('/')) { $rel.Substring(0, $rel.LastIndexOf('/')) } else { '' }

  $linkType = 'references'
  if ($rel -eq 'rules-index.md') { $linkType = 'indexed-by' }
  elseif ($rel -eq 'projects.md' -or $rel -eq 'README.md' -or $rel.EndsWith('/README.md')) { $linkType = 'covers' }

  $inFence = $false
  $inDeadref = $false

  foreach ($line in $lines) {
    if ($line -match '^\s*(```|~~~)') { $inFence = -not $inFence; continue }

    if ($line -like '*<!-- context-graph:orphan-ok -->*') { [void]$orphanok.Add($rel) }

    $hadEnd = $false
    if ($line -like '*dead-ref-ok-start*') { $inDeadref = $true }
    if ($line -like '*dead-ref-ok-end*')   { $hadEnd = $true }

    if (-not $inFence) {
      # config: iconrc excludes globs
      if ($kind -eq 'config' -and ($line -like '*"excludes"*')) {
        $lb = $line.IndexOf('['); $rb = $line.IndexOf(']')
        if ($lb -ge 0 -and $rb -gt $lb) {
          $arr = $line.Substring($lb + 1, $rb - $lb - 1)
          foreach ($tok in $arr.Split(',')) {
            $tk = $tok.Replace('"', '').Trim()
            if ($tk -ne '') { $edges.Add("excludes`ticonrc.json`t$tk") }
          }
        }
      }

      # Markdown links [text](target)
      foreach ($mm in [regex]::Matches($line, '\]\(([^)]+)\)')) {
        $t = CleanTarget $mm.Groups[1].Value
        if ($t -eq '') { continue }
        $combined = if ($srcdir -ne '') { "$srcdir/$t" } else { $t }
        $resolved = NormalizeRel $combined
        if ($resolved -eq '') { continue }
        RecordLinkEdge $linkType $rel $resolved $inDeadref
        # A rules-index File-column row that targets a DIRECTORY indexes each
        # direct-child .md (design §9.1). Emit a covers edge to each so the
        # children get an in-edge — matching check-rules-index.sh's parent-row
        # granularity (direct children only, non-recursive).
        if ($linkType -eq 'indexed-by') {
          $dirAbs = Join-Path $contextFull ($resolved -replace '/', [IO.Path]::DirectorySeparatorChar)
          if (Test-Path -LiteralPath $dirAbs -PathType Container) {
            foreach ($ch in (Get-ChildItem -LiteralPath $dirAbs -Filter '*.md' -File)) {
              $crel = "$resolved/$($ch.Name)"
              $edges.Add("covers`trules-index.md`t$crel")
              [void]$reachable.Add($crel)
            }
          }
        }
      }

      # decision supersede seams (bold-fields + legacy Status prose)
      if ($kind -eq 'decision') {
        if ($line -match '^\*\*Supersedes\*\*:\s*(.+)$') {
          foreach ($mn in [regex]::Matches($Matches[1], 'ADR-([0-9]+)')) {
            $num = $mn.Groups[1].Value
            $tgt = ResolveAdr $num
            if ($tgt -ne '') { $edges.Add("supersedes`t$rel`t$tgt"); [void]$reachable.Add($tgt) }
            elseif (-not $inDeadref) { $dangling.Add("supersedes`t$rel`tdecisions/$num-*.md") }
          }
        }
        if (($line -match '^\*\*Superseded-by\*\*:\s*(.+)$') -or
            ($line -match '^\*\*Status\*\*:.*Superseded by ADR-[0-9]')) {
          foreach ($mn in [regex]::Matches($line, 'ADR-([0-9]+)')) {
            $num = $mn.Groups[1].Value
            $tgt = ResolveAdr $num
            if ($tgt -ne '') { $edges.Add("superseded-by`t$rel`t$tgt"); [void]$reachable.Add($tgt) }
            elseif (-not $inDeadref) { $dangling.Add("superseded-by`t$rel`tdecisions/$num-*.md") }
          }
        }
      }

      # retrospective promotion provenance (Promoted to: <link|path>)
      if ($kind -eq 'retrospective' -and ($line -match '[Pp]romoted to:\s*(.+)$')) {
        $ptail = $Matches[1]
        $praw = ''
        $lm = [regex]::Match($ptail, '\]\(([^)]+)\)')
        if ($lm.Success) { $praw = $lm.Groups[1].Value }
        else { $pm = [regex]::Match($ptail, '[A-Za-z0-9_./-]+\.md'); if ($pm.Success) { $praw = $pm.Value } }
        $praw = CleanTarget $praw
        if ($praw -ne '') {
          $pres = NormalizeRel $praw
          if ($pres -ne '') { $edges.Add("promoted-from`t$rel`t$pres"); [void]$reachable.Add($pres) }
        }
      }
    }

    if ($hadEnd) { $inDeadref = $false }
  }
}

# ------------------------------------------------------------
# Discover nodes, then parse each once.
# ------------------------------------------------------------
$allFiles = Get-ChildItem -LiteralPath $contextFull -Recurse -File -ErrorAction Stop |
            Where-Object { $_.Extension -eq '.md' -or $_.Name -eq 'iconrc.json' }

$discovered = [System.Collections.Generic.List[string]]::new()
foreach ($f in $allFiles) {
  $rel = $f.FullName.Substring($contextFull.Length).TrimStart('\', '/') -replace '\\', '/'
  $kind = Classify $rel
  if ($kind -eq '') { continue }
  $nodes.Add($rel)
  if (IsContentKind $kind) { $content.Add($rel) }
  $discovered.Add($rel)
}

foreach ($rel in $discovered) { ParseFile $rel (Classify $rel) }

# ------------------------------------------------------------
# Fail-closed guard: zero nodes on an existing tree is a parser error.
# ------------------------------------------------------------
if ($nodes.Count -eq 0) {
  [Console]::Error.WriteLine("[context-graph] error: zero nodes discovered under $contextDir")
  [Console]::Error.WriteLine("  (a populated .context/ tree must yield >=1 node; refusing to report clean)")
  exit 2
}

# ------------------------------------------------------------
# EMIT mode
# ------------------------------------------------------------
if ($mode -eq 'emit') {
  [Console]::Out.WriteLine('# NODES')
  foreach ($n in (Sort-UniqueOrdinal $nodes)) { [Console]::Out.WriteLine($n) }
  [Console]::Out.WriteLine('# EDGES')
  foreach ($e in (Sort-UniqueOrdinal $edges)) { [Console]::Out.WriteLine($e) }
  exit 0
}

# ------------------------------------------------------------
# CHECK mode
# ------------------------------------------------------------
foreach ($r in @('overview.md', 'projects.md', 'rules-index.md')) { [void]$reachable.Add($r) }

$orphans = [System.Collections.Generic.List[string]]::new()
foreach ($rel in $content) {
  if ($reachable.Contains($rel)) { continue }
  if ($orphanok.Contains($rel))  { continue }
  $orphans.Add($rel)
}

$fail = $false

if ($dangling.Count -gt 0) {
  $fail = $true
  [Console]::Error.WriteLine('[context-graph] error: dangling reference(s) - link target not found on disk:')
  foreach ($d in (Sort-UniqueOrdinal $dangling)) {
    $p = $d.Split("`t")
    [Console]::Error.WriteLine("  [$($p[0])] $($p[1]) -> $($p[2]) (not found under .context/)")
  }
  [Console]::Error.WriteLine('  fix: repoint the link, add the target, or wrap an intentional gap in')
  [Console]::Error.WriteLine('       <!-- pre-commit:dead-ref-ok-start --> ... <!-- pre-commit:dead-ref-ok-end -->')
}

if ($orphans.Count -gt 0) {
  $fail = $true
  [Console]::Error.WriteLine('[context-graph] error: orphan/unreachable content doc(s) - no in-edge and not a root:')
  foreach ($o in (Sort-UniqueOrdinal $orphans)) {
    [Console]::Error.WriteLine("  $o (nothing links, covers, or indexes it)")
  }
  [Console]::Error.WriteLine('  fix: link it from a related doc (a ## Related entry), index it, or mark an')
  [Console]::Error.WriteLine('       intentional stub with a file-level <!-- context-graph:orphan-ok --> comment')
}

if ($fail) { exit 1 }

[Console]::Out.WriteLine("[context-graph] OK: $($nodes.Count) nodes, no dangling references, no orphans")
exit 0
