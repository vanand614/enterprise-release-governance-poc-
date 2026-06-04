$Headers = @{
    Authorization = "Bearer $env:GITHUB_TOKEN"
    Accept = "application/vnd.github+json"
}

$Branch = $env:CI_COMMIT_REF_NAME

for($i=1;$i -le 20;$i++)
{
    Write-Host "Checking workflow run..."

    $Run = Invoke-RestMethod `
      -Uri "https://api.github.com/repos/$env:GITHUB_OWNER/$env:GITHUB_REPO/actions/workflows/codeql.yml/runs?branch=$Branch&per_page=1" `
      -Headers $Headers

    $Latest = $Run.workflow_runs[0]

    if($Latest.status -eq "completed")
    {
        Write-Host "CodeQL completed"
        exit 0
    }

    Start-Sleep 15
}

throw "CodeQL workflow timeout"