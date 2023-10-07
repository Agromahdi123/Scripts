$work = Split-Path -Parent $MyInvocation.MyCommand.Path
if ($work[-1] -eq '\') { $work = $work.Substring(0, $work.Length - 1) }

$version = (Get-CimInstance Win32_OperatingSystem).Version
if ($version -eq '10.0' -or $version -eq '6.3' -or $version -eq '6.2') {
  goto Check_Admin
}
goto E_Win

:Check_Admin
if (!(Test-Path 'HKU:\S-1-5-19')) {
  goto E_Admin
}

if (!(Get-Command 'certutil' -ErrorAction SilentlyContinue)) {
  goto E_Cu
}

if (!(Get-Command 'powershell' -ErrorAction SilentlyContinue)) {
  goto E_Ps
}

$title = 'IKEv2 Configuration Import Helper Script'
Set-Location $work
Clear-Host
Write-Host '==================================================================='
Write-Host 'Welcome! Use this helper script to import an IKEv2 configuration'
Write-Host 'into a PC running Windows 8, 10 or 11.'
Write-Host 'For more details, see https://vpnsetup.net/ikev2'
Write-Host ''
Write-Host 'Before continuing, you must put the .p12 file you transferred from'
Write-Host 'the VPN server in the *same folder* as this script.'
Write-Host '==================================================================='

$client_name_gen = ''
$p12_latest = Get-ChildItem -Path $work -Filter '*.p12' -File | Sort-Object -Property LastWriteTime -Descending | Select-Object -First 1
if ($p12_latest) {
  $client_name_gen = $p12_latest.Name -replace '\.p12$'
  goto Enter_Client_Name
}

:Enter_Client_Name
Write-Host ''
Write-Host 'Enter the name of the IKEv2 VPN client to import.'
Write-Host 'Note: This is the same as the .p12 filename without extension.'
$client_name = Read-Host -Prompt "VPN client name: [$client_name_gen]"
if ([string]::IsNullOrWhiteSpace($client_name)) {
  $client_name = $client_name_gen
}
$client_name = $client_name -replace '[":]', ''
$client_name = $client_name -replace '\s+', ''
$p12_file = Join-Path $work "$client_name.p12"
if (!(Test-Path $p12_file)) {
  Write-Host ''
  Write-Host "ERROR: File '$p12_file' not found."
  Write-Host 'You must put the .p12 file you transferred from the VPN server'
  Write-Host 'in the *same folder* as this script.'
  goto Enter_Client_Name
}

Write-Host ''
Write-Host 'Enter the IP address (or DNS name) of the VPN server.'
Write-Host 'Note: This must exactly match the VPN server address in the output'
Write-Host 'of the IKEv2 helper script on your server.'
$server_addr = Read-Host -Prompt 'VPN server address:'
if ([string]::IsNullOrWhiteSpace($server_addr)) {
  goto Abort
}
$server_addr = $server_addr -replace '[":]', ''
$server_addr = $server_addr -replace '\s+', ''

$conn_name_gen = "IKEv2 VPN $server_addr"
if (Get-VpnConnection -Name $conn_name_gen -ErrorAction SilentlyContinue) {
  $conn_name_gen = "IKEv2 VPN 2 $server_addr"
  if (Get-VpnConnection -Name $conn_name_gen -ErrorAction SilentlyContinue) {
    $conn_name_gen = "IKEv2 VPN 3 $server_addr"
    if (Get-VpnConnection -Name $conn_name_gen -ErrorAction SilentlyContinue) {
      $conn_name_gen = ''
    }
  }
}

:Enter_Conn_Name
Write-Host ''
Write-Host 'Provide a name for the new IKEv2 connection.'
$conn_name = Read-Host -Prompt "IKEv2 connection name: [$conn_name_gen]"
if ([string]::IsNullOrWhiteSpace($conn_name)) {
  $conn_name = $conn_name_gen
}
$conn_name = $conn_name -replace '[":]', ''
if (Get-VpnConnection -Name $conn_name -ErrorAction SilentlyContinue) {
  Write-Host ''
  Write-Host 'ERROR: A connection with this name already exists.'
  goto Enter_Conn_Name
}

Write-Host ''
Write-Host 'Importing .p12 file...'
certutil -f -p '' -importpfx $p12_file NoExport > $null
if ($LASTEXITCODE -eq 0) {
  goto Create_Conn
}
Write-Host 'When prompted, enter the password for client config files, which can be found'
Write-Host 'in the output of the IKEv2 helper script on your server.'
:Import_P12
certutil -f -importpfx $p12_file NoExport
if ($LASTEXITCODE -ne 0) {
  goto Import_P12
}

:Create_Conn
Write-Host ''
Write-Host 'Creating VPN connection...'
Add-VpnConnection -ServerAddress $server_addr -Name $conn_name -AllUserConnection -TunnelType IKEv2 -AuthenticationMethod MachineCertificate -EncryptionLevel Required -PassThru
if ($LASTEXITCODE -ne 0) {
  Write-Host ''
  Write-Host 'ERROR: Could not create the IKEv2 VPN connection.'
  goto Done
}

Write-Host 'Setting IPsec configuration...'
Set-VpnConnectionIPsecConfiguration -ConnectionName $conn_name -AuthenticationTransformConstants GCMAES128 -CipherTransformConstants GCMAES128 -EncryptionMethod AES256 -IntegrityCheckMethod SHA256 -PfsGroup None -DHGroup Group14 -PassThru -Force
if ($LASTEXITCODE -ne 0) {
  Write-Host ''
  Write-Host 'ERROR: Could not set IPsec configuration for the IKEv2 VPN connection.'
  goto Done
}

Write-Host 'IKEv2 configuration successfully imported!'
Write-Host 'To connect to the VPN, click on the wireless/network icon in your system tray,'
Write-Host "select the '$conn_name' VPN entry, and click Connect."
goto Done

:E_Admin
Write-Host $Error[0]
Write-Host 'This script requires administrator privileges.'
Write-Host "Right-click on the script and select 'Run as administrator'."
goto Done

:E_Win
Write-Host $Error[0]
Write-Host 'This script requires Windows 8, 10 or 11.'
Write-Host 'Windows 7 users can manually import IKEv2 configuration. See https://vpnsetup.net/ikev2'
goto Done

:E_Cu
Write-Host $Error[0]
Write-Host "This script requires 'certutil', which is not detected."
goto Done

:E_Ps
Write-Host $Error[0]
Write-Host "This script requires 'powershell', which is not detected."
goto Done

:Abort
Write-Host ''
Write-Host 'Abort. No changes were made.'

:Done
Write-Host ''
Write-Host 'Press any key to exit.'
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
