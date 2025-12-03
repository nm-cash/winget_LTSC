## 🧑‍💻 Intentos previos fallidos...
Aunque existen métodos de tipo script para integrar al gestor de paquetes sin pasar por la tienda, estos scripts eventualmente se van a quedar obsoletos, y a largo plazo es más sencillo utilizar `wsreset -i`.
En mis intentos, me basé sobre [un repositorio Github de hace algunos años.](https://github.com/SasaDermanovic/2024-Winget-Setup-Guide-Windows-10-LTSC)
Este script realizaba lo siguiente:
1. Buscaba e instalaba VC Libs, las librerías Visual Code Studio necesarias.
2. Buscaba e instalaba Microsoft.UI.Xaml 2.8, dependencias necesarias.
3. Buscaba e instalaba `winget` con su licencia `*_License1.xml`.

Intenté re-ajustar el script para que siempre buscase la paquetería más reciente. En especial porque `winget` y `xaml` habían quedado "congelados" en el tiempo en que se escribió el script original, hacia mitad de 2024. La manera de funcionar era que buscaba enlaces web específicos donde estaban las librerías y dependencias alojadas. Desde la fecha en la que fue escrito hubieron muchas versiones posteriores de `winget` y `xaml` publicadas, y los enlaces de referencia scripteados originalmente se quedaron iguales. Esto resulta en la instalación de versiones obsoletas de los paquetes, que luego tienen que ser actualizadas por sistema y usando `winget upgrade --all`.

```powershell
# 1. Habilitar la ejecución de scripts en la PowerShell.
Set-ExecutionPolicy RemoteSigned

# 2. Llamado al script mencionado, hosteado en su repositorio.
Invoke-Expression (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/SasaDermanovic/2024-Winget-Setup-Guide-Windows-10-LTSC/refs/heads/main/Winget_LTSC_Installer.ps1").Content
```

Comprobé que es posible correr este script → reiniciar el equipo → buscar en el escritorio el paquete desempaquetado en la instalación, "instalador de paquetes" → darle doble click para re-instalarlo, porque la primer instalación por terminal a veces viene rota → llegando finalmente así a winget _desactualizado_ funcionando en mí sistema (sí, es una instalación muy rara). Luego podría dar `winget upgrade --all`, y asegurarme de que todos los paquetes desactualizados se actualicen.

Y si bien eso "funciona", me pareció buena idea intentar con un script que desde el vamos tuviese la posibilidad de obtener los paquetes más actuales cuando sea que sea ejecutado. Terminé llegando a lo siguiente...
```powershell
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
```
Aparenta funcionar, porque ejecuta completo sin mostrar errores en su output. Pero este script reconfigurado misteriosamente no funcionó. Eres libre de comprobarlo si te interesa. Desistí de probarlo más en profundidad. Sospecho que la causa radica en parte sobre que apagué varios servicios de mí sistema que no necesitaba para el uso que le iba a dar luego de instalar. Y esto podría haber vuelto a mi sistema incompatible con el script. El script original fue probado en condiciones diferentes, con un sistema recién instalado y sin apagar nada.
Finalmente acabé por descartarlo:
- Porque le había dedicado suficiente tiempo.
- Porque era mucho más rápido y fluido pasar por la tienda para llegar a `winget` que seguir trastabillando con un script.
- El acercamiento por enlaces eventualmente se va a romper. La manera "future-proof" de hacer esto **_es por medio de la tienda._**

Microsoft ha declarado que los enlaces de descarga para VC Libs que los scripts usan están deprecados. Y que llegados a cierto punto estas librerías van a ser obtenibles exclusivamente como componentes empaquetados con aplicaciones de la tienda, como Visual Code o el mismo '[Instalador de paquetes](https://apps.microsoft.com/detail/9nblggh4nns1)'. En el futuro, va a ser necesario pasar por la tienda sí o sí. Más vale hacerlo antes. A día de hoy no parecen existir desventajas en instalarlo con `wsreset -i`.

En caso de querer intentar hacer pruebas con este script, se puede usar su RAW como enlace a invocar de la misma manera que se demuestra como ejemplo con el script original, reemplazando el enlace.
