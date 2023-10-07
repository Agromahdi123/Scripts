$OU="OU=TestOU,DC=ivycomputer,DC=com"

$ShadowGroup="CN=Test,OU=TestOU,DC=ivycomputer,DC=com"

Get-ADGroupMember –Identity $ShadowGroup | Where-Object {$_.distinguishedName –NotMatch $OU} | ForEach-Object {Remove-ADPrincipalGroupMembership –Identity $_ –MemberOf $ShadowGroup –Confirm:$false}

Get-ADUser –SearchBase $OU –SearchScope OneLevel –LDAPFilter "(!memberOf=$ShadowGroup)" | ForEach-Object {Add-ADPrincipalGroupMembership –Identity $_ –MemberOf $ShadowGroup}
Get-ADComputer –SearchBase $OU –SearchScope OneLevel –LDAPFilter "(!memberOf=$ShadowGroup)" | ForEach-Object {Add-ADPrincipalGroupMembership –Identity $_ –MemberOf $ShadowGroup}