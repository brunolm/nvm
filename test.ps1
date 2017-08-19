while ($true) {
    Remove-Module power-nvm -Force -ErrorAction SilentlyContinue
    Import-Module -Force .\src\power-nvm.psm1

    Clear-Host

    Get-ChildItem spec | ForEach-Object {
        Write-Host $_.Name
        . $_.FullName
        Write-Host ""
    }

    pause
}
