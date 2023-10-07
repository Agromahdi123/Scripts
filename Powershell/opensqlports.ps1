# Define variables for port numbers and other values
$SqlServerPort = 1433
$AdminConnectionPort = 1434
$ServiceBrokerPort = 4022
$DebuggerPort = 135
$AnalysisServicesPort = 2383
$BrowserServicePort = 2382
$HttpPort = 80
$SslPort = 443
$BrowserButtonPort = 1434

# Enable SQL Server ports
Write-Host "Enabling SQL Server ports..."
New-NetFirewallRule -DisplayName "SQL Server ($SqlServerPort)" -Direction Inbound -Action Allow -Protocol TCP -LocalPort $SqlServerPort
New-NetFirewallRule -DisplayName "SQL Admin Connection ($AdminConnectionPort)" -Direction Inbound -Action Allow -Protocol TCP -LocalPort $AdminConnectionPort
New-NetFirewallRule -DisplayName "SQL Service Broker ($ServiceBrokerPort)" -Direction Inbound -Action Allow -Protocol TCP -LocalPort $ServiceBrokerPort
New-NetFirewallRule -DisplayName "SQL Debugger/RPC ($DebuggerPort)" -Direction Inbound -Action Allow -Protocol TCP -LocalPort $DebuggerPort

# Enable Analysis Services ports
Write-Host "Enabling Analysis Services ports..."
New-NetFirewallRule -DisplayName "Analysis Services ($AnalysisServicesPort)" -Direction Inbound -Action Allow -Protocol TCP -LocalPort $AnalysisServicesPort
New-NetFirewallRule -DisplayName "SQL Browser ($BrowserServicePort)" -Direction Inbound -Action Allow -Protocol TCP -LocalPort $BrowserServicePort

# Enable miscellaneous ports
Write-Host "Enabling miscellaneous ports..."
New-NetFirewallRule -DisplayName "HTTP ($HttpPort)" -Direction Inbound -Action Allow -Protocol TCP -LocalPort $HttpPort
New-NetFirewallRule -DisplayName "SSL ($SslPort)" -Direction Inbound -Action Allow -Protocol TCP -LocalPort $SslPort
New-NetFirewallRule -DisplayName "SQL Browser ($BrowserButtonPort)" -Direction Inbound -Action Allow -Protocol TCP -LocalPort $BrowserButtonPort

# Allow Ping command
Write-Host "Enabling Ping command..."
New-NetFirewallRule -DisplayName "ICMP Allow incoming V4 echo request" -Protocol ICMPv4 -IcmpType 8 -Action Allow