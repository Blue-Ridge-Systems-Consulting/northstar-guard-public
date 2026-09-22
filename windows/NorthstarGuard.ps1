[CmdletBinding()]
param(
    [ValidateSet('Install','Uninstall','Scan','Status','TrustPath','UntrustPath')]
    [string]$Action = 'Status',
    [string]$Path
)

$ErrorActionPreference = 'Stop'
$AppName = 'NorthstarGuard'
$Root = Join-Path $env:ProgramData $AppName
$ReportRoot = Join-Path $Root 'reports'
$FindingLog = Join-Path $Root 'findings.jsonl'
$TrustFile = Join-Path $Root 'trusted-known-good.json'
$StatusFile = Join-Path $Root 'status.json'
$TaskName = 'Northstar Guard Server Monitor'
$AgentVersion = '1.0.0'
$MaxFiles = 250
$MaxBytes = 512MB

function Ensure-Store {
    New-Item -ItemType Directory -Force -Path $Root,$ReportRoot | Out-Null
    if (-not (Test-Path $TrustFile)) { @{ items = @() } | ConvertTo-Json | Set-Content -Encoding UTF8 $TrustFile }
}
function Get-AgentId {
    Ensure-Store; $p=Join-Path $Root 'agent-id.txt'
    try { $machine=(Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Cryptography' -Name MachineGuid -ErrorAction Stop).MachineGuid; if($machine){$v=('win-'+$machine.ToString().ToLowerInvariant()); Set-Content -Encoding ASCII $p $v; return $v} } catch {}
    if(Test-Path $p){$v=(Get-Content -Raw $p).Trim(); if($v){return $v}}
    $v=('win-'+$env:COMPUTERNAME.ToLowerInvariant()+'-'+([guid]::NewGuid().ToString('N').Substring(0,12))); Set-Content -Encoding ASCII $p $v; return $v
}
function Read-Trust {
    Ensure-Store
    try { $x = Get-Content -Raw $TrustFile | ConvertFrom-Json; @($x.items) } catch { @() }
}
function Is-Trusted([string]$p) {
    $full = [IO.Path]::GetFullPath($p)
    return ((Read-Trust | Where-Object { $_.path -eq $full }).Count -gt 0)
}
function Write-Status([hashtable]$s) {
    $o=@{schemaVersion='1.0'; agentId=(Get-AgentId); agentVersion=$AgentVersion; platform='windows'; osVersion=((Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue).Caption); architecture=$env:PROCESSOR_ARCHITECTURE; host=@{name=$env:COMPUTERNAME}; monitoring=$true; scanInProgress=$false; scanMode=$null; findings=0; trustedExclusions=0; examined=0; lastScanAt=$null; lastReport=$null; updatedAt=(Get-Date).ToString('o'); capabilities=@{scanFocused=$true;scanFull=$true;trustItems=$true;reports=$true;networkProvider=$null}}
    foreach($k in $s.Keys){$o[$k]=$s[$k]}; $o | ConvertTo-Json -Depth 7 | Set-Content -Encoding UTF8 $StatusFile
}
function Add-Finding([hashtable]$f) {
    $event=@{schemaVersion='1.0';findingId=('f-'+[guid]::NewGuid().ToString('N'));agentId=(Get-AgentId);detectedAt=([string]$f.date);severity=([string]$f.severity);category='heuristic';path=([string]$f.path);sha256=$null;engines=@('northstar-heuristic');reasons=@($f.reasons);state='active';trustedAt=$null;scanRequestId=$null}
    ($event | ConvertTo-Json -Compress -Depth 6) | Add-Content -Encoding UTF8 $FindingLog
}
function Get-ScanRoots {
    $roots = @()
    Get-ChildItem 'C:\Users' -Directory -Force -ErrorAction SilentlyContinue | ForEach-Object {
        foreach ($n in @('Downloads','Desktop','Documents','AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup')) {
            $p = Join-Path $_.FullName $n; if (Test-Path $p) { $roots += $p }
        }
    }
    foreach ($p in @('C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp','C:\Windows\Temp')) { if (Test-Path $p) { $roots += $p } }
    $roots
}
function Inspect-File([IO.FileInfo]$f) {
    if (Is-Trusted $f.FullName) { return @{ trusted = $true; path = $f.FullName } }
    $reasons = [Collections.Generic.List[string]]::new()
    $ext = $f.Extension.ToLowerInvariant()
    if ($ext -in @('.exe','.dll','.sys','.msi','.msp','.scr','.ps1','.bat','.cmd','.vbs','.js','.hta')) {
        if ($f.FullName -match '\\(Downloads|Desktop)\\') { [void]$reasons.Add('executable or installer in a user download/desktop area') }
        $sig = Get-AuthenticodeSignature -LiteralPath $f.FullName
        if ($sig.Status -ne 'Valid') { [void]$reasons.Add("Authenticode signature status: $($sig.Status)") }
        try { if (Get-Item -LiteralPath $f.FullName -Stream Zone.Identifier -ErrorAction SilentlyContinue) { [void]$reasons.Add('Mark-of-the-Web Zone.Identifier present') } } catch {}
    }
    if ($f.Name -match '\.(pdf|docx?|xlsx?|jpg|png|txt|zip|iso)\.(exe|scr|cmd|bat|js|vbs)$') { [void]$reasons.Add('misleading double extension') }
    if ($reasons.Count -gt 0) {
        $severity = if ($reasons -match 'signature status: (NotSigned|Unknown)') { 'HIGH' } else { 'MEDIUM' }
        return @{ path=$f.FullName; date=(Get-Date).ToString('o'); severity=$severity; reasons=@($reasons) }
    }
    @{ clean = $true; path = $f.FullName }
}
function Invoke-Scan {
    Ensure-Store; $started = Get-Date; $findings = @(); $examined = 0; $trusted = 0; $skipped = 0
    Write-Status @{monitoring=$true;scanInProgress=$true;scanMode='focused';updatedAt=(Get-Date).ToString('o')}
    foreach ($root in Get-ScanRoots) {
        Get-ChildItem -LiteralPath $root -File -Recurse -Force -ErrorAction SilentlyContinue | ForEach-Object {
            if ($examined -ge $MaxFiles) { return }
            if ($_.Length -gt $MaxBytes) { $skipped++; return }
            $examined++; $r = Inspect-File $_
            if ($r.trusted) { $trusted++; return }
            if (-not $r.clean) { $findings += $r; Add-Finding $r }
        }
    }
    # Use the built-in Defender engine only for this focused scope; no whole-disk scan.
    foreach ($root in (Get-ScanRoots)) { try { Start-MpScan -ScanPath $root -ScanType CustomScan -ErrorAction SilentlyContinue } catch {} }
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'; $report = Join-Path $ReportRoot "$stamp-northstar-guard-server-focused.md"
    $summary = if ($findings.Count -eq 0) { 'No Northstar heuristic findings were recorded in the configured Server 2025 scope.' } else { "$($findings.Count) finding(s) require review." }
    @('# Northstar Guard Server 2025 Focused Scan Report','',"- **Contract:** Northstar Agent Contract v1.0", "- **Generated:** $(Get-Date -Format o)", "- **Host:** $env:COMPUTERNAME", "- **Agent ID:** $(Get-AgentId)", "- **Files examined:** $examined", "- **Findings:** $($findings.Count)", "- **Trusted exclusions:** $trusted", "- **Oversize files skipped:** $skipped", '- **Scope:** user Downloads/Desktop/Documents, Startup folders, and Windows Temp only','', '## Executive Summary','',$summary,'','## Detection Engines','', '- Authenticode signature validation', '- Mark-of-the-Web (Zone.Identifier) review', '- Focused executable/installer heuristics', '- Misleading double-extension heuristic', '- Microsoft Defender CustomScan integration','', 'This monitor is lightweight and monitor-only; it does not delete or quarantine files.') | Set-Content -Encoding UTF8 $report
    $manifest=@{schemaVersion='1.0';reportId=('r-'+[guid]::NewGuid().ToString('N'));agentId=(Get-AgentId);generatedAt=(Get-Date).ToString('o');mode='focused';scope=@('user Downloads','user Desktop','user Documents','Startup folders','Windows Temp');examined=$examined;findings=$findings.Count;trustedExclusions=$trusted;skipped=$skipped;engines=@('northstar-heuristic','authenticode','mark-of-the-web','microsoft-defender-customscan');markdownPath=$report;summarySource='Local deterministic heuristic based solely on this report evidence.'}
    ($manifest | ConvertTo-Json -Depth 6) | Set-Content -Encoding UTF8 ($report -replace '\.md$','.manifest.json')
    Write-Status @{ monitoring=$true; scanInProgress=$false; scanMode='focused'; examined=$examined; findings=$findings.Count; trustedExclusions=$trusted; lastScanAt=(Get-Date).ToString('o'); lastReport=$report; updatedAt=(Get-Date).ToString('o') }
    $report
}
function Set-Trust([string]$p,[bool]$remove) {
    Ensure-Store; $full = [IO.Path]::GetFullPath($p); $items = @(Read-Trust | Where-Object { $_.path -ne $full })
    if (-not $remove) { $items += @{ path=$full; sha256=$null; trustedAt=(Get-Date).ToString('o'); trustedBy='local-user'; reason='explicitly trusted by the local operator'; originalFindingId=$null } }
    @{ items=$items } | ConvertTo-Json -Depth 5 | Set-Content -Encoding UTF8 $TrustFile
}
switch ($Action) {
    'Install' {
        Ensure-Store; $arg = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" -Action Scan"
        $act = New-ScheduledTaskAction -Execute 'PowerShell.exe' -Argument $arg
        $tr = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) -RepetitionInterval (New-TimeSpan -Minutes 15) -RepetitionDuration (New-TimeSpan -Days 3650)
        Register-ScheduledTask -TaskName $TaskName -Action $act -Trigger $tr -User 'SYSTEM' -RunLevel Highest -Force | Out-Null
        Write-Status @{ monitoring=$true; installedAt=(Get-Date).ToString('o') }; 'Installed Northstar Guard Server 2025.'
    }
    'Uninstall' { Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue; 'Uninstalled scheduled monitor; reports retained.' }
    'Scan' { Invoke-Scan }
    'Status' { Ensure-Store; if (Test-Path $StatusFile) { Get-Content -Raw $StatusFile } else { 'Northstar Guard Server 2025 is not installed.' } }
    'TrustPath' { if (-not $Path) { throw 'Specify -Path.' }; Set-Trust $Path $false; "Trusted $Path" }
    'UntrustPath' { if (-not $Path) { throw 'Specify -Path.' }; Set-Trust $Path $true; "Removed trust for $Path" }
}
