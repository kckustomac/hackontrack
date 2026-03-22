# Define the C# class to interact with the Windows API
$csharpCode = @"
using System;
using System.Runtime.InteropServices;

public class KCKustoMac {
    [StructLayout(LayoutKind.Sequential)]
    struct LASTINPUTINFO {
        public static readonly int SizeOf = Marshal.SizeOf(typeof(LASTINPUTINFO));
        [MarshalAs(UnmanagedType.U4)]
        public UInt32 cbSize;
        [MarshalAs(UnmanagedType.U4)]
        public UInt32 dwTime;
    }

    [DllImport("user32.dll")]
    static extern bool GetLastInputInfo(ref LASTINPUTINFO plii);

    [DllImport("user32.dll")]
    public static extern bool SetCursorPos(int X, int Y);

    [DllImport("user32.dll")]
    public static extern bool GetCursorPos(out POINT lpPoint);

    [DllImport("user32.dll")]
    public static extern void mouse_event(uint dwFlags, int dx, int dy, uint cButtons, uint dwExtraInfo);

    // Check physical keyboard states
    [DllImport("user32.dll")]
    public static extern short GetAsyncKeyState(int vKey);

    // Tell Windows the system and display are in use (prevents sleep / display-off)
    [DllImport("kernel32.dll")]
    static extern uint SetThreadExecutionState(uint esFlags);

    const uint ES_CONTINUOUS       = 0x80000000;
    const uint ES_SYSTEM_REQUIRED  = 0x00000001;
    const uint ES_DISPLAY_REQUIRED = 0x00000002;

    public static void KeepAwake() {
        SetThreadExecutionState(ES_CONTINUOUS | ES_SYSTEM_REQUIRED | ES_DISPLAY_REQUIRED);
    }

    public static void AllowSleep() {
        SetThreadExecutionState(ES_CONTINUOUS);
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct POINT {
        public int X;
        public int Y;
    }

    // ---- SendInput: synthetic input that Windows counts as real activity ----
    [StructLayout(LayoutKind.Sequential)]
    struct MOUSEINPUT {
        public int    dx;
        public int    dy;
        public uint   mouseData;
        public uint   dwFlags;
        public uint   time;
        public IntPtr dwExtraInfo;
    }

    [StructLayout(LayoutKind.Explicit)]
    struct INPUTUNION {
        [FieldOffset(0)] public MOUSEINPUT mi;
    }

    [StructLayout(LayoutKind.Sequential)]
    struct INPUT {
        public uint       type;   // 0 = INPUT_MOUSE
        public INPUTUNION u;
    }

    [DllImport("user32.dll", SetLastError = true)]
    static extern uint SendInput(uint nInputs, INPUT[] pInputs, int cbSize);

    [DllImport("user32.dll")]
    static extern int GetSystemMetrics(int nIndex);

    const uint MOUSEEVENTF_MOVE        = 0x0001;
    const uint MOUSEEVENTF_ABSOLUTE    = 0x8000;
    const uint MOUSEEVENTF_VIRTUALDESK = 0x4000;

    const int SM_XVIRTUALSCREEN  = 76;
    const int SM_YVIRTUALSCREEN  = 77;
    const int SM_CXVIRTUALSCREEN = 78;
    const int SM_CYVIRTUALSCREEN = 79;

    // Move the cursor to screen pixel (x, y) via SendInput.
    // Coordinates are the same as SetCursorPos (primary monitor top-left = 0,0),
    // converted to the 0..65535 normalized space across all monitors.
    public static bool SendMoveTo(int x, int y) {
        int vx = GetSystemMetrics(SM_XVIRTUALSCREEN);
        int vy = GetSystemMetrics(SM_YVIRTUALSCREEN);
        int vw = GetSystemMetrics(SM_CXVIRTUALSCREEN);
        int vh = GetSystemMetrics(SM_CYVIRTUALSCREEN);
        if (vw < 2 || vh < 2) return false;

        INPUT[] inputs = new INPUT[1];
        inputs[0].type = 0;
        inputs[0].u.mi.dx = (int)Math.Round((x - vx) * 65535.0 / (vw - 1));
        inputs[0].u.mi.dy = (int)Math.Round((y - vy) * 65535.0 / (vh - 1));
        inputs[0].u.mi.dwFlags = MOUSEEVENTF_MOVE | MOUSEEVENTF_ABSOLUTE | MOUSEEVENTF_VIRTUALDESK;

        uint sent = SendInput(1, inputs, Marshal.SizeOf(typeof(INPUT)));

        // Snap to the exact pixel in case normalization rounding is off by one
        SetCursorPos(x, y);
        return sent == 1;
    }

    // Milliseconds the system has been idle
    public static uint GetIdleTime() {
        LASTINPUTINFO lastInPut = new LASTINPUTINFO();
        lastInPut.cbSize = (uint)Marshal.SizeOf(lastInPut);
        GetLastInputInfo(ref lastInPut);
        return ((uint)Environment.TickCount - lastInPut.dwTime);
    }

    // Replicates: MouseMove, 1 , 1,, R
    public static void MoveRelative(int dx, int dy) {
        POINT p;
        if (GetCursorPos(out p)) {
            SetCursorPos(p.X + dx, p.Y + dy);
        }
    }

    // Replicates: Click, x, y
    public static void ClickAt(int x, int y) {
        SetCursorPos(x, y);
        // 0x02 = MOUSEEVENTF_LEFTDOWN, 0x04 = MOUSEEVENTF_LEFTUP
        mouse_event(0x02 | 0x04, x, y, 0, 0);
    }
}
"@

# Compile the C# code into the PowerShell session
Add-Type -TypeDefinition $csharpCode

# Two setpoints, visited one per idle period, alternating forever:
# 333,22 -> 369,11 -> 333,22 -> 369,11 -> ...
$points = @(
    @{ X = 333; Y = 22 },
    @{ X = 369; Y = 11 }
)
$nextIndex     = 0       # start with 333,22
$idleThreshold = 177999  # ~178 seconds

# SendInput resets the Windows idle timer (and the inactivity-lock timer), so the
# idle check alone spaces moves ~178s apart. The stopwatch is a backup guard in
# case SendInput is ever blocked (e.g. UAC/secure desktop) and idle doesn't reset.
$sinceMove = [System.Diagnostics.Stopwatch]::StartNew()

# Keep the system and display awake for as long as the script runs
[KCKustoMac]::KeepAwake()

try {
while ($true) {

    # Ctrl (0x11) + '0' (0x30) held down = exit
    $ctrlPressed = [KCKustoMac]::GetAsyncKeyState(0x11) -band 0x8000
    $zeroPressed = [KCKustoMac]::GetAsyncKeyState(0x30) -band 0x8000
    if ($ctrlPressed -and $zeroPressed) {
        break
    }

    $idleTime = [KCKustoMac]::GetIdleTime()

    # Fire when the system has been idle 178s (and 178s since our last move).
    # Any real input -- or our own SendInput move -- resets idleTime and restarts the wait.
    if ($idleTime -gt $idleThreshold -and $sinceMove.ElapsedMilliseconds -gt $idleThreshold) {
        $pt = $points[$nextIndex]
        [KCKustoMac]::SendMoveTo($pt.X, $pt.Y) | Out-Null

        $nextIndex = 1 - $nextIndex   # toggle 0 <-> 1
        $sinceMove.Restart()
    }

    # Check again in a quarter second
    Start-Sleep -Milliseconds 250
}
}
finally {
    # Restore normal power behavior on Ctrl+0 or Ctrl+C
    [KCKustoMac]::AllowSleep()
}
