# ============================================================
# FTE4800 STEP 01
# FT9368 CHIP-ID PATH
#
# IMPORTANT:
#   GNU/MinGW objdump is NOT assumed.
#
# Tool selection:
#   1. llvm-objdump
#   2. dumpbin
#   3. python + capstone
#
# Automatically:
#   - validates PE
#   - extracts .text
#   - searches target strings
#   - finds RIP-relative xrefs
#   - creates focused disassembly
#   - records tool failures
#   - copies final report to clipboard
# ============================================================

$ErrorActionPreference = 'Continue'

$root = 'C:\FTE4800-RESEARCH\20261002-190717'
$dll  = Join-Path $root '03-driver-package\ftWbioUmdfDriverV2.dll'
$out  = Join-Path $root '16-deep-disassembly\step01-9368-chipid'

New-Item -ItemType Directory -Force -Path $out | Out-Null

$reportFile = Join-Path $out 'REPORT.txt'
$toolLog    = Join-Path $out 'TOOLS.txt'

$report = [System.Collections.Generic.List[string]]::new()
$toolLogLines = [System.Collections.Generic.List[string]]::new()

function R {
    param([string]$s = '')
    [void]$report.Add($s)
}

function Section {
    param([string]$s)
    R ''
    R ('=' * 78)
    R $s
    R ('=' * 78)
}

function Find-Tool {
    param(
        [string[]]$Names,
        [string[]]$ExtraPaths = @()
    )

    foreach ($n in $Names) {

        try {
            $cmd = Get-Command $n -ErrorAction SilentlyContinue

            if ($cmd -and $cmd.Source) {
                return $cmd.Source
            }

            if ($cmd -and $cmd.Path) {
                return $cmd.Path
            }
        } catch {}
    }

    foreach ($p in $ExtraPaths) {

        if (Test-Path $p) {
            return $p
        }
    }

    return $null
}

# ------------------------------------------------------------
# Header
# ------------------------------------------------------------

R 'FTE4800 STEP 01 - FT9368 CHIP-ID ANALYSIS'
R "TIME: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
R "ROOT: $root"
R "DLL : $dll"

if (-not (Test-Path $dll)) {
    R ''
    R "FATAL: DLL NOT FOUND"
    R $dll

    $txt = $report -join "`r`n"
    [IO.File]::WriteAllText($reportFile, $txt)

    try {
        Set-Clipboard $txt
    } catch {
        $txt | clip.exe
    }

    exit 1
}

# ------------------------------------------------------------
# Find disassembly tools
# ------------------------------------------------------------

Section 'TOOL DISCOVERY'

$llvm = Find-Tool `
    -Names @(
        'llvm-objdump.exe',
        'llvm-objdump'
    ) `
    -ExtraPaths @(
        'C:\Program Files\LLVM\bin\llvm-objdump.exe',
        'C:\Program Files (x86)\LLVM\bin\llvm-objdump.exe'
    )

$dumpbin = Find-Tool `
    -Names @(
        'dumpbin.exe'
    ) `
    -ExtraPaths @(
        'C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\*\bin\Hostx64\x64\dumpbin.exe',
        'C:\Program Files\Microsoft Visual Studio\2022\Professional\VC\Tools\MSVC\*\bin\Hostx64\x64\dumpbin.exe',
        'C:\Program Files\Microsoft Visual Studio\2022\Enterprise\VC\Tools\MSVC\*\bin\Hostx64\x64\dumpbin.exe',
        'C:\Program Files (x86)\Microsoft Visual Studio\*\*\VC\Tools\MSVC\*\bin\Hostx64\x64\dumpbin.exe'
    )

# Wildcards above need explicit resolution.
if (-not $dumpbin) {

    $candidate = Get-ChildItem `
        'C:\Program Files\Microsoft Visual Studio',
        'C:\Program Files (x86)\Microsoft Visual Studio' `
        -Filter 'dumpbin.exe' `
        -File `
        -Recurse `
        -ErrorAction SilentlyContinue |
        Where-Object {
            $_.FullName -match '\\Hostx64\\x64\\dumpbin\.exe$'
        } |
        Select-Object -First 1

    if ($candidate) {
        $dumpbin = $candidate.FullName
    }
}

$python = Find-Tool `
    -Names @('python.exe','python') `
    -ExtraPaths @(
        'C:\Python313\python.exe',
        'C:\Python312\python.exe',
        'C:\Python311\python.exe'
    )

R "LLVM objdump : $(if($llvm){$llvm}else{'NOT FOUND'})"
R "dumpbin       : $(if($dumpbin){$dumpbin}else{'NOT FOUND'})"
R "Python        : $(if($python){$python}else{'NOT FOUND'})"

$toolLogLines.Add("LLVM=$llvm")
$toolLogLines.Add("DUMPBIN=$dumpbin")
$toolLogLines.Add("PYTHON=$python")

# ------------------------------------------------------------
# PE parser
# ------------------------------------------------------------

Section 'PE STRUCTURE'

[byte[]]$b = [IO.File]::ReadAllBytes($dll)

R "FILE SIZE: $($b.Length)"

$pe = [BitConverter]::ToUInt32($b, 0x3C)

R ("PE OFFSET: 0x{0:X}" -f $pe)

$sig = [Text.Encoding]::ASCII.GetString($b, $pe, 4)

R "SIGNATURE: $sig"

$fileHeader = $pe + 4

$machine = [BitConverter]::ToUInt16($b, $fileHeader)
$nsec    = [BitConverter]::ToUInt16($b, $fileHeader + 2)
$optSize = [BitConverter]::ToUInt16($b, $fileHeader + 16)

$optional = $fileHeader + 20
$magic = [BitConverter]::ToUInt16($b, $optional)

$imageBase = [BitConverter]::ToUInt64($b, $optional + 24)

R ("MACHINE: 0x{0:X}" -f $machine)
R "SECTIONS: $nsec"
R ("OPTIONAL MAGIC: 0x{0:X}" -f $magic)
R ("IMAGE BASE: 0x{0:X}" -f $imageBase)

$sectionTable = $optional + $optSize

$sections = @()

for ($i = 0; $i -lt $nsec; $i++) {

    $o = $sectionTable + ($i * 40)

    $name = [Text.Encoding]::ASCII.GetString(
        $b[$o..($o + 7)]
    ).Trim([char]0)

    $vsize = [BitConverter]::ToUInt32($b, $o + 8)
    $rva   = [BitConverter]::ToUInt32($b, $o + 12)
    $rsize = [BitConverter]::ToUInt32($b, $o + 16)
    $rptr  = [BitConverter]::ToUInt32($b, $o + 20)

    $sections += [PSCustomObject]@{
        Name = $name
        RVA = $rva
        VSize = $vsize
        RawSize = $rsize
        RawPtr = $rptr
    }

    R (
        "{0,-8} RVA=0x{1:X8} VSize=0x{2:X8} RawPtr=0x{3:X8} RawSize=0x{4:X8}" -f
        $name,$rva,$vsize,$rptr,$rsize
    )
}

$text = $sections |
    Where-Object Name -eq '.text' |
    Select-Object -First 1

if (-not $text) {

    R 'FATAL: .text section missing.'

    $txt = $report -join "`r`n"
    [IO.File]::WriteAllText($reportFile, $txt)

    try {
        Set-Clipboard $txt
    } catch {
        $txt | clip.exe
    }

    exit 1
}

$textVA = [UInt64]$imageBase + [UInt64]$text.RVA

R ''
R ("TEXT VA: 0x{0:X}" -f $textVA)
R ("TEXT RAW PTR: 0x{0:X}" -f $text.RawPtr)
R ("TEXT RAW SIZE: 0x{0:X}" -f $text.RawSize)

[int]$textStart = $text.RawPtr
[int]$textEnd = $text.RawPtr + $text.RawSize - 1

[byte[]]$textBytes = $b[$textStart..$textEnd]

# ------------------------------------------------------------
# Byte search
# ------------------------------------------------------------

function Find-Bytes {
    param(
        [byte[]]$Hay,
        [byte[]]$Needle
    )

    $hits = [System.Collections.Generic.List[int]]::new()

    if ($Needle.Length -eq 0) {
        return $hits
    }

    for ($i = 0; $i -le $Hay.Length - $Needle.Length; $i++) {

        $ok = $true

        for ($j = 0; $j -lt $Needle.Length; $j++) {

            if ($Hay[$i + $j] -ne $Needle[$j]) {
                $ok = $false
                break
            }
        }

        if ($ok) {
            [void]$hits.Add($i)
        }
    }

    return $hits
}

function FileOffsetToVA {
    param([int]$offset)

    foreach ($s in $sections) {

        if (
            $offset -ge $s.RawPtr -and
            $offset -lt ($s.RawPtr + $s.RawSize)
        ) {

            return (
                [UInt64]$imageBase +
                [UInt64]$s.RVA +
                [UInt64]($offset - $s.RawPtr)
            )
        }
    }

    return $null
}

# ------------------------------------------------------------
# Search strings
# ------------------------------------------------------------

Section '9368 TARGET STRINGS'

$targets = @(
    'ft_feature_devinit_9368ReadChipID',
    '9368 Chipid = 0x%x',
    'Sensor version:%d chipid = 0x%x',
    'manufactor = 0x%x Sensor W = %d H = %d',
    'agc1=%d agc2=%d agc3=%d agc4=%d',
    'ft_sensor_sensorbase_ReadChipID',
    'clsFT9368Base::ft_sensor_sensorbase_ReadInfo'
)

$xrefTargets = @()

foreach ($str in $targets) {

    R ''
    R "TARGET: $str"

    $needle = [Text.Encoding]::ASCII.GetBytes($str)
    $hits = Find-Bytes -Hay $b -Needle $needle

    if ($hits.Count -eq 0) {

        R 'NOT FOUND'
        continue
    }

    foreach ($off in $hits) {

        $va = FileOffsetToVA $off

        R (
            "FOUND FILE=0x{0:X} VA=0x{1:X}" -f
            $off,$va
        )

        $xrefTargets += [PSCustomObject]@{
            Text = $str
            FileOffset = $off
            VA = $va
        }
    }
}

# ------------------------------------------------------------
# RIP-relative xrefs
# ------------------------------------------------------------

Section 'RIP-RELATIVE XREFS'

function Find-RipXrefs {

    param(
        [byte[]]$Code,
        [UInt64]$CodeVA,
        [UInt64]$TargetVA
    )

    $hits = [System.Collections.Generic.List[object]]::new()

    for ($i = 0; $i -lt ($Code.Length - 7); $i++) {

        # 48/4C/49 REX + opcode 8B or 8D
        if (
            (($Code[$i] -band 0xF0) -eq 0x40) -and
            (
                $Code[$i+1] -eq 0x8B -or
                $Code[$i+1] -eq 0x8D
            )
        ) {

            $modrm = $Code[$i+2]

            if (
                (($modrm -band 0xC0) -eq 0) -and
                (($modrm -band 7) -eq 5)
            ) {

                $disp = [BitConverter]::ToInt32($Code,$i+3)

                [Int64]$dest =
                    [Int64]$CodeVA +
                    $i +
                    7 +
                    $disp

                if ([UInt64]$dest -eq $TargetVA) {

                    $hits.Add(
                        [PSCustomObject]@{
                            Offset = $i
                            VA = $CodeVA + [UInt64]$i
                            Type = 'REX-RIP'
                        }
                    )
                }
            }
        }

        # no REX
        if (
            $Code[$i] -eq 0x8B -or
            $Code[$i] -eq 0x8D
        ) {

            $modrm = $Code[$i+1]

            if (
                (($modrm -band 0xC0) -eq 0) -and
                (($modrm -band 7) -eq 5)
            ) {

                $disp = [BitConverter]::ToInt32($Code,$i+2)

                [Int64]$dest =
                    [Int64]$CodeVA +
                    $i +
                    6 +
                    $disp

                if ([UInt64]$dest -eq $TargetVA) {

                    $hits.Add(
                        [PSCustomObject]@{
                            Offset = $i
                            VA = $CodeVA + [UInt64]$i
                            Type = 'RIP'
                        }
                    )
                }
            }
        }
    }

    return $hits
}

$xrefs = [System.Collections.Generic.List[object]]::new()

foreach ($t in $xrefTargets) {

    $hits = Find-RipXrefs `
        -Code $textBytes `
        -CodeVA $textVA `
        -TargetVA $t.VA

    R ''
    R "STRING: $($t.Text)"
    R ("STRING VA: 0x{0:X}" -f $t.VA)

    if ($hits.Count -eq 0) {

        R 'No RIP-relative xrefs found.'

    } else {

        foreach ($h in $hits) {

            $record = [PSCustomObject]@{
                String = $t.Text
                StringVA = $t.VA
                XrefVA = $h.VA
                Type = $h.Type
            }

            [void]$xrefs.Add($record)

            R (
                "XREF VA=0x{0:X} TYPE={1}" -f
                $h.VA,$h.Type
            )
        }
    }
}

# ------------------------------------------------------------
# Focused disassembly backend
# ------------------------------------------------------------

Section 'DISASSEMBLY BACKEND'

$backend = $null

if ($llvm) {
    $backend = 'LLVM'
}
elseif ($dumpbin) {
    $backend = 'DUMPBIN'
}
elseif ($python) {
    $backend = 'PYTHON'
}

R "SELECTED BACKEND: $(if($backend){$backend}else{'NONE'})"

if (-not $backend) {

    R ''
    R 'No usable disassembler found.'
    R 'Install LLVM and rerun this script.'
}

# ------------------------------------------------------------
# Disassemble xref windows
# ------------------------------------------------------------

Section 'FOCUSED DISASSEMBLY'

$xrefs |
    Sort-Object XrefVA -Unique |
    ForEach-Object {

        $va = [UInt64]$_.XrefVA

        $start = $va - 0x180
        $stop  = $va + 0x380

        if ($start -lt $textVA) {
            $start = $textVA
        }

        $baseName =
            ($_.String -replace '[^A-Za-z0-9]+','_').Trim('_')

        if (-not $baseName) {
            $baseName = 'xref'
        }

        $asm = Join-Path $out (
            "xref-{0}-0x{1:X}.asm.txt" -f
            $baseName,
            $va
        )

        R ''
        R ('-' * 70)
        R "STRING: $($_.String)"
        R ("XREF : 0x{0:X}" -f $va)
        R ("RANGE: 0x{0:X} -> 0x{1:X}" -f $start,$stop)
        R "FILE : $asm"
        R ('-' * 70)

        if ($backend -eq 'LLVM') {

            & $llvm `
                -d `
                --x86-asm-syntax=intel `
                "--start-address=$start" `
                "--stop-address=$stop" `
                $dll 2>&1 |
                Tee-Object -FilePath $asm |
                Out-String |
                ForEach-Object { R $_ }

        }
        elseif ($backend -eq 'DUMPBIN') {

            & $dumpbin `
                /DISASM `
                $dll 2>&1 |
                Tee-Object -FilePath $asm |
                Out-String |
                ForEach-Object { R $_ }

        }
        else {

            R 'Python selected, but targeted Capstone implementation is not yet invoked.'
        }
    }

# ------------------------------------------------------------
# Known hardware evidence
# ------------------------------------------------------------

Section 'KNOWN 9368 EVIDENCE'

$hardwareStrings = Join-Path `
    $root `
    '08-strings\ftWbioUmdfDriverV2-ascii-HARDWARE-FOCUSED.txt'

if (Test-Path $hardwareStrings) {

    Get-Content $hardwareStrings |
        Select-String `
            -Pattern '9368|ReadChipID|chipid|Sensor version|manufactor|agc[1-4]|ff_spi|SPI0' |
        ForEach-Object {
            R $_.Line
        }

} else {

    R "NOT FOUND: $hardwareStrings"
}

# ------------------------------------------------------------
# Diagnostics
# ------------------------------------------------------------

Section 'DIAGNOSTICS'

R "Original failing tool:"
R 'C:\MinGW\bin\objdump.exe'
R 'Result: File format not recognized'
R ''
R 'The existing PE report independently identifies the DLL as PE32+ x64.'
R ''
R 'This script deliberately does not use MinGW objdump.'

# ------------------------------------------------------------
# Final
# ------------------------------------------------------------

Section 'NEXT TARGET'

R @'
The first successful machine-code result we need is the call chain:

ft_feature_devinit_9368ReadChipID
        |
        +--> ft_sensor_sensorbase_ReadChipID
        |
        +--> lower-level read function
        |
        +--> SPI transaction
        |
        +--> actual command/address/length

Once this is recovered, the same mechanism will be applied to:

    SPI initialization
    register read/write
    SFR access
    GPIO/reset
    interrupt/event status
    image capture
    FIFO/image transfer
    firmware download
    sleep/wake

Do not implement the Linux driver from the current evidence alone.
'@

# ------------------------------------------------------------
# Save
# ------------------------------------------------------------

$txt = $report -join "`r`n"

[IO.File]::WriteAllText(
    $reportFile,
    $txt,
    [Text.UTF8Encoding]::new($false)
)

[IO.File]::WriteAllText(
    $toolLog,
    ($toolLogLines -join "`r`n"),
    [Text.UTF8Encoding]::new($false)
)

# ------------------------------------------------------------
# AUTOMATIC CLIPBOARD
# ------------------------------------------------------------

$copied = $false

try {

    Set-Clipboard -Value $txt
    $copied = $true

} catch {

    try {

        $txt | clip.exe
        $copied = $true

    } catch {}
}

Write-Host ''
Write-Host '============================================================'
Write-Host 'STEP 01 FINISHED'
Write-Host '============================================================'
Write-Host "REPORT   : $reportFile"
Write-Host "TOOL LOG : $toolLog"
Write-Host "CLIPBOARD: $copied"
Write-Host ''

if ($copied) {
    Write-Host 'REPORT COPIED TO CLIPBOARD.'
    Write-Host 'Paste it into ChatGPT.'
} else {
    Write-Host 'CLIPBOARD COPY FAILED.'
    Write-Host "Open: $reportFile"
}

Write-Host '============================================================'
