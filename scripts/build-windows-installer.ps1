param(
    [string]$ApiBaseUrl = "http://localhost:3000/api/v1"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$RepoRoot = Split-Path -Parent $PSScriptRoot
$FrontendRoot = Join-Path $RepoRoot "frontend"
$FlutterWrapper = Join-Path $PSScriptRoot "flutter.ps1"
$FlutterExecutable = $null
if (-not (Test-Path -LiteralPath $FlutterWrapper -PathType Leaf)) {
    $FlutterCommand = Get-Command flutter -ErrorAction SilentlyContinue
    if (-not $FlutterCommand) {
        throw "Flutter was not found. Install Flutter and add it to PATH."
    }
    $FlutterExecutable = $FlutterCommand.Source
}
$ReleaseDir = Join-Path $FrontendRoot "build\windows\x64\runner\Release"
$AppExe = Join-Path $ReleaseDir "ReactionPro.exe"
$InstallerDir = Join-Path $FrontendRoot "windows\installer"
$InstallerScript = Join-Path $InstallerDir "ReactionPro.iss"
$PrerequisiteDir = Join-Path $InstallerDir "prerequisites"
$VcRedist = Join-Path $PrerequisiteDir "VC_redist.x64.exe"
$VcRedistUrl = "https://download.visualstudio.microsoft.com/download/pr/ebdab8e5-1d7b-4d9f-a11b-cbb1720c3b12/843068991DAAA1F73AD9F6239BCE4D0F6A07A51F18C37EA2A867E9BECA71295C/VC_redist.x64.exe"
$VcRedistSha256 = "843068991DAAA1F73AD9F6239BCE4D0F6A07A51F18C37EA2A867E9BECA71295C"
$OutputFile = Join-Path $RepoRoot "dist\ReactionPro-Setup-x64-1.0.0.exe"

function Invoke-Flutter {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments,

        [Parameter(Mandatory = $true)]
        [string]$Operation
    )

    if (Test-Path -LiteralPath $FlutterWrapper -PathType Leaf) {
        & $FlutterWrapper @Arguments
    }
    else {
        & $FlutterExecutable @Arguments
    }

    if ($LASTEXITCODE -ne 0) {
        throw "$Operation failed with exit code $LASTEXITCODE."
    }
}

$RunningBuildProcesses = Get-CimInstance Win32_Process | Where-Object {
    $_.Name -in @("ReactionPro.exe", "reaction_time_test.exe") -and
    $_.ExecutablePath -and
    $_.ExecutablePath.StartsWith($ReleaseDir, [System.StringComparison]::OrdinalIgnoreCase)
}
foreach ($Process in $RunningBuildProcesses) {
    Write-Host "Stopping build copy $($Process.Name) (PID $($Process.ProcessId))..."
    Stop-Process -Id $Process.ProcessId -Force
}

Write-Host "Building ReactionPro Windows release..."
Push-Location $FrontendRoot
try {
    Invoke-Flutter -Arguments @("clean") -Operation "Flutter clean"
    Invoke-Flutter -Arguments @(
        "build",
        "windows",
        "--release",
        "--dart-define=API_BASE_URL=$ApiBaseUrl"
    ) -Operation "Flutter Windows build"
}
finally {
    Pop-Location
}

if (-not (Test-Path -LiteralPath $AppExe -PathType Leaf)) {
    throw "Windows release executable was not produced at $AppExe."
}

New-Item -ItemType Directory -Force -Path $PrerequisiteDir | Out-Null
if (Test-Path -LiteralPath $VcRedist -PathType Leaf) {
    $CachedHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $VcRedist).Hash
    if ($CachedHash -ne $VcRedistSha256) {
        Remove-Item -LiteralPath $VcRedist -Force
    }
}
if (-not (Test-Path -LiteralPath $VcRedist -PathType Leaf)) {
    Write-Host "Downloading the Microsoft Visual C++ x64 runtime..."
    Invoke-WebRequest `
        -UseBasicParsing `
        -Uri $VcRedistUrl `
        -OutFile $VcRedist
}

$DownloadedHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $VcRedist).Hash
if ($DownloadedHash -ne $VcRedistSha256) {
    throw "The downloaded Visual C++ runtime does not match its published SHA256 hash."
}

$Signature = Get-AuthenticodeSignature -LiteralPath $VcRedist
if ($Signature.Status -ne "Valid" -or
    $Signature.SignerCertificate.Subject -notlike "*Microsoft Corporation*") {
    throw "The downloaded Visual C++ runtime does not have a valid Microsoft signature."
}

$IsccCandidates = @(
    (Join-Path $env:LOCALAPPDATA "Programs\Inno Setup 7\ISCC.exe"),
    (Join-Path $env:LOCALAPPDATA "Programs\Inno Setup 6\ISCC.exe"),
    (Join-Path ${env:ProgramFiles(x86)} "Inno Setup 7\ISCC.exe"),
    (Join-Path ${env:ProgramFiles(x86)} "Inno Setup 6\ISCC.exe"),
    (Join-Path $env:ProgramFiles "Inno Setup 7\ISCC.exe"),
    (Join-Path $env:ProgramFiles "Inno Setup 6\ISCC.exe")
)
$Iscc = $IsccCandidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
if (-not $Iscc) {
    throw "Inno Setup is required. Install it with: winget install --id JRSoftware.InnoSetup --exact"
}

Write-Host "Compiling the ReactionPro installer..."
& $Iscc $InstallerScript
if ($LASTEXITCODE -ne 0) {
    throw "Inno Setup failed with exit code $LASTEXITCODE."
}

if (-not (Test-Path -LiteralPath $OutputFile -PathType Leaf)) {
    throw "Installer was not produced at $OutputFile."
}

$Installer = Get-Item -LiteralPath $OutputFile
$Hash = Get-FileHash -Algorithm SHA256 -LiteralPath $OutputFile
Write-Host "Installer: $($Installer.FullName)"
Write-Host "Size: $([math]::Round($Installer.Length / 1MB, 2)) MB"
Write-Host "SHA256: $($Hash.Hash)"
