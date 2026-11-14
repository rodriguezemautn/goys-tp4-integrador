#!/usr/bin/env bash
# Revisa los requisitos del Mac y genera la clave SSH del laboratorio.
# Uso: bash mac/preparar-mac.sh [--carpeta-vms /ruta]
#   --carpeta-vms cambia en VirtualBox la carpeta de las VMs nuevas; las que ya existen no se mueven.
set -euo pipefail

demo="$(cd "$(dirname "$0")/.." && pwd)"
carpeta_vms=""
if [ "${1:-}" = "--carpeta-vms" ]; then
  carpeta_vms="${2:?Falta la ruta de --carpeta-vms}"
fi

problemas=0
informar() { # estado texto
  printf '[%-5s] %s\n' "$1" "$2"
  if [ "$1" = "FALTA" ]; then problemas=$((problemas + 1)); fi
}

if [ "$(uname -s)" != "Darwin" ]; then
  informar FALTA "Este script es para macOS"
fi

case "$(uname -m)" in
  arm64) informar AVISO "Apple Silicon: VirtualBox usa VMs ARM. Es la combinación menos probada; ver LEEME.md" ;;
  x86_64) informar OK "Mac con Intel" ;;
  *) informar FALTA "Arquitectura desconocida: $(uname -m)" ;;
esac

if command -v VBoxManage >/dev/null 2>&1; then
  informar OK "VirtualBox $(VBoxManage --version)"
else
  informar FALTA "VirtualBox 7 no está instalado: https://www.virtualbox.org/wiki/Downloads"
fi

if command -v vagrant >/dev/null 2>&1; then
  informar OK "$(vagrant --version)"
else
  informar FALTA "Vagrant no está instalado: https://developer.hashicorp.com/vagrant/install"
fi

if ! command -v ssh-keygen >/dev/null 2>&1; then
  informar FALTA "ssh-keygen no está disponible"
fi

ram_gb=$(($(sysctl -n hw.memsize) / 1073741824))
if [ "$ram_gb" -ge 8 ]; then
  informar OK "RAM: $ram_gb GB"
else
  informar FALTA "RAM: $ram_gb GB; el perfil chico necesita 8 GB"
fi

if command -v VBoxManage >/dev/null 2>&1; then
  if [ -n "$carpeta_vms" ]; then
    mkdir -p "$carpeta_vms"
    VBoxManage setproperty machinefolder "$carpeta_vms"
    informar OK "Carpeta de VMs nuevas: $carpeta_vms"
  fi
  carpeta=$(VBoxManage list systemproperties | sed -n 's/^Default machine folder: *//p')
  medir="$carpeta"
  [ -d "$medir" ] || medir="$HOME"
  libre_gb=$(df -g "$medir" | awk 'NR == 2 {print $4}')
  if [ "$libre_gb" -ge 20 ]; then
    informar OK "Disco de las VMs ($carpeta): $libre_gb GB libres"
  else
    informar FALTA "Disco de las VMs ($carpeta): $libre_gb GB libres; hacen falta 20 GB. Usá --carpeta-vms"
  fi
fi

clave="$demo/.claves/lab_ed25519"
mkdir -p "$demo/.claves"
if [ -f "$clave" ]; then
  informar OK "La clave SSH del laboratorio ya existe"
else
  ssh-keygen -q -t ed25519 -N '' -C lab-tp4 -f "$clave"
  informar OK "Clave SSH generada en $clave"
fi

if [ "$problemas" -gt 0 ]; then
  echo
  echo "Hay $problemas requisito(s) sin cumplir."
  exit 1
fi
echo
echo "Listo: seguí con vagrant up en la carpeta demo."
