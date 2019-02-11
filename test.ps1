while ($true) {
    Clear-Host
    
    Remove-Module power-nvm -Force -ErrorAction SilentlyContinue
    Import-Module -Force .\src\power-nvm.psm1
    
    nvm default 8.9
    nvm use default

    node -v

    echo $env:Path
    echo "---------"
    $x = [Environment]::GetEnvironmentVariable('Path', [EnvironmentVariableTarget]::Machine);
    echo $x

    pause
}
