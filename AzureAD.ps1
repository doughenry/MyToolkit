# Define the directory to scan
$scriptDirectory = "C:\Path\To\Scripts"  # Change this to your target directory

# Get all .ps1 files in the directory (recursively)
$scriptFiles = Get-ChildItem -Path $scriptDirectory -Filter "*.ps1" -Recurse

# Define regex pattern for detecting AzureAD cmdlets
$azureADPattern = "\b(Get|Set|New|Remove|Add|Clear|Update)-AzureAD\w*\b"

# Initialize an array to store results
$results = @()

foreach ($file in $scriptFiles) {
    $content = Get-Content -Path $file.FullName -Raw

    # Check if the file contains AzureAD cmdlets
    if ($content -match $azureADPattern) {
        # Find all occurrences
        $matches = [regex]::Matches($content, $azureADPattern) | Select-Object -ExpandProperty Value -Unique
        $results += [PSCustomObject]@{
            ScriptFile = $file.FullName
            AzureAD_Cmdlets = ($matches -join ", ")
        }
    }
}

# Output results
if ($results.Count -gt 0) {
    Write-Host "Scripts using AzureAD cmdlets found:`n"
    $results | Format-Table -AutoSize
} else {
    Write-Host "No scripts using AzureAD cmdlets found."
}

# Optional: Export results to CSV
$results | Export-Csv -Path "$scriptDirectory\AzureAD_Script_Report.csv" -NoTypeInformation
Write-Host "Report saved to $scriptDirectory\AzureAD_Script_Report.csv"
