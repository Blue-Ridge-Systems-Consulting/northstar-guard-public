[CmdletBinding()]
param([string]$Core = "$PSScriptRoot\NorthstarGuard.ps1")

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[Windows.Forms.Application]::EnableVisualStyles()
$data = Join-Path $env:ProgramData 'NorthstarGuard'
$statusFile = Join-Path $data 'status.json'; $trustFile = Join-Path $data 'trusted-known-good.json'
$findingsFile = Join-Path $data 'findings.jsonl'; $reportDir = Join-Path $data 'reports'
$osCaption = try { (Get-CimInstance Win32_OperatingSystem -ErrorAction Stop).Caption } catch { 'Windows' }
$platform = if($osCaption -match 'Server'){ 'Windows Server 2025' } elseif($osCaption -match 'Windows 10'){ 'Windows 10' } elseif($osCaption -match 'Windows 11'){ 'Windows 11' } else { 'Windows' }

$form = New-Object Windows.Forms.Form
$form.Text = "Northstar Guard | $platform"
$form.Size = New-Object Drawing.Size(980,680); $form.MinimumSize = New-Object Drawing.Size(860,580)
$form.StartPosition = 'CenterScreen'; $form.BackColor = [Drawing.Color]::FromArgb(18,25,38)
$iconPath = Join-Path $PSScriptRoot 'NorthstarGuard.ico'; if(Test-Path $iconPath){$form.Icon=New-Object Drawing.Icon($iconPath)}
function Make-Label($text,$x,$y,$w,$h,$size=10,$bold=$false,$color=[Drawing.Color]::FromArgb(224,232,243)) { $l=New-Object Windows.Forms.Label; $l.Text=$text; $l.Location=New-Object Drawing.Point($x,$y); $l.Size=New-Object Drawing.Size($w,$h); $style=if($bold){[Drawing.FontStyle]::Bold}else{[Drawing.FontStyle]::Regular}; $l.Font=New-Object Drawing.Font('Segoe UI',$size,$style); $l.ForeColor=$color; return $l }
function Make-Button($text,$x,$y,$w,$h) { $b=New-Object Windows.Forms.Button; $b.Text=$text; $b.Location=New-Object Drawing.Point($x,$y); $b.Size=New-Object Drawing.Size($w,$h); $b.FlatStyle='Flat'; $b.FlatAppearance.BorderColor=[Drawing.Color]::FromArgb(64,91,122); $b.BackColor=[Drawing.Color]::FromArgb(31,45,64); $b.ForeColor=[Drawing.Color]::FromArgb(230,238,248); $b.Font=New-Object Drawing.Font('Segoe UI',9); return $b }
function Read-Json($p) { try { if(Test-Path $p){Get-Content -Raw $p | ConvertFrom-Json} } catch {} }
function Invoke-Core([string]$action,[string]$path=$null) { $a=@('-NoProfile','-ExecutionPolicy','Bypass','-File',$Core,'-Action',$action); if($path){$a+=@('-Path',$path)}; try { Start-Process powershell.exe -ArgumentList $a -WindowStyle Hidden -Wait } catch {} }

$header=New-Object Windows.Forms.Panel; $header.Dock='Top'; $header.Height=92; $header.BackColor=[Drawing.Color]::FromArgb(24,39,66); $form.Controls.Add($header)
$header.Controls.Add((Make-Label 'Northstar Guard' 24 15 330 34 22 $true ([Drawing.Color]::White)))
$header.Controls.Add((Make-Label "$platform protection dashboard" 27 53 400 22 10 $false ([Drawing.Color]::FromArgb(190,207,230))))
$state=Make-Label 'Checking monitor…' 650 28 285 30 13 $true ([Drawing.Color]::White); $state.TextAlign='MiddleRight'; $header.Controls.Add($state)

$cards=New-Object Windows.Forms.Panel; $cards.Location=New-Object Drawing.Point(20,108); $cards.Size=New-Object Drawing.Size(925,92); $form.Controls.Add($cards)
function Card($x,$title) { $p=New-Object Windows.Forms.Panel; $p.Location=New-Object Drawing.Point($x,0); $p.Size=New-Object Drawing.Size(215,88); $p.BackColor=[Drawing.Color]::FromArgb(29,42,59); $p.BorderStyle='FixedSingle'; $cards.Controls.Add($p); $p.Controls.Add((Make-Label $title 14 12 180 20 9 $false ([Drawing.Color]::FromArgb(154,176,202)))); $v=Make-Label '—' 14 34 185 38 22 $true ([Drawing.Color]::FromArgb(238,245,252)); $p.Controls.Add($v); return $v }
$examined=Card 0 'FILES EXAMINED'; $findings=Card 235 'ACTIVE FINDINGS'; $trusted=Card 470 'TRUSTED EXCLUSIONS'; $lastScan=Card 705 'LAST SCAN'

$toolbar=New-Object Windows.Forms.Panel; $toolbar.Location=New-Object Drawing.Point(20,214); $toolbar.Size=New-Object Drawing.Size(925,48); $form.Controls.Add($toolbar)
$start=Make-Button 'Start monitoring' 0 5 135 34; $stop=Make-Button 'Stop monitoring' 145 5 135 34; $scan=Make-Button 'Scan now' 290 5 110 34; $full=Make-Button 'Full focused scope' 410 5 145 34; $trustBtn=Make-Button 'Trust selected' 565 5 130 34; $open=Make-Button 'Open reports' 705 5 120 34; $refresh=Make-Button 'Refresh' 835 5 90 34
$toolbar.Controls.AddRange(@($start,$stop,$scan,$full,$trustBtn,$open,$refresh))

$box=New-Object Windows.Forms.GroupBox; $box.Text='Recent findings'; $box.ForeColor=[Drawing.Color]::FromArgb(224,232,243); $box.BackColor=[Drawing.Color]::FromArgb(25,35,50); $box.Location=New-Object Drawing.Point(20,275); $box.Size=New-Object Drawing.Size(925,315); $form.Controls.Add($box)
$list=New-Object Windows.Forms.ListView; $list.View='Details'; $list.FullRowSelect=$true; $list.GridLines=$false; $list.HideSelection=$false; $list.Dock='Fill'; $list.MultiSelect=$false; $list.BackColor=[Drawing.Color]::FromArgb(25,35,50); $list.ForeColor=[Drawing.Color]::FromArgb(225,234,245); $list.Font=New-Object Drawing.Font('Segoe UI',10); $list.OwnerDraw=$true
$spacer=New-Object Windows.Forms.ImageList; $spacer.ImageSize=New-Object Drawing.Size(1,26); $spacer.Images.Add((New-Object Drawing.Bitmap(1,26))); $list.SmallImageList=$spacer
[void]$list.Columns.Add('Severity',100); [void]$list.Columns.Add('Path',475); [void]$list.Columns.Add('Reason',340); $box.Controls.Add($list)
$list.Add_DrawColumnHeader({ param($sender,$e) $brush=New-Object -TypeName Drawing.SolidBrush -ArgumentList ([Drawing.Color]::FromArgb(36,58,82)); $textBrush=New-Object -TypeName Drawing.SolidBrush -ArgumentList ([Drawing.Color]::FromArgb(210,228,244)); $font=New-Object -TypeName Drawing.Font -ArgumentList @('Segoe UI',9,[Drawing.FontStyle]::Bold); $e.Graphics.FillRectangle($brush,$e.Bounds); $e.Graphics.DrawString($e.Header.Text,$font,$textBrush,($e.Bounds.X+10),($e.Bounds.Y+7)) })
$list.Add_DrawItem({ param($sender,$e) $e.DrawDefault=$false })
$list.Add_DrawSubItem({ param($sender,$e) $selected=$e.Item.Selected; $bg=if($selected){[Drawing.Color]::FromArgb(28,105,128)}elseif(($e.ItemIndex % 2)-eq 0){[Drawing.Color]::FromArgb(29,42,59)}else{[Drawing.Color]::FromArgb(25,35,50)}; $fg=if($selected){[Drawing.Color]::White}else{[Drawing.Color]::FromArgb(225,234,245)}; $bgBrush=New-Object -TypeName Drawing.SolidBrush -ArgumentList $bg; $fgBrush=New-Object -TypeName Drawing.SolidBrush -ArgumentList $fg; $font=New-Object -TypeName Drawing.Font -ArgumentList @('Segoe UI',9); $e.Graphics.FillRectangle($bgBrush,$e.Bounds); $e.Graphics.DrawString($e.SubItem.Text,$font,$fgBrush,($e.Bounds.X+10),($e.Bounds.Y+6)) })
$footer=Make-Label 'Monitor-only: Northstar records and reports findings; it does not delete or quarantine files.' 22 602 790 24 9 $false ([Drawing.Color]::FromArgb(95,108,125)); $form.Controls.Add($footer)
$psButton=Make-Button 'PowerShell' 820 598 125 30; $form.Controls.Add($psButton)

function Reload-View {
    $s=Read-Json $statusFile; $t=Read-Json $trustFile; $trustedCount=@($t.items).Count
    $state.Text=if($s.scanInProgress){'● Scan in progress…'}elseif($s.monitoring){'● Monitoring active'}else{'○ Monitoring paused'}
    $state.ForeColor=if($s.monitoring){[Drawing.Color]::FromArgb(144,238,176)}else{[Drawing.Color]::FromArgb(255,210,130)}
    $examinedValue=0; if($null -ne $s.examined){$examinedValue=$s.examined}; $findingValue=0; if($null -ne $s.findings){$findingValue=$s.findings}
    $examined.Text=[string]$examinedValue; $findings.Text=[string]$findingValue; $trusted.Text=[string]$trustedCount
    $lastScan.Text=if($s.lastScanAt){([datetime]$s.lastScanAt).ToLocalTime().ToString('MM/dd HH:mm')}else{'—'}
    $list.Items.Clear(); $trustedPaths=@($t.items | ForEach-Object {$_.path})
    if(Test-Path $findingsFile){ Get-Content $findingsFile -Tail 120 | ForEach-Object { try { $f=$_|ConvertFrom-Json; if($trustedPaths -notcontains $f.path){$i=New-Object Windows.Forms.ListViewItem -ArgumentList ([string]$f.severity); $i.ImageIndex=0; [void]$i.SubItems.Add([string]$f.path); [void]$i.SubItems.Add(([string]::Join('; ',@($f.reasons)))); [void]$list.Items.Add($i) } } catch {} } }
}
$start.Add_Click({Invoke-Core 'Install'; Reload-View}); $stop.Add_Click({Invoke-Core 'Uninstall'; Reload-View})
$scan.Add_Click({Start-Process powershell.exe -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File',$Core,'-Action','Scan') -WindowStyle Hidden; $state.Text='● Scan queued…'})
$full.Add_Click({Start-Process powershell.exe -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File',$Core,'-Action','Scan') -WindowStyle Hidden; $state.Text='● Focused scope queued…'})
$trustBtn.Add_Click({if($list.SelectedItems.Count){Invoke-Core 'TrustPath' $list.SelectedItems[0].SubItems[1].Text; Reload-View}})
$open.Add_Click({if(Test-Path $reportDir){Start-Process explorer.exe $reportDir}}); $refresh.Add_Click({Reload-View})
$psButton.Add_Click({$command="Set-Location 'C:\ProgramData\NorthstarGuard'; Write-Host 'Northstar Guard commands:' -ForegroundColor Cyan; Write-Host '  .\NorthstarGuard.ps1 -Action Status'; Write-Host '  .\NorthstarGuard.ps1 -Action Scan'; Write-Host '  .\NorthstarGuard.ps1 -Action TrustPath -Path <file>' -ForegroundColor Gray"; Start-Process powershell.exe -ArgumentList @('-NoExit','-NoProfile','-ExecutionPolicy','Bypass','-Command',$command)})
$timer=New-Object Windows.Forms.Timer; $timer.Interval=2500; $timer.Add_Tick({Reload-View}); $timer.Start(); $form.Add_Shown({Reload-View})
[Windows.Forms.Application]::Run($form)
