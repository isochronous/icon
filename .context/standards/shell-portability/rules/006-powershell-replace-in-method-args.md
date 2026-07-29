# Rule 6. PowerShell `-replace` inside a .NET method-call argument list: parenthesize it

Inside a .NET method call's argument list, PowerShell parses the two commas of a `-replace 'pattern','replacement'` expression as **method-argument separators**, not as part of the `-replace` operator. So this passes `TryParse` the wrong number of arguments:

```powershell
[int]::TryParse((Get-Content $f -replace '\D',''), [ref]$n)   # BROKEN
```

PowerShell reads it as three arguments — `(Get-Content $f -replace '\D'`, `''`, `[ref]$n` — which throws under `Set-StrictMode` / `$ErrorActionPreference='Stop'`. Wrap the `-replace` expression in its **own** parentheses so its commas are contained within the operand, not the argument list:

```powershell
[int]::TryParse(((Get-Content $f) -replace '\D',''), [ref]$n)   # correct
```

(ICON-0082: a persisted-`Attempts` parse in the PowerShell phase-launcher template silently broke the same bounded-retry guarantee in PS mode until the `-replace` was wrapped in its own parentheses `((… -replace '\D',''))`.)

## Related

- Index: [shell portability rules](README.md)
- See also: [testing pattern](../testing-pattern.md) § PowerShell Is a Fail-Open Generator — the four measured shapes of the surrounding failure mode
