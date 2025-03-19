# Load SharePoint PowerShell Snapin
Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue

# Define output file
$outputFile = "C:\SharePoint_SiteCollections_Report.txt"
$report = @()

# Get all site collections
$siteCollections = Get-SPSite -Limit All

foreach ($site in $siteCollections) {
    $report += "========================================="
    $report += "Site Collection: $($site.Url)"
    $report += "========================================="
    
    # 1. General Information
    $report += "Owner: $($site.Owner.LoginName)"
    $report += "Secondary Owner(s): $($site.SecondaryContact.LoginName)"
    $report += "Storage Used (MB): $([math]::Round($site.Usage.Storage / 1MB, 2))"
    $report += "Created On: $($site.RootWeb.Created)"
    $report += "Template: $($site.RootWeb.WebTemplate)"

    # 2. Structure & Content
    $subsites = $site.AllWebs | Where-Object { $_.Url -ne $site.Url }
    $report += "Number of Subsites: $($subsites.Count)"
    $report += "Largest List/Library: $((Get-SPWeb $site.Url).Lists | Sort-Object ItemCount -Descending | Select-Object -First 1 -Property Title, ItemCount | Format-Table -HideTableHeaders | Out-String)"

    # 3. Security & Permissions
    $users = Get-SPUser -Web $site.RootWeb.Url | Select-Object DisplayName, LoginName
    $report += "Total Unique Users: $($users.Count)"
    $report += "Total Site Groups: $((Get-SPWeb $site.Url).SiteGroups.Count)"
    $report += "External Users: $($users | Where-Object { $_.LoginName -like '*@*' } | Measure-Object | Select-Object -ExpandProperty Count)"

    # 4. Customizations
    $customScripts = $site.RootWeb.UserCustomActions | Where-Object { $_.Title -ne "" }
    $report += "Custom Scripts Installed: $($customScripts.Count)"
    
    # 5. Workflows & Automation
    $workflows = $site.RootWeb.WorkflowAssociations | Where-Object { $_.Enabled -eq $true }
    $report += "Enabled Workflows: $($workflows.Count)"

    # 6. Performance & Maintenance
    $report += "Last Content Audit: $($site.LastContentModifiedDate)"
    $report += "Quota (MB): $($site.Quota.StorageMaximumLevel / 1MB)"

    # 7. Backup & Recovery
    $backupPath = "C:\SharePointBackups\$($site.Url.Replace('http://', '').Replace('https://', '').Replace('/', '_')).bak"
    if (Test-Path $backupPath) {
        $report += "Last Backup Date: $((Get-Item $backupPath).LastWriteTime)"
    } else {
        $report += "Last Backup Date: NOT FOUND"
    }
    
    $report += "`n"
}

# Output Report
$report | Out-File $outputFile
Write-Host "Report generated at $outputFile"
