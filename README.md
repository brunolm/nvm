# nvm for Windows

Manage node installations (downloads zip files).

## Commands

```powershell
nvm default <Version>   # set version as default
nvm install <Version>   # install version
nvm ls [Filter]         # list installed versions
nvm ls-remote [Filter]  # list released versions
nvm setdir <Path>       # set NODE main dir
nvm use <Version>       # use NODE version
```

## Examples

```
nvm ls
nvm ls 8
nvm ls 8.4
nvm ls 8.4.0
nvm ls v8.4.0
nvm ls v8

nvm ls-remote
nvm ls-remote 8
nvm ls-remote 8.4
nvm ls-remote 8.4.0
nvm ls-remote v8.4.0
nvm ls-remote v8

nvm install latest
nvm install 8
nvm install 8.4
nvm install 8.4.0
nvm install v8.4.0
nvm install v8

nvm default latest
nvm default 8
nvm default 8.4
nvm default 8.4.0
nvm default v8.4.0
nvm default v8

nvm setdir "C:\Program Files\nodejs"

nvm use default
nvm use latest
nvm use 8
nvm use 8.4
nvm use 8.4.0
nvm use v8.4.0
nvm use v8
```