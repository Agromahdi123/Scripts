$TargetFile0  = "C:\Program Files\Microsoft Office\root\Office16\excel.exe"
$TargetFile1  = "C:\Program Files\Microsoft Office\root\Office16\winword.exe"
$TargetFile2  = "C:\Program Files\Microsoft Office\root\Office16\powerpnt.exe"
$TargetFile3  = "C:\Program Files\Microsoft Office\root\Office16\outlook.exe"
$TargetFile4  = "C:\Program Files\zoom\bin\Zoom.exe"
$TargetFile5  = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
$targetFile6  = "C:\Program Files\Google\Chrome\Application\chrome.exe"
$TargetFile7  = "C:\Program Files\Microsoft Office\root\Office16\ONENOTE.EXE"
$targetfile8  = "https://berkshire.ultipro.com"
$TargetFile9  = "https://www.concursolutions.com/"
$TargetFile10 = "https://myevolvbfcsyxb.netsmartcloud.com/Account/Login.aspx#!"
$ShortcutFile0  = "$env:Public\Desktop\Excel.lnk"
$ShortcutFile1  = "$env:Public\Desktop\Word.lnk"
$ShortcutFile2  = "$env:Public\Desktop\PowerPoint.lnk"
$ShortcutFile3  = "$env:Public\Desktop\Outlook.lnk"
$ShortcutFile4  = "$env:Public\Desktop\Zoom.lnk"
$ShortcutFile5  = "$env:Public\Desktop\Microsoft Edge.lnk"
$ShortcutFile6  = "$env:Public\Desktop\Google Chrome.lnk"
$ShortcutFile7  = "$env:Public\Desktop\OneNote.lnk"
$ShortcutFile8  = "$env:Public\Desktop\UltiPro.lnk"
$ShortcutFile9  = "$env:Public\Desktop\Concur.lnk"
$ShortcutFile10 = "$env:Public\Desktop\NewEvolv.lnk"
$WScriptShell0 = New-Object -ComObject WScript.Shell
$WScriptShell1 = New-Object -ComObject WScript.Shell
$WScriptShell2 = New-Object -ComObject WScript.Shell
$WScriptShell3 = New-Object -ComObject WScript.Shell
$WScriptShell4 = New-Object -ComObject WScript.Shell
$WScriptShell5 = New-Object -ComObject WScript.Shell
$WScriptShell6 = New-Object -ComObject WScript.Shell
$WScriptShell7 = New-Object -ComObject WScript.Shell
$WScriptShell8 = New-Object -ComObject WScript.Shell
$WScriptSHell9 = New-Object -ComObject WScript.Shell
$WScriptShell10 = New-Object -ComObject WScript.Shell
$Shortcut0 = $WScriptShell0.CreateShortcut($ShortcutFile0)
$Shortcut1 = $WScriptShell1.CreateShortcut($ShortcutFile1)
$Shortcut2 = $WScriptShell2.CreateShortcut($ShortcutFile2)
$Shortcut3 = $WScriptShell3.CreateShortcut($ShortcutFile3)
$Shortcut4 = $WScriptShell4.CreateShortcut($ShortcutFile4)
$Shortcut5 = $WScriptShell5.CreateShortcut($ShortcutFile5)
$Shortcut6 = $WScriptShell6.CreateShortcut($ShortcutFile6)
$Shortcut7 = $WScriptShell7.CreateShortcut($ShortcutFile7)
$Shortcut8 = $WScriptShell8.CreateShortcut($ShortcutFile8)
$Shortcut9 = $WScriptShell9.CreateShortcut($ShortcutFile9)
$Shortcut10 = $WScriptShell10.CreateShortcut($ShortcutFile10)
$Shortcut0.TargetPath = $TargetFile0
$Shortcut1.TargetPath = $TargetFile1
$Shortcut2.TargetPath = $TargetFile2
$Shortcut3.TargetPath = $TargetFile3
$Shortcut4.TargetPath = $TargetFile4
$Shortcut5.TargetPath = $TargetFile5
$Shortcut6.TargetPath = $TargetFile6
$Shortcut7.TargetPath = $TargetFile7
$Shortcut8.TargetPath = $TargetFile8
$Shortcut9.TargetPath = $TargetFile9
$Shortcut10.TargetPath = $TargetFile10
$Shortcut8.IconLocation = "%ProgramFiles%\Google\Chrome\Application\chrome.exe"
$Shortcut9.IconLocation = "%ProgramFiles%\Google\Chrome\Application\chrome.exe"
$Shortcut10.IconLocation = "%ProgramFiles%\Google\Chrome\Application\chrome.exe"
$Shortcut0.Save()
$Shortcut1.Save()
$Shortcut2.Save()
$Shortcut3.Save()
$Shortcut4.Save()
$Shortcut5.Save()
$Shortcut6.Save()
$Shortcut7.Save()
$shortcut8.Save()
$Shortcut9.Save()
$Shortcut10.Save()
