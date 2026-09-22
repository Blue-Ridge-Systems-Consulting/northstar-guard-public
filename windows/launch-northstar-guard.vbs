Option Explicit
Dim sh, cmd
Set sh = CreateObject("WScript.Shell")
cmd = "powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File C:\ProgramData\NorthstarGuard\NorthstarGuard-GUI.ps1"
sh.Run cmd, 0, False
Set sh = Nothing
