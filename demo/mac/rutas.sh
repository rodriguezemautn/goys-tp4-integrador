#!/usr/bin/env bash
# Agrega (o quita con --quitar) la ruta hacia el laboratorio. Pide la clave de administrador.
# No sobrevive a un reinicio: hay que volver a correrlo, con la VM del CHR ya prendida.
set -euo pipefail

if [ "${1:-}" = "--quitar" ]; then
  sudo route -n delete -net 10.10.0.0/16
  echo "Ruta 10.10.0.0/16 quitada."
  exit 0
fi

if netstat -rn -f inet | grep -q '^10\.10/16'; then
  echo "La ruta 10.10.0.0/16 ya existe."
else
  sudo route -n add -net 10.10.0.0/16 192.168.56.2
fi
netstat -rn -f inet | grep '^10\.10/16'
