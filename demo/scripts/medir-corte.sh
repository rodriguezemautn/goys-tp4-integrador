#!/bin/sh
# Un pedido cada 0,2 s e informe de las rachas de errores. POSIX: anda en busybox.
# Uso: medir-corte.sh [url] [segundos]   (Ctrl+C también termina e informa)
URL=${1:-http://10.10.20.10/}
SEGUNDOS=${2:-120}

if command -v curl >/dev/null 2>&1; then
  pedir() { curl -fsS -m 1 -o /dev/null "$URL" 2>/dev/null; }
else
  pedir() { wget -q -T 1 -O /dev/null "$URL" 2>/dev/null; }
fi

total=0
errores=0
rachas=""
en_racha=0
inicio_racha=0
errores_racha=0
inicio=$(date +%s)
fin=$((inicio + SEGUNDOS))

cerrar_racha() {
  [ "$en_racha" -eq 1 ] || return 0
  ahora=$(date +%s)
  rachas="$rachas
  a los $((inicio_racha - inicio)) s: $errores_racha errores en $((ahora - inicio_racha)) s"
  en_racha=0
}

informar() {
  cerrar_racha
  echo
  echo "Pedidos: $total | errores: $errores | duración: $(($(date +%s) - inicio)) s"
  if [ -n "$rachas" ]; then
    echo "Rachas de errores:$rachas"
  else
    echo "Sin errores"
  fi
  exit 0
}
trap informar INT TERM

echo "Midiendo $URL durante $SEGUNDOS s (Ctrl+C para cortar)..."
while [ "$(date +%s)" -lt "$fin" ]; do
  total=$((total + 1))
  if pedir; then
    cerrar_racha
  else
    errores=$((errores + 1))
    if [ "$en_racha" -eq 0 ]; then
      en_racha=1
      inicio_racha=$(date +%s)
      errores_racha=0
    fi
    errores_racha=$((errores_racha + 1))
  fi
  sleep 0.2
done
informar
