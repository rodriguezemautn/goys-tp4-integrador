#!/usr/bin/env bash
# Réplica del laboratorio con contenedores, para medir RAM sin VirtualBox: cada nodo tiene
# de límite la RAM de su VM menos unos 256 MB de Ubuntu. FRR hace de CHR.
# No usar en la laptop de 8 GB con el laboratorio levantado.
#
# Uso: replica-docker.sh [up|down]
#   OOM_RESTRINGIDO=1  usa containerd-config-v3.toml.tmpl (sandbox que no deja bajar oom_score_adj)
set -euo pipefail

K3S_IMAGE=rancher/k3s:v1.36.6-k3s1
FRR_IMAGE=frrouting/frr:v8.4.0
CLIENTE_IMAGE=rancher/mirrored-library-busybox:1.37.0
NET_CLUSTER=replica-cluster
NET_CLIENTES=replica-clientes
CONTENEDORES=(k3s-server k3s-agent1 k3s-agent2 chr-replica cliente)

dir="$(cd "$(dirname "$0")" && pwd)"
frr_dir="$dir/.frr"

bajar() {
  # -v: si no, quedan volúmenes de corridas anteriores y aparece presión de disco.
  docker rm -f -v "${CONTENEDORES[@]}" >/dev/null 2>&1 || true
  docker network rm "$NET_CLUSTER" "$NET_CLIENTES" >/dev/null 2>&1 || true
}

if [ "${1:-up}" = down ]; then
  bajar
  exit 0
fi

bajar
mkdir -p "$frr_dir"
if [ ! -f "$frr_dir/claves.env" ]; then
  (umask 077 && cat > "$frr_dir/claves.env" <<EOF
K3S_TOKEN=$(openssl rand -hex 24)
BGP_MD5=$(openssl rand -hex 12)
GRAFANA_ADMIN=$(openssl rand -hex 12)
EOF
  )
fi
# shellcheck disable=SC1091
. "$frr_dir/claves.env"

sed "s/CAMBIAR-CLAVE-BGP/$BGP_MD5/" "$dir/frr.conf" > "$frr_dir/frr.conf"
cat > "$frr_dir/daemons" <<'EOF'
zebra=yes
bgpd=yes
vtysh_enable=yes
EOF

docker network create --subnet 10.10.10.0/24 --gateway 10.10.10.254 "$NET_CLUSTER" >/dev/null
docker network create --subnet 192.168.56.0/24 --gateway 192.168.56.254 "$NET_CLIENTES" >/dev/null

# Docker 28 o más descarta el tráfico ruteado entre redes bridge.
if ! sudo -n true 2>/dev/null; then echo "Hace falta sudo para las reglas de iptables" >&2; exit 1; fi
for par in "192.168.56.0/24 10.10.0.0/16" "10.10.0.0/16 192.168.56.0/24"; do
  set -- $par
  sudo iptables -t raw -C PREROUTING -s "$1" -d "$2" -j ACCEPT 2>/dev/null \
    || sudo iptables -t raw -I PREROUTING -s "$1" -d "$2" -j ACCEPT
done

docker run -d --name chr-replica --hostname chr-replica --privileged --memory 256m --memory-swap 256m \
  --network "$NET_CLUSTER" --ip 10.10.10.1 \
  -v "$frr_dir/frr.conf:/etc/frr/frr.conf:ro" -v "$frr_dir/daemons:/etc/frr/daemons:ro" \
  "$FRR_IMAGE" >/dev/null
docker network connect --ip 192.168.56.2 "$NET_CLIENTES" chr-replica

extra=()
# Kubernetes 1.36 rechaza cgroup v1 salvo que se lo pida explícitamente.
[ -f /sys/fs/cgroup/cgroup.controllers ] || extra+=(--kubelet-arg=fail-cgroupv1=false)

montajes=()
if [ "${OOM_RESTRINGIDO:-0}" = 1 ]; then
  montajes+=(-v "$dir/containerd-config-v3.toml.tmpl:/var/lib/rancher/k3s/agent/etc/containerd/config-v3.toml.tmpl:ro")
fi

nodo_base() { # nombre ip memoria
  docker run -d --name "$1" --hostname "$1" --privileged --tmpfs /run --tmpfs /var/run \
    --memory "$3" --memory-swap "$3" --network "$NET_CLUSTER" --ip "$2" \
    "${montajes[@]}" "$K3S_IMAGE" "${@:4}" >/dev/null
}

nodo_base k3s-server 10.10.10.11 1280m server \
  --token "$K3S_TOKEN" --node-ip 10.10.10.11 --advertise-address 10.10.10.11 \
  --flannel-iface eth0 --tls-san 10.10.10.11 --write-kubeconfig-mode 0600 \
  --disable servicelb --disable traefik \
  --kube-controller-manager-arg node-monitor-grace-period=20s \
  --kubelet-arg node-status-update-frequency=4s "${extra[@]}"

for n in 1 2; do
  nodo_base "k3s-agent$n" "10.10.10.1$((n + 1))" 512m agent \
    --server https://10.10.10.11:6443 --token "$K3S_TOKEN" --node-ip "10.10.10.1$((n + 1))" \
    --flannel-iface eth0 --kubelet-arg node-status-update-frequency=4s "${extra[@]}"
done

for nodo in k3s-server k3s-agent1 k3s-agent2; do
  docker exec "$nodo" ip route add 192.168.56.0/24 via 10.10.10.1
done

docker run -d --name cliente --hostname cliente --cap-add NET_ADMIN --network "$NET_CLIENTES" --ip 192.168.56.1 \
  "$CLIENTE_IMAGE" sleep 86400 >/dev/null
docker exec cliente ip route add 10.10.0.0/16 via 192.168.56.2

echo "Réplica creada. Seguí con: $dir/desplegar-replica.sh"
