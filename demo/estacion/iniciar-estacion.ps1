# Arranca la estacion sin ventana y espera a que responda por SSH.
# Uso:  powershell -ExecutionPolicy Bypass -File demo\estacion\iniciar-estacion.ps1
# Antes: abrir el proyecto TP4-SistemaInmune en GNS3 (la nube ESTACION escucha en el puerto UDP 45000).
param([string] $Nombre = "ESTACION-TP4", [string] $Llave = "$env:USERPROFILE\.ssh\goys_estacion")
$vbm = "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"

$estado = (& $vbm showvminfo $Nombre --machinereadable | Select-String '^VMState=').Line
if ($estado -notmatch '"running"') { & $vbm startvm $Nombre --type headless | Out-Null }

Write-Host "Esperando SSH en 127.0.0.1:2222 ..."
for ($i = 0; $i -lt 30; $i++) {
  ssh -i $Llave -p 2222 -o BatchMode=yes -o ConnectTimeout=5 goys@127.0.0.1 "true" 2>$null
  if ($LASTEXITCODE -eq 0) { break }
}
ssh -i $Llave -p 2222 -o BatchMode=yes goys@127.0.0.1 "ip -br a show enp0s3; ping -c 2 -W 2 10.20.0.1"
