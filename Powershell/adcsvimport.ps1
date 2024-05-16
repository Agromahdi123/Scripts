<#
.SYNOPSIS
Imports user information from a CSV file or manually input and creates corresponding Active Directory objects.

.DESCRIPTION
This script imports user information from a CSV file or allows the user to manually input the details and creates the following Active Directory objects:
- Organizational Units (OU)
- Groups
- Users

.PARAMETER csvFilePath
Specifies the path to the CSV file containing user information. If not provided, the user will be prompted to manually input the details.

.EXAMPLE
adcsvimport.ps1 -csvFilePath "C:\path\to\users.csv"
Imports user information from "users.csv" and creates corresponding Active Directory objects.

.NOTES
The CSV file should have the following columns:
- OU: The name of the Organizational Unit where the user will be created.
- Group: The name of the group the user will be added to.
- SamAccountName: The SamAccountName of the user.
- FirstName: The first name of the user.
- LastName: The last name of the user.
- Email: The email address of the user.
- Description: The description of the user.
- Password: The password for the user.
<#
# Example CSV file for adcsvimport.ps1

# OU,Group,SamAccountName,FirstName,LastName,Email,Description,Password
"Sales","Sales Group","jsmith","John","Smith","jsmith@example.com","Sales Representative","P@ssw0rd"
"IT","IT Group","jdoe","Jane","Doe","jdoe@example.com","IT Specialist","P@ssw0rd"
"HR","HR Group","msmith","Mary","Smith","msmith@example.com","HR Manager","P@ssw0rd"
#>
#>

# Import the Active Directory module
Import-Module ActiveDirectory

# Import the Windows Forms assembly
Add-Type -AssemblyName System.Windows.Forms

# Create a form
$form = New-Object System.Windows.Forms.Form
$form.Text = "AD CSV Import"
$form.Size = New-Object System.Drawing.Size(400, 300)
$form.StartPosition = "CenterScreen"

# Create a label for the CSV file path
$labelCsvFilePath = New-Object System.Windows.Forms.Label
$labelCsvFilePath.Text = "CSV File Path:"
$labelCsvFilePath.Location = New-Object System.Drawing.Point(10, 10)
$form.Controls.Add($labelCsvFilePath)

# Create a text box for the CSV file path
$textBoxCsvFilePath = New-Object System.Windows.Forms.TextBox
$textBoxCsvFilePath.Location = New-Object System.Drawing.Point(10, 30)
$textBoxCsvFilePath.Size = New-Object System.Drawing.Size(300, 20)
$form.Controls.Add($textBoxCsvFilePath)

# Create a button to import the CSV file or manually input the details
$buttonImport = New-Object System.Windows.Forms.Button
$buttonImport.Text = "Import"
$buttonImport.Location = New-Object System.Drawing.Point(10, 60)
$buttonImport.Add_Click({
    if ($textBoxCsvFilePath.Text) {
        # Read the CSV file
        $users = Import-Csv $textBoxCsvFilePath.Text
    }
    else {
        # Prompt the user to manually input the details
        $user = [PSCustomObject]@{
            OU = Read-Host "Enter the Organizational Unit (OU) name:"
            Group = Read-Host "Enter the group name:"
            SamAccountName = Read-Host "Enter the SamAccountName:"
            FirstName = Read-Host "Enter the first name:"
            LastName = Read-Host "Enter the last name:"
            Email = Read-Host "Enter the email address:"
            Description = Read-Host "Enter the description:"
            Password = Read-Host "Enter the password:" -AsSecureString
        }
        $users = $user | ConvertTo-Csv -NoTypeInformation | ConvertFrom-Csv
    }

    # Loop through each user in the CSV file
    foreach ($user in $users) {
        # Check if a user with the same SamAccountName already exists
        if (Get-ADUser -Filter "SamAccountName -eq '$($user.SamAccountName)'") {
            Write-Output "User $($user.SamAccountName) already exists. Skipping."
            continue
        }

        # Create the OU if it doesn't exist
        $ouPath = "OU=" + $user.OU
        if (-not (Get-ADOrganizationalUnit -Filter "Name -eq '$ouPath'")) {
            New-ADOrganizationalUnit -Name $ouPath -Path "OU=Users,DC=domain,DC=com"
        }

        # Create the group if it doesn't exist
        $groupName = $user.Group
        if (-not (Get-ADGroup -Filter "Name -eq '$groupName'")) {
            New-ADGroup -Name $groupName -GroupCategory Security -GroupScope Global -Path "OU=$ouPath,OU=Users,DC=domain,DC=com"
        }

        # Create a new user object
        $newUser = New-ADUser -SamAccountName $user.SamAccountName -GivenName $user.FirstName -Surname $user.LastName -EmailAddress $user.Email -Description $user.Description -Path "OU=$ouPath,OU=Users,DC=domain,DC=com" -AccountPassword (ConvertTo-SecureString -String $user.Password -AsPlainText -Force) -Enabled $true

        # Add the user to the group
        Add-ADGroupMember -Identity $groupName -Members $newUser

        # Save the new user to Active Directory
        $newUser | Set-ADUser
    }

    [System.Windows.Forms.MessageBox]::Show("CSV file imported successfully.")
})
$form.Controls.Add($buttonImport)

# Show the form
$form.ShowDialog()
