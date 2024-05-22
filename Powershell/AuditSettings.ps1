# Connect to Exchange Online
Connect-ExchangeOnline

# Get all active mailboxes
$mailboxes = Get-Mailbox -RecipientTypeDetails UserMailbox -ResultSize Unlimited

# Iterate through each mailbox
foreach ($mailbox in $mailboxes) {
    $name = $mailbox.DisplayName
    $objectId = $mailbox.ExternalDirectoryObjectId

    # Get AuditOwner settings for the mailbox
    $auditOwnerSettings = $Mailbox | Select-Object -ExpandProperty auditowner

    # Print the name, object ID, and AuditOwner settings
    Write-Host "Name: $name"
    Write-Host "Object ID: $objectId"
    Write-Host "AuditOwner settings: $auditOwnerSettings"
}

