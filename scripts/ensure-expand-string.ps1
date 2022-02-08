[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter()]
    [ValidateSet("System", "User", "Volatile", "Session")]
    [string]$Scope = "User",
    [Parameter(Position = 0)]
    [string[]]$Name = "Path",
    [Parameter()]
    [int]$MinLength = ((
        ((Get-ItemPropertyValue 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' 'SystemRoot').Length),
        ((Get-ItemPropertyValue 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList' 'ProfilesDirectory').Length),
        ((Get-ItemPropertyValue 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList' 'Public').Length),
        ((Get-ItemPropertyValue 'HKCU:\Volatile Environment' 'USERPROFILE').Length) `
            | Measure-Object -Minimum
        ).Minimum),
    [switch]$Force
)

$ConfirmYesToAll = $Force
$ConfirmNoToAll = $false

$GetKnownEnvPath = Join-Path $PSScriptRoot "ls-known-env.ps1"
$GetEnvVarInfoPath = Join-Path $PSScriptRoot "get-env-var-info.ps1"
$BroadcastEnvChangePath = Join-Path $PSScriptRoot "broadcast-environment-change"

[PSCustomObject[]]$AllKnownVariables = & $GetKnownEnvPath `
| Where-Object { $_.Value.Length -ge $MinLength } `
| Sort-Object -Descending -Property (
    @{ Expression = {
            switch ($_.Scope) {
                "UserExtra" { 0 }
                "Volatile" { 1 }
                "Session" { 2 }
                "User" { 3 }
                "SystemExtra" { 4 }
                "System" { 5 }
                "SystemRoot" { 6 }
            }
        }
    },
    @{ Expression = { $_.Value.Length } },
    @{ Expression = {
            switch ($_.Variable) {
                "ProgramW6432" { 0; break; }
                "ProgramFiles(x86)" { 1; break; }
                "ProgramFiles" { 2; break; }
                "CommonProgramW6432" { 0; break; }
                "CommonProgramFiles(x86)" { 1; break; }
                "CommonProgramFiles" { 2; break; }
                default { 0; break; }
            }
        }
    },
    "Variable"
)

[Microsoft.Win32.RegistryKey]$RegistryKey = switch ($Scope) {
    "System" {
        Get-Item "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment"
    }
    "User" {
        Get-Item "HKCU:\Environment"
    }
    "Volatile" {
        Get-Item "HKCU:\Volatile Environment"
    }
    "Session" {
        [int]$SessionId = [System.Diagnostics.Process]::GetCurrentProcess().SessionId
        Get-Item "HKCU:\Volatile Environment\$SessionId"
    }
}
[string[]]$ValueNames = $RegistryKey.GetValueNames() | Where-Object {
    [string]$ValueNameCandidate = $_
    return $Name | Where-Object {
        $ValueNameCandidate -ilike $_
    }
}
$ValueNames | ForEach-Object {
    [string]$CurrentName = $_
    $KnownVariables = $AllKnownVariables | Where-Object -Property Variable -NE $CurrentName
    $GetEnvVarInfoParams = @{
        RegistryKey = $RegistryKey
        Name        = $CurrentName
        Scope       = $Scope
    }
    [string]$OldRawValue = $RegistryKey.GetValue(
        $CurrentName, $null,
        [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames
    )
    [string[]]$NewRawValueSegment = & $GetEnvVarInfoPath @GetEnvVarInfoParams `
    | ForEach-Object {
        [string]$RawValue = $_."Raw Value"
        foreach ($KnownVariable in $KnownVariables) {
            if (-not $RawValue.ToUpperInvariant().Contains($KnownVariable.Value.ToUpperInvariant())) {
                continue
            }
            $NewValue = $RawValue.Replace($KnownVariable.Value, "%$($KnownVariable.Variable)%")
            if ($VerbosePreference -ne [System.Management.Automation.ActionPreference]::SilentlyContinue) {
                Write-Verbose "`"%$CurrentName%`" matched `"%$($KnownVariable.Variable)%`" (Scope: $($KnownVariable.Scope)): `"$RawValue`" -> `"$NewValue`""
            }
            $RawValue = $NewValue
        }
        $RawValue
    }
    [string]$NewRawValue = $NewRawValueSegment -join ([System.IO.Path]::PathSeparator)
    if ($OldRawValue -eq $NewRawValue) {
        return
    }
    $ConfirmResult = $true
    $MessageCaption = "Ensure REG_EXPAND_SZ value for `"%$CurrentName%`"?"
    $MessageQuery = "Set value `"$NewRawValue`" for value `"$CurrentName`" under `"$RegistryKey`""
    if ($ConfirmPreference -ne [System.Management.Automation.ConfirmImpact]::None) {
        $ConfirmResult = $PSCmdlet.ShouldContinue(
            $MessageQuery, "${MessageCaption}?",
            [ref]$ConfirmYesToAll, [ref]$ConfirmNoToAll
        )
    }
    if (-not $ConfirmResult) {
        return
    }
    if ($VerbosePreference -ne [System.Management.Automation.ActionPreference]::SilentlyContinue) {
        Write-Verbose "`"%$CurrentName%`" new value = `"$NewRawValue`""
    }
    $SetItemPropertyParams = @{
        Name         = $CurrentName
        Value        = $NewRawValue
        PropertyType = "ExpandString"
        WhatIf       = $WhatIfPreference
        Force        = $true
        Confirm      = $false
    }
    [void]($RegistryKey | New-ItemProperty @SetItemPropertyParams)
    & $BroadcastEnvChangePath -Verbose:($VerbosePreference -ne [System.Management.Automation.ActionPreference]::SilentlyContinue)
}
