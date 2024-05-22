# Uninstall MicrosoftTeams appx package
Get-AppxPackage -Name MicrosoftTeams | Remove-AppxPackage

# Install MicrosoftTeams from URL
$TeamsInstallerUrl = "https://go.microsoft.com/fwlink/p/?LinkID=2187327&clcid=0x1009&culture=en-ca&country=CA"
$InstallerPath = "$env:TEMP\TeamsInstaller.exe"
Invoke-WebRequest -Uri $TeamsInstallerUrl -OutFile $InstallerPath
Start-Process -FilePath $InstallerPath -Wait

# Clean up the installer
Remove-Item -Path $InstallerPath
