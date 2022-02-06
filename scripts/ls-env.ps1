[CmdletBinding()]
param (
    [Parameter(Position = 0)]
    [ValidateNotNullOrEmpty()]
    [string]$Name = "Path"
)

@(
    [PSCustomObject]@{
        Scope = "System";
        Path  = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment";
    },
    [PSCustomObject]@{
        Scope = "User";
        Path  = "HKCU:\Environment";
    },
    [PSCustomObject]@{
        Scope = "Volatile";
        Path  = "HKCU:\Volatile Environment";
    }
) | ForEach-Object {
    $RegKey = Get-Item $_.Path -ErrorAction SilentlyContinue
    if (-not $RegKey) {
        return
    }
    $EnvVarParams = @{
        RegistryKey = $RegKey
        Name        = $Name
        Scope       = $_.Scope
    }
    $GetEnvVarInfoPath = Join-Path $PSScriptRoot "get-env-var-info.ps1"
    & $GetEnvVarInfoPath @EnvVarParams
}
