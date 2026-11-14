# Bitácora del grupo — TP4

> Registrar acá el avance: qué hizo cada integrante, decisiones tomadas y pendientes.
> Esto ayuda a coordinar el trabajo y deja evidencia de la participación de todos.

---

## 👥 Integrantes

| Nombre | Usuario de GitHub | Rol en el grupo |
|--------|-------------------|-----------------|
| Santiago Natalichio Bestosini | `Sanntinat` | H1 Laboratorio, H2 Conectividad, H5 Defensa (con Tomás) |
| Juan Bautista Cuenca |  | H3 Tablero |
| Tomás Martin |  | H4 Atacante, H5 Defensa (con Santiago) |
| Lautaro Aubert | `LauAubert` | H6 Automatización |

## 🎯 Proyecto

- **Modalidad:** A — Desarrollo
- **Tema:** Sistema Inmune: la red del TP3 que se cura y se defiende sola (monitoreo con Prometheus/Grafana, bloqueo de escaneos en el EDGE y despliegue con Ansible). Ver [`propuesta.md`](propuesta.md).
- **Problema/objetivo:** la red del TP3 se recupera sola, pero nadie se entera de una falla mientras pasa y el firewall no reacciona ante un atacante. Queremos que avise y se defienda, y medir cuánto tarda en recuperarse y en neutralizar un ataque.

## 🗓️ Registro de avance

| Fecha | Qué se hizo | Quién | Commit |
|-------|-------------|-------|--------|
| 07/11/2026 | Propuesta del proyecto (`propuesta.md` y figura de la topología) | Santiago | `75771e9` |
| 12/11/2026 | **H1 Laboratorio:** copia `TP4-SistemaInmune` del proyecto GNS3; el del TP3 queda intacto (mismo SHA-256) | Santiago | ver `git log` |
| 12/11/2026 | **H2 Conectividad:** estación como VM Ubuntu + Docker conectada a SW-SERVERS por túnel UDP; un container le hace ping al EDGE (5/5). Runbook en [`demo/runbooks/preparar-estacion.md`](demo/runbooks/preparar-estacion.md) | Santiago | ver `git log` |
| 14/11/2026 | **H3 Tablero:** usuario de solo lectura y API-SSL en los 5 routers; stack Prometheus + mktxp + blackbox + Grafana en la estación; tablero «Sistema Inmune» y 4 alertas, probadas con cortes en GNS3 (enlace, ISP-1, ISP-2). Tiempo de recuperación ante corte del enlace EDGE–CORE-1: ~1 s | Juan Bautista | ver `git log` |

## 🚧 Pendientes / decisiones

- [x] Definir tema definitivo
- [x] Elegir modalidad (A, B o C)
- [x] Asignar roles (por hito, tabla 5 de la propuesta)
- [x] H3 Tablero
- [ ] H4 Atacante · H5 Defensa · H6 Automatización · H7 Ensayo

**Decisión (12/11, H2):** la estación no es la laptop con un nodo *Cloud* sobre una placa de loopback, como decía la propuesta. En Windows 11 25H2, Windows descarta lo que Npcap le inyecta a esa placa. Queda como **VM Ubuntu en VirtualBox** unida a GNS3 por un **túnel UDP** (nube `ESTACION`). Consecuencias:

- **H3:** Prometheus y Grafana corren en Docker dentro de la VM. Grafana se ve desde Windows en `http://127.0.0.1:3000`.
- **H6:** Ansible corre en la VM, sin WSL.

Detalle y evidencia en el runbook.

## 📝 Notas

- La laptop de la demo tiene 7,4 GB de RAM (no 16 GB como dice la tabla de riesgos): 7 CHR ≈ 1,8 GB + VM 2 GB. Vigilar memoria en H3.
- Para trabajar: abrir `TP4-SistemaInmune` en GNS3, iniciar los nodos y después `demo/estacion/iniciar-estacion.ps1`.
