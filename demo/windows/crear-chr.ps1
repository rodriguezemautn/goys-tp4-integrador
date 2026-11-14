<#
.SYNOPSIS
  Baja la última RouterOS v7 estable y crea la VM tp4-chr (256 MB, NIC 1 host-only, NIC 2 intnet).
#>
param(
    [string]$Nombre = 'tp4-chr',
    [string]$AdaptadorHostOnly = 'VirtualBox Host-Only Ethernet Adapter'
)

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$demo = Split-Path -Parent $PSScriptRoot
$vbox = Join-Path $env:ProgramFiles 'Oracle\VirtualBox\VBoxManage.exe'
$descargas = Join-Path $demo '.descargas'
New-Item -ItemType Directory -Force -Path $descargas | Out-Null

function VBox {
    & $vbox @args
    if ($LASTEXITCODE -ne 0) { throw "VBoxManage $($args -join ' ') falló" }
}

$existentes = & $vbox list vms
if ($existentes -match ('^"' + [regex]::Escape($Nombre) + '"')) {
    Write-Host "La VM $Nombre ya existe: no se toca."
    exit 0
}

$linea = (Invoke-WebRequest -UseBasicParsing 'https://upgrade.mikrotik.com/routeros/NEWESTa7.stable').Content
if ($linea -is [byte[]]) { $linea = [Text.Encoding]::ASCII.GetString($linea) }
$version = $linea.Trim().Split(' ')[0]
if ($version -notmatch '^7\.\d+(\.\d+)?$') { throw "Versión inesperada de RouterOS: $version" }
Write-Host "Última RouterOS v7 estable: $version"

$zip = Join-Path $descargas "chr-$version.vdi.zip"
$vdi = Join-Path $descargas "chr-$version.vdi"
if (-not (Test-Path $vdi)) {
    if (-not (Test-Path $zip)) {
        Invoke-WebRequest -UseBasicParsing "https://download.mikrotik.com/routeros/$version/chr-$version.vdi.zip" -OutFile $zip
    }
    Expand-Archive -Path $zip -DestinationPath $descargas -Force
}

VBox createvm --name $Nombre --ostype Linux26_64 --register
VBox modifyvm $Nombre --memory 256 --cpus 1 --audio-driver none `
    --nic1 hostonly --hostonlyadapter1 $AdaptadorHostOnly `
    --nic2 intnet --intnet2 lab-cluster
VBox storagectl $Nombre --name IDE --add ide
VBox storageattach $Nombre --storagectl IDE --port 0 --device 0 --type hdd --medium $vdi
VBox startvm $Nombre --type gui

Write-Host @"

VM $Nombre creada y encendida. En su consola:
  1. Usuario admin, sin clave; definí una clave nueva.
  2. /ip address print  para ver la IP que tomó por DHCP.
Después importá routeros\chr-borde.rsc (ver demo\README.md).
"@
