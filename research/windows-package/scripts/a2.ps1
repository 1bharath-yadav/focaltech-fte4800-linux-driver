$ErrorActionPreference = "Continue"

$ROOT = Get-ChildItem "C:\FTE4800-RESEARCH" -Directory |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1 -ExpandProperty FullName

$PKG = Join-Path $ROOT "03-driver-package"
$OUT = Join-Path $ROOT "16-deep-disassembly"

New-Item -ItemType Directory -Force $OUT | Out-Null

$DLL = Join-Path $PKG "ftWbioUmdfDriverV2.dll"

Write-Host "ROOT = $ROOT"
Write-Host "DLL  = $DLL"

# Find objdump
$OBJDUMP = $null

$candidates = @(
    "C:\MinGW\bin\objdump.exe",
    "C:\msys64\mingw64\bin\objdump.exe",
    "C:\msys64\ucrt64\bin\objdump.exe",
    "C:\Program Files\LLVM\bin\llvm-objdump.exe"
)

foreach ($c in $candidates) {
    if (Test-Path $c) {
        $OBJDUMP = $c
        break
    }
}

if (-not $OBJDUMP) {
    $x = Get-Command objdump.exe -ErrorAction SilentlyContinue
    if ($x) { $OBJDUMP = $x.Source }
}

if (-not $OBJDUMP) {
    $x = Get-Command llvm-objdump.exe -ErrorAction SilentlyContinue
    if ($x) { $OBJDUMP = $x.Source }
}

if (-not $OBJDUMP) {
    Write-Host "NO OBJDUMP FOUND" -ForegroundColor Red
    exit 1
}

Write-Host "OBJDUMP = $OBJDUMP" -ForegroundColor Green

# ------------------------------------------------------------
# PE metadata
# ------------------------------------------------------------

& $OBJDUMP -x $DLL |
    Out-File "$OUT\01-pe-header.txt" -Encoding UTF8 -Width 8192

& $OBJDUMP -p $DLL |
    Out-File "$OUT\02-private-header.txt" -Encoding UTF8 -Width 8192

# ------------------------------------------------------------
# COMPLETE disassembly
# ------------------------------------------------------------

& $OBJDUMP -d -Mintel $DLL |
    Out-File "$OUT\03-disassembly-intel.txt" -Encoding UTF8 -Width 8192

# ------------------------------------------------------------
# Only .text section
# ------------------------------------------------------------

& $OBJDUMP -d -j .text -Mintel $DLL |
    Out-File "$OUT\04-text-disassembly.txt" -Encoding UTF8 -Width 8192

# ------------------------------------------------------------
# Search exact function names from strings/disassembly context
# ------------------------------------------------------------

$targets = @(
    "ff_spi_write_then_read_buf",
    "ff_spi_sfr_write_then_read_buf",
    "ff_spi_read_image_buf",
    "ft_interface_base_ReadData",
    "ft_interface_base_WriteData",
    "ft_interface_base_9368ReadData",
    "ft_interface_base_9368WriteData",
    "ft_interface_spi_RWDevData",
    "ft_interface_spi_WriteGPIO",
    "ft_interface_spi_CreateSpiTarget",
    "ft_interface_spi_CreateGpioTarget",
    "ft_interface_spi_CreateInterrupt",
    "ft_interface_base_CaptureImageData",
    "ft_feature_devinit_DetectSensorType",
    "ft_feature_devinit_9368ReadChipID",
    "ft_feature_loadfirmware_FT9368isUpdateVersion",
    "ft_feature_FT9368_loadfirmware_LoadFW",
    "fw9369_probe_id",
    "fw9369_config_spi_mode",
    "fw9369_query_event_status",
    "fw9369_fifo_read",
    "fw9369_sram_read_bulk_withecc",
    "fw9369_sram_write_bulk"
)

foreach ($t in $targets) {

    $safe = $t -replace '[^A-Za-z0-9_-]', '_'

    Select-String `
        -Path "$OUT\03-disassembly-intel.txt" `
        -Pattern $t `
        -Context 40,80 `
        -ErrorAction SilentlyContinue |
        Out-File "$OUT\target-$safe.txt" `
            -Encoding UTF8 `
            -Width 8192
}

# ------------------------------------------------------------
# Find immediate constants that look like register addresses
# ------------------------------------------------------------

$addrPatterns = @(
    "0xFE",
    "0x90",
    "0x85C0",
    "0x0000FE",
    "0x000090",
    "0x000085C0",
    "85c0",
    "9368",
    "9369",
    "9536",
    "95a8"
)

foreach ($p in $addrPatterns) {

    $safe = $p -replace '[^A-Za-z0-9_-]', '_'

    Select-String `
        -Path "$OUT\04-text-disassembly.txt" `
        -Pattern $p `
        -Context 12,25 `
        -ErrorAction SilentlyContinue |
        Out-File "$OUT\constant-$safe.txt" `
            -Encoding UTF8 `
            -Width 8192
}

# ------------------------------------------------------------
# Search strings output for source/function references
# ------------------------------------------------------------

$STRINGS = "C:\MinGW\bin\strings.exe"

if (Test-Path $STRINGS) {

    & $STRINGS -n 4 $DLL |
        Out-File "$OUT\05-strings.txt" -Encoding UTF8 -Width 8192

    & $STRINGS -n 4 $DLL |
        Select-String `
            -Pattern `
            "spi",
            "sfr",
            "fifo",
            "read",
            "write",
            "chip",
            "reset",
            "interrupt",
            "firmware",
            "9368",
            "9369",
            "FT93",
            "register" |
        Out-File "$OUT\06-hardware-strings.txt" `
            -Encoding UTF8 `
            -Width 8192
}

# ------------------------------------------------------------
# SHA256
# ------------------------------------------------------------

Get-FileHash $DLL -Algorithm SHA256 |
    Format-List |
    Out-File "$OUT\07-dll-sha256.txt" -Encoding UTF8

# ------------------------------------------------------------
# Make a compact report and copy it to clipboard
# ------------------------------------------------------------

$report = New-Object System.Text.StringBuilder

[void]$report.AppendLine("FTE4800 DEEP DISASSEMBLY")
[void]$report.AppendLine("=======================")
[void]$report.AppendLine("ROOT: $ROOT")
[void]$report.AppendLine("DLL:  $DLL")
[void]$report.AppendLine("OBJDUMP: $OBJDUMP")
[void]$report.AppendLine("")

foreach ($f in Get-ChildItem $OUT -Filter "target-*.txt" -File) {

    [void]$report.AppendLine("")
    [void]$report.AppendLine("============================================================")
    [void]$report.AppendLine($f.Name)
    [void]$report.AppendLine("============================================================")

    try {
        $data = Get-Content $f.FullName -Raw
        if ($data.Length -gt 12000) {
            $data = $data.Substring(0,12000) +
                "`r`n[SECTION TRUNCATED IN CLIPBOARD; FULL FILE ON DISK]`r`n"
        }
        [void]$report.AppendLine($data)
    } catch {}
}

[void]$report.AppendLine("")
[void]$report.AppendLine("============================================================")
[void]$report.AppendLine("REGISTER/CONSTANT SEARCHES")
[void]$report.AppendLine("============================================================")

foreach ($f in Get-ChildItem $OUT -Filter "constant-*.txt" -File) {

    [void]$report.AppendLine("")
    [void]$report.AppendLine("===== $($f.Name) =====")

    try {
        $data = Get-Content $f.FullName -Raw
        if ($data.Length -gt 8000) {
            $data = $data.Substring(0,8000) +
                "`r`n[SECTION TRUNCATED; FULL FILE ON DISK]`r`n"
        }
        [void]$report.AppendLine($data)
    } catch {}
}

$REPORT = $report.ToString()

$REPORT |
    Set-Clipboard

$REPORT |
    Set-Content "$OUT\00-CLIPBOARD-REPORT.txt" -Encoding UTF8

Write-Host ""
Write-Host "==================================================" -ForegroundColor Green
Write-Host "DEEP DISASSEMBLY COMPLETE" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Green
Write-Host "Output:"
Write-Host $OUT
Write-Host ""
Write-Host "CLIPBOARD COPIED." -ForegroundColor Green
Write-Host ""
Write-Host "Now paste the clipboard contents here."
