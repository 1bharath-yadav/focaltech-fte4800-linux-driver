# ============================================================
# FTE4800 FINAL WINDOWS RESOURCE / ACPI EXTRACTION
#
# PURPOSE
# -------
# Final Windows-only evidence collection before Linux boot.
#
# Collects:
#   - FTE4800 PnP resources
#   - FTE4800 PnP stack/services/properties
#   - SPI controller resources
#   - ACPI table enumeration
#   - raw ACPI tables (.bin)
#   - SMBIOS
#   - LogConf / BootConfig / resource blobs
#   - exact driver package paths
#   - DLL/INF/CAT hashes
#   - relevant registry state
#
# DOES NOT:
#   - install/remove driver
#   - modify registry
#   - reset fingerprint
#   - write firmware
#   - alter device configuration
#
# WINDOWS POWERSHELL 5.1 COMPATIBLE
# FINAL REPORT -> AUTOMATICALLY COPIED TO CLIPBOARD
# ============================================================

$ErrorActionPreference = 'Continue'

# ------------------------------------------------------------
# Configuration
# ------------------------------------------------------------

$InstanceId = 'ACPI\FTE4800\4&f064bb&0'
$SpiId      = 'PCI\VEN_8086&DEV_51FB&SUBSYS_00000000&REV_01\3&11583659&0&96'

$ResearchRoot = 'C:\FTE4800-RESEARCH'
$Base = 'C:\FTE4800-RESEARCH\20261002-190717'

if (-not (Test-Path $Base)) {
    $latest = Get-ChildItem $ResearchRoot -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match '^\d{8}-\d{6}$' } |
        Sort-Object Name -Descending |
        Select-Object -First 1

    if ($latest) {
        $Base = $latest.FullName
    }
}

$Out = Join-Path $Base '19-WINDOWS-FINAL-RESOURCE-GATE'

$Evidence = Join-Path $Out 'evidence'
$Resources = Join-Path $Out 'resources'
$ACPI = Join-Path $Out 'acpi'
$Registry = Join-Path $Out 'registry'
$Driver = Join-Path $Out 'driver-package'
$Runtime = Join-Path $Out 'runtime'

foreach ($d in @(
    $Out,
    $Evidence,
    $Resources,
    $ACPI,
    $Registry,
    $Driver,
    $Runtime
)) {
    New-Item -ItemType Directory -Force -Path $d | Out-Null
}

$Report = Join-Path $Out 'FINAL-WINDOWS-RESOURCE-REPORT.txt'
$Errors = Join-Path $Out 'ERRORS.txt'
$Manifest = Join-Path $Out 'SHA256-MANIFEST.txt'

$lines = New-Object 'System.Collections.Generic.List[string]'
$errors = New-Object 'System.Collections.Generic.List[string]'

function Add-Line {
    param([string]$Text = '')
    [void]$lines.Add($Text)
}

function Section {
    param([string]$Title)

    Add-Line ''
    Add-Line ('=' * 80)
    Add-Line $Title
    Add-Line ('=' * 80)
}

function Save-Text {
    param(
        [string]$Path,
        [string]$Text
    )

    try {
        [System.IO.File]::WriteAllText(
            $Path,
            $Text,
            [System.Text.UTF8Encoding]::new($false)
        )
    }
    catch {
        [void]$errors.Add(
            "WRITE FAILED: $Path :: $($_.Exception.Message)"
        )
    }
}

function Run-Command {
    param(
        [string]$Command,
        [string[]]$Arguments,
        [string]$OutputFile
    )

    try {

        $output = & $Command @Arguments 2>&1 | Out-String

        Save-Text $OutputFile $output

        Add-Line "COMMAND: $Command $($Arguments -join ' ')"
        Add-Line "OUTPUT : $OutputFile"

        if ($LASTEXITCODE -ne 0) {

            [void]$errors.Add(
                "COMMAND FAILED [$LASTEXITCODE]: $Command $($Arguments -join ' ')"
            )
        }

        return $output
    }
    catch {

        $msg =
            "COMMAND EXCEPTION: $Command :: $($_.Exception.Message)"

        [void]$errors.Add($msg)
        Save-Text $OutputFile $msg

        return $msg
    }
}

function Run-PSCommand {
    param(
        [string]$Name,
        [scriptblock]$Script,
        [string]$OutputFile
    )

    try {

        $result = & $Script 2>&1 | Out-String

        Save-Text $OutputFile $result

        Add-Line "$Name"
        Add-Line "OUTPUT: $OutputFile"

        return $result
    }
    catch {

        $msg =
            "$Name FAILED :: $($_.Exception.Message)"

        [void]$errors.Add($msg)
        Save-Text $OutputFile $msg

        return $msg
    }
}

# ------------------------------------------------------------
# Header
# ------------------------------------------------------------

Add-Line 'FTE4800 FINAL WINDOWS RESOURCE / ACPI GATE'
Add-Line "TIME          : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Add-Line "COMPUTER      : $env:COMPUTERNAME"
Add-Line "USER          : $env:USERNAME"
Add-Line "POWERSHELL    : $($PSVersionTable.PSVersion)"
Add-Line "RESEARCH BASE : $Base"
Add-Line "OUTPUT        : $Out"
Add-Line "INSTANCE ID   : $InstanceId"
Add-Line "SPI ID        : $SpiId"

# ------------------------------------------------------------
# Administrator
# ------------------------------------------------------------

Section 'ADMINISTRATOR'

try {

    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()

    $principal = New-Object Security.Principal.WindowsPrincipal(
        $identity
    )

    $isAdmin = $principal.IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator
    )

    Add-Line "Administrator: $isAdmin"

}
catch {

    $isAdmin = $false

    Add-Line 'Administrator check failed.'
    Add-Line $_.Exception.Message

    [void]$errors.Add(
        "ADMIN CHECK FAILED"
    )
}

# ------------------------------------------------------------
# PnP device
# ------------------------------------------------------------

Section 'FTE4800 DEVICE'

Run-PSCommand `
    'Get-PnpDevice' `
    {
        Get-PnpDevice `
            -InstanceId $InstanceId |
            Format-List *
    } `
    (Join-Path $Evidence 'FTE4800-Get-PnpDevice.txt')

Run-PSCommand `
    'Get-PnpDeviceProperty' `
    {
        Get-PnpDeviceProperty `
            -InstanceId $InstanceId |
            Sort-Object KeyName |
            Format-List *
    } `
    (Join-Path $Evidence 'FTE4800-ALL-PROPERTIES.txt')

# ------------------------------------------------------------
# PnP resource/stack/service/property views
# ------------------------------------------------------------

Section 'FTE4800 PNP RESOURCE DATA'

foreach ($mode in @(
    'resources',
    'stack',
    'services',
    'drivers',
    'interfaces',
    'properties',
    'relations'
)) {

    $file =
        Join-Path $Resources "FTE4800-$mode.txt"

    Run-Command `
        'pnputil.exe' `
        @(
            '/enum-devices',
            '/instanceid',
            $InstanceId,
            "/$mode"
        ) `
        $file
}

# ------------------------------------------------------------
# Capture all device properties individually in machine-friendly form
# ------------------------------------------------------------

Section 'FTE4800 IMPORTANT PNP PROPERTIES'

$importantPropertyPatterns = @(
    'Location',
    'Resource',
    'Interrupt',
    'Address',
    'UINumber',
    'Enumerator',
    'BusReportedDeviceDesc',
    'HardwareIds',
    'CompatibleIds',
    'Parent',
    'Class',
    'Service',
    'Driver',
    'PDO',
    'ContainerId',
    'DeviceDesc',
    'Manufacturer'
)

try {

    $props =
        Get-PnpDeviceProperty `
            -InstanceId $InstanceId

    foreach ($pattern in $importantPropertyPatterns) {

        Add-Line ''
        Add-Line "PATTERN: $pattern"

        $matches =
            $props |
            Where-Object {
                $_.KeyName -match $pattern
            }

        if ($matches) {

            $matches |
                Format-List * |
                Out-String |
                ForEach-Object {
                    Add-Line $_
                }

        }
        else {

            Add-Line 'No matching property.'
        }
    }

}
catch {

    [void]$errors.Add(
        "IMPORTANT PNP PROPERTY EXTRACTION FAILED"
    )
}

# ------------------------------------------------------------
# SPI controller
# ------------------------------------------------------------

Section 'INTEL SPI CONTROLLER'

Run-PSCommand `
    'SPI Get-PnpDevice' `
    {
        Get-PnpDevice `
            -InstanceId $SpiId |
            Format-List *
    } `
    (Join-Path $Evidence 'SPI51FB-Get-PnpDevice.txt')

Run-PSCommand `
    'SPI properties' `
    {
        Get-PnpDeviceProperty `
            -InstanceId $SpiId |
            Sort-Object KeyName |
            Format-List *
    } `
    (Join-Path $Evidence 'SPI51FB-ALL-PROPERTIES.txt')

foreach ($mode in @(
    'resources',
    'stack',
    'services',
    'drivers',
    'interfaces',
    'properties'
)) {

    $file =
        Join-Path $Resources "SPI51FB-$mode.txt"

    Run-Command `
        'pnputil.exe' `
        @(
            '/enum-devices',
            '/instanceid',
            $SpiId,
            "/$mode"
        ) `
        $file
}

# ------------------------------------------------------------
# DEVICE REGISTRY
# ------------------------------------------------------------

Section 'FTE4800 DEVICE REGISTRY'

$DeviceReg =
    'HKLM\SYSTEM\CurrentControlSet\Enum\ACPI\FTE4800\4&f064bb&0'

Run-Command `
    'reg.exe' `
    @(
        'query',
        $DeviceReg,
        '/s'
    ) `
    (Join-Path $Registry 'FTE4800-device-query.txt')

Run-Command `
    'reg.exe' `
    @(
        'export',
        $DeviceReg,
        (Join-Path $Registry 'FTE4800-device.reg'),
        '/y'
    ) `
    (Join-Path $Registry 'FTE4800-device-export.txt')

# ------------------------------------------------------------
# LogConf specifically
# ------------------------------------------------------------

Section 'LOGCONF / RESOURCE BLOBS'

$logConfReg = "$DeviceReg\LogConf"

Run-Command `
    'reg.exe' `
    @(
        'query',
        $logConfReg,
        '/s'
    ) `
    (Join-Path $Registry 'LogConf-query.txt')

# Capture exact binary values using PowerShell Registry provider
try {

    $rk =
        [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey(
            'SYSTEM\CurrentControlSet\Enum\ACPI\FTE4800\4&f064bb&0\LogConf'
        )

    if ($rk) {

        foreach ($valueName in $rk.GetValueNames()) {

            try {

                $kind =
                    $rk.GetValueKind($valueName)

                $value =
                    $rk.GetValue(
                        $valueName,
                        $null,
                        [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames
                    )

                Add-Line ''
                Add-Line "VALUE: $valueName"
                Add-Line "TYPE : $kind"

                if ($value -is [byte[]]) {

                    $hex =
                        [BitConverter]::ToString($value) `
                            -replace '-',''

                    Add-Line "BYTES: $($value.Length)"
                    Add-Line "HEX  : $hex"

                    [IO.File]::WriteAllBytes(
                        (Join-Path $Registry "$valueName.bin"),
                        $value
                    )

                }
                elseif ($value -is [Array]) {

                    Add-Line (
                        "VALUE: $($value -join ',')"
                    )

                }
                else {

                    Add-Line "VALUE: $value"
                }

            }
            catch {

                [void]$errors.Add(
                    "LOGCONF VALUE FAILED: $valueName"
                )
            }
        }

        $rk.Close()
    }
    else {

        Add-Line 'LogConf registry key not found.'

    }

}
catch {

    [void]$errors.Add(
        "LOGCONF REGISTRY API FAILED :: $($_.Exception.Message)"
    )
}

# ------------------------------------------------------------
# Capture BootConfig / BasicConfigVector / FilteredConfigVector
# from device registry directly
# ------------------------------------------------------------

Section 'RESOURCE CONFIGURATION VECTORS'

try {

    $rk =
        [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey(
            'SYSTEM\CurrentControlSet\Enum\ACPI\FTE4800\4&f064bb&0\LogConf'
        )

    if ($rk) {

        foreach ($name in @(
            'BootConfig',
            'BasicConfigVector'
        )) {

            try {

                $v = $rk.GetValue($name)

                Add-Line ''
                Add-Line "REG VALUE: $name"

                if ($v -is [byte[]]) {

                    Add-Line "BYTE COUNT: $($v.Length)"

                    $h =
                        [BitConverter]::ToString($v) `
                            -replace '-',''

                    Add-Line "HEX: $h"

                    [IO.File]::WriteAllBytes(
                        (Join-Path $Registry "$name.raw.bin"),
                        $v
                    )

                }
                else {

                    Add-Line "VALUE: $v"
                }
            }
            catch {}
        }

        $rk.Close()
    }

}
catch {

    [void]$errors.Add(
        "RESOURCE VECTOR EXTRACTION FAILED"
    )
}

# Control -> FilteredConfigVector
try {

    $rk =
        [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey(
            'SYSTEM\CurrentControlSet\Enum\ACPI\FTE4800\4&f064bb&0\Control'
        )

    if ($rk) {

        foreach ($name in @(
            'FilteredConfigVector'
        )) {

            $v = $rk.GetValue($name)

            Add-Line ''
            Add-Line "REG VALUE: $name"

            if ($v -is [byte[]]) {

                Add-Line "BYTE COUNT: $($v.Length)"

                $h =
                    [BitConverter]::ToString($v) `
                        -replace '-',''

                Add-Line "HEX: $h"

                [IO.File]::WriteAllBytes(
                    (Join-Path $Registry "$name.raw.bin"),
                    $v
                )
            }
        }

        $rk.Close()
    }
}
catch {

    [void]$errors.Add(
        "FILTERED CONFIG EXTRACTION FAILED"
    )
}

# ------------------------------------------------------------
# ACPI TABLES
#
# IMPORTANT:
# Use a UNIQUE class name so this script can safely run after
# the previous FirmwareTables class was already loaded.
# ------------------------------------------------------------

Section 'ACPI TABLE ENUMERATION'

$AcpiTypeName =
    'FTE4800AcpiFirmwareTables_' +
    ([guid]::NewGuid().ToString('N'))

$acpiSource = @"
using System;
using System.Runtime.InteropServices;

public static class $AcpiTypeName
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

    public static uint Signature(string s)
    {
        if (s.Length != 4)
            throw new ArgumentException("Signature must be 4 characters.");

        return
            ((uint)s[0]) |
            ((uint)s[1] << 8) |
            ((uint)s[2] << 16) |
            ((uint)s[3] << 24);
    }

    public static byte[] Enumerate(string provider)
    {
        uint p = Signature(provider);

        uint size =
            EnumSystemFirmwareTables(
                p,
                IntPtr.Zero,
                0
            );

        if (size == 0)
            return new byte[0];

        IntPtr buffer =
            Marshal.AllocHGlobal((int)size);

        try
        {
            uint result =
                EnumSystemFirmwareTables(
                    p,
                    buffer,
                    size
                );

            if (result == 0)
                return new byte[0];

            byte[] data =
                new byte[result];

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

    public static byte[] GetTable(
        string provider,
        string table
    )
    {
        uint p = Signature(provider);
        uint t = Signature(table);

        uint size =
            GetSystemFirmwareTable(
                p,
                t,
                IntPtr.Zero,
                0
            );

        if (size == 0)
            return new byte[0];

        IntPtr buffer =
            Marshal.AllocHGlobal((int)size);

        try
        {
            uint result =
                GetSystemFirmwareTable(
                    p,
                    t,
                    buffer,
                    size
                );

            if (result == 0)
                return new byte[0];

            byte[] data =
                new byte[result];

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
"@

try {

    Add-Type `
        -TypeDefinition $acpiSource `
        -Language CSharp `
        -ErrorAction Stop

    $acpiType =
        [type]::GetType(
            "$AcpiTypeName"
        )

    # Better lookup from generated assembly
    $acpiType =
        [AppDomain]::CurrentDomain.GetAssemblies() |
        ForEach-Object {
            $_.GetType(
                $AcpiTypeName,
                $false,
                $false
            )
        } |
        Where-Object { $_ } |
        Select-Object -First 1

    if (-not $acpiType) {
        throw "Generated ACPI type could not be located."
    }

    $ids =
        $acpiType.GetMethod(
            'Enumerate'
        ).Invoke(
            $null,
            @('ACPI')
        )

    if (-not $ids -or $ids.Length -eq 0) {

        Add-Line 'ACPI ENUMERATION RETURNED ZERO TABLE IDs.'

        [void]$errors.Add(
            'ACPI TABLE ENUMERATION EMPTY'
        )

    }
    else {

        Add-Line "ACPI ENUMERATION BYTES: $($ids.Length)"

        [IO.File]::WriteAllBytes(
            (Join-Path $ACPI 'ACPI-TABLE-ID-LIST.bin'),
            $ids
        )

        $tableCount = 0

        for (
            $i = 0;
            $i + 3 -lt $ids.Length;
            $i += 4
        ) {

            $sig =
                [Text.Encoding]::ASCII.GetString(
                    $ids,
                    $i,
                    4
                )

            $tableCount++

            Add-Line ''
            Add-Line "ACPI TABLE #$tableCount"
            Add-Line "SIGNATURE: $sig"

            try {

                $table =
                    $acpiType.GetMethod(
                        'GetTable'
                    ).Invoke(
                        $null,
                        @('ACPI',$sig)
                    )

                if (
                    $table -and
                    $table.Length -gt 0
                ) {

                    $file =
                        Join-Path $ACPI "$sig.bin"

                    [IO.File]::WriteAllBytes(
                        $file,
                        $table
                    )

                    Add-Line "SIZE: $($table.Length)"
                    Add-Line "FILE: $file"

                    # ACPI header fields where available
                    if ($table.Length -ge 36) {

                        $signature =
                            [Text.Encoding]::ASCII.GetString(
                                $table,
                                0,
                                4
                            )

                        $length =
                            [BitConverter]::ToUInt32(
                                $table,
                                4
                            )

                        $revision =
                            $table[8]

                        $oemId =
                            [Text.Encoding]::ASCII.GetString(
                                $table,
                                10,
                                6
                            ).Trim()

                        $oemTableId =
                            [Text.Encoding]::ASCII.GetString(
                                $table,
                                16,
                                8
                            ).Trim()

                        Add-Line "HEADER SIGNATURE : $signature"
                        Add-Line "HEADER LENGTH    : $length"
                        Add-Line "REVISION         : $revision"
                        Add-Line "OEM ID           : $oemId"
                        Add-Line "OEM TABLE ID     : $oemTableId"
                    }

                }
                else {

                    Add-Line 'TABLE RETRIEVAL RETURNED ZERO BYTES.'

                    [void]$errors.Add(
                        "ACPI TABLE EMPTY: $sig"
                    )
                }

            }
            catch {

                Add-Line (
                    "TABLE ERROR: $($_.Exception.Message)"
                )

                [void]$errors.Add(
                    "ACPI TABLE FAILED: $sig"
                )
            }
        }

        Add-Line ''
        Add-Line "TOTAL ACPI TABLES: $tableCount"
    }

}
catch {

    Add-Line ''
    Add-Line 'ACPI EXTRACTION FAILED'
    Add-Line $_.Exception.Message

    [void]$errors.Add(
        "ACPI EXTRACTION FAILED :: $($_.Exception.Message)"
    )
}

# ------------------------------------------------------------
# SMBIOS
# ------------------------------------------------------------

Section 'SMBIOS'

Run-PSCommand `
    'ComputerSystem' `
    {
        Get-CimInstance Win32_ComputerSystem |
            Format-List *
    } `
    (Join-Path $ACPI 'Win32_ComputerSystem.txt')

Run-PSCommand `
    'BIOS' `
    {
        Get-CimInstance Win32_BIOS |
            Format-List *
    } `
    (Join-Path $ACPI 'Win32_BIOS.txt')

Run-PSCommand `
    'BaseBoard' `
    {
        Get-CimInstance Win32_BaseBoard |
            Format-List *
    } `
    (Join-Path $ACPI 'Win32_BaseBoard.txt')

# ------------------------------------------------------------
# Driver package
# ------------------------------------------------------------

Section 'DRIVER PACKAGE'

$driverFiles = Get-ChildItem `
    'C:\Windows\System32\DriverStore\FileRepository' `
    -Recurse `
    -File `
    -ErrorAction SilentlyContinue |
    Where-Object {
        $_.Name -in @(
            'ftWbioUmdfDriverV2.dll',
            'ftWbioEngineAdapter.dll',
            'ftwbioumdfdriverv2.inf',
            'ftWbioUmdfDriverV2.cat'
        )
    }

foreach ($f in $driverFiles) {

    Add-Line ''
    Add-Line "FILE: $($f.FullName)"
    Add-Line "SIZE: $($f.Length)"

    try {

        $h =
            Get-FileHash `
                -LiteralPath $f.FullName `
                -Algorithm SHA256

        Add-Line "SHA256: $($h.Hash)"

    }
    catch {

        [void]$errors.Add(
            "HASH FAILED: $($f.FullName)"
        )
    }

    # Copy exact file into final evidence package
    try {

        $dest =
            Join-Path $Driver $f.Name

        Copy-Item `
            -LiteralPath $f.FullName `
            -Destination $dest `
            -Force

    }
    catch {

        [void]$errors.Add(
            "DRIVER COPY FAILED: $($f.FullName)"
        )
    }
}

# ------------------------------------------------------------
# Driver versions
# ------------------------------------------------------------

Section 'DRIVER VERSION INFORMATION'

foreach ($f in $driverFiles) {

    if (
        $f.Extension -ieq '.dll'
    ) {

        try {

            $vi = $f.VersionInfo

            Add-Line ''
            Add-Line "FILE: $($f.Name)"
            Add-Line "FileVersion: $($vi.FileVersion)"
            Add-Line "ProductVersion: $($vi.ProductVersion)"
            Add-Line "Company: $($vi.CompanyName)"
            Add-Line "Description: $($vi.FileDescription)"
            Add-Line "InternalName: $($vi.InternalName)"
            Add-Line "OriginalFilename: $($vi.OriginalFilename)"

        }
        catch {}
    }
}

# ------------------------------------------------------------
# Installed driver signature
# ------------------------------------------------------------

Section 'AUTHENTICODE'

foreach ($f in $driverFiles) {

    try {

        $sig =
            Get-AuthenticodeSignature `
                -LiteralPath $f.FullName

        Add-Line ''
        Add-Line "FILE: $($f.Name)"
        Add-Line "STATUS: $($sig.Status)"

        if ($sig.SignerCertificate) {

            Add-Line "SUBJECT: $($sig.SignerCertificate.Subject)"
            Add-Line "ISSUER : $($sig.SignerCertificate.Issuer)"
            Add-Line "SERIAL : $($sig.SignerCertificate.SerialNumber)"
        }

    }
    catch {

        [void]$errors.Add(
            "SIGNATURE CHECK FAILED: $($f.FullName)"
        )
    }
}

# ------------------------------------------------------------
# Relevant registry configuration
# ------------------------------------------------------------

Section 'WINBIO / WUDF / FOCALTECH CONFIGURATION'

foreach ($path in @(
    'HKLM\SYSTEM\CurrentControlSet\Control\focalFp',
    'HKLM\SYSTEM\CurrentControlSet\Services\WUDFRd',
    'HKLM\SYSTEM\CurrentControlSet\Services\WbioSrvc'
)) {

    $safe =
        ($path -replace '[\\/:*?"<>| ]','_')

    Run-Command `
        'reg.exe' `
        @(
            'query',
            $path,
            '/s'
        ) `
        (Join-Path $Registry "$safe.txt")
}

# Device Parameters
Run-Command `
    'reg.exe' `
    @(
        'query',
        "$DeviceReg\Device Parameters",
        '/s'
    ) `
    (Join-Path $Registry 'Device-Parameters-full.txt')

# ------------------------------------------------------------
# Event channels relevant to the sensor
# ------------------------------------------------------------

Section 'RELEVANT EVENT CHANNELS'

$channels =
    @(
        'Microsoft-Windows-Biometrics/Operational',
        'Microsoft-Windows-Biometrics/Analytic',
        'Microsoft-Windows-DriverFrameworks-UserMode/Operational',
        'Microsoft-Windows-Kernel-PnP/Configuration'
    )

foreach ($channel in $channels) {

    $safe =
        ($channel -replace '[\\/:*?"<>| ]','_')

    try {

        $evtx =
            Join-Path $Runtime "$safe.evtx"

        & wevtutil.exe epl `
            $channel `
            $evtx 2>&1 |
            Out-String |
            Out-Null

        Add-Line ''
        Add-Line "CHANNEL: $channel"
        Add-Line "EVTX   : $evtx"

        if ($LASTEXITCODE -ne 0) {

            [void]$errors.Add(
                "EVENT EXPORT FAILED: $channel"
            )
        }

    }
    catch {

        [void]$errors.Add(
            "EVENT EXPORT EXCEPTION: $channel"
        )
    }
}

# ------------------------------------------------------------
# Final raw directory manifest
# ------------------------------------------------------------

Section 'FINAL FILE INVENTORY'

try {

    Get-ChildItem `
        $Out `
        -Recurse `
        -File `
        -ErrorAction SilentlyContinue |
        Sort-Object FullName |
        ForEach-Object {

            Add-Line (
                "{0,12} bytes  {1}" -f
                $_.Length,
                $_.FullName
            )
        }

}
catch {

    [void]$errors.Add(
        'FINAL FILE INVENTORY FAILED'
    )
}

# ------------------------------------------------------------
# SHA256 manifest
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

                "{0}  {1}" -f `
                    $h.Hash,
                    $h.Path

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

    [void]$errors.Add(
        'SHA256 MANIFEST FAILED'
    )
}

# ------------------------------------------------------------
# FINAL STATUS
# ------------------------------------------------------------

Section 'FINAL WINDOWS GATE STATUS'

Add-Line "ADMINISTRATOR: $isAdmin"

$requiredOutputs = @(
    (Join-Path $Resources 'FTE4800-resources.txt'),
    (Join-Path $Resources 'FTE4800-stack.txt'),
    (Join-Path $Resources 'FTE4800-properties.txt'),
    (Join-Path $Registry 'LogConf-query.txt'),
    (Join-Path $Registry 'FTE4800-device-query.txt')
)

$missing = @(
    $requiredOutputs |
    Where-Object {
        -not (Test-Path $_)
    }
)

Add-Line "REQUIRED OUTPUT COUNT: $($requiredOutputs.Count)"
Add-Line "MISSING OUTPUT COUNT : $($missing.Count)"

foreach ($m in $missing) {
    Add-Line "MISSING: $m"
}

$acpiBins =
    @(Get-ChildItem `
        $ACPI `
        -Filter '*.bin' `
        -File `
        -ErrorAction SilentlyContinue)

Add-Line "ACPI RAW BINARIES: $($acpiBins.Count)"


# ------------------------------------------------------------
# DRIVER PACKAGE STATUS
# ------------------------------------------------------------

$driverDll1 = Test-Path (
    Join-Path $Driver 'ftWbioUmdfDriverV2.dll'
)

$driverDll2 = Test-Path (
    Join-Path $Driver 'ftWbioEngineAdapter.dll'
)

$driverInf = Test-Path (
    Join-Path $Driver 'ftwbioumdfdriverv2.inf'
)

$driverPackagePresent = $false

if ($driverDll1) {
    if ($driverDll2) {
        if ($driverInf) {
            $driverPackagePresent = $true
        }
    }
}

Add-Line "Driver DLL 1: $driverDll1"
Add-Line "Driver DLL 2: $driverDll2"
Add-Line "Driver INF   : $driverInf"
Add-Line "DRIVER PACKAGE COPIED: $driverPackagePresent"




if (
    $isAdmin -and
    $missing.Count -eq 0 -and
    $driverPackagePresent
) {

    Add-Line ''
    Add-Line 'WINDOWS-GATE-COMPLETE = TRUE'

}
else {

    Add-Line ''
    Add-Line 'WINDOWS-GATE-COMPLETE = FALSE'
}

Add-Line ''
Add-Line 'NEXT PHASE: LINUX STATIC REVERSE ENGINEERING'
Add-Line ''
Add-Line 'Linux targets:'
Add-Line '  PE parsing'
Add-Line '  raw hexadecimal extraction'
Add-Line '  complete .text disassembly'
Add-Line '  .pdata function-boundary recovery'
Add-Line '  string cross-references'
Add-Line '  call graph'
Add-Line '  chip-ID path'
Add-Line '  sensor-family detection'
Add-Line '  SPI framing'
Add-Line '  register read/write'
Add-Line '  SFR protocol'
Add-Line '  GPIO/reset'
Add-Line '  interrupt/event state machine'
Add-Line '  lifecycle/state transitions'
Add-Line '  sleep/wake'
Add-Line '  image acquisition'
Add-Line '  FIFO/image transfer'
Add-Line '  firmware download'
Add-Line '  firmware update'
Add-Line '  packet reconstruction'
Add-Line '  exact sensor dimensions/raw format'
Add-Line '  FT9368/9369/other-family selection'

# ------------------------------------------------------------
# Errors
# ------------------------------------------------------------

Section 'ERRORS'

if ($errors.Count -eq 0) {

    Add-Line 'NONE'

}
else {

    foreach ($e in $errors) {
        Add-Line $e
    }
}

# ------------------------------------------------------------
# Save report
# ------------------------------------------------------------

$finalText = $lines -join "`r`n"

Save-Text $Report $finalText

if ($errors.Count -eq 0) {

    Save-Text `
        $Errors `
        'NONE'

}
else {

    Save-Text `
        $Errors `
        ($errors -join "`r`n")
}

# ------------------------------------------------------------
# AUTOMATIC CLIPBOARD COPY
# ------------------------------------------------------------

$clipboardOK = $false

try {

    Set-Clipboard `
        -Value $finalText

    $clipboardOK = $true

}
catch {

    try {

        $finalText |
            clip.exe

        $clipboardOK = $true

    }
    catch {}
}

# Add clipboard result to report
$clipboardStatus =
    "CLIPBOARD COPIED: $clipboardOK"

try {

    Add-Content `
        -LiteralPath $Report `
        -Value "`r`n$clipboardStatus" `
        -Encoding UTF8

}
catch {}

# ------------------------------------------------------------
# Console
# ------------------------------------------------------------

Write-Host ''
Write-Host '======================================================================'
Write-Host 'FTE4800 FINAL WINDOWS RESOURCE / ACPI GATE'
Write-Host '======================================================================'
Write-Host "OUTPUT       : $Out"
Write-Host "REPORT       : $Report"
Write-Host "ERRORS       : $Errors"
Write-Host "MANIFEST     : $Manifest"
Write-Host "ACPI TABLES  : $($acpiBins.Count)"
Write-Host "DRIVER       : $driverPackagePresent"
Write-Host "ADMIN        : $isAdmin"
Write-Host "CLIPBOARD    : $clipboardOK"
Write-Host '======================================================================'

if ($isAdmin -and $missing.Count -eq 0 -and $driverPackagePresent) {

    Write-Host ''
    Write-Host 'WINDOWS-GATE-COMPLETE = TRUE'
    Write-Host ''
    Write-Host 'Windows-specific evidence collection is finished.'
    Write-Host 'The next stage can be performed entirely on Linux.'

}
else {

    Write-Host ''
    Write-Host 'WINDOWS-GATE-COMPLETE = FALSE'
    Write-Host 'Inspect the report and ERRORS.txt before leaving Windows.'
}

Write-Host ''
Write-Host 'FINAL REPORT COPIED TO CLIPBOARD.'
Write-Host 'Paste it into ChatGPT.'
Write-Host '======================================================================'
