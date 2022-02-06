[CmdletBinding()]
param (
    [Parameter()]
    [ValidateSet("System", "User", "Volatile", "Session")]
    [string]$Scope = "User",
    [Parameter()]
    [string[]]$Name = "Path",
    [Parameter()]
    [int]$MinLength = ([System.Math]::Min(
        ((Get-ItemPropertyValue 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList' 'ProfilesDirectory').Length),
        ((Get-ItemPropertyValue 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' 'SystemRoot').Length)
        ))
)

$GetKnownEnvPath = Join-Path $PSScriptRoot "ls-known-env.ps1"
[PSCustomObject[]]$KnownVariables = & $GetKnownEnvPath
| Where-Object -Property Variable -NotIn $Name
| Where-Object { $_.Value.Length -ge $MinLength }
| Sort-Object -Descending -Property (
    @{ Expression = {
            switch ($_.Scope) {
                "SystemRoot" { 0 }
                "System" { 1 }
                "SystemExtra" { 2 }
                "User" { 3 }
                "Volatile" { 4 }
                "Session" { 5 }
                "UserExtra" { 6 }
            }
        }
    },
    @{ Expression = { $_.Value.Length } },
    "Variable"
)
$KnownVariables

