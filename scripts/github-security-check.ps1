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
 
    Write-Host ""
    Write-Host "HTTP Status:"
    Write-Host $response.StatusCode
 
    Write-Host ""
    Write-Host "===== RAW CODEQL RESPONSE ====="
    Write-Host $response.Content
    Write-Host "==============================="
 
    $codeqlAlerts = $response.Content | ConvertFrom-Json
 
    Write-Host ""
    Write-Host "Object Type:"
    Write-Host $codeqlAlerts.GetType().FullName
 
    foreach ($alert in @($codeqlAlerts))
    {
        Write-Host ""
        Write-Host "Alert State : $($alert.state)"
 
        if ($alert.rule)
        {
            Write-Host "Alert Rule  : $($alert.rule.id)"
        }
    }
 
    $openCodeQLAlerts = @(
        $codeqlAlerts | Where-Object {
            $_.state -eq "open"
        }
    )
 
    $openCount = $openCodeQLAlerts.Count
 
    Write-Host ""
    Write-Host "Open CodeQL Alerts: $openCount"
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

    $highAlerts = @(
        $dependabotAlerts | Where-Object {
            $_.security_advisory.severity -eq "high"
        }
    )

    $criticalAlerts = @(
        $dependabotAlerts | Where-Object {
            $_.security_advisory.severity -eq "critical"
        }
    )

    $highOrCriticalAlerts = @(
        $dependabotAlerts | Where-Object {
            $_.security_advisory.severity -eq "high" -or
            $_.security_advisory.severity -eq "critical"
        }
    )

    Write-Host ""
    Write-Host "Open Dependabot Alerts: $($dependabotAlerts.Count)"

    Write-Host ""
    Write-Host "High Dependabot Alerts: $($highAlerts.Count)"

    Write-Host ""
    Write-Host "Critical Dependabot Alerts: $($criticalAlerts.Count)"

    Write-Host ""
    Write-Host "High/Critical Dependabot Alerts: $($highOrCriticalAlerts.Count)"
}
catch
{
    if ($_.Exception.Response.StatusCode.value__ -eq 404)
    {
        Write-Host ""
        Write-Host "No Dependabot alerts found."

        $highAlerts = @()
        $criticalAlerts = @()
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
# REPORT GENERATION
# =====================================================

New-Item `    -ItemType Directory`
-Path reports `
-Force | Out-Null

$html = @"

<html>

<head>

<title>GitHub Security Report</title>

<style>

body {
    font-family: Arial;
    margin: 20px;
}

table {
    border-collapse: collapse;
    width: 100%;
}

th, td {
    border: 1px solid black;
    padding: 8px;
}

th {
    background-color: #f2f2f2;
}

</style>

</head>

<body>

<h1>GitHub Security Report</h1>

<p>
<b>Repository:</b> $repoName
</p>

<p>
<b>Generated:</b> $(Get-Date)
</p>

<h2>CodeQL Alerts</h2>

<table>

<tr>
<th>Rule</th>
<th>Severity</th>
<th>State</th>
<th>Branch</th>
</tr>

"@

foreach ($alert in $openCodeQLAlerts)
{
$html += @"

<tr>
<td>$($alert.rule.id)</td>
<td>$($alert.rule.security_severity_level)</td>
<td>$($alert.state)</td>
<td>$($alert.most_recent_instance.ref)</td>
</tr>

"@
}

$html += @"

</table>

<br/>

<h2>Dependabot High/Critical Alerts</h2>

<table>

<tr>
<th>Severity</th>
<th>State</th>
</tr>

"@

foreach ($alert in $highOrCriticalAlerts)
{
$html += @"

<tr>
<td>$($alert.security_advisory.severity)</td>
<td>$($alert.state)</td>
</tr>

"@
}

$html += @"

</table>

</body>

</html>

"@

$html |
Out-File `    -FilePath reports/security-report.html`
-Encoding UTF8

Write-Host ""
Write-Host "======================================"
Write-Host "REPORT GENERATED"
Write-Host "======================================"
Write-Host "reports/security-report.html"
Write-Host ""

# =====================================================
# SECURITY GATE
# =====================================================

$securityFailure = $false

if ($openCount -gt 0)
{
    Write-Host ""
    Write-Host "======================================"
    Write-Host "CODEQL SECURITY FAILURE"
    Write-Host "======================================"

    $securityFailure = $true
}

if ($highOrCriticalAlerts.Count -gt 0)
{
    Write-Host ""
    Write-Host "======================================"
    Write-Host "DEPENDABOT SECURITY FAILURE"
    Write-Host "======================================"

    $securityFailure = $true
}

if ($securityFailure)
{
    Write-Host ""
    Write-Host "SECURITY GATE FAILED"

    exit 1
}

Write-Host ""
Write-Host "======================================"
Write-Host "SECURITY VALIDATION PASSED"
Write-Host "======================================"

exit 0

