[CmdletBinding()]
[OutputType([PSCustomObject[]])]
param (
    [Parameter(ValueFromPipeline = $true)]
    [Microsoft.Win32.RegistryKey]$RegistryKey,
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateNotNullOrEmpty()]
    [string]$Name,
    [Parameter(Position = 1)]
    [string]$Scope
)
[string]$RawValue = $RegistryKey.GetValue($Name, $null, [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
[string]$ExpandValue = $RegistryKey.GetValue($Name, $null)

function Get-SeparatedEnvironmentVariable {
    [OutputType([string[]])]
    param (
        [Parameter(Position = 0)]
        [string]$Value
    )
    if ($Value) {
        [string[]]$ValueArray = $Value -split ([System.IO.Path]::PathSeparator)
        $ValueArray
    }
    else {
        [array]::CreateInstance([string], 0)
    }
}

if ($Name -iin ("Path", "Pathext")) {
    $RawSegments = Get-SeparatedEnvironmentVariable $RawValue
    $ExpandSegments = Get-SeparatedEnvironmentVariable $ExpandValue
}
else {
    $RawSegments = [string[]]@($RawValue)
    $ExpandSegments = [string[]]@($ExpandValue)
}

for ($i = 0; $i -lt $RawSegments.Count; $i++) {
    [PSCustomObject]@{
        "#"              = $i;
        "Scope"          = $Scope;
        "Raw Value"      = $RawSegments[$i];
        "Expanded Value" = $ExpandSegments[$i];
        "Registry Key"   = $RegistryKey;
        "Name"           = $Name
    }
}
