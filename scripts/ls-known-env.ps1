[CmdletBinding()]
param (
)

[Microsoft.Win32.RegistryKey]$WinNTCurrentVersionKey = (
    Get-Item 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\'
)
[string]$SystemRoot = $WinNTCurrentVersionKey.GetValue("SystemRoot")
$SystemDriveInfo = New-Object System.IO.DriveInfo $SystemRoot
[string]$SystemDrive = (
    $SystemDriveInfo.Name.TrimEnd([System.IO.Path]::DirectorySeparatorChar)
)
[Microsoft.Win32.RegistryKey]$WinNTProfileListKey = (
    $WinNTCurrentVersionKey.OpenSubKey("ProfileList")
)
[string]$ProgramData = $WinNTProfileListKey.GetValue("ProgramData")
[Microsoft.Win32.RegistryKey]$WindowsCurrentVersionKey = (
    Get-Item 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\'
)

[PSCustomObject]@{
    Variable = "SystemRoot"
    Value    = $SystemRoot
    Scope    = "SystemRoot"
    Source   = $WinNTCurrentVersionKey
    Name     = "SystemRoot"
}, [PSCustomObject]@{
    Variable = "SystemDrive"
    Value    = $SystemDrive
    Scope    = "SystemRoot"
    Source   = $WinNTCurrentVersionKey
    Name     = "SystemRoot"
}, [PSCustomObject]@{
    Variable = "ProgramData"
    Value    = $ProgramData
    Scope    = "SystemRoot"
    Source   = $WinNTProfileListKey
    Name     = "ProgramData"
}, [PSCustomObject]@{
    Variable = "PUBLIC"
    Value    = [string]($WinNTProfileListKey.GetValue("Public"))
    Scope    = "SystemRoot"
    Source   = $WinNTProfileListKey
    Name     = "Public"
}, [PSCustomObject]@{
    Variable = "ALLUSERSPROFILE"
    Value    = $ProgramData
    Scope    = "SystemRoot"
    Source   = $WinNTProfileListKey
    Name     = "ProgramData"
}, [PSCustomObject]@{
    Variable = "COMPUTERNAME"
    Value    = [System.Environment]::MachineName
    Scope    = "SystemExtra"
    Source   = [System.Environment]
    Name     = "MachineName"
}, [PSCustomObject]@{
    Variable = "CommonProgramFiles"
    Value    = [string]($WindowsCurrentVersionKey.GetValue("CommonFilesDir"))
    Scope    = "SystemExtra"
    Source   = $WindowsCurrentVersionKey
    Name     = "CommonFilesDir"
}, [PSCustomObject]@{
    Variable = "CommonProgramFiles(x86)"
    Value    = [string]($WindowsCurrentVersionKey.GetValue("CommonFilesDir (x86)"))
    Scope    = "SystemExtra"
    Source   = $WindowsCurrentVersionKey
    Name     = "CommonFilesDir (x86)"
}, [PSCustomObject]@{
    Variable = "CommonProgramW6432"
    Value    = [string]($WindowsCurrentVersionKey.GetValue("CommonW6432Dir"))
    Scope    = "SystemExtra"
    Source   = $WindowsCurrentVersionKey
    Name     = "CommonW6432Dir"
}, [PSCustomObject]@{
    Variable = "ProgramFiles"
    Value    = [string]($WindowsCurrentVersionKey.GetValue("ProgramFilesDir"))
    Scope    = "SystemExtra"
    Source   = $WindowsCurrentVersionKey
    Name     = "ProgramFilesDir"
}, [PSCustomObject]@{
    Variable = "ProgramFiles(x86)"
    Value    = [string]($WindowsCurrentVersionKey.GetValue("ProgramFilesDir (x86)"))
    Scope    = "SystemExtra"
    Source   = $WindowsCurrentVersionKey
    Name     = "ProgramFilesDir (x86)"
}, [PSCustomObject]@{
    Variable = "ProgramW6432"
    Value    = [string]($WindowsCurrentVersionKey.GetValue("ProgramW6432Dir"))
    Scope    = "SystemExtra"
    Source   = $WindowsCurrentVersionKey
    Name     = "ProgramW6432Dir"
}
([PSCustomObject]@{
    RegistryKey = (Get-Item "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment")
    Scope       = "System"
}, [PSCustomObject]@{
    RegistryKey = (Get-Item "HKCU:\Environment")
    Scope       = "User"
}, [PSCustomObject]@{
    RegistryKey = (Get-Item "HKCU:\Volatile Environment")
    Scope       = "Volatile"
}, [PSCustomObject]@{
    RegistryKey = (Get-Item "HKCU:\Volatile Environment\$([System.Diagnostics.Process]::GetCurrentProcess().SessionId)")
    Scope       = "Session"
}) | ForEach-Object {
    [Microsoft.Win32.RegistryKey]$RegistryKey = $_.RegistryKey
    [string]$Scope = $_.Scope
    $RegistryKey.GetValueNames() | Where-Object -FilterScript {
        $RegistryKey.GetValueKind($_) -eq [Microsoft.Win32.RegistryValueKind]::String
    } | ForEach-Object {
        [PSCustomObject]@{
            Variable = $_
            Value    = [string]($RegistryKey.GetValue($_))
            Scope    = $Scope
            Source   = $RegistryKey
            Name     = $_
        }
    }
}
[PSCustomObject]@{
    Variable = "USERNAME"
    Value    = [System.Environment]::UserName
    Scope    = "UserExtra"
    Source   = [System.Environment]
    Name     = "UserName"
}
