# Bitácora del grupo — TP4

> Registrar acá el avance: qué hizo cada integrante, decisiones tomadas y pendientes.
> Esto ayuda a coordinar el trabajo y deja evidencia de la participación de todos.

---

## 👥 Integrantes

| Nombre | Usuario de GitHub | Rol en el grupo |
|--------|-------------------|-----------------|
| Pilar Giannelli | `pilargiannelli` | Búsqueda de fuentes, investigación y revisión |
| Tomás Terruli | `TomasTerruli` | Diseño, armado y medición de la mini simulación |
| Martina Castellani | `Marticaste144` | Organización e integración del artículo, póster y repositorio |

## 🎯 Proyecto

- **Modalidad:** B — Artículo de Revisión del Estado del Arte, con una mini simulación
- **Título:** De las métricas a las acciones: calidad de las alertas y detección de fallas en servicios
- **Tema:** Observabilidad de servicios: criterios de alertado para detectar fallas y reducir notificaciones innecesarias
- **Pregunta de investigación:** ¿Cómo influyen los criterios de activación de alertas en la cantidad de notificaciones y en el tiempo de detección de una falla?
- **Simulación:** red chica en GNS3 donde comprobamos la conectividad con ping; comparamos avisar con el primer fallo contra esperar varios fallos seguidos.

## 🗓️ Registro de avance

| Fecha | Qué se hizo | Quién | Commit |
|-------|-------------|-------|--------|
| 09/11/2026 | Borrador de la introducción con una referencia oficial (OpenTelemetry) en `documento/introduccion.md` | Martina | `0bdfa90` |
| 09/11/2026 | Revisión y merge del PR #1 (introducción) | Tomás | `855296a` |
| 12/11/2026 | Ronda 1, paso 1: delimitación del tema. Actualicé el README con título, integrantes, modalidad, objetivo, alcance y entregables. Creé `documento/alcance.md` con la pregunta, los objetivos, los términos que usamos y los límites. Busqué y verifiqué 14 fuentes (documentación oficial, RFC/estándares y artículos académicos) y anoté sus datos y para qué sirve cada una en `documento/fuentes-investigacion.md` | Pilar | rama `pilar-delimitacion-tema` |

## ✅ Decisiones tomadas

- Modalidad B, con una mini simulación como complemento de la revisión.
- Pregunta de investigación y título definidos (ver `documento/alcance.md`).
- Los dos criterios se aplican sobre los mismos registros de conectividad.
- Antes de aplicar los criterios definimos qué interrupción necesita intervención. Una interrupción breve no cuenta como falso positivo por defecto.
- Si aplicamos los criterios a mano sobre una tabla, lo decimos así; no decimos que implementamos alertas automáticas.
- Los resultados de la simulación no se generalizan a redes reales.

## 🚧 Pendientes

### Ronda 1 — organizar y preparar
- [x] Pilar: actualizar README, progreso, alcance y buscar fuentes
- [ ] Tomás: diseñar la topología en GNS3, definir escenarios, intervalo entre pings, duración de las interrupciones, repeticiones y los dos criterios; guardar el protocolo en `demo/README.md` y la topología en `diagramas/`
- [ ] Martina: adaptar la introducción al objetivo, armar el índice según la modalidad B, explicar cómo buscamos y elegimos las fuentes y crear `documento/referencias.md`

### Ronda 2 — investigar y obtener resultados
- [ ] Pilar: leer y verificar las fuentes; redactar alertas accionables, fatiga de alarmas, SLI/SLO, innovaciones recientes, desafíos y seguridad; revisar los criterios del protocolo
- [ ] Tomás: armar la topología, correr cada escenario al menos tres veces y calcular notificaciones, incidentes detectados y demora de detección
- [ ] Martina: integrar el artículo (5–7 páginas), unificar términos y referencias, sumar la tabla comparativa y los resultados, escribir el resumen

### Ronda 3 — revisar y entregar
- [ ] Pilar: revisar citas y referencias; elegir los hallazgos para la infografía
- [ ] Tomás: comprobar que la demo se pueda reproducir, preparar la demostración de 3–5 minutos sin internet y dejar finales el diagrama, las configuraciones, los registros y las tablas
- [ ] Martina: póster A1, exportar a PDF, README final, revisión de `progreso.md` y del checklist

## 📝 Notas

- El `.gitignore` excluye los archivos `*.log`. Los registros de la simulación hay que guardarlos con otra extensión (por ejemplo `.txt` o `.csv`) para que se suban.
- La numeración de `documento/fuentes-investigacion.md` es provisional; la final va en `documento/referencias.md`.
- Hay dos fuentes para confirmar antes de entregar: NIST SP 800-92r1 todavía es un borrador (2023) y AlertGuardian es un preprint aceptado en ASE 2025.
