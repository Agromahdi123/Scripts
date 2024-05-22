$adobeProducts = Get-WmiObject -Query "SELECT * FROM Win32_Product WHERE Name LIKE 'Adobe%'" | Select-Object -Property Name

$keys = @{
    "bAcroSuppressUpsell" = 1
    "bToggleSophiaWebInfra" = 1
    "bLimitPromptsFeatureKey" = 1
}

$detectedKeys = @{}

foreach ($product in $adobeProducts) {
    $productName = $product.Name -replace '\(.*?\)', ''
    $productName = $productName.Trim()
    $registryPath = "HKLM:\SOFTWARE\Policies\Adobe\$productName\DC\FeatureLockdown"
    
    foreach ($key in $keys.Keys) {
        if ((Get-ItemProperty -Path $registryPath -Name $key -ErrorAction SilentlyContinue).$key -eq $keys[$key]) {
            $detectedKeys["$registryPath\$key"] = $keys[$key]
        }
    }
}

if ($detectedKeys.Count -gt 0) {
    Write-Output "Detected keys: $($detectedKeys.Keys -join ', ')"
    exit 1
} else {
    Write-Output "No keys detected."
    exit 0
}