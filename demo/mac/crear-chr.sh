#!/usr/bin/env bash
# Baja la última RouterOS v7 estable y crea la VM tp4-chr (256 MB, NIC 1 host-only, NIC 2 intnet).
# Detecta Intel o Apple Silicon: cambian la imagen, el disco y el tipo de red host-only.
# Uso: bash mac/crear-chr.sh
set -euo pipefail

NOMBRE=tp4-chr
RED_APPLE=lab-clientes

demo="$(cd "$(dirname "$0")/.." && pwd)"
descargas="$demo/.descargas"
mkdir -p "$descargas"

if VBoxManage list vms | grep -q "^\"$NOMBRE\""; then
  echo "La VM $NOMBRE ya existe: no se toca."
  exit 0
fi

version=$(curl -fsSL https://upgrade.mikrotik.com/routeros/NEWESTa7.stable | awk '{print $1}')
case "$version" in
  7.*) echo "Última RouterOS v7 estable: $version" ;;
  *) echo "Versión inesperada de RouterOS: $version" >&2; exit 1 ;;
esac

arquitectura=$(uname -m)
sufijo=""
if [ "$arquitectura" = "arm64" ]; then sufijo="-arm64"; fi

base="chr-$version$sufijo"
if [ ! -f "$descargas/$base.vdi" ]; then
  if [ ! -f "$descargas/$base.vdi.zip" ]; then
    curl -fL -o "$descargas/$base.vdi.zip" "https://download.mikrotik.com/routeros/$version/$base.vdi.zip"
  fi
  unzip -o -q "$descargas/$base.vdi.zip" -d "$descargas"
fi
vdi="$descargas/$base.vdi"
[ -f "$vdi" ] || { echo "No encontré $vdi dentro del zip" >&2; exit 1; }

if [ "$arquitectura" = "arm64" ]; then
  # En Apple Silicon no hay vboxnet: se usa una red host-only de vmnet, y no hay disco IDE.
  if ! VBoxManage list hostonlynets | grep -q "$RED_APPLE"; then
    VBoxManage hostonlynet add --name="$RED_APPLE" --netmask=255.255.255.0 \
      --lower-ip=192.168.56.1 --upper-ip=192.168.56.199 --enable
  fi
  tipos=$(VBoxManage list --platform-arch=arm ostypes)
  os=$(printf '%s\n' "$tipos" | awk '/^ID:/ && $2 ~ /^Linux.*arm64$/ {print $2; exit}')
  VBoxManage createvm --name="$NOMBRE" --platform-architecture=arm --ostype="${os:-Linux_arm64}" --register
  VBoxManage modifyvm "$NOMBRE" --memory=256 --cpus=1 --firmware=efi --audio-driver=none \
    --nic1=hostonlynet --host-only-net1="$RED_APPLE" --nic-type1=virtio \
    --nic2=intnet --intnet2=lab-cluster --nic-type2=virtio
  VBoxManage storagectl "$NOMBRE" --name=VirtioSCSI --add=virtio --controller=VirtIO
  VBoxManage storageattach "$NOMBRE" --storagectl=VirtioSCSI --port=0 --device=0 --type=hdd --medium="$vdi"
else
  adaptador=$(VBoxManage list hostonlyifs | awk '
    /^Name:/ {nombre = $2}
    /^IPAddress:/ && $2 == "192.168.56.1" {print nombre; exit}')
  if [ -z "$adaptador" ]; then
    salida=$(VBoxManage hostonlyif create)
    adaptador=$(printf '%s\n' "$salida" | sed -n "s/.*'\(vboxnet[0-9]*\)'.*/\1/p")
    VBoxManage hostonlyif ipconfig "$adaptador" --ip 192.168.56.1 --netmask 255.255.255.0
    VBoxManage dhcpserver add --network="HostInterfaceNetworking-$adaptador" --server-ip=192.168.56.100 \
      --netmask=255.255.255.0 --lower-ip=192.168.56.101 --upper-ip=192.168.56.254 --enable
  fi
  VBoxManage createvm --name="$NOMBRE" --ostype=Linux26_64 --register
  VBoxManage modifyvm "$NOMBRE" --memory=256 --cpus=1 --audio-driver=none \
    --nic1=hostonly --host-only-adapter1="$adaptador" \
    --nic2=intnet --intnet2=lab-cluster
  VBoxManage storagectl "$NOMBRE" --name=IDE --add=ide --controller=PIIX4
  VBoxManage storageattach "$NOMBRE" --storagectl=IDE --port=0 --device=0 --type=hdd --medium="$vdi"
fi

VBoxManage startvm "$NOMBRE" --type=gui

cat <<EOF

VM $NOMBRE creada y encendida. En su consola:
  1. Usuario admin, sin clave; definí una clave nueva.
  2. /ip address print  para ver la IP que tomó por DHCP.

En el Mac, revisá que la IP en esa red sea 192.168.56.1:
  ifconfig | grep 'inet 192.168.56.'
Si es otra, cambiá 192.168.56.1 por esa IP en la copia temporal de routeros/chr-borde.rsc.

Después importá el .rsc (ver "En Mac" en demo/README.md).
EOF
