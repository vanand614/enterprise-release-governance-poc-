. "$PSScriptRoot\variables.ps1"
 
Write-Host ""
Write-Host "======================================"
Write-Host "Creating Freshservice Ticket"
Write-Host "======================================"
 
$body = @{
 
    description = @"
Deployment initiated from Azure DevOps.
 
Build Number : $BuildNumber
Build ID     : $BuildId
Branch       : $Branch
 
Pipeline URL :
$PipelineUrl
"@
 
    subject = "CAB Deployment Request"
 
    email = "devops@company.com"
 
    priority = 1
 
    status = 2
 
    source = 2
}
 
$jsonBody = $body | ConvertTo-Json -Depth 10
 
$uri = "https://$domain.freshservice.com/api/v2/tickets"
 
Write-Host ""
Write-Host "Calling URI:"
Write-Host $uri
 
$response = Invoke-RestMethod -Uri $uri `
                              -Method POST `
                              -Headers $headers `
                              -Body $jsonBody
 
$ticketId = $response.ticket.id
 
Write-Host ""
Write-Host "SUCCESS - Ticket Created"
 
Write-Host "Ticket ID : $ticketId"
 
Write-Host "##vso[task.setvariable variable=ticketId;isOutput=true]$ticketId"