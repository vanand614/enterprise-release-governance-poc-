# =====================================================
# GITHUB SECURITY VALIDATION SCRIPT
# =====================================================
 
$githubToken = $env:githubToken
$repoOwner   = $env:githubOwner
$repoName    = $env:githubRepo
 
Write-Host ""
Write-Host "GitHub Owner: $repoOwner"
Write-Host "GitHub Repo: $repoName"
Write-Host "GitHub Token Exists: $($githubToken -ne $null)"
 
# =====================================================
# HEADERS
# =====================================================
 
$headers = @{
    Authorization = "Bearer $githubToken"
    Accept        = "application/vnd.github+json"
}
 
Write-Host ""
Write-Host "======================================"
Write-Host "GITHUB SECURITY VALIDATION"
Write-Host "======================================"
 
# =====================================================
# CODEQL ALERTS
# =====================================================
 
$codeqlUri = "https://api.github.com/repos/$repoOwner/$repoName/code-scanning/alerts"
 
Write-Host ""
Write-Host "CodeQL URI:"
Write-Host $codeqlUri
 
Write-Host ""
Write-Host "Checking CodeQL Alerts..."
 
$codeqlAlerts = Invoke-RestMethod -Uri $codeqlUri -Headers $headers -Method GET
 
$openCodeQLAlerts = $codeqlAlerts | Where-Object {
    $_.state -eq "open"
}
 
Write-Host ""
Write-Host "Open CodeQL Alerts: $($openCodeQLAlerts.Count)"
 
# =====================================================
# DEPENDABOT ALERTS
# =====================================================
 
$dependabotUri = "https://api.github.com/repos/$repoOwner/$repoName/dependabot/alerts"
 
Write-Host ""
Write-Host "Dependabot URI:"
Write-Host $dependabotUri
 
Write-Host ""
Write-Host "Checking Dependabot Alerts..."
 
$dependabotAlerts = Invoke-RestMethod -Uri $dependabotUri -Headers $headers -Method GET
 
$criticalAlerts = $dependabotAlerts | Where-Object {
    $_.security_advisory.severity -eq "critical"
}
 
Write-Host ""
Write-Host "Critical Dependabot Alerts: $($criticalAlerts.Count)"
 
# =====================================================
# SECURITY GATE
# =====================================================
 
if ($openCodeQLAlerts.Count -gt 0)
{
    Write-Host ""
    Write-Host "======================================"
    Write-Host "CODEQL SECURITY FAILURE"
    Write-Host "======================================"
 
    exit 1
}
 
if ($criticalAlerts.Count -gt 0)
{
    Write-Host ""
    Write-Host "======================================"
    Write-Host "DEPENDABOT SECURITY FAILURE"
    Write-Host "======================================"
 
    exit 1
}
 
Write-Host ""
Write-Host "======================================"
Write-Host "SECURITY VALIDATION PASSED"
Write-Host "======================================"
