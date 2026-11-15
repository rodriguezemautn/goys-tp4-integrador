## 5. Limitaciones y trabajo futuro

Tabla 6: Limitaciones conocidas

| Limitación | Consecuencia | Cómo se resolvería |
|---|---|---|
| **Un solo server de k3s** | No hay alta disponibilidad del plano de control. Si cae el server, los pods que ya corren siguen atendiendo, pero no se puede administrar el clúster ni reponer réplicas | Tres servers con etcd embebido (quórum de 2 de 3). Quedó afuera por RAM: el server es el nodo que más consume (~1,1 GiB medido) |
| **~14 s de pedidos sueltos con error ante la caída de un nodo** | Durante esa ventana falla una parte de los pedidos (10 de 384 en la réplica), sin corte total. Con los valores por defecto de Kubernetes eran ~43 s; se bajó con `holdTime: 9s` en BGP, `node-monitor-grace-period=20s` y `node-status-update-frequency=4s` | Llegar a 0 pide **BFD** entre el CHR y los nodos, que detecta la caída en menos de un segundo. MetalLB lo soporta solo en modo FRR, que agrega un contenedor de FRR por nodo: más RAM de la que había disponible |
| **La estación es un Mac de 24 GiB, no la laptop de 8 GB del planteo** | La meta original era que todo entrara en una laptop de 8 GB. La demo se presenta en el Mac del grupo con QEMU (Ubuntu ARM64 con HVF y el CHR x86_64 emulado con TCG). El consumo en 8 GB solo se midió en la réplica con contenedores | Medir el perfil `chico` en una laptop de 8 GB con VirtualBox (`windows\medir-ram.ps1`); la laptop de respaldo queda como plan B |
| Bajar los tiempos de detección tiene costo | Un `node-monitor-grace-period` corto puede dar por caído un nodo que solo estaba lento (por ejemplo, el CHR emulado o una VM con poca CPU) | En producción se usarían los valores por defecto junto con BFD en la red |
| SNAT por `externalTrafficPolicy: Cluster` | El backend no ve la IP real del cliente | `Local` evita el SNAT, pero solo anuncian la IP los nodos con réplica |

**Trabajo futuro.** Además de lo anterior: un Ingress con TLS delante del frontend, una base de datos con réplicas en el backend (hoy no guarda estado) y probar la restauración completa de la estación desde el respaldo, que todavía no se hizo.
