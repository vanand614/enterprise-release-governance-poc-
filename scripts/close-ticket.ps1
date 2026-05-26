. "$PSScriptRoot\variables.ps1"
 
$ticketId = $env:ticketId
 
Write-Host ""

Write-Host "======================================"

Write-Host "Closing Deployment Ticket"

Write-Host "======================================"
 
Write-Host "Ticket ID: $ticketId"
 
# =====================================================

# CLOSURE BODY

# =====================================================
 
$closeBody = @{
 
    status = 5
 
    resolution_notes = @"

Deployment completed successfully.
 
Environment : QA

Deployment Status : SUCCESS
 
Build Number : $BuildNumber

Build ID     : $BuildId

Branch       : $Branch
 
Pipeline URL :

$PipelineUrl
 
Closure Time :

$(Get-Date)

"@

}
 
$closeJson = $closeBody | ConvertTo-Json -Depth 10
 
# =====================================================

# URI

# =====================================================
 
$uri = "https://$domain.freshservice.com/api/v2/tickets/$ticketId"
 
Write-Host ""

Write-Host "Closing URI:"

Write-Host $uri
 
# =====================================================

# API CALL

# =====================================================
 
$response = Invoke-RestMethod -Uri $uri `

                              -Method PUT `

                              -Headers $headers `

                              -Body $closeJson
 
Write-Host ""

Write-Host "SUCCESS - Ticket Closed"
 