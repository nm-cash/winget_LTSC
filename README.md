# Windows 10/11 LTSC - Configurándole `winget`
Para los fanáticos de los sistemas minimalistas "out-of-the-box", las ediciones LTSC de Windows 10 y 11 son una solución perfecta. Ni bien desplegados, **vienen prácticamente sin software.**  Se trata de versiones de Windows que eliminan de la ecuación esa tarea rutinaria de "extirpar bloatware" de un sistema luego de instalar.  Estas versiones permiten reducir el proceso de instalación, que normalmente se compone de "Instalación → Des-instalación de Bloatware → Actualizaciones de Sistema → Fine-Tuning", descartando completamente el segundo paso descrito en dicha secuencia.
## 🔰 Ventajas de optar por LTSC
- Son sistemas "minimalistas". Servir un sistema virgen, al cual el usuario deba integrar selectivamente esos programas específicos que requiere a medida en que los vaya necesitando, **convierte al sistema en uno más _personalizable._** 
- El despliegue de cualquier sistema obtiene resultados mucho más prolijos. Es probable que incluso luego de hacer debloating, en el sistema quedasen "elementos huérfanos", u otros restantes inadvertidos que no eran tan obvios de eliminar, y que podrían estar ocupando lugar en forma innecesaria en nuestro sistema.
- Los sistemas que vienen con lo mínimo indispensables por defecto son más livianos, y su instalación inicial es más rápida. **Tratamos de aligerar un poco la tarea de "De-bloating" para enfocarnos más en el "Fine-Tuning". Obteniendo sistemas tallados a medida.**
## 🌐 ¿Qué son los gestores de paquetes en Windows, y cómo habilitar `winget` en Windows LTSC?
[`winget`](https://github.com/microsoft/winget-cli) es el gestor de paquetes via terminal que se utiliza en los sistemas Windows.  De manera similar a como lo hace un gestor de paquetes para sistemas UNIX, con `winget` podemos utilizar la terminal PowerShell de nuestro sistema para escribir comandos de terminal con argumentos → que busquen programas, desplieguen información o distintos datos acerca de esos programas, y finalmente que instalen/remuevan esos programas.

`winget` busca estos paquetes desde repositorios oficiales revisados por Microsoft. Esto hace que, relativamente, de entre los varios gestores de paquetes disponibles, sea este el "más oficial", o "más fiable", de ellos. Aún así caben mencionar los otros dos mayores contendientes en cuanto a gestores de paquetes alternativos que no se quedan atrás, que son [chocolatey](https://github.com/chocolatey/choco) y [scoop](https://github.com/ScoopInstaller/Scoop).

Los tres ofrecen lo mismo: posibilidad de escribir argumentos por línea de comandos mediante los cuales administrar programas en nuestro sistema. Tanto buscarlos en línea para instalarlos por esta vía, así como ver y administrar los que ya tenemos instalados. En general ofrecen un control granular y muy flexible sobre los programas disponibles y aquellos que nos interesarían incorporar a nuestro sistema. Por eso es tan interesante contar con un gestor de paquetes en LTSC.

Por defecto `winget` (ni sus contrapartes) vienen por defecto en LTSC. Pero es una herramienta indispensable para un power-user que quiera poblar su despliegue de Windows ligero y minimalista → con herramientas seleccionadas a medida.  Si queremos lograr una cheff-kiss edition de Windows como esta, tenemos que habilitarlo.

Por fortuna el proceso para instalar `winget` en LTSC es muy sencillo. Se debe inputar un comando en la PowerShell, estando la misma abierta con permisos de administrador.
```
wsreset -i
```
**Esto va a forzar la re-instalación de la tienda de Microsoft.** Lo cual va a ser necesario porque la misma es la única manera viable a largo plazo para obtener las librerías y dependencias necesarias para usar `winget`. Una vez ejecutado el comando, hay que esperar hasta que aparezca una notificación pop-up que indique que "La tienda ha sido instalada". Luego de esto, instalar el '[Instalador de aplicaciones](https://apps.microsoft.com/detail/9nblggh4nns1)', que incluye `winget` y permite la instalación de paquetes en formato `*.appx` como los que `winget` usa.

Eso es todo. Diviértete con tu 'Minimal Windows' personalizable a medida.
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

-----
Finalmente acabé por descartarlo:
- Porque le había dedicado suficiente tiempo.
- Porque era mucho más rápido y fluido pasar por la tienda para llegar a `winget` que seguir trastabillando con un script.
- El acercamiento por enlaces eventualmente se va a romper. La manera "future-proof" de hacer esto **_es por medio de la tienda._**

Microsoft ha declarado que los enlaces de descarga para VC Libs que los scripts usan están deprecados. Y que llegados a cierto punto estas librerías van a ser obtenibles exclusivamente como componentes empaquetados con aplicaciones de la tienda, como Visual Code o el mismo '[Instalador de paquetes](https://apps.microsoft.com/detail/9nblggh4nns1)'. En el futuro, va a ser necesario pasar por la tienda sí o sí. Más vale hacerlo antes. A día de hoy no parecen existir desventajas en instalarlo con `wsreset -i`.

En caso de querer intentar hacer pruebas con este script, se puede usar su RAW como enlace a invocar de la misma manera que se demuestra como ejemplo con el script original, reemplazando el enlace.
