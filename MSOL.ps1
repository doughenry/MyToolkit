# Define the directory to search
$searchPath = "C:\Path\To\Scripts" # Change this to your scripts directory

# Define the MSOnline cmdlets to search for
$msOnlineCmdlets = @(
    "Connect-MsolService",
    "Get-MsolUser",
    "Set-MsolUser",
    "Remove-MsolUser",
    "New-MsolUser",
    "Get-MsolGroup",
    "Set-MsolGroup",
    "Remove-MsolGroup",
    "New-MsolGroup",
    "Get-MsolRole",
    "Add-MsolRoleMember",
    "Get-MsolRoleMember",
    "Remove-MsolRoleMember",
    "Get-MsolDomain",
    "Set-MsolDomain",
    "Get-MsolSubscription"
)

# Get all .ps1 files recursively
$psFiles = Get-ChildItem -Path $searchPath -Filter "*.ps1" -Recurse

# Check each script for MSOnline cmdlets
$results = foreach ($file in $psFiles) {
    $content = Get-Content -Path $file.FullName -Raw
    foreach ($cmdlet in $msOnlineCmdlets) {
        if ($content -match "\b$cmdlet\b") {
            [PSCustomObject]@{
                ScriptPath = $file.FullName
                CmdletUsed = $cmdlet
            }
        }
    }
}

# Output results
if ($results) {
    $results | Sort-Object ScriptPath | Format-Table -AutoSize
} else {
    Write-Host "No scripts using MSOnline cmdlets were found."
}
