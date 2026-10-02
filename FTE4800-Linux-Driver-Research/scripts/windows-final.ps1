# ===========================================================
# FTE4800 WINDOWS FINAL EVIDENCE GATE
#
# Purpose:
#   Finish ALL Windows-specific collection before moving to Linux.
#
# Read-only:
#   No driver installation
#   No driver removal
#   No registry modification
#   No firmware modification
#   No device reset
#
# Output:
#   C:\FTE4800-RESEARCH\<latest>\18-WINDOWS-FINAL-GATE\
#
# Final report is automatically copied to clipboard.
# ============================================================

$ErrorActionPreference = 'Continue'

# ------------------------------------------------------------
# CONFIGURATION
# ------------------------------------------------------------

$ResearchRoot = 'C:\FTE4800-RESEARCH'
$InstanceId   = 'ACPI\FTE4800\4&f064bb&0'
$HardwareId   = 'ACPI\VEN_FTE&DEV_4800'
$DriverInf   = 'oem37.inf'
$OriginalInf = 'ftwbioumdfdriverv2.inf'

$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'

$latest = Get-ChildItem `
    $ResearchRoot `
    -Directory `
    -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -match '^\d{8}-\d{6}$' } |
    Sort-Object Name -Descending |
    Select-Object -First 1

if ($latest) {
    $Base = $latest.FullName
}
else {
    $Base = Join-Path $ResearchRoot $timestamp
    New-Item -ItemType Directory -Force -Path $Base | Out-Null
}

$Out = Join-Path $Base '18-WINDOWS-FINAL-GATE'

New-Item -ItemType Directory -Force -Path $Out | Out-Null

$Evidence = Join-Path $Out 'evidence'
$Driver   = Join-Path $Out 'driver-package'
$Registry = Join-Path $Out 'registry'
$Events   = Join-Path $Out 'events'
$ACPI     = Join-Path $Out 'acpi'
$Runtime  = Join-Path $Out 'runtime'

foreach ($d in @($Evidence,$Driver,$Registry,$Events,$ACPI,$Runtime)) {
    New-Item -ItemType Directory -Force -Path $d | Out-Null
}

$Report = Join-Path $Out 'WINDOWS-FINAL-REPORT.txt'
$Errors = Join-Path $Out 'ALL-ERRORS.txt'
$Manifest = Join-Path $Out 'MANIFEST-SHA256.txt'

$lines = [System.Collections.Generic.List[string]]::new()
$errors = [System.Collections.Generic.List[string]]::new()

function Add-Line {
    param([string]$Text = '')
    [void]$lines.Add($Text)
}

function Add-Section {
    param([string]$Title)

    Add-Line ''
    Add-Line ('=' * 78)
    Add-Line $Title
    Add-Line ('=' * 78)
}

function Save-Text {
    param(
        [string]$Path,
        [string]$Text
    )

    try {
        [IO.File]::WriteAllText(
            $Path,
            $Text,
            [Text.UTF8Encoding]::new($false)
        )
    }
    catch {
        $errors.Add(
            "WRITE FAILED: $Path :: $($_.Exception.Message)"
        )
    }
}

function Run-Native {
    param(
        [string]$Command,
        [string[]]$Arguments,
        [string]$OutputFile
    )

    try {

        $result =
            & $Command @Arguments 2>&1 |
            Out-String

        Save-Text $OutputFile $result

        Add-Line "COMMAND: $Command $($Arguments -join ' ')"
        Add-Line "OUTPUT : $OutputFile"

        if ($LASTEXITCODE -ne 0) {
            $errors.Add(
                "COMMAND FAILED [$LASTEXITCODE]: $Command $($Arguments -join ' ')"
            )
        }

        return $result

    }
    catch {

        $msg =
            "NATIVE COMMAND EXCEPTION: $Command :: $($_.Exception.Message)"

        $errors.Add($msg)

        Save-Text $OutputFile $msg

        return $msg
    }
}

function Run-PS {
    param(
        [string]$Name,
        [scriptblock]$Script,
        [string]$OutputFile
    )

    try {

        $result = & $Script 2>&1 | Out-String

        Save-Text $OutputFile $result

        Add-Line "$Name -> $OutputFile"

        return $result

    }
    catch {

        $msg =
            "$Name FAILED :: $($_.Exception.Message)"

        $errors.Add($msg)

        Save-Text $OutputFile $msg

        return $msg
    }
}

# ------------------------------------------------------------
# HEADER
# ------------------------------------------------------------

Add-Line 'FTE4800 WINDOWS FINAL EVIDENCE GATE'
Add-Line "Collection time : $(Get-Date)"
Add-Line "Computer        : $env:COMPUTERNAME"
Add-Line "User            : $env:USERNAME"
Add-Line "PowerShell      : $($PSVersionTable.PSVersion)"
Add-Line "Research root   : $Base"
Add-Line "Instance ID     : $InstanceId"
Add-Line "Hardware ID     : $HardwareId"

# ------------------------------------------------------------
# ADMIN CHECK
# ------------------------------------------------------------
#
# ------------------------------------------------------------
# ADMIN CHECK
# ------------------------------------------------------------

Add-Section 'ADMINISTRATOR STATE'

try {
    $currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()

    $currentPrincipal =
        New-Object Security.Principal.WindowsPrincipal(
            $currentIdentity
        )

    $isAdmin =
        $currentPrincipal.IsInRole(
            [Security.Principal.WindowsBuiltInRole]::Administrator
        )

    Add-Line "Administrator: $isAdmin"
}
catch {
    $isAdmin = $false

    Add-Line "Administrator: CHECK FAILED"
    Add-Line $_.Exception.Message

    $errors.Add(
        "ADMINISTRATOR CHECK FAILED :: $($_.Exception.Message)"
    )
}

# ------------------------------------------------------------
# DEVICE
# ------------------------------------------------------------

Add-Section 'PNP DEVICE'

Run-PS `
    'Get-PnpDevice' `
    {
        Get-PnpDevice -InstanceId $InstanceId |
            Format-List *
    } `
    (Join-Path $Evidence 'Get-PnpDevice.txt')

Run-PS `
    'Get-PnpDeviceProperty' `
    {
        Get-PnpDeviceProperty -InstanceId $InstanceId |
            Sort-Object KeyName |
            Format-List *
    } `
    (Join-Path $Evidence 'ALL-DEVICE-PROPERTIES.txt')

Run-Native `
    'pnputil.exe' `
    @('/enum-devices','/instanceid',$InstanceId) `
    (Join-Path $Evidence 'pnputil-device.txt')

Run-Native `
    'pnputil.exe' `
    @('/enum-devices','/instanceid',$InstanceId,'/drivers') `
    (Join-Path $Evidence 'pnputil-drivers.txt')

Run-Native `
    'pnputil.exe' `
    @('/enum-devices','/instanceid',$InstanceId,'/interfaces') `
    (Join-Path $Evidence 'pnputil-interfaces.txt')

Run-Native `
    'pnputil.exe' `
    @('/enum-devices','/instanceid',$InstanceId,'/resources') `
    (Join-Path $Evidence 'pnputil-resources.txt')

Run-Native `
    'pnputil.exe' `
    @('/enum-devices','/instanceid',$InstanceId,'/relations') `
    (Join-Path $Evidence 'pnputil-relations.txt')

# ------------------------------------------------------------
# SPI CONTROLLER
# ------------------------------------------------------------

Add-Section 'SPI CONTROLLER'

$spi = Get-PnpDevice -ErrorAction SilentlyContinue |
    Where-Object {
        $_.InstanceId -match 'VEN_8086&DEV_51FB' -or
        $_.FriendlyName -match 'SPI Host Controller.*51FB'
    } |
    Select-Object -First 1

if ($spi) {

    Add-Line "SPI controller: $($spi.InstanceId)"
    Add-Line "Friendly name : $($spi.FriendlyName)"
    Add-Line "Status        : $($spi.Status)"

    Run-PS `
        'SPI properties' `
        {
            Get-PnpDeviceProperty -InstanceId $spi.InstanceId |
                Sort-Object KeyName |
                Format-List *
        } `
        (Join-Path $Evidence 'SPI-CONTROLLER-PROPERTIES.txt')

    Run-Native `
        'pnputil.exe' `
        @('/enum-devices','/instanceid',$spi.InstanceId,'/resources') `
        (Join-Path $Evidence 'SPI-CONTROLLER-RESOURCES.txt')

}
else {

    Add-Line 'SPI controller 51FB NOT FOUND.'
    $errors.Add('SPI CONTROLLER 51FB NOT FOUND')
}

# ------------------------------------------------------------
# DRIVER STORE
# ------------------------------------------------------------

Add-Section 'DRIVER STORE'

Run-Native `
    'pnputil.exe' `
    @('/enum-drivers','/class','Biometric') `
    (Join-Path $Driver 'pnputil-biometric-drivers.txt')

Run-Native `
    'pnputil.exe' `
    @('/enum-drivers') `
    (Join-Path $Driver 'pnputil-all-drivers.txt')

# Search driver store for the exact package
$driverHits = @()

try {

    $driverHits = Get-ChildItem `
        'C:\Windows\System32\DriverStore\FileRepository' `
        -Recurse `
        -File `
        -ErrorAction SilentlyContinue |
        Where-Object {
            $_.Name -in @(
                'ftWbioUmdfDriverV2.dll',
                'ftWbioEngineAdapter.dll',
                'ftwbioumdfdriverv2.inf'
            )
        }

}
catch {

    $errors.Add(
        "DRIVER STORE SEARCH FAILED :: $($_.Exception.Message)"
    )
}

if ($driverHits.Count -gt 0) {

    Add-Line "Driver-store matching files: $($driverHits.Count)"

    foreach ($f in $driverHits) {

        Add-Line "FOUND: $($f.FullName)"

        try {

            $pkg = $f.Directory.FullName

            Add-Line "PACKAGE DIR: $pkg"

            $destDir = Join-Path `
                $Driver `
                $f.Directory.Name

            New-Item `
                -ItemType Directory `
                -Force `
                -Path $destDir |
                Out-Null

            Copy-Item `
                -LiteralPath $f.FullName `
                -Destination $destDir `
                -Force

        }
        catch {

            $errors.Add(
                "DRIVER COPY FAILED: $($f.FullName) :: $($_.Exception.Message)"
            )
        }
    }

}
else {

    Add-Line 'No exact driver-store files found.'
    $errors.Add('DRIVER STORE PACKAGE NOT LOCATED')
}

# ------------------------------------------------------------
# INSTALLED DRIVER DETAILS
# ------------------------------------------------------------

Add-Section 'INSTALLED DRIVER DETAILS'

Run-PS `
    'Win32_PnPSignedDriver' `
    {
        Get-CimInstance Win32_PnPSignedDriver |
            Where-Object {
                $_.DeviceID -eq $InstanceId
            } |
            Format-List *
    } `
    (Join-Path $Driver 'Win32_PnPSignedDriver.txt')

Run-Native `
    'driverquery.exe' `
    @('/v','/fo','list') `
    (Join-Path $Driver 'driverquery.txt')

# ------------------------------------------------------------
# FILE HASHES / SIGNATURES
# ------------------------------------------------------------

Add-Section 'FILE HASHES AND SIGNATURES'

$interesting = @(
    'ftWbioUmdfDriverV2.dll',
    'ftWbioEngineAdapter.dll',
    'ftwbioumdfdriverv2.inf',
    'ftWbioUmdfDriverV2.cat'
)

foreach ($name in $interesting) {

    $files = Get-ChildItem `
        'C:\Windows\System32\DriverStore\FileRepository' `
        -Recurse `
        -File `
        -Filter $name `
        -ErrorAction SilentlyContinue

    foreach ($f in $files) {

        Add-Line ''
        Add-Line "FILE: $($f.FullName)"

        try {

            $hash = Get-FileHash `
                -LiteralPath $f.FullName `
                -Algorithm SHA256

            Add-Line "SHA256: $($hash.Hash)"

        }
        catch {

            $errors.Add(
                "HASH FAILED: $($f.FullName)"
            )
        }

        try {

            $sig = Get-AuthenticodeSignature `
                -LiteralPath $f.FullName

            Add-Line "SIGNATURE STATUS: $($sig.Status)"
            Add-Line "SIGNER SUBJECT : $($sig.SignerCertificate.Subject)"
            Add-Line "SIGNER ISSUER  : $($sig.SignerCertificate.Issuer)"

        }
        catch {

            $errors.Add(
                "SIGNATURE FAILED: $($f.FullName)"
            )
        }
    }
}

# ------------------------------------------------------------
# INF ANALYSIS
# ------------------------------------------------------------

Add-Section 'INF FILE ANALYSIS'

$infFiles = Get-ChildItem `
    $Driver `
    -Recurse `
    -Filter '*.inf' `
    -File `
    -ErrorAction SilentlyContinue

foreach ($inf in $infFiles) {

    Add-Line ''
    Add-Line "INF: $($inf.FullName)"

    try {

        $content = Get-Content `
            -LiteralPath $inf.FullName `
            -Raw

        Add-Line '--- SPI / UMDF / GPIO / WDF MATCHES ---'

        $content `
            -split "`r?`n" |
            Select-String `
                -Pattern `
                'FTE4800|FTE4800|SPI|SPB|GPIO|Interrupt|Umdf|Wdf|DirectHardware|Service|Device' |
            ForEach-Object {
                Add-Line $_.Line
            }

    }
    catch {

        $errors.Add(
            "INF READ FAILED: $($inf.FullName)"
        )
    }
}

# Also collect installed setup information
Run-PS `
    'SetupAPI FTE4800 matches' `
    {
        $setup = 'C:\Windows\INF\setupapi.dev.log'

        if (Test-Path $setup) {

            Select-String `
                -Path $setup `
                -Pattern 'FTE4800|ftwbioumdfdriverv2|FocalTech|oem37.inf' `
                -Context 12,20

        }
    } `
    (Join-Path $Driver 'setupapi-FTE4800-context.txt')

# ------------------------------------------------------------
# REGISTRY
# ------------------------------------------------------------

Add-Section 'REGISTRY CONFIGURATION'

$regPaths = @(
    "HKLM\SYSTEM\CurrentControlSet\Enum\ACPI\FTE4800",
    "HKLM\SYSTEM\CurrentControlSet\Services\WUDFRd",
    "HKLM\SYSTEM\CurrentControlSet\Control\focalFp",
    "HKLM\SYSTEM\CurrentControlSet\Control\Biometrics",
    "HKLM\SYSTEM\CurrentControlSet\Services\WbioSrvc"
)

foreach ($path in $regPaths) {

    $safe = ($path -replace '[\\/:*?"<>| ]','_')
    $dest = Join-Path $Registry "$safe.reg"

    Add-Line ''
    Add-Line "REGISTRY EXPORT: $path"

    try {

        & reg.exe export $path $dest /y 2>&1 |
            Out-String |
            ForEach-Object {
                Add-Line $_.TrimEnd()
            }

        if ($LASTEXITCODE -ne 0) {

            $errors.Add(
                "REG EXPORT FAILED [$LASTEXITCODE]: $path"
            )
        }

    }
    catch {

        $errors.Add(
            "REG EXPORT EXCEPTION: $path"
        )
    }
}

# Exact device registry
$deviceReg =
    'HKLM\SYSTEM\CurrentControlSet\Enum\ACPI\FTE4800\4&f064bb&0'

Run-Native `
    'reg.exe' `
    @('query',$deviceReg,'/s') `
    (Join-Path $Registry 'FTE4800-device-full-registry.txt')

# ------------------------------------------------------------
# ACPI TABLES
# ------------------------------------------------------------

Add-Section 'ACPI / FIRMWARE TABLES'

$acpiSource = @'
using System;
using System.Runtime.InteropServices;
using System.Text;

public static class FirmwareTables
{
    [DllImport("kernel32.dll", SetLastError=true)]
    public static extern uint EnumSystemFirmwareTables(
        uint FirmwareTableProviderSignature,
        IntPtr pFirmwareTableBuffer,
        uint BufferSize
    );

    [DllImport("kernel32.dll", SetLastError=true)]
    public static extern uint GetSystemFirmwareTable(
        uint FirmwareTableProviderSignature,
        uint FirmwareTableID,
        IntPtr pFirmwareTableBuffer,
        uint BufferSize
    );

    public static uint Sig(string s)
    {
        if (s.Length != 4)
            throw new ArgumentException("Signature must be 4 chars");

        return
            ((uint)s[0]) |
            ((uint)s[1] << 8) |
            ((uint)s[2] << 16) |
            ((uint)s[3] << 24);
    }

    public static byte[] Get(string provider, string table)
    {
        uint p = Sig(provider);
        uint t = Sig(table);

        uint size = GetSystemFirmwareTable(
            p,
            t,
            IntPtr.Zero,
            0
        );

        if (size == 0)
            return Array.Empty<byte>();

        IntPtr buffer = Marshal.AllocHGlobal((int)size);

        try
        {
            uint result = GetSystemFirmwareTable(
                p,
                t,
                buffer,
                size
            );

            if (result == 0)
                return Array.Empty<byte>();

            byte[] data = new byte[result];

            Marshal.Copy(
                buffer,
                data,
                0,
                (int)result
            );

            return data;
        }
        finally
        {
            Marshal.FreeHGlobal(buffer);
        }
    }

    public static byte[] Enumerate(string provider)
    {
        uint p = Sig(provider);

        uint size = EnumSystemFirmwareTables(
            p,
            IntPtr.Zero,
            0
        );

        if (size == 0)
            return Array.Empty<byte>();

        IntPtr buffer = Marshal.AllocHGlobal((int)size);

        try
        {
            uint result = EnumSystemFirmwareTables(
                p,
                buffer,
                size
            );

            if (result == 0)
                return Array.Empty<byte>();

            byte[] data = new byte[result];

            Marshal.Copy(
                buffer,
                data,
                0,
                (int)result
            );

            return data;
        }
        finally
        {
            Marshal.FreeHGlobal(buffer);
        }
    }
}
'@

try {
    Add-Type -TypeDefinition $acpiSource
}
catch {
    $errors.Add(
        "ACPI P/INVOKE COMPILE FAILED :: $($_.Exception.Message)"
    )
}

try {

    $ids =
        [FirmwareTables]::Enumerate('ACPI')

    if ($ids.Length -gt 0) {

        [IO.File]::WriteAllBytes(
            (Join-Path $ACPI 'ACPI-ENUM-TABLE-IDS.bin'),
            $ids
        )

        Add-Line "ACPI table ID bytes: $($ids.Length)"

        for ($i = 0; $i + 3 -lt $ids.Length; $i += 4) {

            $sig = [Text.Encoding]::ASCII.GetString(
                $ids,
                $i,
                4
            )

            Add-Line "ACPI TABLE: $sig"

            try {

                $table =
                    [FirmwareTables]::Get(
                        'ACPI',
                        $sig
                    )

                if ($table.Length -gt 0) {

                    [IO.File]::WriteAllBytes(
                        (Join-Path $ACPI "$sig.bin"),
                        $table
                    )

                    Add-Line `
                        "$sig -> $($table.Length) bytes"
                }

            }
            catch {

                $errors.Add(
                    "ACPI TABLE FAILED: $sig :: $($_.Exception.Message)"
                )
            }
        }

    }
    else {

        Add-Line 'ACPI enumeration returned no tables.'
        $errors.Add('ACPI TABLE ENUMERATION EMPTY')
    }

}
catch {

    $errors.Add(
        "ACPI ENUMERATION FAILED :: $($_.Exception.Message)"
    )
}

# ------------------------------------------------------------
# SMBIOS
# ------------------------------------------------------------

Add-Section 'SMBIOS'

Run-PS `
    'SMBIOS' `
    {
        Get-CimInstance Win32_ComputerSystem |
            Format-List *

        Get-CimInstance Win32_BIOS |
            Format-List *

        Get-CimInstance Win32_BaseBoard |
            Format-List *
    } `
    (Join-Path $ACPI 'SMBIOS.txt')

# ------------------------------------------------------------
# SERVICES
# ------------------------------------------------------------

Add-Section 'SERVICES'

foreach ($svc in @(
    'WUDFRd',
    'WbioSrvc'
)) {

    Run-Native `
        'sc.exe' `
        @('query',$svc) `
        (Join-Path $Runtime "$svc-query.txt")

    Run-Native `
        'sc.exe' `
        @('qc',$svc) `
        (Join-Path $Runtime "$svc-config.txt")
}

Run-PS `
    'Services matching fingerprint stack' `
    {
        Get-Service |
            Where-Object {
                $_.Name -match 'Wbio|WUDF|Focal|Bio' -or
                $_.DisplayName -match 'Wbio|WUDF|Focal|Bio'
            } |
            Format-List *
    } `
    (Join-Path $Runtime 'biometric-services.txt')

# ------------------------------------------------------------
# WUDF HOST RUNTIME
# ------------------------------------------------------------

Add-Section 'WUDF HOST RUNTIME'

Run-Native `
    'tasklist.exe' `
    @('/v') `
    (Join-Path $Runtime 'tasklist.txt')

Run-Native `
    'tasklist.exe' `
    @('/m','ftWbioUmdfDriverV2.dll') `
    (Join-Path $Runtime 'tasklist-ftWbioUmdfDriverV2.txt')

Run-Native `
    'tasklist.exe' `
    @('/m','ftWbioEngineAdapter.dll') `
    (Join-Path $Runtime 'tasklist-ftWbioEngineAdapter.txt')

Run-PS `
    'WUDFHost processes' `
    {
        Get-CimInstance Win32_Process |
            Where-Object {
                $_.Name -ieq 'WUDFHost.exe'
            } |
            Select-Object `
                ProcessId,
                ParentProcessId,
                ExecutablePath,
                CommandLine |
            Format-List
    } `
    (Join-Path $Runtime 'WUDFHost-processes.txt')

# Try module enumeration
try {

    $hosts = Get-Process WUDFHost -ErrorAction SilentlyContinue

    foreach ($p in $hosts) {

        $safe = "WUDFHost-$($p.Id)-modules.txt"

        try {

            $p.Modules |
                Select-Object ModuleName,FileName,FileVersionInfo |
                Format-List |
                Out-File `
                    (Join-Path $Runtime $safe) `
                    -Encoding UTF8

        }
        catch {

            $errors.Add(
                "MODULE ENUM FAILED PID=$($p.Id)"
            )
        }
    }

}
catch {

    $errors.Add(
        "WUDF MODULE ENUMERATION FAILED"
    )
}

# ------------------------------------------------------------
# POWER / IDLE POLICY
# ------------------------------------------------------------

Add-Section 'POWER AND DEVICE IDLE'

Run-Native `
    'powercfg.exe' `
    @('/getactivescheme') `
    (Join-Path $Runtime 'powercfg-active.txt')

Run-Native `
    'powercfg.exe' `
    @('/query') `
    (Join-Path $Runtime 'powercfg-query.txt')

Run-PS `
    'Device power properties' `
    {
        Get-PnpDeviceProperty `
            -InstanceId $InstanceId |
            Where-Object {
                $_.KeyName -match 'Power|Idle|Wake'
            } |
            Format-List *
    } `
    (Join-Path $Runtime 'device-power-properties.txt')

# ------------------------------------------------------------
# EVENT LOGS
# ------------------------------------------------------------

Add-Section 'EVENT LOGS'

$channels = @()

try {

    $channels =
        & wevtutil.exe el 2>$null |
        Where-Object {
            $_ -match 'Biometrics|DriverFrameworks-UserMode|Kernel-PnP|WUDF'
        } |
        Sort-Object -Unique

}
catch {

    $errors.Add('WEVTUTIL CHANNEL ENUMERATION FAILED')
}

foreach ($channel in $channels) {

    Add-Line "EVENT CHANNEL: $channel"

    $safe =
        ($channel -replace '[\\/:*?"<>| ]','_')

    # Full EVTX export
    try {

        $evtx =
            Join-Path $Events "$safe.evtx"

        & wevtutil.exe epl `
            $channel `
            $evtx 2>&1 |
            Out-String |
            Out-Null

        if ($LASTEXITCODE -ne 0) {

            $errors.Add(
                "EVENT EXPORT FAILED [$LASTEXITCODE]: $channel"
            )
        }

    }
    catch {

        $errors.Add(
            "EVENT EXPORT EXCEPTION: $channel"
        )
    }

    # Human-readable recent events
    try {

        Get-WinEvent `
            -LogName $channel `
            -MaxEvents 500 `
            -ErrorAction Stop |
            Where-Object {
                $_.TimeCreated -gt (Get-Date).AddDays(-7)
            } |
            Select-Object TimeCreated,Id,LevelDisplayName,ProviderName,Message |
            Format-List |
            Out-File `
                (Join-Path $Events "$safe-recent.txt") `
                -Encoding UTF8

    }
    catch {

        $errors.Add(
            "GET-WINEVENT FAILED: $channel"
        )
    }
}

# Additional PnP / service events
try {

    Get-WinEvent `
        -FilterHashtable @{
            LogName = 'System'
            StartTime = (Get-Date).AddDays(-7)
        } `
        -MaxEvents 5000 |
        Where-Object {
            $_.ProviderName -match `
                'Kernel-PnP|UserPnp|WUDF|DriverFrameworks'
        } |
        Select-Object TimeCreated,Id,ProviderName,LevelDisplayName,Message |
        Format-List |
        Out-File `
            (Join-Path $Events 'System-PnP-WUDF-last7days.txt') `
            -Encoding UTF8

}
catch {

    $errors.Add(
        'SYSTEM PNP EVENT EXTRACTION FAILED'
    )
}

# ------------------------------------------------------------
# BIOMETRICS / WINBIO REGISTRY
# ------------------------------------------------------------

Add-Section 'WINBIO CONFIGURATION'

Run-Native `
    'reg.exe' `
    @(
        'query',
        'HKLM\SYSTEM\CurrentControlSet\Control\Biometrics',
        '/s'
    ) `
    (Join-Path $Registry 'Biometrics-full.txt')

Run-Native `
    'reg.exe' `
    @(
        'query',
        'HKLM\SYSTEM\CurrentControlSet\Enum\ACPI\FTE4800\4&f064bb&0\Device Parameters',
        '/s'
    ) `
    (Join-Path $Registry 'FTE4800-Device-Parameters-full.txt')

# ------------------------------------------------------------
# FOCALTECH REGISTRY
# ------------------------------------------------------------

Add-Section 'FOCALTECH REGISTRY'

Run-Native `
    'reg.exe' `
    @(
        'query',
        'HKLM\SYSTEM\CurrentControlSet\Control\focalFp',
        '/s'
    ) `
    (Join-Path $Registry 'focalFp-full.txt')

# ------------------------------------------------------------
# DEVICE INTERFACES
# ------------------------------------------------------------

Add-Section 'DEVICE INTERFACES'

Run-PS `
    'PnP interfaces' `
    {
        Get-PnpDevice -PresentOnly |
            Where-Object {
                $_.InstanceId -eq $InstanceId
            } |
            Format-List *
    } `
    (Join-Path $Evidence 'device-present-state.txt')

Run-PS `
    'Biometric class devices' `
    {
        Get-PnpDevice -Class Biometric |
            Sort-Object Status,InstanceId |
            Format-List *
    } `
    (Join-Path $Evidence 'all-biometric-devices.txt')

# ------------------------------------------------------------
# RUNTIME DLL INFORMATION
# ------------------------------------------------------------

Add-Section 'RUNTIME DLL INFORMATION'

foreach ($dllName in @(
    'ftWbioUmdfDriverV2.dll',
    'ftWbioEngineAdapter.dll'
)) {

    $hits =
        Get-ChildItem `
            'C:\Windows\System32\DriverStore\FileRepository' `
            -Recurse `
            -File `
            -Filter $dllName `
            -ErrorAction SilentlyContinue

    foreach ($dllFile in $hits) {

        Add-Line ''
        Add-Line "DLL: $($dllFile.FullName)"
        Add-Line "Length: $($dllFile.Length)"
        Add-Line "Creation: $($dllFile.CreationTimeUtc)"
        Add-Line "WriteTime: $($dllFile.LastWriteTimeUtc)"

        try {

            $v =
                $dllFile.VersionInfo

            Add-Line "FileVersion: $($v.FileVersion)"
            Add-Line "ProductVersion: $($v.ProductVersion)"
            Add-Line "CompanyName: $($v.CompanyName)"
            Add-Line "OriginalFilename: $($v.OriginalFilename)"
            Add-Line "InternalName: $($v.InternalName)"
            Add-Line "ProductName: $($v.ProductName)"
            Add-Line "FileDescription: $($v.FileDescription)"

        }
        catch {

            $errors.Add(
                "VERSIONINFO FAILED: $($dllFile.FullName)"
            )
        }

        try {

            $h =
                Get-FileHash `
                    -LiteralPath $dllFile.FullName `
                    -Algorithm SHA256

            Add-Line "SHA256: $($h.Hash)"

        }
        catch {

            $errors.Add(
                "DLL HASH FAILED: $($dllFile.FullName)"
            )
        }
    }
}

# ------------------------------------------------------------
# WINDOWS DRIVER LOGGING PROVIDERS
# ------------------------------------------------------------

Add-Section 'ETW / TRACE PROVIDER DISCOVERY'

try {

    $providers =
        & logman.exe query providers 2>$null |
        Out-String

    Save-Text `
        (Join-Path $Runtime 'logman-providers.txt') `
        $providers

    $providers |
        Select-String `
            -Pattern 'WUDF|DriverFramework|Biometric|Focal|Fingerprint|WinBio' |
        ForEach-Object {
            Add-Line $_.Line
        }

}
catch {

    $errors.Add(
        'ETW PROVIDER ENUMERATION FAILED'
    )
}

# ------------------------------------------------------------
# WINDOWS VERSION
# ------------------------------------------------------------

Add-Section 'WINDOWS VERSION'

Run-PS `
    'Windows version' `
    {
        Get-CimInstance Win32_OperatingSystem |
            Format-List *
    } `
    (Join-Path $Runtime 'windows-version.txt')

Run-Native `
    'systeminfo.exe' `
    @() `
    (Join-Path $Runtime 'systeminfo.txt')

# ------------------------------------------------------------
# COMPLETE FILE MANIFEST
# ------------------------------------------------------------

Add-Section 'COLLECTION DIRECTORY'

try {

    Get-ChildItem `
        $Out `
        -Recurse `
        -File `
        -ErrorAction SilentlyContinue |
        ForEach-Object {
            Add-Line (
                "{0} bytes  {1}" -f
                $_.Length,
                $_.FullName
            )
        }

}
catch {

    $errors.Add('COLLECTION DIRECTORY ENUMERATION FAILED')
}

# ------------------------------------------------------------
# HASH EVERYTHING
# ------------------------------------------------------------

try {

    $hashLines =
        Get-ChildItem `
            $Out `
            -Recurse `
            -File `
            -ErrorAction SilentlyContinue |
        Sort-Object FullName |
        ForEach-Object {

            try {

                $h =
                    Get-FileHash `
                        -LiteralPath $_.FullName `
                        -Algorithm SHA256

                "{0}  {1}" -f $h.Hash,$_.FullName

            }
            catch {

                "HASH_ERROR  $($_.FullName)"
            }
        }

    Save-Text `
        $Manifest `
        ($hashLines -join "`r`n")

}
catch {

    $errors.Add('FINAL MANIFEST HASH FAILED')
}

# ------------------------------------------------------------
# ERRORS
# ------------------------------------------------------------

Add-Section 'ERRORS'

if ($errors.Count -eq 0) {

    Add-Line 'NONE'

}
else {

    foreach ($e in $errors) {
        Add-Line $e
    }
}

# ------------------------------------------------------------
# WINDOWS GATE VERDICT
# ------------------------------------------------------------

Add-Section 'WINDOWS GATE STATUS'

$criticalFiles = @(
    (Join-Path $Driver 'pnputil-biometric-drivers.txt'),
    (Join-Path $Evidence 'Get-PnpDevice.txt'),
    (Join-Path $Evidence 'ALL-DEVICE-PROPERTIES.txt'),
    (Join-Path $Registry 'FTE4800-Device-Parameters-full.txt'),
    (Join-Path $Registry 'focalFp-full.txt')
)

$missingCritical = $criticalFiles |
    Where-Object {
        -not (Test-Path $_)
    }

if (
    $isAdmin -and
    $driverHits.Count -gt 0 -and
    $missingCritical.Count -eq 0
) {

    Add-Line 'WINDOWS-GATE-COMPLETE = TRUE'

}
else {

    Add-Line 'WINDOWS-GATE-COMPLETE = FALSE'

    if (-not $isAdmin) {
        Add-Line 'Reason: not Administrator'
    }

    if ($driverHits.Count -eq 0) {
        Add-Line 'Reason: driver-store package was not found'
    }

    foreach ($m in $missingCritical) {
        Add-Line "Missing: $m"
    }
}

Add-Line ''
Add-Line 'IMPORTANT: This gate only means Windows-specific evidence was collected.'
Add-Line 'It does NOT mean the SPI protocol has already been reconstructed.'
Add-Line 'The PE/DLL reverse engineering will be performed on Linux.'
Add-Line ''
Add-Line 'Linux analysis targets:'
Add-Line '  SPI framing'
Add-Line '  chip ID transaction'
Add-Line '  register read/write'
Add-Line '  SFR framing'
Add-Line '  GPIO/reset'
Add-Line '  interrupt status/clear'
Add-Line '  state machine'
Add-Line '  sleep/wake'
Add-Line '  image acquisition'
Add-Line '  FIFO/image transfer'
Add-Line '  firmware download'
Add-Line '  firmware update'
Add-Line '  packet constants'
Add-Line '  function graph'
Add-Line '  raw image dimensions/format'
Add-Line '  exact FT9368 vs other-family selection'

# ------------------------------------------------------------
# SAVE FINAL REPORT
# ------------------------------------------------------------

$finalText = $lines -join "`r`n"

Save-Text $Report $finalText

# Save errors separately
if ($errors.Count -gt 0) {

    Save-Text `
        $Errors `
        ($errors -join "`r`n")

}
else {

    Save-Text $Errors 'NONE'
}

# ------------------------------------------------------------
# FINAL CLIPBOARD COPY
# ------------------------------------------------------------

$clipboardOK = $false

try {

    Set-Clipboard -Value $finalText
    $clipboardOK = $true

}
catch {

    try {

        $finalText | clip.exe
        $clipboardOK = $true

    }
    catch {}
}

# ------------------------------------------------------------
# CONSOLE OUTPUT
# ------------------------------------------------------------

Write-Host ''
Write-Host '======================================================================'
Write-Host 'FTE4800 WINDOWS FINAL EVIDENCE GATE COMPLETE'
Write-Host '======================================================================'
Write-Host "OUTPUT      : $Out"
Write-Host "REPORT      : $Report"
Write-Host "MANIFEST    : $Manifest"
Write-Host "ERRORS      : $Errors"
Write-Host "FILES FOUND : $($driverHits.Count)"
Write-Host "ADMIN       : $isAdmin"
Write-Host "CLIPBOARD   : $clipboardOK"
Write-Host '======================================================================'
Write-Host ''

if ($finalText -match 'WINDOWS-GATE-COMPLETE = TRUE') {
    Write-Host 'WINDOWS GATE: COMPLETE'
    Write-Host ''
    Write-Host 'The Windows-specific evidence collection is complete.'
    Write-Host 'The next stage is Linux-side PE/hex/disassembly analysis.'
}
else {
    Write-Host 'WINDOWS GATE: NOT COMPLETE'
    Write-Host ''
    Write-Host 'Inspect ALL-ERRORS.txt before leaving Windows.'
}

Write-Host ''
Write-Host 'The report has been copied to the clipboard.'
Write-Host 'Paste it into ChatGPT.'
Write-Host '======================================================================'
