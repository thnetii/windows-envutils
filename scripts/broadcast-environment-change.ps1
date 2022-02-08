[CmdletBinding()]
param ()

[string]$SendMessageFuncDef = @"
[DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
public static extern int SendMessageTimeout(
    IntPtr hWnd,
    uint msg,
    UIntPtr wParam,
    [MarshalAs(UnmanagedType.LPTStr)]
    string lParam,
    uint fuFlags,
    uint uTimeout,
    out int lpdwResult
);
"@
try {
    [void](
        Add-Type -Namespace Win32Api -Name NativeMethods `
            -MemberDefinition $SendMessageFuncDef -Language CSharp `
    )
}
catch {
    Write-Warning "Unable to create P/Invoke for WinApi function SendMessageTimeout"
    Write-Warning $Error[0].Exception.Message
    return
}

$HWND_BROADCAST = [System.IntPtr]0xFFFF
[System.UInt32]$WM_SETTINGCHANGE = 0x001A # Same as WM_WININICHANGE
[System.UInt32]$fuFlags = 2  # SMTO_ABORTIFHUNG: return if receiving thread does not respond (hangs)
[System.UInt32]$timeOutMs = 1000  # Timeout in milliseconds
[int]$ErrorCode = 0

$ReturnValue = [Win32Api.NativeMethods]::SendMessageTimeout(
    $HWND_BROADCAST,
    $WM_SETTINGCHANGE,
    [System.UIntPtr]::Zero,
    "Environment",
    $fuFlags,
    $timeOutMs,
    [ref]$ErrorCode
)
$Win32Except = New-Object "System.ComponentModel.Win32Exception" $ErrorCode
if (-not $ReturnValue) {
    throw $Win32Except
}
elseif ($VerbosePreference -ne [System.Management.Automation.ActionPreference]::SilentlyContinue) {
    Write-Verbose $Win32Except.Message
}
