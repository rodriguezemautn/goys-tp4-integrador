<#
.SYNOPSIS
  Un pedido cada 0,2 s desde la laptop e informe de las rachas de errores. Ctrl+C no informa: usar -Segundos.
#>
param(
    [string]$Url = 'http://10.10.20.10/',
    [int]$Segundos = 120
)

Add-Type -AssemblyName System.Net.Http
$cliente = New-Object System.Net.Http.HttpClient
$cliente.Timeout = [TimeSpan]::FromSeconds(1)

$total = 0
$errores = 0
$rachas = New-Object System.Collections.ArrayList
$racha = $null
$inicio = Get-Date
$fin = $inicio.AddSeconds($Segundos)

Write-Host "Midiendo $Url durante $Segundos s..."
while ((Get-Date) -lt $fin) {
    $total++
    $bien = $false
    try {
        $respuesta = $cliente.GetAsync($Url).GetAwaiter().GetResult()
        $bien = $respuesta.IsSuccessStatusCode
        $respuesta.Dispose()
    } catch {
        $bien = $false
    }

    if ($bien) {
        if ($racha) {
            $racha.Fin = Get-Date
            [void]$rachas.Add($racha)
            $racha = $null
        }
    } else {
        $errores++
        if (-not $racha) {
            $racha = [pscustomobject]@{ Inicio = Get-Date; Fin = $null; Errores = 0 }
        }
        $racha.Errores++
    }
    Start-Sleep -Milliseconds 200
}
if ($racha) {
    $racha.Fin = Get-Date
    [void]$rachas.Add($racha)
}
$cliente.Dispose()

Write-Host "`nPedidos: $total | errores: $errores"
if ($rachas.Count -eq 0) {
    Write-Host 'Sin errores' -ForegroundColor Green
} else {
    Write-Host 'Rachas de errores:' -ForegroundColor Yellow
    foreach ($r in $rachas) {
        '  a los {0:N0} s: {1} errores en {2:N1} s' -f ($r.Inicio - $inicio).TotalSeconds, $r.Errores, ($r.Fin - $r.Inicio).TotalSeconds
    }
}
