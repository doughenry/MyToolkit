# Requires running as SharePoint Farm Administrator
Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue

$report = @()

# 1. SharePoint Version & Farm Details
$version = (Get-SPFarm).BuildVersion
$farmID = (Get-SPFarm).Id.Guid
$report += "SharePoint Farm Version: $version"
$report += "Farm ID: $farmID"

# 2. Servers in the Farm
$servers = Get-SPServer | Select-Object Name, Role
$report += "`nSharePoint Farm Servers:"
$servers | ForEach-Object { $report += "  $_.Name - Role: $_.Role" }

# 3. Web Applications & Authentication Methods
$webApps = Get-SPWebApplication | Select-Object Url, UseClaimsAuthentication
$report += "`nWeb Applications:"
$webApps | ForEach-Object { 
    $authMethod = If ($_.UseClaimsAuthentication) { "Claims-Based" } else { "Classic Mode" }
    $report += "  $_.Url - Authentication: $authMethod"
}

# 4. Databases & SQL Server Details
$report += "`nDatabases:"
Get-SPDatabase | Select-Object Name, TypeName, Server | ForEach-Object { 
    $report += "  $_.Name - Type: $_.TypeName - Hosted on: $_.Server"
}

# 5. Installed Updates
$updates = Get-HotFix | Where-Object { $_.Description -like "*Update*" }
$report += "`nInstalled SharePoint Updates:"
$updates | ForEach-Object { $report += "  $_.HotFixID - Installed on: $_.InstalledOn" }

# 6. Service Accounts & Administrators
$farmAdminGroup = (Get-SPFarm).Administrators
$report += "`nFarm Administrators:"
$farmAdminGroup | ForEach-Object { $report += "  $_" }

# 7. Performance Metrics (Cache Size, Disk Space)
$cache = Get-SPServiceApplication | Where-Object { $_.TypeName -like "*Cache*" }
$report += "`nCache Settings:"
$cache | ForEach-Object { $report += "  $_.Name - Status: $_.Status" }

$drives = Get-PSDrive -PSProvider FileSystem | Select-Object Name, Used, Free
$report += "`nDisk Space:"
$drives | ForEach-Object { $report += "  Drive $_.Name - Used: $($_.Used/1GB) GB - Free: $($_.Free/1GB) GB" }

# 8. Active Timer Jobs
$timerJobs = Get-SPTimerJob | Select-Object DisplayName, LastRunTime, IsDisabled
$report += "`nActive Timer Jobs:"
$timerJobs | Where-Object { -not $_.IsDisabled } | ForEach-Object { 
    $report += "  $_.DisplayName - Last Run: $_.LastRunTime"
}

# 9. SSL Certificates (Expiring in 90 Days)
$report += "`nSSL Certificates Expiring Soon:"
$certs = Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object { $_.NotAfter -lt (Get-Date).AddDays(90) }
$certs | ForEach-Object { 
    $report += "  $_.Subject - Expiry Date: $($_.NotAfter)"
}

# 10. Backup & Recovery
$backupLocation = "C:\SharePointBackups"  # Change this if necessary
$backups = Get-ChildItem -Path $backupLocation | Sort-Object LastWriteTime -Descending | Select-Object -First 5
$report += "`nRecent Backups:"
$backups | ForEach-Object { $report += "  $_.Name - Date: $_.LastWriteTime" }

# Output Report
$report | Out-File "C:\SharePoint_Farm_Report.txt"
Write-Host "Report generated at C:\SharePoint_Farm_Report.txt"
