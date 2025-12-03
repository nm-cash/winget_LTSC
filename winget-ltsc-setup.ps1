# ==============================================
# Winget Setup Script for Windows 10 LTSC
# Enhanced version based on Sasa Dermanovic's work
# ==============================================

# 1. Check for Administrator privileges

$IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $IsAdmin) {
Write-Host "[ERROR] Este script debe ser ejecutado como administrador." -ForegroundColor Red
Read-Host "Presione [Enter] para salir..."
exit 1
}

Write-Host "[INFO] Lanzando LTSC setup script..." -ForegroundColor Cyan

# 1.1 Forces use of TLS 1.2 for all downloads.
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# 2. Detect system architecture
$systemType = (Get-CimInstance -ClassName Win32_ComputerSystem).SystemType.ToLower()

switch -Wildcard ($systemType) {
"*x86*" { $arch = "x86"; break }
"*x64*" { $arch = "x64"; break }
"*arm64*" { $arch = "arm64"; break }
"*arm*" { $arch = "arm"; break }
default { Write-Host "[!] Arquitectura no reconocida: $systemType" -ForegroundColor Red; exit 1 }
}
Write-Host "[*] Arquitectura detectada: $arch" -ForegroundColor Cyan

# 3. Function to get latest GitHub release asset
function Get-Latest-GitHub-Release-Asset {
param(
[string]$Repo,
[string]$AssetPattern
)
try {
$apiUrl = "https://api.github.com/repos/$Repo/releases/latest"
$release = Invoke-RestMethod -Uri $apiUrl -UseBasicParsing
$asset = $release.assets | Where-Object { $_.name -like $AssetPattern } | Select-Object -First 1
if ($asset) { return $asset } else { return $null }
} catch { return $null }
}

# 4. Install VCLibs
try {
Add-AppxPackage "https://aka.ms/Microsoft.VCLibs.$arch.14.00.Desktop.appx" -Verbose
}
catch {
Write-Host "Failed to install VCLibs package. Error: $_" -ForegroundColor Red
exit 1
}
  
# 5. Install Microsoft.UI.Xaml
$xamlVersion = "2.8.7"
try {
$ProgressPreference = 'SilentlyContinue'
Invoke-WebRequest -Uri "https://www.nuget.org/api/v2/package/Microsoft.UI.Xaml/$xamlVersion" -OutFile "microsoft.ui.xaml.$xamlVersion.zip" -ErrorAction Stop
}
catch {
Write-Host "Failed to download XAML package. Error: $_" -ForegroundColor Red
exit 1
}

 
try {
Expand-Archive .\microsoft.ui.xaml.$xamlVersion.zip -Force -ErrorAction Stop
}
catch {
Write-Host "Failed to extract XAML package. Error: $_" -ForegroundColor Red
exit 1
}

 
try {
Add-AppPackage .\microsoft.ui.xaml.$xamlVersion\tools\AppX\$arch\Release\Microsoft.UI.Xaml.2.8.appx -Verbose
}
catch {
Write-Host "Failed to install XAML package. Error: $_" -ForegroundColor Red
exit 1
}
  
Write-Host "Dependencies installed successfully." -ForegroundColor Green
  
# 6. Install Winget (latest release)
$wingetAsset = Get-Latest-GitHub-Release-Asset -Repo "microsoft/winget-cli" -AssetPattern "*.msixbundle"
$licenseAsset = Get-Latest-GitHub-Release-Asset -Repo "microsoft/winget-cli" -AssetPattern "*_License1.xml"

if (-not $wingetAsset -or -not $licenseAsset) {
Write-Host "[ERROR] No se pudo encontrar la última versión de Winget" -ForegroundColor Red
exit 1
}

try {
$ProgressPreference = 'SilentlyContinue'
Invoke-WebRequest -Uri $wingetAsset.browser_download_url -OutFile $wingetAsset.name -ErrorAction Stop
Invoke-WebRequest -Uri $licenseAsset.browser_download_url -OutFile $licenseAsset.name -ErrorAction Stop
}
catch {
Write-Host "Failed to download Winget package. Error: $_" -ForegroundColor Red
exit 1
}

try {
Add-AppxProvisionedPackage -Online -PackagePath (Resolve-Path $wingetAsset.name) -LicensePath (Resolve-Path $licenseAsset.name) -Verbose
}
catch {
Write-Host "Failed to install Winget package. Error: $_" -ForegroundColor Red
exit 1
}

Write-Host "Winget installed successfully." -ForegroundColor Green
