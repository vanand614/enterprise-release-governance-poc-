# =====================================================
# GITHUB SECURITY VALIDATION SCRIPT
# =====================================================

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

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
    "User-Agent"  = "AzureDevOpsPipeline"
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

try
{
    Write-Host ""
    Write-Host "Checking CodeQL Alerts..."

    $response = Invoke-WebRequest `
        -Uri $codeqlUri `
        -Headers $headers `
        -Method GET `
        -UseBasicParsing

    $codeqlAlerts = $response.Content | ConvertFrom-Json

    $openCodeQLAlerts = $codeqlAlerts | Where-Object {
        $_.state -eq "open"
    }

    Write-Host ""
    Write-Host "Open CodeQL Alerts: $($openCodeQLAlerts.Count)"
}
catch
{
    if ($_.Exception.Response.StatusCode.value__ -eq 404)
    {
        Write-Host ""
        Write-Host "No CodeQL alerts found."

        $openCodeQLAlerts = @()
    }
    else
    {
        Write-Host ""
        Write-Host "CODEQL API ERROR"

        Write-Host $_.Exception.Message

        exit 1
    }
}
# =====================================================
# DEPENDABOT ALERTS
# =====================================================

$dependabotUri = "https://api.github.com/repos/$repoOwner/$repoName/dependabot/alerts"

Write-Host ""
Write-Host "Dependabot URI:"
Write-Host $dependabotUri

try
{
    Write-Host ""
    Write-Host "Checking Dependabot Alerts..."

    $response = Invoke-WebRequest `
        -Uri $dependabotUri `
        -Headers $headers `
        -Method GET `
        -UseBasicParsing

    $dependabotAlerts = $response.Content | ConvertFrom-Json

    $criticalAlerts = $dependabotAlerts | Where-Object {
        $_.security_advisory.severity -eq "critical"
    }

    Write-Host ""
    Write-Host "Critical Dependabot Alerts: $($criticalAlerts.Count)"
}
catch
{
    if ($_.Exception.Response.StatusCode.value__ -eq 404)
    {
        Write-Host ""
        Write-Host "No Dependabot alerts found."

        $criticalAlerts = @()
    }
    else
    {
        Write-Host ""
        Write-Host "DEPENDABOT API ERROR"

        Write-Host $_.Exception.Message

        exit 1
    }
}

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
