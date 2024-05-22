# List of common bloatware apps to uninstall
$appsToUninstall = @(
    "Microsoft.BingWeather",
    "Microsoft.GetHelp",
    "Microsoft.Getstarted",
    "Microsoft.Messaging",
    "Microsoft.Microsoft3DViewer",
    "Microsoft.MicrosoftOfficeHub",
    "Microsoft.MicrosoftSolitaireCollection",
    "Microsoft.MicrosoftStickyNotes",
    "Microsoft.MixedReality.Portal",
    "Microsoft.MSPaint",
    "Microsoft.Office.OneNote",
    "Microsoft.OneConnect",
    "Microsoft.People",
    "Microsoft.Print3D",
    "Microsoft.SkypeApp",
    "Microsoft.StorePurchaseApp",
    "Microsoft.Wallet",
    "Microsoft.Windows.Photos",
    "Microsoft.WindowsAlarms",
    "Microsoft.WindowsCalculator",
    "Microsoft.WindowsCamera",
    "Microsoft.WindowsFeedbackHub",
    "Microsoft.WindowsMaps",
    "Microsoft.WindowsSoundRecorder",
    "Microsoft.WindowsStore",
    "Microsoft.XboxApp",
    "Microsoft.XboxGameOverlay",
    "Microsoft.XboxGamingOverlay",
    "Microsoft.XboxIdentityProvider",
    "Microsoft.XboxSpeechToTextOverlay",
    "Microsoft.YourPhone",
    "Microsoft.ZuneMusic",
    "Microsoft.ZuneVideo",
    "Microsoft.XboxGameCallableUI",
    "Microsoft.GamingServices" ,
    "Microsoft.Xbox.TCUI",
    "MicrosoftTeams", #uninstall Microsoft TeamsHome
    "*xbox*" # Uninstall all Xbox-related apps
)

# Loop through the list of apps and uninstall them
foreach ($app in $appsToUninstall) {
    $package = Get-AppxPackage -Name $app -AllUsers
    if ($package) {
        Write-Host "Uninstalling $app..."
        $package | Remove-AppxPackage -AllUsers
        Write-Host "$app uninstalled successfully."
    } else {
        Write-Host "$app is not installed."
    }
}