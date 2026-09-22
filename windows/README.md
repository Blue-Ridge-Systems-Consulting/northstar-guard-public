# Northstar Guard for Windows 10, Windows 11, and Windows Server 2025

This saved Windows edition is compatible with 64-bit Windows 10, Windows 11, and Windows Server 2025. It uses components already included with Windows: Windows PowerShell 5.1, WinForms, Windows Task Scheduler, Authenticode, and Microsoft Defender when Defender is available.

This is the lightweight, monitor-only Server 2025 edition. It uses focused scans rather than scanning the whole machine, stays capped at 250 files per pass with 512 MiB per-file limits, and runs every 15 minutes as a SYSTEM scheduled task. It records Markdown reports and JSONL findings under `C:\ProgramData\NorthstarGuard\reports` and `findings.jsonl`.

Detection layers are **not Defender-only**. Northstar adds its own focused executable/installer heuristics, Authenticode signature status, Mark-of-the-Web metadata, misleading double-extension checks, and persistence-area coverage. Microsoft Defender is invoked as an additional CustomScan layer for the same focused roots when the Defender cmdlets are available. It does not delete or quarantine files. Use `-Action TrustPath -Path <file>` for an explicit local allowlist entry.

Install from an elevated PowerShell prompt:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
.\install-northstar-guard.ps1
```

Commands: `-Action Scan`, `-Action Status`, `-Action Uninstall`, `-Action TrustPath -Path <file>`, and `-Action UntrustPath -Path <file>`.

The `NorthstarGuard-GUI.ps1` dashboard provides Start/Stop monitoring, Scan Now, report browsing, status refresh, and explicit trust-path controls. The installer also places a branded **Northstar Guard** shortcut on the Public Desktop. Run it from an interactive Server 2025 desktop session with:

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\NorthstarGuard-GUI.ps1
```

The dashboard's **PowerShell** button opens an intentional command window in `C:\ProgramData\NorthstarGuard`. Supported examples are `NorthstarGuard.ps1 -Action Status`, `-Action Scan`, `-Action Install`, `-Action Uninstall`, `-Action TrustPath -Path <file>`, and `-Action UntrustPath -Path <file>`.
