# Para R2 — validación de red (15/11)

Lo corrió Naim (R4) en su Mac, en la **réplica con contenedores** (`demo/prueba-ram/`), porque la estación de R1 no estaba funcionando. **No es la estación QEMU:** el router es **FRR 8.4 en lugar del MikroTik CHR**, con la misma lógica de filtros que `chr-borde.rsc`. Cada comando de RouterOS que pediste está traducido a su equivalente, y lo dice cada archivo.

Según el PLAN, lo subís vos con tu usuario.

## Archivos

| Archivo | Lo que pediste | Qué hay |
|---|---|---|
| `01-router-antes.txt` | `/system resource print`, `/ip address print`, `/routing bgp session print`, `/ip route print where bgp` | Versión, uptime y memoria del router, sus direcciones (`192.168.56.2` hacia clientes, `10.10.10.1` hacia el clúster), 3 sesiones establecidas y la ruta `10.10.20.10/32` por los 3 nodos |
| `02-config-router.txt` | `/export` sin la clave | `show running-config` de FRR, con la línea de la clave reemplazada por `<borrada>` |
| `03-caida-agent1.txt` | Hora, matar agent1, sesiones, rutas y log a los 15 s, volver a prender | Ver resultados abajo |
| `r2-bgp.pcap` | `tcpdump` en el server | 56 paquetes, todos con TCP MD5 |
| `r2-bgp-router.pcap` y `05-captura-router.txt` | (agregado) | La misma prueba capturada **del lado del router**, donde se ven las 3 sesiones |
| `04-traceroute.txt` | `/tool traceroute 10.10.20.10` | Desde el router y desde el cliente |

Los `.pcap` los escribe `tcpdump` en formato pcap, no pcapng. Wireshark los abre igual. Filtro útil: `tcp.port == 179 && tcp.option_kind == 19`.

## Resultados

- **Caída de agent1** (`docker kill`, que equivale a matar el proceso de QEMU): la sesión pasó a `Idle` **1 s** después y quedó en `Connect` reintentando. A los 15 s, la ruta al VIP seguía solo por `.11` y `.13`.
- **Vuelta de agent1:** la sesión volvió a `Established` **4-5 s** después de prenderlo, y la ruta volvió a pasar por los 3 nodos.
- **Captura del lado del router:** 151 paquetes, **todos con MD5**. Se ven 11 intentos de conexión (SYN) mientras agent1 estaba caído, y **2 OPEN y 1 UPDATE** cuando vuelve.
- **Traceroute desde el cliente:** `192.168.56.2` (router) y después `10.10.10.13` (un nodo). El router reparte entre los 3 nodos (ECMP), así que el nodo puede cambiar entre corridas. El traceroute termina en el nodo porque el VIP no es un equipo: cada nodo lo atiende en el puerto 80.
- **El router no se cayó nunca**, así que no hubo `autosupout` ni equivalente.

## Diferencias con la estación que tenés que tener en cuenta

1. **`r2-bgp.pcap` solo muestra la sesión del server.** Capturando en el server se ve el BGP del server, no el de agent1. Por eso agregué la captura del router. En la estación puede pasar lo mismo, salvo que el helper de red reparta el tráfico como un hub.
2. **El log de BGP está vacío.** FRR no tiene `bgp log-neighbor-changes` en esta configuración. La secuencia de la sesión está en `05-captura-router.txt`.
3. **La caída se detectó en ~1 s.** Al matar el contenedor desaparece su interfaz de red. Con el CHR y QEMU el enlace puede seguir arriba, y entonces la detección tardaría hasta el hold time (9 s). Conviene compararlo en la estación.
4. **La hora del router está en UTC** (16:51 = 13:51 en hora local).
5. **No hay clave en ningún archivo.** Lo revisé contra la clave real, incluidos los `.pcap`: llevan la firma MD5 de cada segmento, no la clave.
