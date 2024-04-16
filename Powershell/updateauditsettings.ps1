
$names = Get-Content -Path "C:\path\to\names.txt"

foreach ($name in $names) {
    Set-Mailbox -Identity $name -AuditOwner @{
        add = "update", "moveToDeletedItems", "softDelete", "hardDelete", "updateFolderPermissions", "updateInboxRules", "updateCalendarDelegation", "applyRecord", "mailItemsAccessed", "send"
    }
}
