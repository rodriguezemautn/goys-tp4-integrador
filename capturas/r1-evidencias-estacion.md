# R1 — Evidencias revisadas de la estación

| Prueba | Resultado observado | Alcance |
|---|---|---|
| Aislamiento de los tres Ubuntu (10/11) | El ensayo con el helper nftables corregido pasó. Los pods originales se mantuvieron y no quedaron Jobs de prueba pendientes. | No se desconectó el Mac de internet y no equivale al ensayo de Feria. |
| Restauraciones de monitoreo (12/11) | Grafana y Prometheus se restauraron en réplicas aisladas. El SHA-256 de cada respaldo cifrado original permaneció sin cambios. | No se probaron credenciales históricas contra servicios reales ni se comprobó continuidad de datos en la estación original. |
| Ciclo en frío de la estación (13/11) | 3/3 nodos Ready, BGP 3/3, monitoreo 10/10 y HTTP 200 en frontend y API desde los tres Ubuntu. | Se reinició con los discos originales. No se probó arrancar desde el respaldo completo. |
| Idempotencia de Ansible | [Cuatro corridas en réplica](r1-idempotencia-replica.json): `changed=8/0/1/0`. | El cambio deliberado fue detectado y corregido. No se ejecutó contra la estación. |
| Arranque con los scripts publicables | [Prueba desechable](r1-qemu-arranque-desechable.json): login de CHR, tres listeners del helper y cloud-init completado en los tres Ubuntu. | No prueba K3s, BGP ni tráfico entre las VMs de la réplica. |

Los registros originales, las capturas crudas y los respaldos no forman parte de la entrega pública. La [medición de RAM](../demo/prueba-ram/RESULTADOS.md) queda documentada por separado.
