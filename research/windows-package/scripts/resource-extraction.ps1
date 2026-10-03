# ============================================================
# FTE4800 FINAL RESOURCE EXTRACTION
# PowerShell 5.1
#
# ONLY extracts:
#   - FTE4800 PnP resources
#   - LogConf
#   - BootConfig
#   - BasicConfigVector
#   - FilteredConfigVector
#   - AllocConfig
#   - complete device registry
#   - raw registry export
#
# No cmd.exe wrapper.
# No variable-name collisions.
# No R() helper.
#
# Automatically copies final report to clipboard.
# ============================================================

$ErrorActionPreference = 'Continue'

$Base = 'C:\FTE4800-RESEARCH\20261002-190717'
$Out  = Join-Path $Base '22-RESOURCE-FINAL'

New-Item -ItemType Directory -Force -Path $Out | Out-Null

$Device = 'ACPI\FTE4800\4&f064bb&0'

$RegRoot =
    'HKLM\SYSTEM\CurrentControlSet\Enum\ACPI\FTE4800\4&f064bb&0'

$RegLogConf =
    "$RegRoot\LogConf"

$RegControl =
    "$RegRoot\Control"

$PnpPath =
    Join-Path $Out 'FTE4800-resources.txt'

$LogConfPath =
    Join-Path $Out 'LogConf.txt'

$BootPath =
    Join-Path $Out 'BootConfig.txt'

$BasicPath =
    Join-Path $Out 'BasicConfigVector.txt'

$FilteredPath =
    Join-Path $Out 'FilteredConfigVector.txt'

$AllocPath =
    Join-Path $Out 'AllocConfig.txt'

$RegistryPath =
    Join-Path $Out 'FTE4800-device-registry.txt'

$ExportPath =
    Join-Path $Out 'FTE4800-device.reg'

$ReportPath =
    Join-Path $Out 'RESOURCE-FINAL-REPORT.txt'

$HexPath =
    Join-Path $Out 'RESOURCE-HEX.txt'

$ReportLines =
    New-Object 'System.Collections.Generic.List[string]'

function Add-ReportLine {
    param([string]$Text = '')
    [void]$ReportLines.Add($Text)
}

function Run-NativeCommand {
    param(
        [string]$Exe,
        [string[]]$Args,
        [string]$OutputPath
    )

    Write-Host ''
    Write-Host "Running: $Exe $($Args -join ' ')"

    try {

        $result =
            & $Exe @Args 2>&1

        $exitCode = $LASTEXITCODE

        $text =
            $result | Out-String

        [IO.File]::WriteAllText(
            $OutputPath,
            $text,
            [Text.UTF8Encoding]::new($false)
        )

        Write-Host "Exit code: $exitCode"
        Write-Host "Output   : $OutputPath"

        return [PSCustomObject]@{
            ExitCode = $exitCode
            Text     = $text
        }

    }
    catch {

        $text =
            "EXCEPTION: $($_.Exception.Message)"

        [IO.File]::WriteAllText(
            $OutputPath,
            $text,
            [Text.UTF8Encoding]::new($false)
        )

        Write-Host $text

        return [PSCustomObject]@{
            ExitCode = -1
            Text     = $text
        }
    }
}

# ============================================================
# HEADER
# ============================================================

Add-ReportLine 'FTE4800 FINAL RESOURCE EXTRACTION'
Add-ReportLine "TIME      : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Add-ReportLine "DEVICE    : $Device"
Add-ReportLine "REG ROOT  : $RegRoot"
Add-ReportLine "OUTPUT    : $Out"

# ============================================================
# 1. DIRECT PNPUTIL RESOURCE QUERY
# ============================================================

Add-ReportLine ''
Add-ReportLine ('=' * 80)
Add-ReportLine 'FTE4800 PNP RESOURCES'
Add-ReportLine ('=' * 80)

$pnpResult =
    Run-NativeCommand `
        'C:\Windows\System32\pnputil.exe' `
        @(
            '/enum-devices'
            '/instanceid'
            $Device
            '/resources'
        ) `
        $PnpPath

Add-ReportLine $pnpResult.Text

# Detect whether we accidentally received help.
$pnpLooksLikeHelp =
    $pnpResult.Text -match 'PNPUTIL \['

if ($pnpLooksLikeHelp) {

    Add-ReportLine ''
    Add-ReportLine 'WARNING: PNPUTIL RETURNED HELP INSTEAD OF RESOURCE DATA.'
    Add-ReportLine 'DIRECT NATIVE INVOCATION DID NOT PRODUCE RESOURCE DATA.'

}
else {

    Add-ReportLine ''
    Add-ReportLine 'PNPUTIL APPEARS TO HAVE RETURNED DEVICE-SPECIFIC DATA.'
}

# ============================================================
# 2. DIRECT REG QUERY - LOGCONF
# ============================================================

Add-ReportLine ''
Add-ReportLine ('=' * 80)
Add-ReportLine 'LOGCONF'
Add-ReportLine ('=' * 80)

$logResult =
    Run-NativeCommand `
        'C:\Windows\System32\reg.exe' `
        @(
            'query'
            $RegLogConf
            '/s'
        ) `
        $LogConfPath

Add-ReportLine $logResult.Text

# ============================================================
# 3. BOOTCONFIG
# ============================================================

Add-ReportLine ''
Add-ReportLine ('=' * 80)
Add-ReportLine 'BOOTCONFIG'
Add-ReportLine ('=' * 80)

$bootResult =
    Run-NativeCommand `
        'C:\Windows\System32\reg.exe' `
        @(
            'query'
            $RegLogConf
            '/v'
            'BootConfig'
        ) `
        $BootPath

Add-ReportLine $bootResult.Text

# ============================================================
# 4. BASIC CONFIG VECTOR
# ============================================================

Add-ReportLine ''
Add-ReportLine ('=' * 80)
Add-ReportLine 'BASIC CONFIG VECTOR'
Add-ReportLine ('=' * 80)

$basicResult =
    Run-NativeCommand `
        'C:\Windows\System32\reg.exe' `
        @(
            'query'
            $RegLogConf
            '/v'
            'BasicConfigVector'
        ) `
        $BasicPath

Add-ReportLine $basicResult.Text

# ============================================================
# 5. FILTERED CONFIG VECTOR
# ============================================================

Add-ReportLine ''
Add-ReportLine ('=' * 80)
Add-ReportLine 'FILTERED CONFIG VECTOR'
Add-ReportLine ('=' * 80)

$filteredResult =
    Run-NativeCommand `
        'C:\Windows\System32\reg.exe' `
        @(
            'query'
            $RegControl
            '/v'
            'FilteredConfigVector'
        ) `
        $FilteredPath

Add-ReportLine $filteredResult.Text

# ============================================================
# 6. ALLOCCONFIG
# ============================================================

Add-ReportLine ''
Add-ReportLine ('=' * 80)
Add-ReportLine 'ALLOCCONFIG'
Add-ReportLine ('=' * 80)

$allocResult =
    Run-NativeCommand `
        'C:\Windows\System32\reg.exe' `
        @(
            'query'
            $RegLogConf
            '/v'
            'AllocConfig'
        ) `
        $AllocPath

Add-ReportLine $allocResult.Text

# ============================================================
# 7. COMPLETE DEVICE REGISTRY
# ============================================================

Add-ReportLine ''
Add-ReportLine ('=' * 80)
Add-ReportLine 'COMPLETE DEVICE REGISTRY'
Add-ReportLine ('=' * 80)

$registryResult =
    Run-NativeCommand `
        'C:\Windows\System32\reg.exe' `
        @(
            'query'
            $RegRoot
            '/s'
        ) `
        $RegistryPath

Add-ReportLine $registryResult.Text

# ============================================================
# 8. REGISTRY EXPORT
# ============================================================

Add-ReportLine ''
Add-ReportLine ('=' * 80)
Add-ReportLine 'REGISTRY EXPORT'
Add-ReportLine ('=' * 80)

$exportResult =
    Run-NativeCommand `
        'C:\Windows\System32\reg.exe' `
        @(
            'export'
            $RegRoot
            $ExportPath
            '/y'
        ) `
        (Join-Path $Out 'registry-export-result.txt')

Add-ReportLine $exportResult.Text

# ============================================================
# 9. EXTRACT LONG HEX STRINGS FROM OUTPUT
# ============================================================

Add-ReportLine ''
Add-ReportLine ('=' * 80)
Add-ReportLine 'RESOURCE HEX EXTRACTION'
Add-ReportLine ('=' * 80)

$hexFiles = @(
    $LogConfPath
    $BootPath
    $BasicPath
    $FilteredPath
    $AllocPath
    $RegistryPath
)

$hexLines =
    New-Object 'System.Collections.Generic.List[string]'

foreach ($filePath in $hexFiles) {

    [void]$hexLines.Add('')
    [void]$hexLines.Add("SOURCE: $filePath")
    [void]$hexLines.Add(('-' * 80))

    if (-not (Test-Path $filePath)) {

        [void]$hexLines.Add('FILE DOES NOT EXIST')
        continue
    }

    $sourceText =
        Get-Content `
            -LiteralPath $filePath `
            -Raw

    # Match sequences of hexadecimal bytes.
    $hexMatches =
        [regex]::Matches(
            $sourceText,
            '(?i)(?:[0-9a-f]{2}){8,}'
        )

    if ($hexMatches.Count -eq 0) {

        [void]$hexLines.Add('NO LONG HEX SEQUENCE FOUND')

    }
    else {

        $uniqueHex =
            $hexMatches |
            ForEach-Object {
                $_.Value
            } |
            Sort-Object -Unique

        foreach ($hex in $uniqueHex) {

            [void]$hexLines.Add(
                "HEX: $hex"
            )

            [void]$hexLines.Add(
                "BYTE_COUNT: $([int]($hex.Length / 2))"
            )
        }
    }
}

$hexText =
    $hexLines -join "`r`n"

[IO.File]::WriteAllText(
    $HexPath,
    $hexText,
    [Text.UTF8Encoding]::new($false)
)

Add-ReportLine $hexText

# ============================================================
# 10. CRITICAL FILE SIZES
# ============================================================

Add-ReportLine ''
Add-ReportLine ('=' * 80)
Add-ReportLine 'FILE VALIDATION'
Add-ReportLine ('=' * 80)

foreach ($filePath in @(
    $PnpPath
    $LogConfPath
    $BootPath
    $BasicPath
    $FilteredPath
    $AllocPath
    $RegistryPath
    $ExportPath
    $HexPath
)) {

    if (Test-Path $filePath) {

        $fileInfo =
            Get-Item $filePath

        Add-ReportLine (
            "{0,10} bytes  {1}" -f
            $fileInfo.Length,
            $filePath
        )

    }
    else {

        Add-ReportLine "MISSING: $filePath"
    }
}

# ============================================================
# 11. FINAL INTERPRETATION
# ============================================================

Add-ReportLine ''
Add-ReportLine ('=' * 80)
Add-ReportLine 'STATUS'
Add-ReportLine ('=' * 80)

if ($pnpLooksLikeHelp) {

    Add-ReportLine 'PNP_RESOURCE_STATUS = FAILED'

}
else {

    Add-ReportLine 'PNP_RESOURCE_STATUS = DATA_RETURNED'
}

$logText =
    if (Test-Path $LogConfPath) {
        Get-Content $LogConfPath -Raw
    }
    else {
        ''
    }

if ($logText -match 'BootConfig' -and $logText -match 'BasicConfigVector') {

    Add-ReportLine 'LOGCONF_STATUS = VALUES_VISIBLE'

}
else {

    Add-ReportLine 'LOGCONF_STATUS = VALUES_NOT_CONFIRMED'
}

Add-ReportLine ''
Add-ReportLine 'This is the final Windows resource-only collection.'
Add-ReportLine 'The DLL/package reverse engineering will be performed on Linux.'

# ============================================================
# SAVE REPORT
# ============================================================

$finalReportText =
    $ReportLines -join "`r`n"

[IO.File]::WriteAllText(
    $ReportPath,
    $finalReportText,
    [Text.UTF8Encoding]::new($false)
)

# ============================================================
# CLIPBOARD
# ============================================================

$clipboardOK = $false

try {

    Set-Clipboard `
        -Value $finalReportText

    $clipboardOK = $true

}
catch {

    try {

        $finalReportText |
            clip.exe

        $clipboardOK = $true

    }
    catch {}
}

# ============================================================
# CONSOLE
# ============================================================

Write-Host ''
Write-Host '======================================================================'
Write-Host 'FTE4800 RESOURCE FINAL'
Write-Host '======================================================================'
Write-Host "OUTPUT    : $Out"
Write-Host "REPORT    : $ReportPath"
Write-Host "CLIPBOARD : $clipboardOK"
Write-Host '======================================================================'
Write-Host ''

if ($clipboardOK) {
    Write-Host 'REPORT COPIED TO CLIPBOARD.'
}
else {
    Write-Host 'CLIPBOARD COPY FAILED.'
}

Write-Host ''
Write-Host 'Paste the clipboard contents into ChatGPT.'
