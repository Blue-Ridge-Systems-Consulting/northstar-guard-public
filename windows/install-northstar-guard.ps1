[CmdletBinding()]
param([string]$Source = "$PSScriptRoot\NorthstarGuard.ps1")
$dataRoot = Join-Path $env:ProgramData 'NorthstarGuard'
$programFilesRoot = Join-Path $env:ProgramFiles 'Northstar Guard'
$guiSource = Join-Path $PSScriptRoot 'NorthstarGuard-GUI.ps1'
$iconSource = Join-Path $PSScriptRoot 'NorthstarGuard.ico'
$launcherSource = Join-Path $PSScriptRoot 'launch-northstar-guard.vbs'
$null = New-Item -ItemType Directory -Force $dataRoot
$dest = Join-Path $programFilesRoot 'NorthstarGuard.ps1'
New-Item -ItemType Directory -Force (Split-Path $dest) | Out-Null
Copy-Item -Force $Source $dest
Copy-Item -Force $Source (Join-Path $dataRoot 'NorthstarGuard.ps1')
Copy-Item -Force $guiSource (Join-Path $dataRoot 'NorthstarGuard-GUI.ps1')
Copy-Item -Force $iconSource (Join-Path $dataRoot 'NorthstarGuard.ico')
Copy-Item -Force $launcherSource (Join-Path $dataRoot 'launch-northstar-guard.vbs')
$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut((Join-Path $env:Public 'Desktop\Northstar Guard.lnk'))
$shortcut.TargetPath = Join-Path $env:SystemRoot 'System32\wscript.exe'
$shortcut.Arguments = Join-Path $dataRoot 'launch-northstar-guard.vbs'
$shortcut.WorkingDirectory = $dataRoot
$shortcut.IconLocation = (Join-Path $dataRoot 'NorthstarGuard.ico') + ',0'
$shortcut.Description = 'Northstar Guard Server 2025 dashboard'
$shortcut.Save()
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $dest -Action Install
