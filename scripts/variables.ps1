# =====================================================
# VARIABLES
# =====================================================
 
$domain = "valuemomentum"
$apiKey = "PNrOk8Uu3eWtE8nzyuIe"
 
$BuildNumber = $env:BUILD_BUILDNUMBER
$BuildId = $env:BUILD_BUILDID
$Branch = $env:BUILD_SOURCEBRANCHNAME
 
$PipelineUrl = "$env:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI$env:SYSTEM_TEAMPROJECT/_build/results?buildId=$BuildId"
 
Write-Host "Domain Value: $domain"
Write-Host "API Key Exists: $($apiKey -ne $null)"
 
# =====================================================
# AUTHENTICATION
# =====================================================
 
$pair = "$($apiKey):X"
 
$encodedCreds = [Convert]::ToBase64String(
    [Text.Encoding]::ASCII.GetBytes($pair)
)
 
$headers = @{
    Authorization = "Basic $encodedCreds"
    "Content-Type" = "application/json"
}