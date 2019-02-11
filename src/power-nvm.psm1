Add-Type -AssemblyName System.IO.Compression.FileSystem
function Unzip
{
    param([string]$zipfile, [string]$outpath)

    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outpath)
}

function Add-DirToPath($Path, [Switch] $Permanent) {
    if ($Path) {
        Remove-DirFromPath $Path
    }

    $newPath = $env:Path -split ";";
    $newPath = ($newPath | Where-Object { $_ -notlike "$env:NODE_DIR\version*" -and $_.Length -gt 0 });

    if ($Path) {
        $newPath = @($Path) + ($newPath);
    }

    $newPath = $newPath -join ";";

    $env:Path = $newPath;

    if ($Permanent) {
        [Environment]::SetEnvironmentVariable('Path', $newPath, [EnvironmentVariableTarget]::Machine);
    }
}

function Add-NodeDirToDefault($versionDir) {
    $defaultDir = Join-Path $env:NODE_DIR "default"

    $defaultDirInfo = Get-Item $defaultDir
    if ($defaultDirInfo) {
        $defaultDirInfo.Delete()
    }
    
    New-Item -Path $defaultDir -ItemType SymbolicLink -Value $versionDir | Out-Null
}
function Add-NodeDirToPath() {
    $defaultDir = Join-Path $env:NODE_DIR "default"

    Remove-NodeDirFromPath
    Add-DirToPath $env:NODE_DIR -Permanent
    Add-DirToPath $defaultDir -Permanent
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
    $newPath = $newPath -join ";"

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

    $defaultDir = Join-Path $env:NODE_DIR "default"
    Remove-DirFromPath $env:NODE_DIR -Permanent
    Remove-DirFromPath $defaultDir -Permanent
}

function YesNoQuestion($question, $message, $defaultOpt = 1) {
    $choices = New-Object Collections.ObjectModel.Collection[Management.Automation.Host.ChoiceDescription]
    $choices.Add((New-Object Management.Automation.Host.ChoiceDescription -ArgumentList '&Yes', 'Continue'))
    $choices.Add((New-Object Management.Automation.Host.ChoiceDescription -ArgumentList '&No', 'Cancel'))

    $decision = $Host.UI.PromptForChoice($question, $message, $choices, $defaultOpt)
    
    if ($decision -eq 0) {
        return $true;
    }

    return $false;
}

function Add-PermanentEnv($Key, $Value) {
    [Environment]::SetEnvironmentVariable($Key, $Value, [EnvironmentVariableTarget]::Machine);
    Set-Item "env:$Key" $Value
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
    $global:progressPreference = 'silentlyContinue';
    Write-Host "Retrieving versions...";
    $versions = Invoke-WebRequest -Uri https://nodejs.org/dist/index.json | ConvertFrom-Json;
    $global:progressPreference = 'Continue';

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
    $versionsDir = Get-NodeVersionsDir;

    $finalDir = Join-Path $versionsDir $versionToInstall;

    if (Test-Path $finalDir -PathType Container) {
        if (!(YesNoQuestion "Version already exists. Overwrite?" "Globally installed packages will be lost.")) {
            Write-Host "Cancelling..."
            return;
        }
    }
    
    $versionTag = $( if ([Environment]::Is64BitOperatingSystem) { "x64" } else { "x86" } );
    $downloadUrl = "https://nodejs.org/dist/$versionToInstall/node-$versionToInstall-win-$versionTag.zip";
    
    $dest = (Join-Path $env:TEMP "node-${versionToInstall}.zip");
    Invoke-WebRequest $downloadUrl -OutFile $dest;
    
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

    _fixNpm $targetDir

    if (YesNoQuestion "Would you like to make this version default?" "" 0) {
        Set-NodeDefault $versionToInstall
    }
}
function _sym(
    [string]
    [Parameter(mandatory=$true)]
    $dir,

    [string]
    [Parameter(mandatory=$true)]
    [ValidatePattern('^(npm|npx)([.]cmd)?$')]
    $name
) {
    $dir = ($dir -replace "\\$","");
    $target = "$dir\node_modules\npm\bin\$name";

    if (!(Test-Path $target -PathType Leaf)) {
        return;
    }

    Remove-Item "$dir\$name";
    Remove-Item "$dir\$name.cmd";
    New-Item -ItemType SymbolicLink -Path "$dir\$name" -Target $target;
    New-Item -ItemType SymbolicLink -Path "$dir\$name.cmd" -Target "$target.cmd";
}
function _fixNpm(
    [string]
    [Parameter(mandatory=$true)]
    $dir
) {
    _sym $dir "npm"
    _sym $dir "npx"
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

    Add-DirToPath $pathToInstall -Permanent
    Add-NodeDirToDefault $pathToInstall;
    Add-PermanentEnv "NODE_DEFAULT" $pathToInstall
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
    Unonstall node in versions folder under node main dir
.Description
    Downloads node zip file and extracts to node main dir under versions folder.
    Then sets the path (of the current session) to the extracted folder.
.Parameter $Version
    Node version to Uninstall.
.Example
    nvm Uninstall latest
.Example
    nvm Uninstall 8
.Example
    nvm Uninstall 8.4
.Example
    nvm Uninstall 8.4.0
.Example
    nvm Uninstall v8.4.0
.Example
    nvm Uninstall v8
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
    else {
        Add-DirToPath
        return
    }

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
