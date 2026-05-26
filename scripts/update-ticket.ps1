. "$PSScriptRoot\variables.ps1"
 
$ticketId = $env:ticketId
 
Write-Host ""
Write-Host "======================================"
Write-Host "Updating Deployment Status"
Write-Host "======================================"
 
Write-Host "Ticket ID: $ticketId"
 
# =====================================================
# UPDATE BODY
# =====================================================
 
$updateBody = @{
 
    status = 3
 
    resolution_notes = @"
Deployment approved and started.
 
Environment : QA
Deployment Status : IN PROGRESS
 
Build Number : $BuildNumber
"@
}
 
$updateJson = $updateBody | ConvertTo-Json -Depth 10
 
# =====================================================
# URI
# =====================================================
 
$uri = "https://$domain.freshservice.com/api/v2/tickets/$ticketId"
 
Write-Host ""
Write-Host "Updating URI:"
Write-Host $uri
 
# =====================================================
# API CALL
# =====================================================
 
$response = Invoke-RestMethod -Uri $uri `
                              -Method PUT `
                              -Headers $headers `
                              -Body $updateJson
 
Write-Host ""
Write-Host "SUCCESS - Ticket Updated To Pending"

Write-Host ""
Write-Host "Pipeline URL:"
Write-Host $PipelineUrl