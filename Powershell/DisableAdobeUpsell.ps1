$adobeProducts = Get-WmiObject -Query "SELECT * FROM Win32_Product WHERE Name LIKE 'Adobe%'" | Select-Object -Property Name

foreach ($product in $adobeProducts) {
    $productName = $product.Name -replace '\(.*?\)', ''
    $productName = $productName.Trim()
    $registryPath = "HKLM:\SOFTWARE\Policies\Adobe\$productName\DC\FeatureLockdown"
    
    if (!(Test-Path $registryPath)) {
        New-Item -Path $registryPath -Force | Out-Null
    }
    
    Set-ItemProperty -Path $registryPath -Name "bAcroSuppressUpsell" -Value 1
    Set-ItemProperty -Path $registryPath -Name "bToggleSophiaWebInfra" -Value 1
    Set-ItemProperty -Path $registryPath -Name "bLimitPromptsFeatureKey" -Value 1
}

