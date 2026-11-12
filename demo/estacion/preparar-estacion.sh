#!/usr/bin/env bash
# Prepara la estacion de monitoreo del TP4 (VM Ubuntu Server 24.04 en VirtualBox).
# Uso, dentro de la VM:  sudo bash preparar-estacion.sh
# Se puede correr mas de una vez: cada paso revisa si ya esta hecho.
set -euo pipefail

AQUI="$(cd "$(dirname "$0")" && pwd)"
USUARIO="${SUDO_USER:-goys}"

if [[ $EUID -ne 0 ]]; then
  echo "Correlo con sudo: sudo bash $0" >&2
  exit 1
fi

echo "== 1/5 Disco: usar los 20 GB completos"
LV=/dev/ubuntu-vg/ubuntu-lv
if [[ -e $LV ]] && [[ $(vgs --noheadings -o vg_free --units g --nosuffix ubuntu-vg | tr -d ' ' | cut -d. -f1) -gt 0 ]]; then
  lvextend -l +100%FREE -r "$LV"
else
  echo "   ya usa todo el disco"
fi

echo "== 2/5 Hora local (Argentina), para que los logs coincidan con las capturas"
timedatectl set-timezone America/Argentina/Buenos_Aires

echo "== 3/5 Red del laboratorio en enp0s3 (10.20.0.101/24)"
install -m 600 "$AQUI/60-laboratorio.yaml" /etc/netplan/60-laboratorio.yaml
netplan apply

echo "== 4/5 Docker Engine desde el repositorio oficial"
if ! command -v docker >/dev/null; then
  apt-get update -qq
  apt-get install -y -qq ca-certificates curl tcpdump traceroute
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  chmod a+r /etc/apt/keyrings/docker.asc
  . /etc/os-release
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu ${VERSION_CODENAME} stable" \
    > /etc/apt/sources.list.d/docker.list
  apt-get update -qq
  apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
else
  echo "   docker ya instalado: $(docker --version)"
fi
usermod -aG docker "$USUARIO"

echo "== 5/5 Imagen de prueba descargada de antemano (la demo corre sin Internet)"
docker pull -q alpine:3.20

echo
echo "Listo. Cerra la sesion y volve a entrar para usar docker sin sudo."
ip -br addr show enp0s3
