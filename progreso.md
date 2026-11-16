# Bitácora del grupo — TP4

> Registrar acá el avance: qué hizo cada integrante, decisiones tomadas y pendientes.
> Esto ayuda a coordinar el trabajo y deja evidencia de la participación de todos.

---

## 👥 Integrantes

| Nombre | Usuario de GitHub | Rol en el grupo |
|--------|-------------------|-----------------|
| Ferrari, Agustín Nicolás | FerrariAgustinNicolas | 1. Infraestructura (levanta el laboratorio) |
| Siadore, Valentino | valentinosiadore | 2. Red |
| Kloster, Agustín Ignacio | AgusKlos | 3. Aplicación y alta disponibilidad |
| Guarino, Naim Hernan | naimguar | 4. Seguridad |
| Bellomo, Lorenzo | LoLoo03 | 5. Monitoreo, comunicación y backups |

El reparto y las fechas están en [PLAN.md](PLAN.md).

## 🎯 Proyecto

- **Modalidad:** A — Desarrollo
- **Tema:** Servicios en alta disponibilidad con k3s, publicados por BGP hacia un MikroTik CHR, con segmentación y monitoreo
- **Problema/objetivo:** Mantener un servicio disponible ante la caída de un nodo, con el tráfico segmentado y visible, en una demo offline que entra en una laptop de 8 GB

## 🗓️ Registro de avance

| Fecha | Qué se hizo | Quién | Commit |
|-------|-------------|-------|--------|
| 6/11 | Esqueleto de la demo y plan del grupo | Lorenzo | |
| 6/11 | Scripts para Mac y playbooks de backup y restauración | Lorenzo | |
| 15/11 | Red: diagrama de la estación, secciones 2.1, 3.1 y 4.1 y evidencia de las pruebas de red en la réplica (PR #2) | Valentino | |
| 15/11 | Secciones 3.2 (segmentación) y 4.2 (pruebas de segmentación) | Naim | 63a0090, 7557d87 |
| 15/11 | Réplica levantada en la Mac de Naim (respaldo de la Feria); pruebas de seguridad: segmentación 8 de 8, BGP con MD5, secretos fuera de git | Naim | 6e525dc |
| 15/11 | Pruebas de red de R2 y de alta disponibilidad de R3 corridas en la réplica, entregadas a cada uno | Naim | |
| 15/11 | Memoria real de Grafana y de los nodos en la réplica | Naim | aeb4308 |
| 15/11 | Revisión de los PR #2 (red) y #5 (documento, monitoreo y póster) | Naim | |
| 15/11 | Alta disponibilidad: análisis de la caída, rolling update, rollback y drain; guion de la Feria; `medir-corte.sh` informa el cambio de versión; secciones 2.3, 3.2 y 5 (PR #4) | Agustín | fb29922, 772e9cf |

## 🚧 Pendientes / decisiones

- [x] Definir tema definitivo
- [x] Elegir modalidad: A
- [x] Asignar roles (ver [PLAN.md](PLAN.md))
- [x] Completar nombres y usuarios de GitHub
- [x] Elegir la estación: la PC del compañero con el rol 1
- [x] Elegir la laptop de respaldo: la de Lorenzo, con Windows
- [ ] Confirmar con los docentes las fechas (informe 10/11, Feria 17/11; el README dice 5/11) y el grupo de 5 (el README dice 3-4)
- [ ] Cada integrante configura su identidad de git ("Apellido, Nombre")

## 📝 Notas

- Ideas, dudas para el docente, riesgos, etc.
