# Crea la VM de la estacion de monitoreo en VirtualBox (Windows, PowerShell).
# Uso:  powershell -ExecutionPolicy Bypass -File demo\estacion\crear-vm.ps1 -Iso "C:\ruta\ubuntu-24.04.5-live-server-amd64.iso"
#
# Placa 1: tunel UDP hacia la nube ESTACION de GNS3 (puertos 45001 -> 45000), cableada a SW-SERVERS.
# Placa 2: NAT de VirtualBox, para Internet y para entrar desde Windows:
#          SSH 127.0.0.1:2222, Grafana 127.0.0.1:3000, Prometheus 127.0.0.1:9090.
param(
  [Parameter(Mandatory = $true)] [string] $Iso,
  [string] $Nombre = "ESTACION-TP4",
  [string] $Carpeta = "$env:USERPROFILE\VirtualBox VMs",   # la VM de Santiago esta en D:\VirtualBox VMs
  [int] $RamMB = 2048
)
$ErrorActionPreference = "Stop"
$vbm = "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"
$vdi = Join-Path $Carpeta "$Nombre\$Nombre.vdi"

& $vbm createvm --name $Nombre --ostype Ubuntu_64 --basefolder $Carpeta --register
& $vbm modifyvm $Nombre --memory $RamMB --cpus 2 --vram 16 --graphicscontroller vmsvga `
  --boot1 dvd --boot2 disk --boot3 none --boot4 none --uart1 off `
  --nic1 generic --nictype1 82540EM --nicgenericdrv1 UDPTunnel --cableconnected1 on `
  --nic2 nat --nictype2 82540EM --cableconnected2 on `
  --natpf2 "ssh,tcp,127.0.0.1,2222,,22" `
  --natpf2 "grafana,tcp,127.0.0.1,3000,,3000" `
  --natpf2 "prometheus,tcp,127.0.0.1,9090,,9090"
& $vbm modifyvm $Nombre --nicproperty1 dest=127.0.0.1 --nicproperty1 sport=45001 --nicproperty1 dport=45000
& $vbm createmedium disk --filename $vdi --size 20480 --format VDI
& $vbm storagectl $Nombre --name SATA --add sata --controller IntelAhci --portcount 2
& $vbm storageattach $Nombre --storagectl SATA --port 0 --device 0 --type hdd --medium $vdi
& $vbm storageattach $Nombre --storagectl SATA --port 1 --device 0 --type dvddrive --medium $Iso

Write-Host "VM $Nombre creada. Iniciala desde VirtualBox para instalar Ubuntu Server (ver runbook)."
