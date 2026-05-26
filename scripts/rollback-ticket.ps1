. "$PSScriptRoot\variables.ps1"
 
$ticketId = $env:ticketId
 
Write-Host ""
Write-Host "======================================"
Write-Host "Rollback Initiated"
Write-Host "======================================"
 
Write-Host "Ticket ID: $ticketId"
 
# =====================================================
# ROLLBACK BODY
# =====================================================
 
$rollbackBody = @{
 
    status = 3
 
    resolution_notes = @"
Deployment failed.
 
Rollback initiated successfully.
 
Environment : QA
Rollback Status : COMPLETED
 
Build Number : $BuildNumber
Build ID     : $BuildId
 
Rollback Time :
$(Get-Date)
"@
}
 
$rollbackJson = $rollbackBody | ConvertTo-Json -Depth 10
 
# =====================================================
# URI
# =====================================================
 
$uri = "https://$domain.freshservice.com/api/v2/tickets/$ticketId"
 
Write-Host ""
Write-Host "Rollback URI:"
Write-Host $uri
 
# =====================================================
# API CALL
# =====================================================
 
$response = Invoke-RestMethod -Uri $uri `
                              -Method PUT `
                              -Headers $headers `
                              -Body $rollbackJson
 
Write-Host ""
Write-Host "SUCCESS - Rollback Status Updated"

Write-Host ""
Write-Host "Pipeline URL:"
Write-Host $PipelineUrl