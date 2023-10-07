# Check if the script is running as an administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script must be run as an administrator."
    Exit
}

# List the available network interface names
Get-NetAdapter | Select-Object -ExpandProperty Name

# Prompt user for interface name
$interfaceName = Read-Host "Enter the interface name (e.g. Ethernet, Wi-Fi)"

# Prompt user for IP address, subnet mask, and default gateway
$ipAddress = Read-Host "Enter the IP address"
$subnetMask = Read-Host "Enter the subnet mask"
$defaultGateway = Read-Host "Enter the default gateway"

# Set the IP address, subnet mask, and default gateway for the interface
New-NetIPAddress -InterfaceAlias $interfaceName -IPAddress $ipAddress -PrefixLength $subnetMask -DefaultGateway $defaultGateway

# Prompt user for DNS server addresses
$dnsServers = Read-Host "Enter the DNS server addresses (separated by commas)"

# Set the DNS server addresses for the interface
Set-DnsClientServerAddress -InterfaceAlias $interfaceName -ServerAddresses $dnsServers.Split(",")

# Prompt user for domain name
$domainName = Read-Host "Enter the domain name"

# Set the domain name for the interface
Set-DnsClient -InterfaceAlias $interfaceName -ConnectionSpecificSuffix $domainName

# Prompt user for firewall zone
$firewallZone = Read-Host "Enter the firewall zone (e.g. Public, Private, Domain)"

# Set the firewall zone for the interface
Set-NetConnectionProfile -InterfaceAlias $interfaceName -NetworkCategory $firewallZone
