# R3 — Caída de un nodo, rolling update, rollback y mantenimiento

Pruebas del 15/11. **Se corrieron en la réplica con contenedores** (`demo/prueba-ram/`, en la Mac de Naim), porque ese día la estación QEMU de R1 no estaba funcionando. El router es FRR en lugar del CHR; los manifiestos de Kubernetes y la configuración de detección rápida son los del repo. Operó Naim; Kloster analizó y documentó.

**Falta repetirlas en la estación QEMU.**

| Qué | Cómo, en la réplica |
|---|---|
| Desde dónde se mide | Contenedor `cliente` (192.168.56.1) del otro lado del router: el pedido pasa por el router y por BGP, como una laptop de la red de clientes |
| Medidor | `medir-corte.sh` de `main` y, en paralelo, un registro de la versión que responde (`*-versiones.txt`) |
| Apagar un agent de golpe | `docker kill k3s-agent1`, equivalente a matar el proceso de QEMU |
| Prenderlo | `./lab.sh levantar-nodo agent1`; vuelve a `Ready` en 2 a 5 s |

Tabla de resultados. Todos los horarios son locales (-03).

| Prueba | Pedidos | Errores | Esperado | ¿Cumple? |
|---|---|---|---|---|
| Caída de `agent1`, con 1 de los 3 frontends ahí | 674 | 12, sueltos, en ~18 s | ~14 s con errores sueltos | Sí, con una ventana unos 4 s más larga |
| Caída de `agent1`, sin frontends ahí (contraste) | 732 | 0 | — | — |
| Rolling update a v2 | 294 | 0 | 0 perdidos y cambia a v2 | Sí: v2 responde 2 s después del comando y el rollout tarda 3 s |
| Rollback a v1 | 293 | 0 | Vuelve a v1 sin cortes | Sí: ~2 s con v1 y v2 mezclados, después solo v1 |
| `drain` y `uncordon` de `agent2`, con 2 frontends ahí | 436 | 0 | El PDB mantiene al menos 2 réplicas | Sí: el PDB frenó el segundo desalojo hasta que hubo reemplazo |

## Caída de un agent

Archivos: [01-caida-agent1.txt](r3-replica-15-11/01-caida-agent1.txt), [línea de tiempo](r3-replica-15-11/01-caida-agent1-linea-de-tiempo.txt) y [medidor](r3-replica-15-11/01-caida-agent1-medidor.txt).

| Tiempo desde el `kill` | Qué pasa |
|---|---|
| 0 s (14:00:03) | Se mata `agent1` |
| +1 s | El router da la sesión BGP de `agent1` por caída (`Idle`) y retira esa ruta |
| +1 a +19 s | 12 errores sueltos (rachas de 1, y una de 4 en 4 s) |
| +18 s | Kubernetes marca `agent1` `NotReady` y saca su frontend del Service (2/3) |
| +60 s | Se vuelve a prender: `Ready` a los 2 s y BGP `Established` a los 4 s |

El router retiró la ruta en 1 s, y los errores igual siguieron hasta el `NotReady`. La razón es `externalTrafficPolicy: Cluster`: los nodos sanos siguen repartiendo pedidos entre los 3 frontends, incluido el del nodo muerto, hasta que Kubernetes da el nodo por caído. Por eso la ventana la fija `node-monitor-grace-period` (20 s) y no BGP. Con el nodo sin frontends, la misma caída dio 0 errores.

En la réplica, la sesión cayó en 1 s y no en 9 s (el `holdTime`). Probablemente sea porque, al desaparecer el contenedor, el router se entera enseguida de que el vecino no está. En QEMU o en VirtualBox, con la VM apagada de golpe, hay que esperar los 9 s: falta verificarlo.

## Rolling update y rollback

Archivos: [rolling update](r3-replica-15-11/02-rolling-update.txt) ([medidor](r3-replica-15-11/02-rolling-update-medidor.txt), [versiones](r3-replica-15-11/02-rolling-update-versiones.txt)) y [rollback](r3-replica-15-11/03-rollback.txt) ([medidor](r3-replica-15-11/03-rollback-medidor.txt), [versiones](r3-replica-15-11/03-rollback-versiones.txt)).

- Las dos operaciones terminaron en 3 s, con 0 errores; las imágenes ya estaban descargadas.
- Durante el rollback, entre 13:55:42 y 13:55:44, responden v1 y v2 alternados: conviven réplicas viejas y nuevas, y ningún pedido falla.
- `rollout undo` avisa que el Deployment se había creado con `kubectl apply`. No afecta la prueba, pero la próxima vez que se aplique `deploy.yml` se vuelve a lo que diga el repo.

## Mantenimiento con drain

Archivos: [04-drain.txt](r3-replica-15-11/04-drain.txt) y [medidor](r3-replica-15-11/04-drain-medidor.txt).

`kubectl drain k3s-agent2 --ignore-daemonsets --delete-emptydir-data` intentó desalojar los 2 frontends de `agent2`. El PDB (`minAvailable: 2`) rechazó el segundo con "Cannot evict pod as it would violate the pod's disruption budget" y lo reintentó a los 5 s, cuando el primero ya tenía reemplazo. El drain tardó 12 s, con 0 errores. Después del `uncordon`, los pods no vuelven solos a `agent2`: es lo esperado.

## Condiciones de la réplica

- En la Mac de Naim se subió la RAM de los nodos (server a 2 GiB y agents a 1 GiB) y el límite de Grafana a 1 GiB, porque Grafana dejaba sin memoria al server. Son cambios locales: el repo no se tocó.
- Antes de la caída y del drain se usó `kubectl rollout restart` para que hubiera frontends en el nodo a probar. Con `whenUnsatisfiable: ScheduleAnyway`, el reparto no siempre queda en 1 por nodo.
