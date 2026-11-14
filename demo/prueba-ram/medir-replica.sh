#!/usr/bin/env bash
# Máximo de memoria, memoria no liberable y eventos OOM por nodo de la réplica.
# Uso: medir-replica.sh [segundos]    (por defecto 600)
set -euo pipefail

SEGUNDOS=${1:-600}
NODOS=(k3s-server k3s-agent1 k3s-agent2 chr-replica)
declare -A maximo anon

leer() { # contenedor archivo
  docker exec "$1" cat "/sys/fs/cgroup/$2" 2>/dev/null
}

fin=$(($(date +%s) + SEGUNDOS))
echo "Midiendo durante $SEGUNDOS s..."
while [ "$(date +%s)" -lt "$fin" ]; do
  for n in "${NODOS[@]}"; do
    actual=$(leer "$n" memory.current || leer "$n" memory/memory.usage_in_bytes || echo 0)
    [ "$actual" -gt "${maximo[$n]:-0}" ] && maximo[$n]=$actual
    a=$(leer "$n" memory.stat | awk '$1 == "anon" {print $2}')
    [ -n "$a" ] && [ "$a" -gt "${anon[$n]:-0}" ] && anon[$n]=$a
  done
  sleep 5
done

printf '%-14s %10s %10s %6s\n' Nodo 'Max MiB' 'RSS MiB' OOM
for n in "${NODOS[@]}"; do
  oom=$(leer "$n" memory.events | awk '$1 == "oom_kill" {print $2}')
  printf '%-14s %10d %10d %6s\n' "$n" "$((${maximo[$n]:-0} / 1048576))" "$((${anon[$n]:-0} / 1048576))" "${oom:-?}"
done
