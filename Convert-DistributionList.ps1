# Import the Exchange Online module
Import-Module ExchangeOnlineManagement

# Connect to Exchange Online
$Session = Connect-ExchangeOnline -ShowBanner:$false

# Variables
$DistributionListName = "YourDistributionListName" # Replace with the name of the distribution list

# Step 1: Get the distribution list details
$DistributionList = Get-DistributionGroup -Identity $DistributionListName

if (-not $DistributionList) {
    Write-Error "Distribution List '$DistributionListName' not found."
    Disconnect-ExchangeOnline -Confirm:$false
    return
}

# Generate a temporary alias for the old distribution list
$TemporaryAlias = "$($DistributionList.Alias)-temp"

# Step 2: Rename the original distribution list alias to avoid conflicts
Write-Host "Renaming the alias of the distribution list to '$TemporaryAlias'..."
Set-DistributionGroup -Identity $DistributionListName -Alias $TemporaryAlias
Write-Host "Alias updated to '$TemporaryAlias'."

# Step 3: Create a new mail-enabled security group in Azure AD
$SecurityGroupName = "$($DistributionList.DisplayName)-Security"
Write-Host "Creating a mail-enabled security group: $SecurityGroupName"

# Use Microsoft Graph API or Azure AD module to create a new security group
Install-Module -Name AzureAD -Force -Scope CurrentUser -AllowClobber
Connect-AzureAD

$NewSecurityGroup = New-AzureADGroup -DisplayName $SecurityGroupName -MailEnabled $true -SecurityEnabled $true -MailNickName $($DistributionList.Alias)

Write-Host "Mail-enabled security group '$SecurityGroupName' created successfully."

# Step 4: Copy members from the distribution list to the security group
$Members = Get-DistributionGroupMember -Identity $DistributionListName

foreach ($Member in $Members) {
    Write-Host "Adding $($Member.DisplayName) to $SecurityGroupName"
    Add-AzureADGroupMember -ObjectId $NewSecurityGroup.ObjectId -RefObjectId $Member.ExternalDirectoryObjectId
}

Write-Host "Members copied successfully."

# Step 5: Optionally delete the old distribution list
$DeleteOldDL = Read-Host "Do you want to delete the old distribution list? (Yes/No)"
if ($DeleteOldDL -eq "Yes") {
    Remove-DistributionGroup -Identity $DistributionListName -Confirm:$false
    Write-Host "Old distribution list '$DistributionListName' deleted successfully."
} else {
    # Restore the original alias for the distribution list if not deleting
    Write-Host "Restoring the original alias for the distribution list..."
    Set-DistributionGroup -Identity $DistributionListName -Alias $($DistributionList.Alias)
    Write-Host "Original alias restored."
}

# Disconnect sessions
Disconnect-ExchangeOnline -Confirm:$false
Disconnect-AzureAD

Write-Host "Process completed successfully."
