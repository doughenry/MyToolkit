# Define the directory to scan
$scriptDirectory = "C:\Path\To\Scripts"  # Change this to your target directory

# Get all .ps1 files in the directory (recursively)
$scriptFiles = Get-ChildItem -Path $scriptDirectory -Filter "*.ps1" -Recurse

# Define regex pattern for detecting MSOL cmdlets
$msolPattern = "\b(Get|Set|New|Remove|Add|Clear|Update)-Msol\w*\b"

# Initialize an array to store results
$results = @()

foreach ($file in $scriptFiles) {
    $content = Get-Content -Path $file.FullName -Raw

    # Check if the file contains MSOL cmdlets
    if ($content -match $msolPattern) {
        # Find all occurrences
        $matches = [regex]::Matches($content, $msolPattern) | Select-Object -ExpandProperty Value -Unique
        $results += [PSCustomObject]@{
            ScriptFile = $file.FullName
            MSOL_Cmdlets = ($matches -join ", ")
        }
    }
}

# Output results
if ($results.Count -gt 0) {
    Write-Host "Scripts using MSOL cmdlets found:`n"
    $results | Format-Table -AutoSize
} else {
    Write-Host "No scripts using MSOL cmdlets found."
}

# Optional: Export results to CSV
$results | Export-Csv -Path "$scriptDirectory\MSOL_Script_Report.csv" -NoTypeInformation
Write-Host "Report saved to $scriptDirectory\MSOL_Script_Report.csv"
