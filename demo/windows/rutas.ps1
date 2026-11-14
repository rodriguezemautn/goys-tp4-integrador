<#
.SYNOPSIS
  Agrega (o quita con -Quitar) la ruta persistente hacia el laboratorio. Requiere administrador.
#>
#Requires -RunAsAdministrator
param([switch]$Quitar)

$existe = Get-NetRoute -DestinationPrefix '10.10.0.0/16' -ErrorAction SilentlyContinue

if ($Quitar) {
    if ($existe) { route -p delete 10.10.0.0 | Out-Null }
    Write-Host 'Ruta 10.10.0.0/16 quitada.'
} elseif ($existe) {
    Write-Host 'La ruta 10.10.0.0/16 ya existe.'
} else {
    route -p add 10.10.0.0 mask 255.255.0.0 192.168.56.2
}
Get-NetRoute -DestinationPrefix '10.10.0.0/16' -ErrorAction SilentlyContinue |
    Format-Table DestinationPrefix, NextHop, InterfaceAlias
