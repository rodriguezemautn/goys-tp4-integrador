# Bitácora del grupo — TP4

> Registro del avance continuo: tareas realizadas por cada integrante, decisiones técnicas y estado de los entregables para la Feria de Redes (17/11).

---

## Integrantes y Roles

| Integrante | Rol en el Proyecto | Foco Principal |
| :--- | :--- | :--- |
| **Alvite Damian** | Infraestructura & Red | Docker Compose, bridge virtual, topología y víctima |
| **Capre Rodrigo** | SOC & Sensor IDS | Suricata 8.x, configuración (`suricata.yaml`) y reglas de firma (`local.rules`) |
| **Moscuzza Vicente** | AIOps & SecOps | Agente autónomo Python, integración con Groq LLM y firewall iptables |
| **Di Grappa Emiliano** | NOC & Observabilidad | Servidor Prometheus, aprovisionamiento de Grafana y dashboards |
| **Elizalde Benjamin** | Demo & Documentación | Scripts de simulación de ataque, redacción de informe y póster A1 |

---

## Proyecto

- **Modalidad:** A — Proyecto de Desarrollo
- **Tema:** Plataforma Integrada NOC/SOC con Remediación Agéntica Automatizada (AIOps / SecOps) y Observabilidad en Tiempo Real.
- **Problema/Objetivo:** Resolver la desconexión típica entre el monitoreo de infraestructura (NOC) y la respuesta ante incidentes de ciberseguridad (SOC). Implementamos una arquitectura contenerizada donde Suricata IDS inspecciona el tráfico de red, emite telemetría estructurada (JSON) hacia un agente autónomo potenciado por un LLM (Groq API) que evalúa el contexto en milisegundos y ejecuta contramedidas de red dinámicas (iptables `DOCKER-USER`), reflejando la neutralización del ataque en Grafana en tiempo real.

---

## Registro de avance

| Fecha | Qué se hizo | Quién / Rol | Estado |
| :--- | :--- | :--- | :--- |
| 08/11 | Aprobación de la propuesta por el docente y creación de estructura inicial de directorios | Todo el equipo | Hecho |
| 09/11 | Creación de topología Docker Compose y configuración de bridge virtual `br-monitored` | Integrante 1 | Hecho |
| 09/11 | Confección de página institucional de prueba en Nginx (`lab/web/index.html`) | Integrante 1 | Hecho |
| 09/11 | Creación de `suricata.yaml` y validación de sintaxis con Suricata 8.0 | Integrante 2 | Hecho |
| 09/11 | Definición de firmas en `local.rules` (SQLi, escáneres, path traversal, DoS) | Integrante 2 | Hecho |
| 09/11 | Corrección de dependencias (`requirements.txt` con SDK `groq`) | Integrante 3 | Hecho |
| 09/11 | Desarrollo de `agent.py` con Groq LLM, latencia <200ms, fallback y servidor HTTP de telemetría | Integrante 3 | Hecho |
| 09/11 | Aprovisionamiento de Prometheus y Dashboard de Grafana (`noc_soc_dashboard.json`) | Integrante 4 | Hecho |
| 09/11 | Creación de script interactivo de demostración en vivo (`demo/simular_ataque.sh`) | Integrante 5 | Hecho |

---

## Pendientes para la Feria

- [x] Configuración y validación del entorno Docker Compose base
- [x] Agente de remediación conectado a Groq API con fallback offline
- [x] Aprovisionamiento de dashboards en Grafana
- [ ] Colocar la `GROQ_API_KEY` en `lab/.env` y validar remediación en vivo
- [ ] Redacción final del documento técnico en `documento/entrega-modalidad-a.md`
- [ ] Diseño final e impresión del póster en formato A1 en `poster/`
- [ ] Ensayo general de la demo previa al 17/11

---

## Notas Técnicas y Decisiones de Arquitectura

1. **Uso de Groq:** Se seleccionó Groq (`qwen/qwen3.8-27b`) por su latencia de inferencia ultra reducida (~150 ms) y soporte robusto de salida JSON estructurada, requisito indispensable para que una remediación activa a nivel de red sea efectiva antes de que el ataque cause impacto.
2. **Resiliencia en Vivo (Feria):** El agente cuenta con un modo de contingencia heurística local automático. Si el WiFi de la feria llega a fallar, el agente sigue bloqueando los ataques basándose en las firmas de Suricata sin interrumpir la demo.
3. **Cadena iptables `DOCKER-USER`:** Se decidió insertar las reglas de bloqueo en `DOCKER-USER` para asegurar que el kernel descarte los paquetes maliciosos antes de que el subsistema NAT de Docker los reenvíe a los contenedores.
