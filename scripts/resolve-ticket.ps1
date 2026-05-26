. "$PSScriptRoot\variables.ps1"
 
$ticketId = $env:ticketId
 
Write-Host ""
Write-Host "======================================"
Write-Host "Resolving Deployment Ticket"
Write-Host "======================================"
 
Write-Host "Ticket ID: $ticketId"
 
Write-Host ""
Write-Host "Build Number : $BuildNumber"
Write-Host "Build ID     : $BuildId"
Write-Host "Branch       : $Branch"
 
Write-Host ""
Write-Host "Pipeline URL:"
Write-Host $PipelineUrl
 
$resolveBody = @{
 
    status = 4
 
    resolution_notes = @"
Deployment completed successfully.
 
Environment : QA
Deployment Status : RESOLVED
 
Build Number : $BuildNumber
Build ID     : $BuildId
Branch       : $Branch
 
Pipeline URL :
$PipelineUrl
 
Resolution Time :
$(Get-Date)
"@
}
 
$resolveJson = $resolveBody | ConvertTo-Json -Depth 10
 
$uri = "https://$domain.freshservice.com/api/v2/tickets/$ticketId"
 
Write-Host ""
Write-Host "Resolve URI:"
Write-Host $uri
 
$response = Invoke-RestMethod `
                -Uri $uri `
                -Method PUT `
                -Headers $headers `
                -Body $resolveJson
 
Write-Host ""
Write-Host "SUCCESS - Ticket Resolved"