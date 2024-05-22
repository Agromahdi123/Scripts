$packageName = "MicrosoftTeams"

$package = Get-AppxPackage | Where-Object { $_.Name -eq $packageName }

if ($package) {
    Write-Output "Package $packageName is installed."
    exit 0
} else {
    Write-Output "Package $packageName is not installed."
    exit 1
}