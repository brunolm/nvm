function Unzip
{
    param([string]$zipfile, [string]$outpath)

    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outpath)
}

function Add-DirToPath($Path, [Switch] $Permanent) {
    Remove-DirFromPath $Path

    $newPath = @($Path) + ($env:Path -split ";");
    $newPath = $newPath -join ";";

    $env:Path = $newPath;

    if ($Permanent) {
        [Environment]::SetEnvironmentVariable('Path', $newPath, [EnvironmentVariableTarget]::Machine);
    }
}

function Add-NodeDirToPath() {
    Remove-NodeDirFromPath
    Add-DirToPath $env:NODE_DIR -Permanent
}

function Get-NodeVersionsDir() {
    $dir = Join-Path $env:NODE_DIR "versions";
    if (!(Test-Path $dir)) {
        New-Item $dir -Type Directory
    }
    return $dir;
}

function Get-YesNo($Question) {
    do
    {
        $answer = Read-Host "$Question (Y/n)"
    } while (($answer -ne "y") -and ($answer -ne "n"));

    return $answer -eq "y";
}

function Remove-DirFromPath($Path, [Switch] $Permanent) {
    $newPath = ($env:Path -split ";") | Where-Object { $_ -ne "$Path\" -and $_ -ne $Path }

    $env:PathBackup = $env:Path;
    $env:Path = $newPath -join ";";

    if ($Permanent) {
        [Environment]::SetEnvironmentVariable('Path', $newPath, [EnvironmentVariableTarget]::Machine);
    }
}

function Remove-NodeDirFromPath() {
    if (!$env:NODE_DIR) {
        return;
    }

    Remove-DirFromPath $env:NODE_DIR -Permanent
}


<#
.Synopsis
    Lists all installed node versions from this module.
.Description
    Lists all node versions downloaded into node main dir under versions folder.
.Parameter $Filter
    Node version to filter.
.Example
    nvm ls
.Example
    nvm ls 8
.Example
    nvm ls 8.4
.Example
    nvm ls 8.4.0
.Example
    nvm ls v8.4.0
.Example
    nvm ls v8
#>
function Get-InstalledNode(
    [string]
    [ValidatePattern('^(v?\d{1,2}([.]\d+){0,2})|v$')]
    $Filter
) {
    $Filter = "v" + $Filter.ToString().Replace("v", "");

    $dir = Get-NodeVersionsDir;
    Get-ChildItem $dir `
        | Where-Object { $_.Name -like "$Filter*" } `
        | Sort-Object { [Version] ($_.Name -replace 'v', '') } -Descending `
        | Select-Object -Property @{name="Version"; expression={ $_.Name }}
}


<#
.Synopsis
    List available node versions to download
.Description
    Retrieves information from node dist index.json file listing available node versions
    to install.
.Parameter $Filter
    Node version to filter.
.Example
    nvm ls-remote
.Example
    nvm ls-remote 8
.Example
    nvm ls-remote 8.4
.Example
    nvm ls-remote 8.4.0
.Example
    nvm ls-remote v8.4.0
.Example
    nvm ls-remote v8
#>
function Get-NodeVersions(
    [string]
    [ValidatePattern('^v?\d{1,2}([.]\d+){0,2}$')]
    $Filter
) {
    $versions = Invoke-WebRequest -Uri https://nodejs.org/dist/index.json | ConvertFrom-Json
    $versions | Where-Object { $_.version.Contains($Filter) } | Select-Object -Property version,npm,date
}

<#
.Synopsis
    Install node in versions folder under node main dir
.Description
    Downloads node zip file and extracts to node main dir under versions folder.
    Then sets the path (of the current session) to the extracted folder.
.Parameter $Version
    Node version to install.
.Example
    nvm install latest
.Example
    nvm install 8
.Example
    nvm install 8.4
.Example
    nvm install 8.4.0
.Example
    nvm install v8.4.0
.Example
    nvm install v8
#>
function Install-Node(
    [string]
    [Parameter(mandatory=$true)]
    [ValidatePattern('^(v?\d{1,2}([.]\d+){0,2})|latest$')]
    $Version
) {
    $versions = Invoke-WebRequest -Uri https://nodejs.org/dist/index.json | ConvertFrom-Json;

    if ($Version -eq "latest") {
        $node = $versions | Select-Object -First 1
    }
    else {
        $Version = "v" + $Version.ToString().Replace("v", "");

        $node = $versions | Where-Object { $_.version.StartsWith($Version) } | Select-Object -First 1
    }

    Write-Host "Installing..."
    $node | Select-Object -Property version,npm,v8,date | Format-List

    $versionToInstall = $node.version;

    $versionTag = $( if ([Environment]::Is64BitOperatingSystem) { "x64" } else { "x86" } );
    $downloadUrl = "https://nodejs.org/dist/$versionToInstall/node-$versionToInstall-win-$versionTag.zip";

    $dest = (Join-Path $env:TEMP "node-${versionToInstall}.zip");
    Invoke-WebRequest $downloadUrl -OutFile $dest;

    $versionsDir = Get-NodeVersionsDir;

    try {
        7z x $dest -o"$versionsDir" -r -aoa
    }
    catch {
        Unzip $dest $versionsDir
    }

    $folder = Get-ChildItem $versionsDir | Where-Object { $_.Name -match "node-$versionToInstall" }

    $targetDir = (Join-Path $folder[0].Parent.FullName $versionToInstall);

    if (Test-Path $targetDir) {
        Remove-Item -Force -Recurse $targetDir;
    }

    Move-Item $folder[0].FullName $targetDir;
}

<#
.Synopsis
    Copy files to main node dir
.Description
    Copy the node version files to node dir making it the default installation.
.Example
    nvm default latest
.Example
    nvm default 8
.Example
    nvm default 8.4
.Example
    nvm default 8.4.0
.Example
    nvm default v8.4.0
.Example
    nvm default v8
#>
function Set-NodeDefault(
    [string]
    [Parameter(mandatory=$true)]
    [ValidatePattern('^(v?\d{1,2}([.]\d+){0,2})|latest$')]
    $Version
) {
    $versionsDir = Get-NodeVersionsDir;

    if ($Version -eq "latest") {
        $versionToInstall = (Get-InstalledNode | Select-Object -First 1).Version;
    }
    else {
        $versionToInstall = (Get-InstalledNode $Version | Select-Object -First 1).Version;
    }

    $pathToInstall = (Join-Path $versionsDir $versionToInstall);

    Get-ChildItem $pathToInstall | ForEach-Object { Copy-Item $_.FullName $env:NODE_DIR -Recurse -Force }
}

<#
.Synopsis
    Sets the dir where node is going to be installed
.Description
    Sets the dir where node is going to be installed and versions downloaded to.
.Parameter $Path
    A valid directory path, if it doesn't exist then it asks to create a new dir.
.Example
    nvm setdir "C:\Program Files\nodejs"
#>
function Set-NodeDir(
    [string]
    [ValidateScript({ !(Test-Path $_ -PathType Leaf) })]
    [Parameter(Mandatory=$true)]
    $Path
) {
    $dir = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path);

    if ($env:NODE_DIR) {
        Remove-NodeDirFromPath
    }

    if (!(Test-Path $dir -PathType Container)) {
        Write-Host "$dir not found"

        do
        {
            $shouldCreate = Read-Host "This path doesn't exists, would you like to create? (Y/n)"
        } while (($shouldCreate -ne "y") -and ($shouldCreate -ne "n") -and ($shouldCreate -ne ""));

        if ($shouldCreate -eq "y" -or !$shouldCreate) {
            New-Item $dir -ItemType Directory
        }
        else {
            return;
        }
    }

    $env:NODE_DIR = $Path;
    [Environment]::SetEnvironmentVariable('NODE_DIR', $Path, [EnvironmentVariableTarget]::Machine);
    Add-NodeDirToPath
}


<#
.Synopsis
    Install node in versions folder under node main dir
.Description
    Downloads node zip file and extracts to node main dir under versions folder.
    Then sets the path (of the current session) to the extracted folder.
.Parameter $Version
    Node version to install.
.Example
    nvm install latest
.Example
    nvm install 8
.Example
    nvm install 8.4
.Example
    nvm install 8.4.0
.Example
    nvm install v8.4.0
.Example
    nvm install v8
#>
function Uninstall-Node(
    [string]
    [Parameter(mandatory=$true)]
    [ValidatePattern('^(v?\d{1,2}([.]\d+){0,2})|latest$')]
    $Version
) {
    $versionsDir = Get-NodeVersionsDir;

    if ($Version -eq "latest") {
        $versionToUninstall = (Get-InstalledNode | Select-Object -First 1).Version;
    }
    else {
        $versionToUninstall = (Get-InstalledNode $Version | Select-Object -First 1).Version;
    }

    $pathToUninstall = (Join-Path $versionsDir $versionToUninstall);

    Remove-Item $pathToUninstall -Recurse -Force
}

<#
.Synopsis
    Set the default node installation on node dir
.Description
    Copy the node version files to node dir making it the default installation.
.Parameter $Version
    Node version to use.
.Example
    nvm use default
.Example
    nvm use latest
.Example
    nvm use 8
.Example
    nvm use 8.4
.Example
    nvm use 8.4.0
.Example
    nvm use v8.4.0
.Example
    nvm use v8
#>
function Use-Node(
    [string]
    [ValidatePattern('^(v?\d{1,2}([.]\d+){0,2})|latest|default$')]
    $Version
) {
    if (!$Version) {
        # Look for .nvmrc
        $nvmrc = Join-Path $pwd ".nvmrc";
        if (Test-Path $nvmrc -PathType Leaf) {
            $rcVersion = (Get-Content $nvmrc) -split "`n" | Select-Object -First 1;

            if ($rcVersion) {
                return Use-Node $rcVersion;
            }

            throw ".nvmrc is empty";
        }

        throw ".nvmrc file not found";
    }

    $versionsDir = Get-NodeVersionsDir;

    if ($Version -ne "default") {
        if ($Version -eq "latest") {
            $versionToInstall = (Get-InstalledNode | Select-Object -First 1).Version;
        }
        else {
            $versionToInstall = (Get-InstalledNode $Version | Select-Object -First 1).Version;
        }
        $pathToInstall = (Join-Path $versionsDir $versionToInstall);
    }

    # Node might not yet be installed
    try {
        $currentNodeVersion = node -v;
        Remove-DirFromPath (join-path $versionsDir $currentNodeVersion)
    }
    catch { }

    if ($pathToInstall) {
        Add-DirToPath $pathToInstall;
    }

    node -v
    npm -v
}

$commandMap = @{
    default = "Set-NodeDefault";
    install = "Install-Node";
    ls = "Get-InstalledNode";
    "ls-remote" = "Get-NodeVersions";
    setdir = "Set-NodeDir";
    uninstall = "Uninstall-Node";
    use = "Use-Node";
};

<#
.Synopsis
    Helps manage node installations.
.Description
    Manage node installations.

    COMMANDS

        nvm default
        nvm install
        nvm ls
        nvm ls-remote
        nvm setdir
        nvm use

    Pass `-help` to get more info (ex: `nvm use -help`)
#>
function nvm(
    [ValidateSet(
        "default",
        "install",
        "ls-remote",
        "ls",
        "setdir",
        "uninstall",
        "use"
    )]
    $Command,
    [Switch]
    $Help
) {
    if (!$env:NODE_DIR) {
        Write-Host -ForegroundColor Yellow "[WARNING] env:NODE_DIR not found, trying to set to $dir"

        $dir = Join-Path $env:ProgramFiles "nodejs";
        $env:NODE_DIR = $dir;
        Set-NodeDir $dir
    }

    if (!(Test-Path $env:NODE_DIR)) {
        if ($Command -ne "setdir") {
            Write-Host "Node dir must be set first, nvm setdir <Path>"
            return;
        }
    }

    if ($Command) {
        if ($Help) {
            & Get-Help $commandMap.$Command @args
            Write-Host "COMMAND"
            Write-Host "    nvm $Command"
        }
        else {
            & $commandMap.$Command @args
        }
    }
    else {
        Get-Help nvm
    }
}

Export-ModuleMember -Function nvm


## Install
if (!$env:NODE_DIR) {
    $dir = Join-Path $env:ProgramFiles "nodejs";
    $env:NODE_DIR = $dir;
}

Set-NodeDir $env:NODE_DIR
