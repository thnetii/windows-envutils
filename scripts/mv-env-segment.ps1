[CmdletBinding()]
param (
    [Parameter(Position = 0)]
    [ValidateSet("System", "User", "Volatile")]
    [string]$Scope = "User",
    [ValidateNotNullOrEmpty()]
    [string]$Name = "Path",
    [Parameter(Mandatory = $true, Position = 1)]
    [int]$Index,
    [Parameter(Mandatory = $true, Position = 2)]
    [int]$TargetIndex,
    [switch]$InsertAfter
)

$GetEnvVarInfoPath = Join-Path $PSScriptRoot "get-env-var-info.ps1"
[ValidateNotNull()][string]$RegKeyPath = switch ($Scope) {
    "System" { "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment"; break }
    "User" { "HKCU:\Environment"; break }
    "Volatile" { "HKCU:\Volatile Environment"; break }
}
[Microsoft.Win32.RegistryKey]$RegKey = Get-Item $RegKeyPath
$GetEnvVarInfoParams = @{
    RegistryKey = $RegKey;
    Name        = $Name;
    Scope       = $Scope;
}
[PSObject[]]$RegKeySegments = & $GetEnvVarInfoPath @GetEnvVarInfoParams
$SelectSegmentInfo = $RegKeySegments[$Index]
[int]$TargetIndexValue = if ($TargetIndex -lt $RegKeySegments.Length) {
    if ($InsertAfter) {
        $TargetIndex + 1
    }
    else {
        $TargetIndex
    }
}
else {
    $TargetIndex
}

if ($Index -eq $TargetIndexValue) {
    if ($VerbosePreference -ne [System.Management.Automation.ActionPreference]::SilentlyContinue) {
        Write-Verbose "Segment '$($SelectSegmentInfo."Raw Value")' is already at requested position."
    }
    return
}

if ($VerbosePreference -ne [System.Management.Automation.ActionPreference]::SilentlyContinue) {
    switch ($TargetIndexValue) {
        0 {
            Write-Verbose "Moving segment '$($SelectSegmentInfo."Raw Value")' in front of position 0, i.e. in front of '$($RegKeySegments[0]."Raw Value")'."
        }
        { $_ -eq $RegKeySegments.Length } {
            Write-Verbose "Moving segment '$($SelectSegmentInfo."Raw Value")' behind position $($RegKeySegments.Length - 1), i.e. behind '$($RegKeySegments[$RegKeySegments.Length - 1]."Raw Value")'."
        }
        default {
            Write-Verbose "Moving segment '$($SelectSegmentInfo."Raw Value")' between positions $($TargetIndexValue - 1) and $($TargetIndexValue), i.e. between '$($RegKeySegments[$TargetIndexValue - 1]."Raw Value")' and '$($RegKeySegments[$TargetIndexValue]."Raw Value")'."
        }
    }
}

[string[]]$NewSegments = [array]::CreateInstance([string], $RegKeySegments.Length)
$NewIndex = 0
for ($SrcIndex = 0; $SrcIndex -lt $RegKeySegments.Length; $SrcIndex += 1) {
    switch ($SrcIndex) {
        { $_ -eq $Index } { break }
        { $_ -eq $TargetIndexValue } {
            $NewSegments[$NewIndex] = $SelectSegmentInfo."Raw Value"
            $NewIndex += 1
        }
        { $true } {
            $NewSegments[$NewIndex] = $RegKeySegments[$_]."Raw Value"
            $NewIndex += 1
            break
        }
    }
}
if ($TargetIndexValue -ge $RegKeySegments.Length) {
    $NewSegments[$NewSegments.Length - 1] = $SelectSegmentInfo."Raw Value"
}

$NewSegments = $NewSegments | Where-Object { -not ([string]::IsNullOrWhiteSpace($_)) }
if ($VerbosePreference -ne [System.Management.Automation.ActionPreference]::SilentlyContinue) {
    $NewSegments | Write-Verbose
}
