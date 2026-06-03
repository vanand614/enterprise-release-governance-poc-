# =====================================================
# GITHUB SECURITY VALIDATION SCRIPT
# =====================================================

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$githubToken = $env:GITHUB_TOKEN
$repoOwner   = $env:GITHUB_OWNER
$repoName    = $env:GITHUB_REPO

Write-Host ""
Write-Host "GitHub Owner: $repoOwner"
Write-Host "GitHub Repo: $repoName"
Write-Host "GitHub Token Exists: $($null -ne $githubToken)"

# =====================================================
# HEADERS
# =====================================================

$headers = @{
    Authorization = "Bearer $githubToken"
    Accept        = "application/vnd.github+json"
    "User-Agent"  = "GitLabPipeline"
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

    Write-Host ""
    Write-Host "HTTP Status:"
    Write-Host $response.StatusCode

    $codeqlAlerts = $response.Content | ConvertFrom-Json

    Write-Host $codeqlAlerts

    $openCodeQLAlerts = @(
        $codeqlAlerts | Where-Object {
            $_.state -eq "open"
        }
    )

    $openCount = $openCodeQLAlerts.Count

    Write-Host ""
    Write-Host "Open CodeQL Alerts: $openCount"

    foreach ($alert in $openCodeQLAlerts)
    {
        Write-Host ""
        Write-Host "--------------------------------------"

        if ($alert.rule)
        {
            Write-Host "Rule     : $($alert.rule.id)"
            Write-Host "Severity : $($alert.rule.security_severity_level)"
        }

        Write-Host "State    : $($alert.state)"
    }
}
catch
{
    if ($_.Exception.Response.StatusCode.value__ -eq 404)
    {
        Write-Host ""
        Write-Host "No CodeQL alerts found."

        $openCount = 0
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

    $highOrCriticalAlerts = @(
        $dependabotAlerts | Where-Object {
            $_.security_advisory.severity -in @(
                "high",
                "critical"
            )
        }
    )

    Write-Host ""
    Write-Host "High/Critical Dependabot Alerts: $($highOrCriticalAlerts.Count)"

    foreach ($alert in $highOrCriticalAlerts)
    {
        Write-Host ""
        Write-Host "--------------------------------------"

        if ($alert.dependency.package)
        {
            Write-Host "Package  : $($alert.dependency.package.name)"
        }

        Write-Host "Severity : $($alert.security_advisory.severity)"
        Write-Host "State    : $($alert.state)"
    }
}
catch
{
    if ($_.Exception.Response.StatusCode.value__ -eq 404)
    {
        Write-Host ""
        Write-Host "No Dependabot alerts found."

        $highOrCriticalAlerts = @()
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

$securityFailure = $false

Write-Host ""
Write-Host "======================================"
Write-Host "SECURITY GATE VALIDATION"
Write-Host "======================================"

if ($openCount -gt 0)
{
    Write-Host ""
    Write-Host "CODEQL SECURITY FAILURE"
    Write-Host "Open CodeQL Alerts: $openCount"

    $securityFailure = $true
}

if ($highOrCriticalAlerts.Count -gt 0)
{
    Write-Host ""
    Write-Host "DEPENDABOT SECURITY FAILURE"
    Write-Host "High/Critical Alerts: $($highOrCriticalAlerts.Count)"

    $securityFailure = $true
}

if ($securityFailure)
{
    Write-Host ""
    Write-Host "======================================"
    Write-Host "SECURITY GATE FAILED"
    Write-Host "DEPLOYMENT BLOCKED"
    Write-Host "======================================"

    exit 1
}

Write-Host ""
Write-Host "======================================"
Write-Host "SECURITY VALIDATION PASSED"
Write-Host "DEPLOYMENT APPROVED"
Write-Host "======================================"

exit 0