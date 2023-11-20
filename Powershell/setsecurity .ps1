# This script sets recommended security settings for Windows 10
# Run this script as an administrator
# This script is provided as-is and is not supported by Microsoft
# This script has not been tested in all environments and is provided for demonstration purposes only

# Function to set security settings
function Set-SecuritySettings {
    param (
        [Parameter(Mandatory=$true)]
        [Hashtable]$Settings
    )

    foreach ($key in $Settings.Keys) {
        try {
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name $key -Value $Settings[$key]
        } catch {
            Write-Error "Failed to set security setting: $key"
            Write-Error $_.Exception.Message
        }
    }

    Write-Output "Security settings have been configured."
}

# Set recommended firewall settings
$FirewallSettings = @{
    "Windows Firewall: Domain: Firewall state" = 1
    "Windows Firewall: Domain: Inbound connections" = 1
    "Windows Firewall: Domain: Outbound connections" = 1
    "Windows Firewall: Private: Firewall state" = 1
    "Windows Firewall: Private: Inbound connections" = 1
    "Windows Firewall: Private: Outbound connections" = 1
    "Windows Firewall: Public: Firewall state" = 1
    "Windows Firewall: Public: Inbound connections" = 1
    "Windows Firewall: Public: Outbound connections" = 1
}

foreach ($key in $FirewallSettings.Keys) {
    try {
        Set-NetFirewallProfile -Name $key -Enabled $FirewallSettings[$key] -ErrorAction Stop
    } catch {
        Write-Error "Failed to set firewall setting: $key"
        Write-Error $_.Exception.Message
    }
}

# Disable consumer experiences
$ConsumerExperiencesPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
if (Test-Path $ConsumerExperiencesPath) {
    try {
        Set-ItemProperty -Path $ConsumerExperiencesPath -Name "SubscribedContent-338388Enabled" -Value 0
    } catch {
        Write-Error "Failed to disable consumer experiences"
        Write-Error $_.Exception.Message
    }
} else {
    Write-Warning "Consumer experiences registry key not found."
}

# Set recommended password policy
$PasswordPolicy = @{
    "PasswordComplexity" = 1
    "MinimumPasswordLength" = 8
    "PasswordHistorySize" = 24
    "MaximumPasswordAge" = (New-TimeSpan -Days 90).TotalDays
    "MinimumPasswordAge" = 1
    "PasswordReversibleEncryptionEnabled" = $false
}

try {
    Set-LocalUserPasswordPolicy @PasswordPolicy
} catch {
    Write-Error "Failed to set password policy"
    Write-Error $_.Exception.Message
}

# Set recommended account lockout policy
$AccountLockoutPolicy = @{
    "AccountLockoutThreshold" = 5
    "ResetAccountLockoutCounterAfter" = (New-TimeSpan -Minutes 15).TotalMinutes
    "AccountLockoutDuration" = (New-TimeSpan -Minutes 30).TotalMinutes
}

try {
    Set-LocalUserAccountLockoutPolicy @AccountLockoutPolicy
} catch {
    Write-Error "Failed to set account lockout policy"
    Write-Error $_.Exception.Message
}

# Set recommended security options
$SecurityOptions = @{
    "Accounts: Administrator account status" = 1
    "Accounts: Guest account status" = 0
    "Network access: Do not allow anonymous enumeration of SAM accounts and shares" = 1
    "Network access: Do not allow anonymous enumeration of SAM accounts" = 1
    "Network access: Do not allow anonymous enumeration of SAM accounts and shares" = 1
    "Network access: Let Everyone permissions apply to anonymous users" = 0
    "Network access: Named Pipes that can be accessed anonymously" = ""
    "Network access: Remotely accessible registry paths" = ""
    "Network access: Remotely accessible registry paths and sub-paths" = ""
    "Network access: Restrict anonymous access to Named Pipes and Shares" = 1
    "Network access: Shares that can be accessed anonymously" = ""
    "System cryptography: Use FIPS compliant algorithms for encryption, hashing, and signing" = 1
    "Audit: Audit the access of global system objects" = 3
    "Audit: Audit the use of Backup and Restore privilege" = 3
    "Audit: Audit the use of User Right Assignment" = 3
    "Audit: Audit account logon events" = 3
    "Audit: Audit account management" = 3
    "Audit: Audit directory service access" = 3
    "Audit: Audit logon events" = 3
    "Audit: Audit object access" = 3
    "Audit: Audit policy change" = 3
    "Audit: Audit privilege use" = 3
    "Audit: Audit system events" = 3
    # Add more audit log settings here
}

Set-SecuritySettings -Settings $SecurityOptions
