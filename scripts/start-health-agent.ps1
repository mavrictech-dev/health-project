[CmdletBinding()]
param(
    [ValidateSet('architect', 'programmer')][string]$Role = 'programmer',
    [Parameter(Mandatory = $true)][string]$WorktreePath,
    [Parameter(Mandatory = $true)][string]$CodexHome,
    [Parameter(Mandatory = $true)][string]$ExpectedEmail,
    [switch]$IdentityOnly
)

# Run inside a fresh Orca terminal belonging to this agent's workspace.
# No account selection, login, logout, credential copying, or global config writes.
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$repositoryRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$targetRoot = (Resolve-Path -LiteralPath $WorktreePath).Path
$accountRoot = (Resolve-Path -LiteralPath $CodexHome).Path

function Get-GitPath([string]$Directory, [string]$Argument) {
    $value = & git -C $Directory rev-parse --path-format=absolute $Argument
    if ($LASTEXITCODE -ne 0) { throw "No se pudo verificar Git en $Directory" }
    return [IO.Path]::GetFullPath(($value | Select-Object -First 1).Trim())
}

if ((Get-GitPath $repositoryRoot '--show-toplevel') -ne $repositoryRoot) {
    throw 'El lanzador debe estar en scripts del checkout principal de Health Project.'
}
$remote = & git -C $repositoryRoot remote get-url origin
if ($LASTEXITCODE -ne 0 -or $remote -notmatch 'github\.com[:/]mavrictech-dev/health-project(?:\.git)?$') {
    throw 'El repositorio no corresponde a Health Project.'
}
if ((Get-GitPath $targetRoot '--show-toplevel') -ne $targetRoot) {
    throw 'La ruta debe ser la raiz de un checkout de Health Project.'
}
if ($Role -eq 'programmer' -and $targetRoot -eq $repositoryRoot) {
    throw 'El programador necesita la raiz de un worktree separado.'
}
if ($Role -eq 'architect' -and $targetRoot -ne $repositoryRoot) {
    throw 'El arquitecto debe usar el checkout supervisor de Health Project.'
}
if ((Get-GitPath $targetRoot '--git-common-dir') -ne (Get-GitPath $repositoryRoot '--git-common-dir')) {
    throw 'El worktree no pertenece al mismo repositorio Health Project.'
}

$auth = Get-Content -Raw -LiteralPath (Join-Path $accountRoot 'auth.json') | ConvertFrom-Json
if ($auth.auth_mode -ne 'chatgpt') { throw 'Se esperaba una sesion ChatGPT existente.' }
$encodedClaims = $auth.tokens.id_token.Split('.')[1].Replace('-', '+').Replace('_', '/')
$encodedClaims = $encodedClaims.PadRight($encodedClaims.Length + ((4 - $encodedClaims.Length % 4) % 4), '=')
$claims = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($encodedClaims)) | ConvertFrom-Json
if ($claims.email -ne $ExpectedEmail) { throw 'La identidad guardada no coincide con la cuenta asignada.' }
$codexCommand = Get-Command codex.cmd -CommandType Application -ErrorAction Stop
$helpText = (& $codexCommand.Source --help | Out-String)
if ($LASTEXITCODE -ne 0 -or $helpText -notmatch '--no-daemon') {
    throw 'Esta version de Codex no acredita el aislamiento mediante --no-daemon.'
}

# This receipt contains identity metadata only. Never output auth objects or JWTs.
[ordered]@{
    role = $Role
    worktree = $targetRoot
    codexHome = $accountRoot
    email = $claims.email
    providerAccountId = $auth.tokens.account_id
    isolation = '--no-daemon'
    verification = 'stored identity; verify effective identity in the launched worker before dispatch'
} | ConvertTo-Json -Compress | Write-Output
if ($IdentityOnly) { return }

$environmentNames = @('CODEX_HOME', 'ORCA_CODEX_HOME', 'ORCA_CODEX_ISOLATE', 'CODEX_SESSION_ID', 'CODEX_THREAD_ID')
$previousEnvironment = @{}
foreach ($name in $environmentNames) {
    $previousEnvironment[$name] = [Environment]::GetEnvironmentVariable($name, 'Process')
}
try {
    $env:CODEX_HOME = $accountRoot
    $env:ORCA_CODEX_HOME = $accountRoot
    $env:ORCA_CODEX_ISOLATE = '1'
    Remove-Item Env:CODEX_SESSION_ID,Env:CODEX_THREAD_ID -ErrorAction SilentlyContinue
    & $codexCommand.Source --no-daemon --cd $targetRoot
    if ($LASTEXITCODE -ne 0) { throw "Codex termino con codigo $LASTEXITCODE" }
} finally {
    foreach ($name in $environmentNames) {
        [Environment]::SetEnvironmentVariable($name, $previousEnvironment[$name], 'Process')
    }
}
