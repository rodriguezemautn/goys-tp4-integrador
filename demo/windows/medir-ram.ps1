<#
.SYNOPSIS
  Mide la RAM de Windows con el laboratorio levantado y decide si alcanza el perfil actual.
  Correrlo con Grafana abierto, Wireshark capturando y Claude abierto.
#>
param(
    [int]$Minutos = 10,
    [int]$IntervaloSegundos = 5,
    [int]$UmbralPorciento = 85
)

$ErrorActionPreference = 'Stop'
$demo = Split-Path -Parent $PSScriptRoot
$vbox = Join-Path $env:ProgramFiles 'Oracle\VirtualBox\VBoxManage.exe'
$descargas = Join-Path $demo '.descargas'
New-Item -ItemType Directory -Force -Path $descargas | Out-Null
$csv = Join-Path $descargas ("ram-{0:yyyyMMdd-HHmm}.csv" -f (Get-Date))

function TopProcesos {
    Get-Process | Group-Object ProcessName | ForEach-Object {
        [pscustomobject]@{
            Proceso = $_.Name
            MB      = [math]::Round(($_.Group | Measure-Object WS -Sum).Sum / 1MB)
        }
    } | Sort-Object MB -Descending | Select-Object -First 10
}

$vms = @(& $vbox list runningvms)
Write-Host "VMs encendidas: $($vms.Count)"
$vms | ForEach-Object { Write-Host "  $_" }
if ($vms.Count -lt 4) {
    Write-Warning 'Se esperaban 4 VMs (3 nodos k3s y el CHR): la medición va a dar de menos.'
}

$pico = -1.0
$sumaUso = 0.0
$muestras = 0
$topPico = $null
$fin = (Get-Date).AddMinutes($Minutos)
Write-Host "Midiendo durante $Minutos minutos..."

while ((Get-Date) -lt $fin) {
    $so = Get-CimInstance Win32_OperatingSystem
    $totalGB = $so.TotalVisibleMemorySize / 1MB
    $libreGB = $so.FreePhysicalMemory / 1MB
    $uso = [math]::Round(100 * ($totalGB - $libreGB) / $totalGB, 1)
    $commit = [math]::Round(100 * ($so.TotalVirtualMemorySize - $so.FreeVirtualMemory) / $so.TotalVirtualMemorySize, 1)

    [pscustomobject]@{
        Hora       = (Get-Date).ToString('HH:mm:ss')
        UsoPct     = $uso
        LibreGB    = [math]::Round($libreGB, 2)
        CommitPct  = $commit
    } | Export-Csv -Path $csv -Append -NoTypeInformation -Encoding UTF8

    $sumaUso += $uso
    $muestras++
    if ($uso -gt $pico) {
        $pico = $uso
        $topPico = TopProcesos
    }
    Write-Progress -Activity 'Midiendo RAM' -Status "Uso $uso % | pico $pico %" `
        -SecondsRemaining ([int]($fin - (Get-Date)).TotalSeconds)
    Start-Sleep -Seconds $IntervaloSegundos
}
Write-Progress -Activity 'Midiendo RAM' -Completed

$promedio = [math]::Round($sumaUso / $muestras, 1)
Write-Host "`nMuestras: $muestras | promedio: $promedio % | pico: $pico % | umbral: $UmbralPorciento %"
Write-Host 'Procesos con más RAM en el pico:'
$topPico | Format-Table -AutoSize | Out-String | Write-Host
Write-Host "Detalle: $csv"

if ($pico -lt $UmbralPorciento) {
    Write-Host "DECISIÓN: el pico queda debajo de $UmbralPorciento %, se sigue con este perfil." -ForegroundColor Green
    exit 0
}
Write-Host "DECISIÓN: el pico supera $UmbralPorciento %. Cerrá programas o bajá RAM, y volvé a medir." -ForegroundColor Red
exit 1
