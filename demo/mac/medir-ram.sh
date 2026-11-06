#!/usr/bin/env bash
# Mide la RAM del Mac con el laboratorio levantado y decide si alcanza el perfil actual.
# Correrlo con Grafana abierto, Wireshark capturando y Claude abierto.
# Uso: bash mac/medir-ram.sh [minutos]    (por defecto 10)
#
# Cuenta lo mismo que "Memoria usada" del Monitor de Actividad: activa, residente y comprimida.
# macOS usa la RAM libre como caché, así que ver poca memoria libre no es un problema.
set -euo pipefail

MINUTOS=${1:-10}
INTERVALO=${INTERVALO:-5}
UMBRAL=${UMBRAL:-85}

demo="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$demo/.descargas"
csv="$demo/.descargas/ram-$(date +%Y%m%d-%H%M).csv"
echo "hora,uso_pct,usada_gb" > "$csv"

total=$(sysctl -n hw.memsize)
pagina=$(sysctl -n hw.pagesize)

usada_bytes() {
  vm_stat | awk -v pagina="$pagina" '
    /^Pages active:/ {a = $3 + 0}
    /^Pages wired down:/ {w = $4 + 0}
    /^Pages occupied by compressor:/ {c = $5 + 0}
    END {printf "%.0f", (a + w + c) * pagina}'
}

top_procesos() {
  ps -axo rss=,comm= | sort -rn | head -10 |
    awk '{mb = $1 / 1024; $1 = ""; n = split($0, partes, "/"); printf "  %6.0f MB  %s\n", mb, partes[n]}'
}

vms=$(VBoxManage list runningvms | wc -l | tr -d ' ')
echo "VMs encendidas: $vms"
if [ "$vms" -lt 4 ]; then
  echo "Aviso: se esperaban 4 VMs (3 nodos k3s y el CHR); la medición va a dar de menos."
fi

segundos=$(awk -v m="$MINUTOS" 'BEGIN {printf "%d", m * 60}')
fin=$(($(date +%s) + segundos))
pico=0
suma=0
muestras=0
top_pico=""
echo "Midiendo durante $MINUTOS minutos..."

while [ "$(date +%s)" -lt "$fin" ]; do
  usada=$(usada_bytes)
  uso=$(awk -v u="$usada" -v t="$total" 'BEGIN {printf "%.1f", 100 * u / t}')
  gb=$(awk -v u="$usada" 'BEGIN {printf "%.2f", u / 1073741824}')
  echo "$(date +%H:%M:%S),$uso,$gb" >> "$csv"
  suma=$(awk -v s="$suma" -v u="$uso" 'BEGIN {print s + u}')
  muestras=$((muestras + 1))
  if awk -v u="$uso" -v p="$pico" 'BEGIN {exit !(u > p)}'; then
    pico=$uso
    top_pico=$(top_procesos)
  fi
  printf '\rUso %s %% | pico %s %%   ' "$uso" "$pico"
  sleep "$INTERVALO"
done
echo

if [ "$muestras" -eq 0 ]; then
  echo "No se tomó ninguna muestra." >&2
  exit 2
fi

promedio=$(awk -v s="$suma" -v n="$muestras" 'BEGIN {printf "%.1f", s / n}')
echo "Muestras: $muestras | promedio: $promedio % | pico: $pico % | umbral: $UMBRAL %"
echo "Procesos con más RAM en el pico:"
echo "$top_pico"
echo "Detalle: $csv"

if awk -v p="$pico" -v u="$UMBRAL" 'BEGIN {exit !(p < u)}'; then
  echo "DECISIÓN: el pico queda debajo de $UMBRAL %, se sigue con este perfil."
  exit 0
fi
echo "DECISIÓN: el pico supera $UMBRAL %. Cerrá programas o bajá RAM, y volvé a medir."
exit 1
