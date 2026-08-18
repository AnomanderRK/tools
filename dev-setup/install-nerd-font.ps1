# install-nerd-font.ps1
# Run this ONCE from PowerShell (as your user, not admin) to install
# JetBrainsMono Nerd Font so Neovim icons render correctly.
#
# How to run:
#   1. Open PowerShell (Windows, not WSL)
#   2. Run: Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
#   3. Run: ~\install-nerd-font.ps1

$ErrorActionPreference = "Stop"
$releaseUrl = "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
$tmpZip     = "$env:TEMP\JetBrainsMono.zip"
$tmpDir     = "$env:TEMP\JetBrainsMono"
$fontsDir   = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts"

Write-Host "Downloading JetBrainsMono Nerd Font..." -ForegroundColor Cyan
Invoke-WebRequest -Uri $releaseUrl -OutFile $tmpZip -UseBasicParsing

Write-Host "Extracting..." -ForegroundColor Cyan
Expand-Archive -Path $tmpZip -DestinationPath $tmpDir -Force

New-Item -ItemType Directory -Force -Path $fontsDir | Out-Null
$shell = New-Object -ComObject Shell.Application
$fontsFolder = $shell.Namespace(0x14)

Get-ChildItem "$tmpDir\*.ttf" | Where-Object { $_.Name -notmatch "Windows Compatible" } | ForEach-Object {
    $dest = Join-Path $fontsDir $_.Name
    if (-not (Test-Path $dest)) {
        Copy-Item $_.FullName $dest
        $fontsFolder.CopyHere($_.FullName, 0x10)
        Write-Host "  Installed: $($_.Name)" -ForegroundColor Green
    } else {
        Write-Host "  Already installed: $($_.Name)" -ForegroundColor DarkGray
    }
}

# Register fonts in the registry (per-user)
$regPath = "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts"
Get-ChildItem "$tmpDir\*.ttf" | Where-Object { $_.Name -notmatch "Windows Compatible" } | ForEach-Object {
    $fontEntry = $_.BaseName + " (TrueType)"
    $fontFile  = Join-Path $fontsDir $_.Name
    Set-ItemProperty -Path $regPath -Name $fontEntry -Value $fontFile -ErrorAction SilentlyContinue
}

Remove-Item $tmpZip, $tmpDir -Recurse -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "Done! Now:" -ForegroundColor Green
Write-Host "  1. Open Windows Terminal settings" -ForegroundColor White
Write-Host "  2. Go to your WSL profile -> Appearance -> Font face" -ForegroundColor White
Write-Host "  3. Set it to: JetBrainsMono Nerd Font Mono" -ForegroundColor Cyan
Write-Host "  4. Restart the terminal" -ForegroundColor White
