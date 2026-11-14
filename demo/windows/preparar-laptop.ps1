<#
.SYNOPSIS
  Revisa los requisitos de la laptop y genera la clave SSH del laboratorio.
.PARAMETER CarpetaVMs
  Opcional. Cambia en VirtualBox la carpeta por defecto de las VMs nuevas (por ejemplo D:\VMs).
  Las VMs que ya existen no se mueven.
#>
param([string]$CarpetaVMs)

$ErrorActionPreference = 'Stop'
$demo = Split-Path -Parent $PSScriptRoot
$vbox = Join-Path $env:ProgramFiles 'Oracle\VirtualBox\VBoxManage.exe'
$problemas = 0

function Informar([string]$estado, [string]$texto) {
    $color = @{ OK = 'Green'; AVISO = 'Yellow'; FALTA = 'Red' }[$estado]
    Write-Host ('[{0,-5}] {1}' -f $estado, $texto) -ForegroundColor $color
    if ($estado -eq 'FALTA') { $script:problemas++ }
}

if (Test-Path $vbox) {
    Informar OK "VirtualBox $(& $vbox --version)"
} else {
    Informar FALTA 'VirtualBox 7 no está instalado'
}

if (Get-Command vagrant -ErrorAction SilentlyContinue) {
    Informar OK (& vagrant --version)
} else {
    Informar FALTA 'Vagrant no está instalado: https://developer.hashicorp.com/vagrant/install'
}

if (-not (Get-Command ssh-keygen -ErrorAction SilentlyContinue)) {
    Informar FALTA 'ssh-keygen no está disponible (cliente OpenSSH de Windows)'
}

$so = Get-CimInstance Win32_OperatingSystem
$ramTotal = [math]::Round($so.TotalVisibleMemorySize / 1MB, 1)
$ramLibre = [math]::Round($so.FreePhysicalMemory / 1MB, 1)
if ($ramTotal -ge 7.5) {
    Informar OK "RAM: $ramTotal GB en total, $ramLibre GB libres"
} else {
    Informar FALTA "RAM: $ramTotal GB; el perfil chico necesita una laptop de 8 GB"
}

if ($CarpetaVMs -and (Test-Path $vbox)) {
    New-Item -ItemType Directory -Force -Path $CarpetaVMs | Out-Null
    & $vbox setproperty machinefolder $CarpetaVMs
    Informar OK "Carpeta de VMs nuevas: $CarpetaVMs"
}

$carpeta = (& $vbox list systemproperties | Select-String 'Default machine folder:').ToString().Split(':', 2)[1].Trim()
$unidad = (Split-Path -Qualifier $carpeta).TrimEnd(':')
$libre = [math]::Round((Get-PSDrive $unidad).Free / 1GB, 1)
if ($libre -ge 20) {
    Informar OK "Disco de las VMs ($carpeta): $libre GB libres"
} else {
    Informar FALTA "Disco de las VMs ($carpeta): $libre GB libres; hacen falta 20 GB. Usá -CarpetaVMs D:\VMs"
}

$sc = Get-CimInstance Win32_ComputerSystem
if ($sc.HypervisorPresent) {
    Informar AVISO 'Hay un hipervisor activo (Hyper-V, WSL2 o Integridad de memoria): VirtualBox anda más lento'
}

$wsl = (& wsl.exe --list --running 2>$null) -join ''
if ($LASTEXITCODE -eq 0 -and $wsl) {
    Informar AVISO 'WSL2 está corriendo: ejecutá wsl --shutdown antes de levantar el laboratorio'
}
if (Get-Process 'Docker Desktop' -ErrorAction SilentlyContinue) {
    Informar AVISO 'Docker Desktop está abierto: cerralo antes de levantar el laboratorio'
}

$claves = Join-Path $demo '.claves'
$clave = Join-Path $claves 'lab_ed25519'
New-Item -ItemType Directory -Force -Path $claves | Out-Null
if (Test-Path $clave) {
    Informar OK 'La clave SSH del laboratorio ya existe'
} else {
    # En PowerShell 5.1 una cadena vacía no llega al ejecutable: hay que pasarla con comillas.
    & ssh-keygen -q -t ed25519 -N '""' -C 'lab-tp4' -f $clave
    if ($LASTEXITCODE -ne 0) { throw 'ssh-keygen falló' }
    Informar OK "Clave SSH generada en $clave"
}

if ($problemas -gt 0) {
    Write-Host "`nHay $problemas requisito(s) sin cumplir." -ForegroundColor Red
    exit 1
}
Write-Host "`nListo: seguí con vagrant up en la carpeta demo." -ForegroundColor Green
