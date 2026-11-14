#!/usr/bin/env bash
# Despliega en la réplica lo mismo que ansible/deploy.yml, en el mismo orden.
#   METALLB_BITNAMI=1  usa las imágenes de Bitnami si quay.io está bloqueado (corren como
#                      uid 1001 y el speaker necesita runAsUser: 0)
set -euo pipefail

dir="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
. "$dir/.frr/claves.env"
k() { docker exec -i k3s-server kubectl "$@"; }

echo "Esperando al clúster..."
until k get nodes >/dev/null 2>&1; do sleep 3; done
for nodo in k3s-server k3s-agent1 k3s-agent2; do
  until k wait --for=condition=Ready "node/$nodo" --timeout=10s >/dev/null 2>&1; do sleep 3; done
done

docker exec k3s-server rm -rf /tmp/k8s
docker cp "$dir/../k8s" k3s-server:/tmp/k8s

if [ "${METALLB_BITNAMI:-0}" = 1 ]; then
  docker exec k3s-server sed -i \
    -e 's#quay.io/metallb/controller:v0.15.2#docker.io/bitnamilegacy/metallb-controller:0.15.2#' \
    -e 's#quay.io/metallb/speaker:v0.15.2#docker.io/bitnamilegacy/metallb-speaker:0.15.2#' \
    /tmp/k8s/metallb/metallb-native.yaml
fi

k apply -f /tmp/k8s/metallb/metallb-native.yaml
if [ "${METALLB_BITNAMI:-0}" = 1 ]; then
  k -n metallb-system patch daemonset speaker --type=strategic \
    -p '{"spec":{"template":{"spec":{"securityContext":{"runAsUser":0}}}}}'
fi
k -n metallb-system rollout status deployment/controller --timeout=300s

k -n metallb-system create secret generic bgp-md5 --type=kubernetes.io/basic-auth \
  --from-literal=password="$BGP_MD5" --dry-run=client -o yaml | k apply -f -

until k apply -f /tmp/k8s/metallb/bgp.yaml; do
  echo "Esperando al webhook de MetalLB..."
  sleep 5
done

k apply -k /tmp/k8s/app

k apply -f /tmp/k8s/monitoring/namespace.yaml
k -n monitoring create secret generic grafana-admin \
  --from-literal=password="$GRAFANA_ADMIN" --dry-run=client -o yaml | k apply -f -
k apply -k /tmp/k8s/monitoring

k apply -k /tmp/k8s/netpol

for d in web/frontend datos/backend monitoring/prometheus monitoring/grafana; do
  k -n "${d%/*}" rollout status "deployment/${d#*/}" --timeout=300s
done

docker exec chr-replica vtysh -c 'show ip bgp summary' -c 'show ip route bgp'
docker exec cliente wget -q -O- http://10.10.20.10/
docker exec cliente wget -q -O- http://10.10.20.10/api/ | head -3
