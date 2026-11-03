[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$WorktreePath,
    [Parameter(Mandatory = $true)][string]$CodexHome,
    [Parameter(Mandatory = $true)][string]$ExpectedEmail,
    [switch]$IdentityOnly
)

# Compatibility entry point: same programmer-only validation and isolation.
& (Join-Path $PSScriptRoot 'start-health-agent.ps1') -Role programmer @PSBoundParameters
