# Disable Windows Update service
Set-Service -Name wuauserv -StartupType Disabled

# Disable Windows Update scheduled tasks
Get-ScheduledTask -TaskPath '\Microsoft\Windows\WindowsUpdate' | Disable-ScheduledTask

# Disable Windows Update registry keys
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate' -Name 'DisableWindowsUpdateAccess' -Value 1
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' -Name 'NoAutoUpdate' -Value 1

# Block communication with Microsoft update servers
$hostsFile = "$env:SystemRoot\System32\drivers\etc\hosts"
$hostsContent = Get-Content $hostsFile
$hostsContent += '0.0.0.0 windowsupdate.microsoft.com'
$hostsContent += '0.0.0.0 update.microsoft.com'
$hostsContent += '0.0.0.0 download.windowsupdate.com'
$hostsContent += '0.0.0.0 test.stats.update.microsoft.com'
$hostsContent += '0.0.0.0 ntservicepack.microsoft.com'
$hostsContent += '0.0.0.0 stats.microsoft.com'
$hostsContent | Set-Content $hostsFile

Write-Host "Windows updates and communication with Microsoft have been disabled."