# IKEv2 Configuration Import Helper Script for Windows 8, 10 and 11
# Copyright (C) 2022 Lin Song <linsongui@gmail.com>
# This work is licensed under the Creative Commons Attribution-ShareAlike 3.0
# Unported License: http://creativecommons.org/licenses/by-sa/3.0/
# Attribution required: please include my name in any derivative and let me
# know how you have improved it!

$ErrorActionPreference = "Stop"
$SPath = "$env:SystemRoot\System32"
if (Test-Path "$env:SystemRoot\Sysnative\reg.exe") {
    $SPath = "$env:SystemRoot\Sysnative"
}
$env:Path = "$SPath;$env:SystemRoot;$SPath\Wbem;$SPath\WindowsPowerShell\v1.0\"
$err = "====== ERROR ====="
$work = Split-Path -Parent $MyInvocation.MyCommand.Path

$version = (Get-WmiObject -Class Win32_OperatingSystem).Version
if ($version -notmatch "^10\.0|^6\.[23]$") {
    Write-Error "$err`nThis script requires Windows 8, 10 or 11.`nWindows 7 users can manually import IKEv2 configuration. See https://vpnsetup.net/ikev2"
    exit 1
}

if (!(Get-Command certutil -ErrorAction SilentlyContinue)) {
    Write-Error "$err`nThis script requires 'certutil', which is not detected."
    exit 1
}
if (!(Get-Command powershell -ErrorAction SilentlyContinue)) {
    Write-Error "$err`nThis script requires 'powershell', which is not detected."
    exit 1
}

$host.UI.RawUI.WindowTitle = "IKEv2 Configuration Import Helper Script"
Set-Location $work
Clear-Host
Write-Host "==================================================================="
Write-Host "Welcome^^! Use this helper script to import an IKEv2 configuration"
Write-Host "into a PC running Windows 8, 10 or 11."
Write-Host "For more details, see https://vpnsetup.net/ikev2"
Write-Host ""
Write-Host "Before continuing, you must put the .p12 file you transferred from"
Write-Host "the VPN server in the *same folder* as this script."
Write-Host "==================================================================="

$client_name_gen = ""
$p12_latest = Get-ChildItem -Path $work -Filter "*.p12" -File | Sort-Object -Property LastWriteTime -Descending | Select-Object -First 1 -ExpandProperty Name
$client_name_gen = $p12_latest -replace "\.p12$"
do {
    $client_name = Read-Host "Enter the name of the IKEv2 VPN client to import.`nNote: This is the same as the .p12 filename without extension."
    if (!$client_name) {
        $client_name = $client_name_gen
    }
    $client_name = $client_name -replace '[":*?<>|/\\]', ''
    $p12_file = Join-Path $work "$client_name.p12"
    if (!(Test-Path $p12_file)) {
        Write-Error "$err`nFile '$p12_file' not found.`nYou must put the .p12 file you transferred from the VPN server in the *same folder* as this script."
        $client_name_gen = ""
    }
} until (Test-Path $p12_file)

do {
    $server_addr = Read-Host "Enter the IP address (or DNS name) of the VPN server.`nNote: This must exactly match the VPN server address in the output of the IKEv2 helper script on your server."
    $server_addr = $server_addr -replace '[":*?<>|/\\]', ''
} until ($server_addr)

$conn_name_gen = "IKEv2 VPN $server_addr"
for ($i = 2; $i -le 3; $i++) {
    $conn_name_gen_try = "IKEv2 VPN $i $server_addr"
    if (!(Get-VpnConnection -Name $conn_name_gen_try -ErrorAction SilentlyContinue)) {
        $conn_name_gen = $conn_name_gen_try
        break
    }
}

do {
    $conn_name = Read-Host "Provide a name for the new IKEv2 connection."
    if (!$conn_name) {
        $conn_name = $conn_name_gen
    }
    $conn_name = $conn_name -replace '[":*?<>|/\\]', ''
    if (Get-VpnConnection -Name $conn_name -ErrorAction SilentlyContinue) {
        Write-Error "$err`nA connection with this name already exists."
        $conn_name_gen = ""
    }
} until (Test-Path $p12_file)

Write-Host ""
Write-Host "Importing .p12 file..."
certutil -f -p "" -importpfx $p12_file NoExport >$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "When prompted, enter the password for client config files, which can be found in the output of the IKEv2 helper script on your server."
    certutil -f -importpfx $p12_file NoExport
    if ($LASTEXITCODE -ne 0) {
        Write-Error "$err`nCould not import the .p12 file."
        exit 1
    }
}

Write-Host ""
Write-Host "Creating VPN connection..."
Add-VpnConnection -ServerAddress $server_addr -Name $conn_name -AllUserConnection -TunnelType IKEv2 -AuthenticationMethod MachineCertificate -EncryptionLevel Required -PassThru -SplitTunneling -Force | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Error "$err`nCould not create the IKEv2 VPN connection."
    exit 1
}

Write-Host "Setting IPsec configuration..."
Set-VpnConnectionIPsecConfiguration -ConnectionName $conn_name -AuthenticationTransformConstants GCMAES128 -CipherTransformConstants GCMAES128 -EncryptionMethod AES256 -IntegrityCheckMethod SHA256 -PfsGroup None -DHGroup Group14 -PassThru -Force | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Error "$err`nCould not set IPsec configuration for the IKEv2 VPN connection."
    exit 1
}

$add_route = Read-Host "Do you want to set a route through the VPN gateway? (y/n)"
if ($add_route -eq "y") {
    $route_address = Read-Host "Enter the IP address or network address of the route to add."
    $route_mask = Read-Host "Enter the subnet mask for the route to add."
    $route_metric = Read-Host "Enter the metric for the route to add."
    Write-Host "Adding route through VPN gateway..."
    New-NetRoute -DestinationPrefix $route_address/$route_mask -InterfaceAlias $conn_name -RouteMetric $route_metric
}

Write-Host "IKEv2 configuration successfully imported^^!"
Write-Host "To connect to the VPN, click on the wireless/network icon in your system tray,"
Write-Host "select the '$conn_name' VPN entry, and click Connect."

Read-Host "`nPress any key to exit."