#!/usr/bin/env bash
# 8 pruebas de segmentación. Uso, en el server: sudo /vagrant/scripts/prueba-netpol.sh
#
# Un pod recién creado saltea las NetworkPolicies unos segundos y daría un falso
# "permitido": por eso los pods de prueba se crean, se espera 15 s y recién ahí se prueba.
set -u

IMAGEN=rancher/mirrored-library-busybox:1.37.0
FRONTEND=http://frontend.web.svc.cluster.local/
BACKEND=http://backend.datos.svc.cluster.local/
PROMETHEUS=http://prometheus.monitoring.svc.cluster.local:9090/-/ready
GRAFANA=http://grafana.monitoring.svc.cluster.local:3000/api/health

k() { k3s kubectl "$@"; }

borrar_pods() {
  k -n otros delete pod prueba-otros --ignore-not-found --wait=false >/dev/null 2>&1
  k -n web delete pod prueba-web --ignore-not-found --wait=false >/dev/null 2>&1
  k -n datos delete pod prueba-datos --ignore-not-found --wait=false >/dev/null 2>&1
}
trap borrar_pods EXIT

crear_pod() { # namespace nombre
  k -n "$1" delete pod "$2" --ignore-not-found --wait=true >/dev/null 2>&1
  k -n "$1" run "$2" --image="$IMAGEN" --image-pull-policy=IfNotPresent \
    --labels=app=prueba --restart=Never --command -- sleep 3600 >/dev/null
}

http() { # namespace destino_exec url
  k -n "$1" exec "$2" -- wget -q -T 3 -O /dev/null "$3" >/dev/null 2>&1
}

dns() { # namespace pod nombre
  k -n "$1" exec "$2" -- timeout 5 nslookup "$3" >/dev/null 2>&1
}

ok=0
total=0
probar() { # esperado descripcion comando...
  esperado=$1
  descripcion=$2
  shift 2
  total=$((total + 1))
  if "$@"; then resultado=permitido; else resultado=bloqueado; fi
  if [ "$resultado" = "$esperado" ]; then
    ok=$((ok + 1))
    printf 'OK     %2d. %-58s %s\n' "$total" "$descripcion" "$resultado"
  else
    printf 'FALLA  %2d. %-58s %s (se esperaba %s)\n' "$total" "$descripcion" "$resultado" "$esperado"
  fi
}

crear_pod otros prueba-otros
crear_pod web prueba-web
crear_pod datos prueba-datos
k -n otros wait --for=condition=Ready pod/prueba-otros --timeout=90s >/dev/null || exit 2
k -n web wait --for=condition=Ready pod/prueba-web --timeout=90s >/dev/null || exit 2
k -n datos wait --for=condition=Ready pod/prueba-datos --timeout=90s >/dev/null || exit 2
echo "Pods de prueba listos; espero 15 s a que se apliquen las NetworkPolicies..."
sleep 15

probar permitido "otros -> frontend:80 (servicio público)" http otros prueba-otros "$FRONTEND"
probar bloqueado "otros -> backend:80" http otros prueba-otros "$BACKEND"
probar permitido "web/frontend -> backend:80" http web deployment/frontend "$BACKEND"
probar bloqueado "web/otro pod -> backend:80" http web prueba-web "$BACKEND"
probar bloqueado "datos -> frontend:80 (egreso denegado)" http datos prueba-datos "$FRONTEND"
probar permitido "datos -> kube-dns:53 (único egreso)" dns datos prueba-datos kubernetes.default.svc.cluster.local
probar bloqueado "otros -> prometheus:9090" http otros prueba-otros "$PROMETHEUS"
probar permitido "otros -> grafana:3000" http otros prueba-otros "$GRAFANA"

echo "Resultado: $ok de $total"
[ "$ok" -eq "$total" ]
