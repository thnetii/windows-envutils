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
[void](
    Add-Type -Namespace Win32Api -Name NativeMethods `
        -MemberDefinition $SendMessageFuncDef -Language CSharp
)

$HWND_BROADCAST = [System.IntPtr]0xFFFF
[uint]$WM_SETTINGCHANGE = 0x001A # Same as WM_WININICHANGE
[uint]$fuFlags = 2  # SMTO_ABORTIFHUNG: return if receiving thread does not respond (hangs)
[uint]$timeOutMs = 1000  # Timeout in milliseconds
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
} elseif ($VerbosePreference -ne [System.Management.Automation.ActionPreference]::SilentlyContinue) {
    Write-Verbose $Win32Except.Message
}
