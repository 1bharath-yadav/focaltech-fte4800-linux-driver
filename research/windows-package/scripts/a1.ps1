# =====================================================================
# FTE4800 COMPLETE WINDOWS FORENSICS / DRIVER RESEARCH COLLECTOR
# Infinix ZERO BOOK / FocalTech FTE4800
#
# RUN:
#   Open PowerShell AS ADMINISTRATOR
#   Paste this entire script
#
# OUTPUT:
#   C:\FTE4800-RESEARCH\<timestamp>\
#
# CLIPBOARD:
#   Automatically populated at the end with the consolidated report.
# =====================================================================

$ErrorActionPreference = "Continue"

# ---------------------------------------------------------------------
# CONFIGURATION
# ---------------------------------------------------------------------

$STAMP = Get-Date -Format "yyyyMMdd-HHmmss"
$ROOT = "C:\FTE4800-RESEARCH\$STAMP"

$DEVICE_ID = "ACPI\FTE4800\4&f064bb&0"
$DEVICE_HWID = "ACPI\FTE4800"
$PARENT_SPI = "PCI\VEN_8086&DEV_51FB&SUBSYS_00000000&REV_01\3&11583659&0&96"

$OLD_RESEARCH = "C:\Users\$env:USERNAME\fp-re"
$OLD_RESEARCH2 = "C:\FTE4800-Linux-Driver-Research"

# ---------------------------------------------------------------------
# ADMIN CHECK
# ---------------------------------------------------------------------

$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)
$IS_ADMIN = $principal.IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)

if (-not $IS_ADMIN) {
    Write-Host ""
    Write-Host "ERROR: PowerShell is NOT running as Administrator." -ForegroundColor Red
    Write-Host "Close this window, open PowerShell as Administrator, and paste again."
    exit 1
}

# ---------------------------------------------------------------------
# DIRECTORIES
# ---------------------------------------------------------------------

$DIRS = @(
    "$ROOT",
    "$ROOT\00-summary",
    "$ROOT\01-device",
    "$ROOT\02-spi-controller",
    "$ROOT\03-driver-package",
    "$ROOT\04-driver-store",
    "$ROOT\05-registry",
    "$ROOT\06-acpi",
    "$ROOT\07-pe-analysis",
    "$ROOT\08-strings",
    "$ROOT\09-setupapi",
    "$ROOT\10-events",
    "$ROOT\11-services",
    "$ROOT\12-system",
    "$ROOT\13-runtime",
    "$ROOT\14-existing-research",
    "$ROOT\15-hashes"
)

foreach ($d in $DIRS) {
    New-Item -ItemType Directory -Force -Path $d | Out-Null
}

# ---------------------------------------------------------------------
# LOGGING
# ---------------------------------------------------------------------

$TRANSCRIPT = "$ROOT\00-summary\collector-transcript.txt"

try {
    Start-Transcript -Path $TRANSCRIPT -Force | Out-Null
} catch {}

function Save-Text {
    param(
        [string]$Path,
        [scriptblock]$Command
    )

    try {
        & $Command 2>&1 |
            Out-File -FilePath $Path -Encoding UTF8 -Width 8192
    }
    catch {
        "ERROR: $($_.Exception.Message)" |
            Out-File $Path -Encoding UTF8
    }
}

function Save-Command {
    param(
        [string]$Path,
        [string]$Command
    )

    try {
        cmd.exe /c $Command 2>&1 |
            Out-File -FilePath $Path -Encoding UTF8 -Width 8192
    }
    catch {
        "ERROR: $($_.Exception.Message)" |
            Out-File $Path -Encoding UTF8
    }
}

function Safe-Copy {
    param(
        [string]$Source,
        [string]$Destination
    )

    try {
        if (Test-Path $Source) {
            Copy-Item $Source $Destination -Force -ErrorAction Stop
            return $true
        }
    }
    catch {
        Write-Host "COPY FAILED: $Source -> $Destination" -ForegroundColor Yellow
    }

    return $false
}

# ---------------------------------------------------------------------
# SYSTEM IDENTITY
# ---------------------------------------------------------------------

Write-Host ""
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host " FTE4800 WINDOWS DRIVER RESEARCH COLLECTION" -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host "Output: $ROOT"
Write-Host ""

Save-Text "$ROOT\12-system\computerinfo.txt" {
    Get-ComputerInfo
}

Save-Text "$ROOT\12-system\computer-system.txt" {
    Get-CimInstance Win32_ComputerSystem | Format-List *
}

Save-Text "$ROOT\12-system\bios.txt" {
    Get-CimInstance Win32_BIOS | Format-List *
}

Save-Text "$ROOT\12-system\baseboard.txt" {
    Get-CimInstance Win32_BaseBoard | Format-List *
}

Save-Text "$ROOT\12-system\cpu.txt" {
    Get-CimInstance Win32_Processor | Format-List *
}

Save-Text "$ROOT\12-system\windows.txt" {
    Get-CimInstance Win32_OperatingSystem | Format-List *
}

Save-Text "$ROOT\12-system\whoami.txt" {
    whoami
    whoami /all
}

# ---------------------------------------------------------------------
# EXACT FINGERPRINT DEVICE
# ---------------------------------------------------------------------

Write-Host "[1/18] Collecting FTE4800 device..." -ForegroundColor Green

Save-Text "$ROOT\01-device\device.txt" {
    Get-PnpDevice -InstanceId $DEVICE_ID
}

Save-Text "$ROOT\01-device\device-properties.txt" {
    Get-PnpDeviceProperty -InstanceId $DEVICE_ID |
        Format-List *
}

Save-Command "$ROOT\01-device\pnputil-device.txt" `
    "pnputil /enum-devices /instanceid `"$DEVICE_ID`" /deviceids /services /stack /drivers /interfaces /properties /resources"

Save-Command "$ROOT\01-device\hardware-ids.txt" `
    "pnputil /enum-devices /instanceid `"$DEVICE_ID`" /deviceids"

Save-Command "$ROOT\01-device\resources.txt" `
    "pnputil /enum-devices /instanceid `"$DEVICE_ID`" /resources /properties"

Save-Command "$ROOT\01-device\interfaces.txt" `
    "pnputil /enum-devices /instanceid `"$DEVICE_ID`" /interfaces"

Save-Text "$ROOT\01-device\signed-driver.txt" {
    Get-CimInstance Win32_PnPSignedDriver |
        Where-Object {
            $_.DeviceID -eq $DEVICE_ID -or
            $_.PNPDeviceID -eq $DEVICE_ID -or
            $_.DeviceName -match "FocalTech"
        } |
        Format-List *
}

# ---------------------------------------------------------------------
# ALL RELATED DEVICES
# ---------------------------------------------------------------------

Save-Text "$ROOT\01-device\related-devices.txt" {
    Get-PnpDevice |
        Where-Object {
            "$($_.FriendlyName) $($_.InstanceId) $($_.Class)" `
                -match "Focal|Fingerprint|Biometric|SPI|FTE4800|FPNT"
        } |
        Format-List *
}

Save-Text "$ROOT\01-device\device-table.txt" {
    Get-PnpDevice |
        Where-Object {
            "$($_.FriendlyName) $($_.InstanceId) $($_.Class)" `
                -match "Focal|Fingerprint|Biometric|SPI|FTE4800|FPNT"
        } |
        Format-Table Status,Class,FriendlyName,InstanceId -AutoSize
}

# ---------------------------------------------------------------------
# PARENT INTEL SPI CONTROLLER
# ---------------------------------------------------------------------

Write-Host "[2/18] Collecting Intel SPI controller..." -ForegroundColor Green

Save-Text "$ROOT\02-spi-controller\properties.txt" {
    Get-PnpDeviceProperty -InstanceId $PARENT_SPI |
        Format-List *
}

Save-Command "$ROOT\02-spi-controller\pnputil.txt" `
    "pnputil /enum-devices /instanceid `"$PARENT_SPI`" /deviceids /services /stack /drivers /interfaces /properties /resources"

Save-Text "$ROOT\02-spi-controller\device.txt" {
    Get-PnpDevice -InstanceId $PARENT_SPI
}

Save-Text "$ROOT\02-spi-controller\related-spi-devices.txt" {
    Get-PnpDevice |
        Where-Object {
            "$($_.FriendlyName) $($_.InstanceId)" -match "SPI|Serial IO"
        } |
        Format-Table Status,Class,FriendlyName,InstanceId -AutoSize
}

Save-Command "$ROOT\02-spi-controller\all-spi.txt" `
    "pnputil /enum-devices /connected /deviceids /services /stack /drivers /properties /resources"

# ---------------------------------------------------------------------
# DRIVER STORE
# ---------------------------------------------------------------------

Write-Host "[3/18] Exporting driver package..." -ForegroundColor Green

Save-Command "$ROOT\03-driver-package\pnputil-export.txt" `
    "pnputil /export-driver oem37.inf `"$ROOT\03-driver-package`""

Save-Command "$ROOT\03-driver-package\driver-store-files.txt" `
    "pnputil /enum-drivers /files"

Save-Command "$ROOT\03-driver-package\driver-store-focaltech.txt" `
    "pnputil /enum-drivers /files"

Save-Command "$ROOT\03-driver-package\dism-drivers.txt" `
    "dism /online /get-drivers /format:table"

# ---------------------------------------------------------------------
# SEARCH DRIVER STORE FOR EXACT BINARIES
# ---------------------------------------------------------------------

Write-Host "[4/18] Finding installed FocalTech files..." -ForegroundColor Green

$SYSTEM32 = "$env:WINDIR\System32"

foreach ($name in @(
    "ftWbioUmdfDriverV2.dll",
    "ftWbioEngineAdapter.dll",
    "ftWbioUmdfDriverV2.cat",
    "ftwbioumdfdriverv2.inf"
)) {

    Save-Text "$ROOT\04-driver-store\search-$name.txt" {

        Get-ChildItem `
            "$env:WINDIR\System32" `
            -Recurse `
            -File `
            -Filter $name `
            -ErrorAction SilentlyContinue |
            Select-Object FullName,Length,LastWriteTime
    }
}

Save-Text "$ROOT\04-driver-store\driver-store-focaltech-files.txt" {

    Get-ChildItem `
        "$env:WINDIR\System32\DriverStore\FileRepository" `
        -Recurse `
        -File `
        -ErrorAction SilentlyContinue |
        Where-Object {
            $_.Name -match "ftWbio|ftwbioumdf|focaltech|Focal"
        } |
        Select-Object FullName,Name,Length,LastWriteTime
}

# ---------------------------------------------------------------------
# DRIVER PACKAGE INVENTORY
# ---------------------------------------------------------------------

Write-Host "[5/18] Inventorying package..." -ForegroundColor Green

Get-ChildItem "$ROOT\03-driver-package" -Recurse -File |
    Select-Object FullName,Name,Extension,Length,LastWriteTime |
    Export-Csv "$ROOT\03-driver-package\inventory.csv" -NoTypeInformation

Get-ChildItem "$ROOT\03-driver-package" -Recurse -File |
    Format-Table FullName,Length,Extension -AutoSize |
    Out-File "$ROOT\03-driver-package\inventory.txt" -Encoding UTF8 -Width 8192

# Locate actual DLLs
$DLLS = Get-ChildItem "$ROOT\03-driver-package" -Recurse -Filter "*.dll" -File

foreach ($dll in $DLLS) {

    $base = $dll.BaseName

    Save-Text "$ROOT\03-driver-package\$base-fileversion.txt" {
        [System.Diagnostics.FileVersionInfo]::GetVersionInfo($dll.FullName) |
            Format-List *
    }

    try {
        Get-AuthenticodeSignature $dll.FullName |
            Format-List * |
            Out-File "$ROOT\03-driver-package\$base-signature.txt" `
                -Encoding UTF8 -Width 8192
    } catch {}
}

# ---------------------------------------------------------------------
# INF ANALYSIS
# ---------------------------------------------------------------------

Write-Host "[6/18] Analysing INF..." -ForegroundColor Green

$INF = Get-ChildItem `
    "$ROOT\03-driver-package" `
    -Recurse `
    -Filter "*.inf" `
    -File |
    Select-Object -First 1

if ($INF) {

    Copy-Item $INF.FullName `
        "$ROOT\03-driver-package\ORIGINAL-INF.txt" `
        -Force

    Save-Text "$ROOT\03-driver-package\INF-SPI-ANALYSIS.txt" {

        Get-Content $INF.FullName |
            Select-String `
                -Pattern `
                "FTE4800",
                "FTE",
                "SPI",
                "SPB",
                "GPIO",
                "Umdf",
                "UmdfService",
                "UmdfDirectHardwareAccess",
                "ServiceBinary",
                "DriverPlugIn",
                "WinBio",
                "DatabaseId",
                "focalFp",
                "Firmware",
                "FW",
                "FT93",
                "FW93",
                "FW95" `
                -Context 5,15
    }
}

# ---------------------------------------------------------------------
# REGISTRY
# ---------------------------------------------------------------------

Write-Host "[7/18] Collecting registry..." -ForegroundColor Green

Save-Command "$ROOT\05-registry\fte4800-device.txt" `
    "reg.exe query `"HKLM\SYSTEM\CurrentControlSet\Enum\ACPI\FTE4800\4&f064bb&0`" /s"

Save-Command "$ROOT\05-registry\focalFp.txt" `
    "reg.exe query `"HKLM\SYSTEM\CurrentControlSet\Control\focalFp`" /s"

Save-Command "$ROOT\05-registry\wudfrd.txt" `
    "reg.exe query `"HKLM\SYSTEM\CurrentControlSet\Services\WUDFRd`" /s"

Save-Command "$ROOT\05-registry\wbiosrvc.txt" `
    "reg.exe query `"HKLM\SYSTEM\CurrentControlSet\Services\WbioSrvc`" /s"

Save-Command "$ROOT\05-registry\FTE4800-device-parameters.txt" `
    "reg.exe query `"HKLM\SYSTEM\CurrentControlSet\Enum\ACPI\FTE4800\4&f064bb&0\Device Parameters`" /s"

Save-Command "$ROOT\05-registry\FTE4800-properties.txt" `
    "reg.exe query `"HKLM\SYSTEM\CurrentControlSet\Enum\ACPI\FTE4800\4&f064bb&0\Properties`" /s"

Save-Command "$ROOT\05-registry\wdf.txt" `
    "reg.exe query `"HKLM\SYSTEM\CurrentControlSet\Enum\ACPI\FTE4800\4&f064bb&0`" /v DeviceInterfaceGUIDs"

# ---------------------------------------------------------------------
# ACPI FIRMWARE TABLE DUMP
# ---------------------------------------------------------------------

Write-Host "[8/18] Dumping raw ACPI firmware tables..." -ForegroundColor Green

$ACPI_CS = @"
using System;
using System.Runtime.InteropServices;

public static class FirmwareTables
{
    [DllImport("kernel32.dll", SetLastError=true)]
    public static extern uint EnumSystemFirmwareTables(
        uint FirmwareTableProviderSignature,
        IntPtr pFirmwareTableBuffer,
        uint BufferSize);

    [DllImport("kernel32.dll", SetLastError=true)]
    public static extern uint GetSystemFirmwareTable(
        uint FirmwareTableProviderSignature,
        uint FirmwareTableID,
        IntPtr pFirmwareTableBuffer,
        uint BufferSize);

    public const uint ACPI = 0x41435049;
    public const uint RSMB = 0x52534D42;
}
"@

try {
    Add-Type -TypeDefinition $ACPI_CS -ErrorAction Stop
} catch {}

function Get-FirmwareTables {
    param(
        [uint32]$Provider,
        [string]$ProviderName
    )

    try {

        $size = [FirmwareTables]::EnumSystemFirmwareTables(
            $Provider,
            [IntPtr]::Zero,
            0
        )

        if ($size -eq 0) {
            return
        }

        $ptr = [Runtime.InteropServices.Marshal]::AllocHGlobal(
            [int]$size
        )

        try {

            $actual = [FirmwareTables]::EnumSystemFirmwareTables(
                $Provider,
                $ptr,
                $size
            )

            $bytes = New-Object byte[] $actual

            [Runtime.InteropServices.Marshal]::Copy(
                $ptr,
                $bytes,
                0,
                [int]$actual
            )

            for ($i = 0; $i -lt $bytes.Length; $i += 4) {

                if (($i + 3) -ge $bytes.Length) {
                    break
                }

                $idBytes = $bytes[$i..($i + 3)]

                $id = [Text.Encoding]::ASCII.GetString($idBytes)

                $idValue = `
                    ([uint32]$idBytes[0]) `
                    -bor (([uint32]$idBytes[1]) -shl 8) `
                    -bor (([uint32]$idBytes[2]) -shl 16) `
                    -bor (([uint32]$idBytes[3]) -shl 24)

                $tableSize = [FirmwareTables]::GetSystemFirmwareTable(
                    $Provider,
                    $idValue,
                    [IntPtr]::Zero,
                    0
                )

                if ($tableSize -eq 0) {
                    continue
                }

                $tablePtr = [Runtime.InteropServices.Marshal]::AllocHGlobal(
                    [int]$tableSize
                )

                try {

                    $got = [FirmwareTables]::GetSystemFirmwareTable(
                        $Provider,
                        $idValue,
                        $tablePtr,
                        $tableSize
                    )

                    $tableBytes = New-Object byte[] $got

                    [Runtime.InteropServices.Marshal]::Copy(
                        $tablePtr,
                        $tableBytes,
                        0,
                        [int]$got
                    )

                    $safeId = $id -replace '[^A-Za-z0-9_.-]', '_'

                    $binPath = `
                        "$ROOT\06-acpi\$ProviderName-$safeId.bin"

                    [IO.File]::WriteAllBytes(
                        $binPath,
                        $tableBytes
                    )

                    # Printable ASCII
                    $ascii = [Text.StringBuilder]::new()

                    foreach ($b in $tableBytes) {

                        if ($b -ge 32 -and $b -le 126) {
                            [void]$ascii.Append([char]$b)
                        }
                        else {
                            [void]$ascii.Append(" ")
                        }
                    }

                    $ascii.ToString() |
                        Out-File `
                            "$ROOT\06-acpi\$ProviderName-$safeId-ascii.txt" `
                            -Encoding UTF8

                    # UTF-16-ish printable strings
                    $utf16 = [Text.Encoding]::Unicode.GetString($tableBytes)

                    $utf16 |
                        Select-String `
                            -Pattern "[A-Za-z0-9_\\().:-]{5,}" `
                            -AllMatches |
                        ForEach-Object { $_.Matches.Value } |
                        Sort-Object -Unique |
                        Out-File `
                            "$ROOT\06-acpi\$ProviderName-$safeId-utf16.txt" `
                            -Encoding UTF8
                }
                finally {
                    [Runtime.InteropServices.Marshal]::FreeHGlobal($tablePtr)
                }
            }
        }
        finally {
            [Runtime.InteropServices.Marshal]::FreeHGlobal($ptr)
        }
    }
    catch {
        "ACPI enumeration error: $($_.Exception.Message)" |
            Out-File "$ROOT\06-acpi\ERROR.txt" -Encoding UTF8
    }
}

Get-FirmwareTables `
    -Provider ([FirmwareTables]::ACPI) `
    -ProviderName "ACPI"

# Also collect SMBIOS
Get-FirmwareTables `
    -Provider ([FirmwareTables]::RSMB) `
    -ProviderName "SMBIOS"

# ---------------------------------------------------------------------
# SEARCH ACPI TABLES FOR FINGERPRINT / SPI INFORMATION
# ---------------------------------------------------------------------

Save-Text "$ROOT\06-acpi\fingerprint-acpi-search.txt" {

    Get-ChildItem "$ROOT\06-acpi" -File |
        Select-String `
            -Pattern `
            "FTE4800",
            "FTE",
            "FPNT",
            "SPI2",
            "SPI0",
            "SPI",
            "GFPI",
            "GFPS",
            "INTC1055",
            "9368",
            "9369",
            "FT9368",
            "FT9369",
            "GPIO" `
            -Context 8,20 `
            -ErrorAction SilentlyContinue
}

# ---------------------------------------------------------------------
# SETUPAPI
# ---------------------------------------------------------------------

Write-Host "[9/18] Searching SetupAPI..." -ForegroundColor Green

Save-Text "$ROOT\09-setupapi\FTE4800-detailed.txt" {

    Select-String `
        "C:\Windows\INF\setupapi.dev.log" `
        -Pattern `
        "FTE4800",
        "FocalTech",
        "ftWbioUmdfDriverV2",
        "ftWbioEngineAdapter",
        "ftwbioumdfdriverv2.inf",
        "oem37.inf",
        "SPIdevice_Install",
        "AllowDirectHardwareAccess" `
        -Context 40,80
}

Safe-Copy `
    "C:\Windows\INF\setupapi.dev.log" `
    "$ROOT\09-setupapi\setupapi.dev.log"

# ---------------------------------------------------------------------
# EVENT LOGS
# ---------------------------------------------------------------------

Write-Host "[10/18] Collecting runtime events..." -ForegroundColor Green

Save-Command "$ROOT\10-events\event-log-names.txt" `
    "wevtutil el"

$EVENTS = @(
    "Microsoft-Windows-Biometrics/Operational",
    "Microsoft-Windows-UserPnp/DeviceInstall",
    "Microsoft-Windows-DriverFrameworks-UserMode/Operational",
    "Microsoft-Windows-DriverFrameworks-KernelMode/Operational"
)

foreach ($log in $EVENTS) {

    $safe = $log -replace '[\\/:*?"<>|]', '_'

    Save-Text "$ROOT\10-events\$safe.txt" {

        Get-WinEvent `
            -LogName $log `
            -MaxEvents 500 `
            -ErrorAction SilentlyContinue |
            Select-Object TimeCreated,
                          Id,
                          LevelDisplayName,
                          ProviderName,
                          Message |
            Format-List *
    }
}

# ---------------------------------------------------------------------
# SERVICES / PROCESSES
# ---------------------------------------------------------------------

Write-Host "[11/18] Collecting services and processes..." -ForegroundColor Green

Save-Text "$ROOT\11-services\related-services.txt" {

    Get-Service |
        Where-Object {
            $_.Name -match `
                "bio|finger|focal|wudf|winbio" `
            -or
            $_.DisplayName -match `
                "bio|finger|focal|wudf|winbio"
        } |
        Format-List *
}

Save-Text "$ROOT\11-services\wudf-processes.txt" {

    Get-Process |
        Where-Object {
            $_.ProcessName -match "WUDF|Bio|WinBio|Wbio"
        } |
        Select-Object Id,ProcessName,Path,StartTime |
        Format-List *
}

Save-Command "$ROOT\11-services\wudf-driver.txt" `
    "sc.exe qc WUDFRd"

Save-Command "$ROOT\11-services\wbiosrvc.txt" `
    "sc.exe qc WbioSrvc"

# ---------------------------------------------------------------------
# DRIVER BINARY SEARCH
# ---------------------------------------------------------------------

Write-Host "[12/18] Finding installed binaries..." -ForegroundColor Green

$EXACT_FILES = @(
    "ftWbioUmdfDriverV2.dll",
    "ftWbioEngineAdapter.dll",
    "ftWbioUmdfDriverV2.cat"
)

foreach ($name in $EXACT_FILES) {

    Get-ChildItem `
        "$env:WINDIR\System32" `
        -Recurse `
        -File `
        -Filter $name `
        -ErrorAction SilentlyContinue |
        Select-Object FullName,Length,LastWriteTime |
        Out-File `
            "$ROOT\13-runtime\installed-$name.txt" `
            -Encoding UTF8 `
            -Width 8192
}

# ---------------------------------------------------------------------
# STRINGS
# ---------------------------------------------------------------------

Write-Host "[13/18] Extracting ASCII / UTF16 strings..." -ForegroundColor Green

$STRINGSEXES = @(
    "C:\MinGW\bin\strings.exe",
    "$env:USERPROFILE\scoop\shims\strings.exe",
    "C:\Program Files\Git\usr\bin\strings.exe"
)

$STRINGS = $null

foreach ($candidate in $STRINGSEXES) {
    if (Test-Path $candidate) {
        $STRINGS = $candidate
        break
    }
}

if (-not $STRINGS) {
    $found = Get-Command strings.exe -ErrorAction SilentlyContinue
    if ($found) {
        $STRINGS = $found.Source
    }
}

$packageDLLs = Get-ChildItem `
    "$ROOT\03-driver-package" `
    -Recurse `
    -Filter "*.dll" `
    -File

foreach ($dll in $packageDLLs) {

    $base = $dll.BaseName

    if ($STRINGS) {

        & $STRINGS -n 5 "$($dll.FullName)" |
            Out-File `
                "$ROOT\08-strings\$base-ascii.txt" `
                -Encoding UTF8 `
                -Width 8192

        & $STRINGS -el -n 5 "$($dll.FullName)" |
            Out-File `
                "$ROOT\08-strings\$base-utf16.txt" `
                -Encoding UTF8 `
                -Width 8192
    }
    else {

        "GNU strings.exe was not found." |
            Out-File `
                "$ROOT\08-strings\$base-NO-STRINGS-TOOL.txt"
    }
}

# ---------------------------------------------------------------------
# PYTHON PE PARSER
# ---------------------------------------------------------------------

Write-Host "[14/18] Parsing PE headers/imports/exports/PDB..." -ForegroundColor Green

$PY = $null

$pythonCandidates = @(
    "py",
    "python",
    "python3"
)

foreach ($c in $pythonCandidates) {

    if (Get-Command $c -ErrorAction SilentlyContinue) {
        $PY = $c
        break
    }
}

$PE_SCRIPT = "$ROOT\07-pe-analysis\pe_analyzer.py"

@'
import sys
import struct
from pathlib import Path

def u16(b,o):
    return struct.unpack_from("<H",b,o)[0]

def u32(b,o):
    return struct.unpack_from("<I",b,o)[0]

def u64(b,o):
    return struct.unpack_from("<Q",b,o)[0]

def cstr(b,o):
    if o < 0 or o >= len(b):
        return ""
    end = b.find(b"\0",o)
    if end < 0:
        end = len(b)
    return b[o:end].decode("utf-8","replace")

def align(x,a):
    return (x+a-1)//a*a

def parse(path):
    data = Path(path).read_bytes()

    print("="*80)
    print(path)
    print("="*80)
    print("FILE_SIZE:", len(data))

    if data[:2] != b"MZ":
        print("NOT A PE FILE")
        return

    peoff = u32(data,0x3c)
    print("PE_OFFSET:",hex(peoff))

    if data[peoff:peoff+4] != b"PE\0\0":
        print("BAD PE SIGNATURE")
        return

    coff = peoff + 4

    machine = u16(data,coff)
    sections = u16(data,coff+2)
    timestamp = u32(data,coff+4)
    optsize = u16(data,coff+16)

    print("MACHINE:",hex(machine))
    print("SECTIONS:",sections)
    print("TIMESTAMP:",timestamp)
    print("TIMESTAMP_HEX:",hex(timestamp))

    opt = coff + 20
    magic = u16(data,opt)

    is64 = magic == 0x20b
    print("OPTIONAL_HEADER_MAGIC:",hex(magic))
    print("PE32_PLUS:",is64)

    if is64:
        entry = u32(data,opt+16)
        imagebase = u64(data,opt+24)
        num_dirs = u32(data,opt+108)
        dirs = opt + 112
    else:
        entry = u32(data,opt+16)
        imagebase = u32(data,opt+28)
        num_dirs = u32(data,opt+92)
        dirs = opt + 96

    print("ENTRY_RVA:",hex(entry))
    print("IMAGE_BASE:",hex(imagebase))
    print("DIRECTORIES:",num_dirs)

    secbase = opt + optsize
    secs=[]

    for i in range(sections):
        o = secbase + i*40
        name = data[o:o+8].split(b"\0")[0].decode("ascii","replace")
        vsize = u32(data,o+8)
        rva = u32(data,o+12)
        rawsize = u32(data,o+16)
        rawptr = u32(data,o+20)

        secs.append((rva,vsize,rawsize,rawptr,name))

        print(
            "SECTION",
            i,
            name,
            "RVA",hex(rva),
            "VSIZE",hex(vsize),
            "RAWPTR",hex(rawptr),
            "RAWSIZE",hex(rawsize)
        )

    def rva_to_offset(rva):
        for srva,vsize,rawsize,rawptr,name in secs:
            maxsize=max(vsize,rawsize)
            if srva <= rva < srva+maxsize:
                return rawptr + (rva-srva)
        return None

    def directory(i):
        if i >= num_dirs:
            return (0,0)
        o=dirs+i*8
        return (u32(data,o),u32(data,o+4))

    # EXPORT
    erva,esize=directory(0)

    print("\n[EXPORTS]")
    print("RVA:",hex(erva),"SIZE:",hex(esize))

    if erva:
        off=rva_to_offset(erva)
        if off:
            ordinal_base=u32(data,off+16)
            nfunc=u32(data,off+20)
            nname=u32(data,off+24)
            funcs_rva=u32(data,off+28)
            names_rva=u32(data,off+32)
            ords_rva=u32(data,off+36)

            print("ORDINAL_BASE:",ordinal_base)
            print("FUNCTION_COUNT:",nfunc)
            print("NAME_COUNT:",nname)

            noff=rva_to_offset(names_rva)
            ooff=rva_to_offset(ords_rva)
            foff=rva_to_offset(funcs_rva)

            if noff and ooff and foff:
                for i in range(nname):
                    nrva=u32(data,noff+i*4)
                    nn=rva_to_offset(nrva)

                    if nn is None:
                        continue

                    nm=cstr(data,nn)
                    ordidx=u16(data,ooff+i*2)

                    if ordidx < nfunc:
                        frva=u32(data,foff+ordidx*4)
                    else:
                        frva=0

                    print(nm, "RVA",hex(frva))

    # IMPORTS
    irva,isize=directory(1)

    print("\n[IMPORTS]")
    print("RVA:",hex(irva),"SIZE:",hex(isize))

    if irva:
        off=rva_to_offset(irva)

        if off:
            desc_size=20
            index=0

            while True:
                d=off+index*desc_size

                if d+20 > len(data):
                    break

                oft=u32(data,d)
                name_rva=u32(data,d+12)
                ft=u32(data,d+16)

                if oft==0 and name_rva==0 and ft==0:
                    break

                no=rva_to_offset(name_rva)
                if no is None:
                    index+=1
                    continue

                dll=cstr(data,no)
                print("DLL:",dll)

                thunk_rva=oft or ft
                toff=rva_to_offset(thunk_rva)

                if toff:
                    step=8 if is64 else 4
                    j=0

                    while True:
                        qoff=toff+j*step

                        if qoff+step > len(data):
                            break

                        val=u64(data,qoff) if is64 else u32(data,qoff)

                        if val==0:
                            break

                        ordinal_mask = 0x8000000000000000 if is64 else 0x80000000

                        if val & ordinal_mask:
                            print("  ORDINAL",hex(val & 0xffff))
                        else:
                            hintname_off=rva_to_offset(val)
                            if hintname_off is not None:
                                hint=u16(data,hintname_off)
                                name=cstr(data,hintname_off+2)
                                print("  ",name,"HINT",hint)

                        j+=1

                index+=1

    # DEBUG DIRECTORY
    drva,dsize=directory(6)

    print("\n[DEBUG_DIRECTORY]")
    print("RVA:",hex(drva),"SIZE:",hex(dsize))

    if drva:
        off=rva_to_offset(drva)

        if off:
            for i in range(0,dsize,28):

                d=off+i
                if d+28 > len(data):
                    break

                chars=u32(data,d)
                stamp=u32(data,d+4)
                major=u16(data,d+8)
                minor=u16(data,d+10)
                dtype=u32(data,d+12)
                size=u32(data,d+16)
                addr=u32(data,d+20)
                rawptr=u32(data,d+24)

                print(
                    "TYPE",hex(dtype),
                    "SIZE",hex(size),
                    "ADDR",hex(addr),
                    "RAWPTR",hex(rawptr)
                )

                if dtype == 2 and rawptr and rawptr+size <= len(data):
                    blob=data[rawptr:rawptr+size]

                    if blob[:4] == b"RSDS" and len(blob)>=24:
                        guid=blob[4:20]
                        age=u32(blob,20)
                        pdb=blob[24:].split(b"\0")[0].decode(
                            "utf-8","replace"
                        )

                        print("RSDS_GUID:",guid.hex())
                        print("PDB_AGE:",age)
                        print("PDB_PATH:",pdb)

    # TLS / RESOURCE / RELOC / etc summary
    print("\n[DIRECTORIES]")
    names=[
        "EXPORT","IMPORT","RESOURCE","EXCEPTION",
        "SECURITY","BASERELOC","DEBUG","ARCHITECTURE",
        "GLOBALPTR","TLS","LOAD_CONFIG","BOUND_IMPORT",
        "IAT","DELAY_IMPORT","CLR"
    ]

    for i,name in enumerate(names):
        if i >= num_dirs:
            break
        r,s=directory(i)
        print(name,hex(r),hex(s))

for p in sys.argv[1:]:
    try:
        parse(p)
    except Exception as e:
        print("ERROR:",p,e)
'@ | Set-Content -Path $PE_SCRIPT -Encoding UTF8

if ($PY) {

    foreach ($dll in $packageDLLs) {

        $out = "$ROOT\07-pe-analysis\$($dll.BaseName)-PE.txt"

        try {
            & $PY $PE_SCRIPT "$($dll.FullName)" |
                Out-File $out -Encoding UTF8 -Width 8192
        }
        catch {
            "PE parser error: $($_.Exception.Message)" |
                Out-File $out -Encoding UTF8
        }
    }
}
else {

    "Python was not available. PE parser was not executed." |
        Out-File `
            "$ROOT\07-pe-analysis\PYTHON-NOT-FOUND.txt" `
            -Encoding UTF8
}

# ---------------------------------------------------------------------
# TARGETED STRING SEARCH
# ---------------------------------------------------------------------

Write-Host "[15/18] Searching binaries for hardware protocol clues..." -ForegroundColor Green

$PATTERNS = @(
    "focal_",
    "SPI",
    "SPB",
    "GPIO",
    "ACPI",
    "FTE4800",
    "FT9338",
    "FT9348",
    "FT9361",
    "FT9368",
    "FT9369",
    "FT9536",
    "FW9368",
    "FW9369",
    "FW9371",
    "FW9536",
    "FW9362",
    "FW9391",
    "95A8",
    "register",
    "sensor",
    "chip",
    "firmware",
    "pramboot",
    "reset",
    "interrupt",
    "irq",
    "wake",
    "sleep",
    "deep sleep",
    "idle",
    "image",
    "frame",
    "fifo",
    "read",
    "write",
    "DeviceIoControl",
    "CreateFile",
    "ReadFile",
    "WriteFile",
    "Wdf",
    "WUDF",
    "SPB"
)

foreach ($txt in Get-ChildItem "$ROOT\08-strings" -Filter "*.txt" -File) {

    $target = `
        "$ROOT\08-strings\$($txt.BaseName)-HARDWARE-FOCUSED.txt"

    Get-Content $txt.FullName |
        Select-String -Pattern $PATTERNS |
        Sort-Object LineNumber |
        Out-File $target -Encoding UTF8 -Width 8192
}

# ---------------------------------------------------------------------
# PDB SEARCH
# ---------------------------------------------------------------------

Write-Host "[16/18] Searching for PDB files..." -ForegroundColor Green

Save-Text "$ROOT\07-pe-analysis\PDB-files-found.txt" {

    Get-ChildItem `
        C:\ `
        -Recurse `
        -Include "*.pdb","*.dbg" `
        -File `
        -ErrorAction SilentlyContinue |
        Where-Object {
            $_.Name -match "ftWbio|focal"
        } |
        Select-Object FullName,Length,LastWriteTime
}

# ---------------------------------------------------------------------
# FULL FILE HASHES
# ---------------------------------------------------------------------

Write-Host "[17/18] Hashing research artifacts..." -ForegroundColor Green

Get-ChildItem "$ROOT" -Recurse -File |
    Get-FileHash -Algorithm SHA256 |
    Export-Csv "$ROOT\15-hashes\SHA256.csv" `
        -NoTypeInformation

Get-ChildItem "$ROOT" -Recurse -File |
    Select-Object FullName,Length,LastWriteTime |
    Export-Csv "$ROOT\15-hashes\FILE-INVENTORY.csv" `
        -NoTypeInformation

# ---------------------------------------------------------------------
# PRESERVE PRIOR RESEARCH
# ---------------------------------------------------------------------

Write-Host "[18/18] Preserving previous research..." -ForegroundColor Green

if (Test-Path $OLD_RESEARCH) {

    Copy-Item `
        $OLD_RESEARCH `
        "$ROOT\14-existing-research\fp-re" `
        -Recurse `
        -Force `
        -ErrorAction SilentlyContinue
}

if (Test-Path $OLD_RESEARCH2) {

    Copy-Item `
        $OLD_RESEARCH2 `
        "$ROOT\14-existing-research\previous-FTE4800-research" `
        -Recurse `
        -Force `
        -ErrorAction SilentlyContinue
}

# ---------------------------------------------------------------------
# COLLECT EXISTING DRIVER PACKAGE FROM PREVIOUS LOCATION
# ---------------------------------------------------------------------

if (Test-Path $OLD_RESEARCH2) {

    $oldPackage = "$OLD_RESEARCH2\package"

    if (Test-Path $oldPackage) {

        New-Item `
            -ItemType Directory `
            -Force `
            -Path "$ROOT\14-existing-research\previous-package" |
            Out-Null

        Copy-Item `
            "$oldPackage\*" `
            "$ROOT\14-existing-research\previous-package" `
            -Recurse `
            -Force `
            -ErrorAction SilentlyContinue
    }
}

# ---------------------------------------------------------------------
# GENERATE TARGETED MASTER DATA
# ---------------------------------------------------------------------

$MASTER = "$ROOT\00-summary\FTE4800-MASTER-REPORT.txt"

$header = @"
=======================================================================
FTE4800 / FOCALTECH LINUX DRIVER RESEARCH
=======================================================================

Collection time:
$(Get-Date)

Computer:
$env:COMPUTERNAME

User:
$env:USERNAME

Administrator:
$IS_ADMIN

=======================================================================
KNOWN HARDWARE IDENTITY
=======================================================================

Fingerprint device:
$DEVICE_ID

Hardware ID:
ACPI\VEN_FTE&DEV_4800
ACPI\FTE4800
*FTE4800

ACPI path:
\_SB.PC00.SPI2.FPNT

Parent:
$PARENT_SPI

Vendor:
FocalTech Electronics (ShenZhen) Co., Ltd

Windows driver:
oem37.inf

Original INF:
ftwbioumdfdriverv2.inf

Driver version:
2.2.3.79

UMDF service:
WUDFRd

=======================================================================
RESEARCH TARGET
=======================================================================

Primary binary:
ftWbioUmdfDriverV2.dll

Secondary binary:
ftWbioEngineAdapter.dll

The primary objective is to determine:

1. SPI framing
2. command opcodes
3. register addresses
4. chip ID detection
5. reset sequence
6. GPIO semantics
7. interrupt/event protocol
8. image acquisition protocol
9. FIFO/buffer protocol
10. firmware download protocol
11. sleep/wake protocol
12. sensor initialization
13. power sequencing
14. firmware blobs
15. IC family / exact silicon
16. raw-image format suitable for libfprint

=======================================================================
COLLECTION ROOT
=======================================================================

$ROOT

=======================================================================
IMPORTANT FILES
=======================================================================

01-device\
02-spi-controller\
03-driver-package\
05-registry\
06-acpi\
07-pe-analysis\
08-strings\
09-setupapi\
10-events\
11-services\
13-runtime\

=======================================================================
"@

$header | Out-File $MASTER -Encoding UTF8

# Append the most useful text artifacts
$important = @(
    "$ROOT\01-device\device-properties.txt",
    "$ROOT\01-device\pnputil-device.txt",
    "$ROOT\01-device\signed-driver.txt",
    "$ROOT\02-spi-controller\properties.txt",
    "$ROOT\02-spi-controller\pnputil.txt",
    "$ROOT\03-driver-package\ORIGINAL-INF.txt",
    "$ROOT\03-driver-package\INF-SPI-ANALYSIS.txt",
    "$ROOT\05-registry\fte4800-device.txt",
    "$ROOT\05-registry\focalFp.txt",
    "$ROOT\05-registry\FTE4800-device-parameters.txt",
    "$ROOT\06-acpi\fingerprint-acpi-search.txt",
    "$ROOT\07-pe-analysis\ftWbioUmdfDriverV2-PE.txt",
    "$ROOT\07-pe-analysis\ftWbioEngineAdapter-PE.txt",
    "$ROOT\07-pe-analysis\PDB-files-found.txt",
    "$ROOT\09-setupapi\FTE4800-detailed.txt",
    "$ROOT\10-events\Microsoft-Windows-Biometrics_Operational.txt",
    "$ROOT\10-events\Microsoft-Windows-DriverFrameworks-UserMode_Operational.txt",
    "$ROOT\11-services\related-services.txt",
    "$ROOT\13-runtime\installed-ftWbioUmdfDriverV2.dll.txt",
    "$ROOT\13-runtime\installed-ftWbioEngineAdapter.dll.txt"
)

foreach ($f in $important) {

    if (Test-Path $f) {

        "`r`n`r`n=======================================================================" |
            Add-Content $MASTER -Encoding UTF8

        "FILE: $f" |
            Add-Content $MASTER -Encoding UTF8

        "=======================================================================" |
            Add-Content $MASTER -Encoding UTF8

        try {
            Get-Content $f -Raw |
                Add-Content $MASTER -Encoding UTF8
        }
        catch {}
    }
}

# ---------------------------------------------------------------------
# EXTRACT HIGH-VALUE ENGINE STRINGS INTO ONE FILE
# ---------------------------------------------------------------------

$engineStringFiles = @(
    "$ROOT\08-strings\ftWbioEngineAdapter-ascii.txt",
    "$ROOT\08-strings\ftWbioEngineAdapter-utf16.txt",
    "$ROOT\08-strings\ftWbioEngineAdapter-ascii-HARDWARE-FOCUSED.txt",
    "$ROOT\08-strings\ftWbioEngineAdapter-utf16-HARDWARE-FOCUSED.txt"
)

$engineCombined = "$ROOT\00-summary\ENGINE-IMPORTANT-STRINGS.txt"

foreach ($f in $engineStringFiles) {

    if (Test-Path $f) {

        "`r`n===== $f =====`r`n" |
            Add-Content $engineCombined -Encoding UTF8

        Get-Content $f -Raw |
            Add-Content $engineCombined -Encoding UTF8
    }
}

# ---------------------------------------------------------------------
# EXTRACT HIGH-VALUE UMDF STRINGS
# ---------------------------------------------------------------------

$umdfStringFiles = @(
    "$ROOT\08-strings\ftWbioUmdfDriverV2-ascii.txt",
    "$ROOT\08-strings\ftWbioUmdfDriverV2-utf16.txt",
    "$ROOT\08-strings\ftWbioUmdfDriverV2-ascii-HARDWARE-FOCUSED.txt",
    "$ROOT\08-strings\ftWbioUmdfDriverV2-utf16-HARDWARE-FOCUSED.txt"
)

$umdfCombined = "$ROOT\00-summary\UMDF-IMPORTANT-STRINGS.txt"

foreach ($f in $umdfStringFiles) {

    if (Test-Path $f) {

        "`r`n===== $f =====`r`n" |
            Add-Content $umdfCombined -Encoding UTF8

        Get-Content $f -Raw |
            Add-Content $umdfCombined -Encoding UTF8
    }
}

# Add those to master
foreach ($f in @(
    $engineCombined,
    $umdfCombined
)) {

    if (Test-Path $f) {

        "`r`n`r`n=======================================================================" |
            Add-Content $MASTER -Encoding UTF8

        "FILE: $f" |
            Add-Content $MASTER -Encoding UTF8

        "=======================================================================" |
            Add-Content $MASTER -Encoding UTF8

        Get-Content $f -Raw |
            Add-Content $MASTER -Encoding UTF8
    }
}

# ---------------------------------------------------------------------
# CREATE RESEARCH INDEX
# ---------------------------------------------------------------------

$INDEX = "$ROOT\00-summary\INDEX.txt"

@"
FTE4800 RESEARCH INDEX
======================

ROOT:
$ROOT

DEVICE
------
01-device\device.txt
01-device\device-properties.txt
01-device\pnputil-device.txt
01-device\hardware-ids.txt
01-device\resources.txt
01-device\interfaces.txt
01-device\signed-driver.txt

SPI CONTROLLER
--------------
02-spi-controller\device.txt
02-spi-controller\properties.txt
02-spi-controller\pnputil.txt
02-spi-controller\all-spi.txt

DRIVER PACKAGE
--------------
03-driver-package\
    ftWbioUmdfDriverV2.dll
    ftWbioEngineAdapter.dll
    ftWbioUmdfDriverV2.cat
    ftwbioumdfdriverv2.inf

REGISTRY
--------
05-registry\fte4800-device.txt
05-registry\focalFp.txt
05-registry\FTE4800-device-parameters.txt
05-registry\FTE4800-properties.txt

ACPI
----
06-acpi\
    Raw firmware tables
    SMBIOS
    ACPI
    Fingerprint search

PE REVERSE ENGINEERING
----------------------
07-pe-analysis\
    imports
    exports
    PE headers
    sections
    debug directory
    RSDS
    PDB path
    data directories

STRINGS
-------
08-strings\
    ASCII
    UTF-16
    hardware-focused

INSTALLATION
------------
09-setupapi\
    setupapi.dev.log
    FTE4800 installation matches

RUNTIME
-------
10-events\
11-services\

PREVIOUS RESEARCH
-----------------
14-existing-research\

HASHES
------
15-hashes\SHA256.csv
15-hashes\FILE-INVENTORY.csv

MASTER REPORT
-------------
00-summary\FTE4800-MASTER-REPORT.txt

NEXT REVERSE-ENGINEERING TARGETS
--------------------------------
1. Exact sensor class
2. Exact chip ID
3. DetectSensorType
4. factory/class-selection logic
5. SPI initialization
6. SPI opcodes
7. register read/write framing
8. interrupt/event codes
9. reset GPIO
10. firmware blobs
11. image transfer
12. firmware update
13. raw image dimensions/format

"@ | Out-File $INDEX -Encoding UTF8

# ---------------------------------------------------------------------
# CREATE ZIP
# ---------------------------------------------------------------------

$ZIP = "C:\FTE4800-RESEARCH-$STAMP.zip"

try {
    Compress-Archive `
        -Path "$ROOT\*" `
        -DestinationPath $ZIP `
        -Force `
        -CompressionLevel Optimal
}
catch {
    Write-Host "ZIP creation failed: $($_.Exception.Message)" -ForegroundColor Yellow
}

# ---------------------------------------------------------------------
# FINAL SUMMARY
# ---------------------------------------------------------------------

$filesCount = (
    Get-ChildItem $ROOT -Recurse -File -ErrorAction SilentlyContinue
).Count

$bytes = (
    Get-ChildItem $ROOT -Recurse -File -ErrorAction SilentlyContinue |
    Measure-Object Length -Sum
).Sum

$final = @"

=======================================================================
FTE4800 COLLECTION FINISHED
=======================================================================

TIME:
$(Get-Date)

ROOT:
$ROOT

ZIP:
$ZIP

FILES:
$filesCount

TOTAL BYTES:
$bytes

DEVICE:
ACPI\FTE4800\4&f064bb&0

HARDWARE:
ACPI\VEN_FTE&DEV_4800
ACPI\FTE4800
*FTE4800

ACPI:
\_SB.PC00.SPI2.FPNT

PARENT SPI:
PCI\VEN_8086&DEV_51FB&SUBSYS_00000000&REV_01\3&11583659&0&96

DRIVER:
oem37.inf
ftwbioumdfdriverv2.inf
2.2.3.79

PRIMARY BINARY:
ftWbioUmdfDriverV2.dll

ENGINE BINARY:
ftWbioEngineAdapter.dll

MASTER:
$MASTER

INDEX:
$INDEX

ZIP:
$ZIP

=======================================================================
HIGH-VALUE RESULTS TO INSPECT FIRST
=======================================================================

1. 07-pe-analysis\ftWbioUmdfDriverV2-PE.txt
2. 07-pe-analysis\ftWbioEngineAdapter-PE.txt
3. 07-pe-analysis\PDB-files-found.txt
4. 08-strings\ftWbioUmdfDriverV2-ascii-HARDWARE-FOCUSED.txt
5. 08-strings\ftWbioUmdfDriverV2-utf16-HARDWARE-FOCUSED.txt
6. 08-strings\ftWbioEngineAdapter-ascii-HARDWARE-FOCUSED.txt
7. 08-strings\ftWbioEngineAdapter-utf16-HARDWARE-FOCUSED.txt
8. 06-acpi\fingerprint-acpi-search.txt
9. 05-registry\focalFp.txt
10. 09-setupapi\FTE4800-detailed.txt
11. 01-device\pnputil-device.txt
12. 02-spi-controller\pnputil.txt

=======================================================================
CLIPBOARD
=======================================================================

The consolidated master report will now be copied to the clipboard.

=======================================================================
"@

$final | Add-Content $MASTER -Encoding UTF8

# ---------------------------------------------------------------------
# CLIPBOARD PREPARATION
# ---------------------------------------------------------------------

# Keep clipboard practical while ensuring the most useful material is present.
# Full artifacts remain on disk and in the ZIP.

$clipParts = @(
    $MASTER,
    "$ROOT\00-summary\INDEX.txt",
    "$ROOT\07-pe-analysis\ftWbioUmdfDriverV2-PE.txt",
    "$ROOT\07-pe-analysis\ftWbioEngineAdapter-PE.txt",
    "$ROOT\07-pe-analysis\PDB-files-found.txt",
    "$ROOT\00-summary\UMDF-IMPORTANT-STRINGS.txt",
    "$ROOT\00-summary\ENGINE-IMPORTANT-STRINGS.txt",
    "$ROOT\06-acpi\fingerprint-acpi-search.txt"
)

$clip = New-Object System.Text.StringBuilder

foreach ($f in $clipParts) {

    if (Test-Path $f) {

        [void]$clip.AppendLine("")
        [void]$clip.AppendLine(
            "==================== $f ===================="
        )
        [void]$clip.AppendLine("")

        try {
            [void]$clip.Append(
                [IO.File]::ReadAllText($f)
            )
        }
        catch {}
    }
}

$clipText = $clip.ToString()

# Clipboard safety cap
$MAX_CLIP = 12MB

if ($clipText.Length -gt $MAX_CLIP) {

    $clipText =
        $clipText.Substring(
            0,
            $MAX_CLIP
        ) +
        "`r`n`r`n[CLIPBOARD TRUNCATED - COMPLETE DATA IS IN THE ROOT DIRECTORY]`r`n" +
        $ROOT
}

try {

    Set-Clipboard -Value $clipText

    Write-Host ""
    Write-Host "CLIPBOARD UPDATED SUCCESSFULLY." -ForegroundColor Green
}
catch {

    Write-Host ""
    Write-Host "Set-Clipboard failed; trying clip.exe..." -ForegroundColor Yellow

    try {

        $clipText | clip.exe

        Write-Host "clip.exe clipboard update succeeded." `
            -ForegroundColor Green
    }
    catch {

        Write-Host "Clipboard update failed." `
            -ForegroundColor Red
    }
}

# ---------------------------------------------------------------------
# STOP TRANSCRIPT
# ---------------------------------------------------------------------

try {
    Stop-Transcript | Out-Null
} catch {}

# ---------------------------------------------------------------------
# FINAL SCREEN
# ---------------------------------------------------------------------

Write-Host ""
Write-Host "=======================================================================" `
    -ForegroundColor Green
Write-Host "              FTE4800 RESEARCH COLLECTION COMPLETE" `
    -ForegroundColor Green
Write-Host "=======================================================================" `
    -ForegroundColor Green
Write-Host ""
Write-Host "ROOT:" -ForegroundColor Cyan
Write-Host $ROOT
Write-Host ""
Write-Host "ZIP:" -ForegroundColor Cyan
Write-Host $ZIP
Write-Host ""
Write-Host "MASTER REPORT:" -ForegroundColor Cyan
Write-Host $MASTER
Write-Host ""
Write-Host "CLIPBOARD: COPIED" -ForegroundColor Green
Write-Host ""
Write-Host "Paste the clipboard contents here."
Write-Host ""
