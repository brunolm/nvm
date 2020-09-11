# DEPRECATED

This project has some issues with initial installation and is slow. Instead of it use [nvs](https://github.com/jasongin/nvs).

---

# power-nvm

power-nvm is a `nvm` version for Windows. It manages node versions on your machine.

It creates a folder `versions` under your node root dir and install each version on its folder, allowing you to have isolated global packages and settings.

When you switch versions it changes the `path`, you can do it temporarily (`nvm use`) or permanently (`nvm default <Version>`).

It will set and depend on two env variables: `NODE_DIR` and `NODE_DEFAULT`.

## Install

```powershell
Install-Module -Name power-nvm
```

### First time install

If you don't have node yet on your machine you might want to execute

```powershell
nvm install latest
# Answer [Y] to make it default version
```

## Commands

```powershell
nvm install <Version>   # install version
nvm use [Version]       # use NODE version (supports .nvmrc)
nvm default <Version>   # set version as default

nvm ls [Filter]         # list installed versions
nvm ls-remote [Filter]  # list released versions

nvm setdir <Path>       # set NODE main dir
nvm uninstall <Version> # remove installation folder of a specific version
```

More help: `nvm <command> -help`

## Examples

```
nvm install latest
nvm install 11
nvm install 11.2
nvm install 11.2.0
nvm install v11.2.0
nvm install v11

nvm use # reads version from .nvmrc file
nvm use default
nvm use latest
nvm use 11
nvm use 11.2
nvm use 11.2.0
nvm use v11.2.0
nvm use v11

nvm default latest
nvm default 11
nvm default 11.2
nvm default 11.2.0
nvm default v11.2.0
nvm default v11


nvm ls
nvm ls 11
nvm ls 11.2
nvm ls 11.2.0
nvm ls v11.2.0
nvm ls v11

nvm ls-remote
nvm ls-remote 11
nvm ls-remote 11.2
nvm ls-remote 11.2.0
nvm ls-remote v11.2.0
nvm ls-remote v11


nvm setdir "C:\Program Files\nodejs"

nvm uninstall latest
nvm uninstall 11
nvm uninstall 11.2
nvm uninstall 11.2.0
nvm uninstall v11.2.0
nvm uninstall v11
```

### .nvmrc file example

```
v11.2.0
```

## Breaking changes

- `v0.x` --> `v1.x`
  - root path is no longer used; now uses `versions/v#.#.#`
  - `nvm default <Version>` sets `$env:NODE_DEFAULT` and `npm use default` depends on this, so you have to redefine default
