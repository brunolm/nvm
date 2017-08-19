Set-Location src
Write-Host -ForegroundColor Green "Publishing..."
Publish-Module -Name .\power-nvm.psm1 -NuGetApiKey $env:POWERSHELL_GALLERY_KEY;
Set-Location ..
