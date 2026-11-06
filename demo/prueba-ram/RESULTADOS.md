# Resultados medidos

Cada vez que algo falle en el laboratorio real, se corrige y se anota en "Bitácora en la laptop".

## Réplica con contenedores

Medido en la sesión anterior en contenedores Docker (k3s v1.36.6, FRR 8.4 en lugar del CHR), con un límite de RAM por nodo igual a la VM menos unos 256 MB de Ubuntu. Los scripts de esta carpeta se reconstruyeron a partir del traspaso y no se volvieron a correr.

| Nodo | Máximo medido / límite | RSS (memoria no liberable) | Eventos OOM |
|---|---|---|---|
| k3s-server | 1132 / 1280 MiB | ~810 MiB | 0 |
| k3s-agent1 | 339 / 512 MiB | ~206 MiB | 0 |
| k3s-agent2 | 283 / 512 MiB | ~181 MiB | 0 |
| CHR (FRR) | 18 / 256 MiB | 16 MiB | 0 |

Por componente: Grafana 230–300 MiB, Prometheus ~40 MiB, MetalLB ~20 MiB el controller y ~19 MiB cada speaker, metrics-server ~20 MiB, CoreDNS ~13 MiB, node-exporter ~7 MiB, frontend ~5 MiB y backend ~2 MiB por réplica.

| Prueba | Resultado |
|---|---|
| 3 sesiones BGP con MD5 | Establecidas; el router recibe 10.10.20.10/32 por los 3 nodos |
| Cliente → 10.10.20.10 → frontend → backend | Funciona |
| NetworkPolicies (`prueba-netpol.sh`) | 8 de 8 |
| Prometheus y dashboard de Grafana precargado | Funcionan |
| Rolling update, rollback y `kubectl drain` con PDB | 0 pedidos perdidos |
| Rol `comun` de Ansible, dos corridas | Idempotente: la segunda da `changed=0` |
| `ansible-lint` sobre site.yml y deploy.yml | Pasa en perfil production |
| Caída de un agent, detección por defecto | 31 de 475 pedidos fallan en una ventana de ~43 s |
| Caída de un agent, detección rápida | 10 de 384 pedidos fallan en una ventana de ~14 s |

Con el agent congelado y detección rápida: a los 10 s el router retira la ruta por ese nodo y a los 15 s Kubernetes lo marca `NotReady`.

## Errores encontrados y correcciones

| Problema | Corrección |
|---|---|
| MetalLB en modo nativo rechaza `keepaliveTime` en el BGPPeer | Solo `holdTime: 9s` |
| Grafana 13 intenta descargar plugins al arrancar, y sin internet falla | `GF_PLUGINS_PREINSTALL_DISABLED=true` |
| Grafana usa 230–300 MiB; con un límite de 256 MiB lo cortaban por OOM | Límite de 384 MiB |
| El rolling update perdía 4 pedidos porque nginx se apagaba antes de salir del balanceo | `preStop: sleep 5 s` y `terminationGracePeriodSeconds: 20` |
| Kubernetes tarda ~40 s en dar por caído un nodo y sigue mandando tráfico a pods muertos | `node-monitor-grace-period=20s` y `node-status-update-frequency=4s` |
| node-exporter montaba `/` del host sin necesitarlo | Solo `/proc` y `/sys` |
| Un pod recién creado saltea las NetworkPolicies y la prueba daba un falso "permitido" | `prueba-netpol.sh` crea los pods, espera 15 s y después prueba |
| Wireshark con `bgp.type == 2` no muestra nada si el nodo se apaga de golpe | Filtrar `bgp.type == 3 \|\| bgp.type == 4` |

Problemas propios de la réplica, que no aplican a las VMs:

- El host usa cgroup v1 y Kubernetes 1.36 lo rechaza: `--kubelet-arg=fail-cgroupv1=false`, solo si no hay cgroup v2.
- El sandbox no permite bajar `oom_score_adj`: plantilla de containerd con `restrict_oom_score_adj = true`.
- Docker 28 o más descarta el tráfico ruteado entre redes bridge: reglas `iptables -t raw` de ACCEPT en los dos sentidos.
- quay.io estaba bloqueado: imágenes de MetalLB de Bitnami con otro tag; corren como uid 1001 y el speaker necesita `runAsUser: 0` (`METALLB_BITNAMI=1`).
- Quedaban volúmenes de corridas anteriores y había presión de disco: `docker rm -f -v`.

## Presupuesto estimado en Windows (sin medir)

| Consumo | Perfil chico | Perfil normal |
|---|---|---|
| VMs k3s | 3,0 GB | 4,0 GB |
| CHR | 0,25 GB | 0,25 GB |
| Sobrecarga de VirtualBox | ~0,3 GB | ~0,4 GB |
| Windows 11 | 2,5–3,5 GB | 2,5–3,5 GB |
| Claude (app de escritorio) | ~0,5–1 GB | ~0,5–1 GB |
| Navegador con Grafana | ~0,3–0,5 GB | ~0,3–0,5 GB |
| **Total** | **~6,9–8,5 GB** | **~8,0–9,6 GB** |

## Medición en la laptop

Pendiente: `windows\medir-ram.ps1 -Minutos 10` con todo levantado.

| Fecha | Laptop | Perfil | Pico | Promedio | Decisión |
|---|---|---|---|---|---|
| | | | | | |

## Bitácora en la laptop

| Fecha | Qué falló | Causa | Corrección | Quién |
|---|---|---|---|---|
| | | | | |
