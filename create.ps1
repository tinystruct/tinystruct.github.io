# tinystruct project bootstrap for Windows (PowerShell 5.1+ / 7+)
#
#   irm https://tinystruct.org/create.ps1 | iex
#
# Thin wrapper: collects the answers, then runs the POSIX installer
# (https://tinystruct.org/create) through Git Bash or WSL.
#
# Optional environment variables (skip the matching prompt):
#   TS_NAME, TS_PACKAGE, TS_TYPE (basic|web|mcp|workflow|agent or 1-5), TS_VERSION

& {
    $ErrorActionPreference = 'Stop'
    $Url = 'https://tinystruct.org/create'

    function Info($m) { Write-Host '==> ' -NoNewline -ForegroundColor Blue; Write-Host $m }
    function Ok($m)   { Write-Host ' ok ' -NoNewline -ForegroundColor Green; Write-Host $m }
    function Fail($m) { Write-Host 'error ' -NoNewline -ForegroundColor Red; Write-Host $m; return }

    # --- find a POSIX shell: Git Bash first, then WSL --------------------
    $mode = $null; $bash = $null
    $candidates = @(
        "$env:ProgramFiles\Git\bin\bash.exe",
        "${env:ProgramFiles(x86)}\Git\bin\bash.exe",
        "$env:LOCALAPPDATA\Programs\Git\bin\bash.exe"
    )
    $git = Get-Command git.exe -ErrorAction SilentlyContinue
    if ($git) {
        # <git>\cmd\git.exe  ->  <git>\bin\bash.exe
        $candidates += (Join-Path (Split-Path (Split-Path $git.Source)) 'bin\bash.exe')
    }
    foreach ($c in $candidates) {
        if ($c -and (Test-Path $c)) { $bash = $c; $mode = 'gitbash'; break }
    }
    if (-not $mode -and (Get-Command wsl.exe -ErrorAction SilentlyContinue)) {
        & wsl.exe -e true 2>$null
        if ($LASTEXITCODE -eq 0) { $mode = 'wsl' }
    }
    if (-not $mode) {
        Fail 'Neither Git Bash nor WSL was found.'
        Write-Host @'

  The installer needs a POSIX shell. Install one of:
    Git for Windows : winget install --id Git.Git -e
    WSL             : wsl --install
  Then re-run:  irm https://tinystruct.org/create.ps1 | iex
'@
        return
    }
    Ok ("Using " + $(if ($mode -eq 'gitbash') { "Git Bash ($bash)" } else { 'WSL' }))
    if ($mode -eq 'wsl') {
        Write-Host '    Note: with WSL, Java 17+ and Maven must be installed inside the WSL distribution.' -ForegroundColor Yellow
    }

    # --- collect answers (the shell has no usable TTY when launched from here)
    $name = $env:TS_NAME
    if (-not $name) { $name = Read-Host 'Project name' }
    if (-not $name) { Fail 'Project name is required.'; return }

    $pkg = $env:TS_PACKAGE
    if (-not $pkg) {
        $default = ($name.ToLower() -replace '[^a-z0-9]', '')
        if ($default -match '^[0-9]') { $default = "app$default" }
        $pkg = Read-Host "Package name [$default]"
        if (-not $pkg) { $pkg = $default }
    }

    $type = $env:TS_TYPE
    if (-not $type) {
        Write-Host '? Project type:'
        Write-Host '    1) basic     CLI + HTTP hello-world'
        Write-Host '    2) web       HTTP server with HTML page and JSON API'
        Write-Host '    3) mcp       Model Context Protocol server with a sample tool'
        Write-Host '    4) workflow  Multi-step pipeline of composable actions'
        Write-Host '    5) agent     MCP tool-calling agent scaffold'
        $type = Read-Host 'Choose [1-5] [1]'
        if (-not $type) { $type = '1' }
    }

    $env:TS_NAME = $name; $env:TS_PACKAGE = $pkg; $env:TS_TYPE = $type
    $env:NO_COLOR = ''   # let the script decide; it colors only on a terminal

    # --- download the installer (LF endings, no BOM) ----------------------
    $tmp = Join-Path ([IO.Path]::GetTempPath()) ("tinystruct-create-" + [guid]::NewGuid().ToString('N') + '.sh')
    try {
        Info "Downloading $Url"
        $text = (Invoke-RestMethod -Uri $Url -UseBasicParsing) -replace "`r`n", "`n"
        [IO.File]::WriteAllText($tmp, $text, (New-Object Text.UTF8Encoding($false)))

        Info 'Running installer'
        if ($mode -eq 'gitbash') {
            $unix = $tmp -replace '\\', '/'
            & $bash $unix
        } else {
            $env:WSLENV = 'TS_NAME:TS_PACKAGE:TS_TYPE:TS_VERSION:NO_COLOR'
            $wslPath = (& wsl.exe -e wslpath -a $tmp).Trim()
            & wsl.exe -e sh $wslPath
        }
        if ($LASTEXITCODE -ne 0) { Fail "Installer exited with code $LASTEXITCODE."; return }
    }
    finally {
        Remove-Item $tmp -Force -ErrorAction SilentlyContinue
    }
}
