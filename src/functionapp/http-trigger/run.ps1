using namespace System.Net

param($Request)

Write-Host "Azure function was triggered."

Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body       = @{
            message = "Hello from Azure Function!"
        }
    })
