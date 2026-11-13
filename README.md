# De las métricas a las acciones: calidad de las alertas y detección de fallas en servicios

> **TP4 — Proyecto Integrador** · Gestión Operativa y Seguridad en Redes (GOYS) · UTN FR La Plata
> **Modalidad B:** Artículo de Revisión del Estado del Arte, con una mini simulación en GNS3.

## Integrantes

| Integrante | Usuario de GitHub | Qué hace cada uno |
|------------|-------------------|-------------------|
| Pilar Giannelli | `pilargiannelli` | Busca y revisa las fuentes, redacta la parte de investigación |
| Tomás Terruli | `TomasTerruli` | Diseña, arma y mide la mini simulación |
| Martina Castellani | `Marticaste144` | Organiza e integra el artículo, el póster y el repositorio |

Los resultados los interpretamos entre los tres y las conclusiones las acordamos juntos.

## Tema

Observabilidad de servicios: criterios de alertado para detectar fallas y reducir notificaciones innecesarias. Queremos ver cómo pasar de las métricas a avisos que realmente le sirvan a quien opera una red o un servicio.

## Pregunta de investigación

¿Cómo influyen los criterios de activación de alertas en la cantidad de notificaciones y en el tiempo de detección de una falla?

## Objetivo

Revisar qué se sabe hoy sobre la calidad de las alertas (alertas accionables, SLI/SLO, fatiga de alarmas e innovaciones recientes) y sumarle una mini simulación donde comparamos dos criterios de alerta sobre los mismos registros de conectividad:

- **Criterio 1:** avisar con el primer fallo.
- **Criterio 2:** avisar recién después de varios fallos seguidos.

Para cada criterio contamos cuántas notificaciones se emiten, cuántos incidentes se detectan y cuánto tarda en detectarlos.

## Alcance

- **Revisión bibliográfica:** observabilidad, estrategias de alertado, SLI/SLO, fatiga de alarmas, innovaciones de los últimos tres años, seguridad y protección de los registros, y desafíos. Usamos al menos seis fuentes verificadas, con al menos un artículo académico, una documentación oficial y un RFC o estándar.
- **Mini simulación:** una red chica en GNS3 (cliente, servidor y los equipos del medio) donde comprobamos la conectividad con ping cada cierto tiempo. Los escenarios son funcionamiento normal, interrupción breve, caída sostenida y recuperación. Cada uno se repite al menos tres veces.
- **Límites:** la simulación es un complemento para discutir ventajas y limitaciones, no algo para sacar conclusiones generales sobre redes reales. Si aplicamos los criterios a mano sobre una tabla, lo decimos así y no lo presentamos como un sistema de alertas automático.

El detalle está en [`documento/alcance.md`](documento/alcance.md).

## Entregables

| Entregable | Qué incluye | Dónde está |
|------------|-------------|------------|
| Artículo de revisión | 5–7 páginas: resumen, introducción, estado del arte, comparación, innovaciones emergentes, oportunidades y desafíos (con seguridad), conclusiones y referencias | `documento/` (PDF y editable) |
| Mini simulación | Protocolo, topología, configuraciones, registros originales, tablas de resultados y capturas | `demo/`, `diagramas/`, `capturas/` |
| Póster A1 | Problema, objetivo, diagrama de red, metodología, resultados comparativos, conclusiones y QR al repositorio | `poster/` (PDF y editable) |
| Repositorio | Bitácora, instrucciones para reproducir la demo y enlaces finales | este repositorio |

## Archivos de trabajo

| Archivo | Qué tiene |
|---------|-----------|
| [`progreso.md`](progreso.md) | Bitácora: avances, decisiones y pendientes |
| [`documento/alcance.md`](documento/alcance.md) | Pregunta, objetivos y límites |
| [`documento/fuentes-investigacion.md`](documento/fuentes-investigacion.md) | Fuentes que encontramos, sus datos y para qué nos sirve cada una |
| [`documento/introduccion.md`](documento/introduccion.md) | Borrador de la introducción |

## Cómo trabajamos en GitHub

El orden es Pilar → Tomás → Martina, y se repite en las tres rondas (organizar y preparar; investigar y obtener resultados; revisar y entregar). En cada turno, el que le toca actualiza su copia de `main`, crea una rama para su tarea, anota lo que hizo en `progreso.md`, hace su commit, abre un PR hacia `main` de `TomasTerruli/goys-tp4-integrador` y otro integrante lo revisa y hace el merge.

---

## Guía de la cátedra

> **GOYS** — Gestión Operativa y Seguridad en Redes · UTN FR La Plata
> **Peso:** 60% de la nota del bloque Redes/Operación
> **Muestra:** Feria de Redes (última clase del bloque)

Este es el **repositorio base del Trabajo Práctico Integrador (TP4)**. Un integrante del grupo lo **forkea**, agrega al resto como **colaboradores**, y todo el trabajo colaborativo del TP4 se hace acá.

---

### 1. ¿Qué es el TP4?

El TP4 integra **las 3 áreas de la materia** —**Redes**, **Operación (Gestión)** y **Seguridad**— en un proyecto con mayor autonomía:

| Área | Qué cubre |
|------|-----------|
| 🔌 **Redes** | Topología, routing (BGP/OSPF), switching, VXLAN, containers, L2/L3 |
| ⚙️ **Operación (Gestión)** | Automatización (Ansible), monitoreo (Prometheus/Grafana), orquestación (K3s), GitOps |
| 🛡️ **Seguridad** | Segmentación, network policies, mTLS, Zero Trust, Cilium/Hubble |

Se muestra al final en una **Feria de Redes** (formato congreso): cada grupo monta una **estación** con póster, documento y demo funcionando, y la defiende frente a docentes, compañeros e invitados.

Cada grupo elige **UNA** de las 3 modalidades (sección 2).

---

### 2. Modalidades (elegir UNA)

| Modalidad | Qué es | Template |
|-----------|--------|----------|
| **A — Proyecto de Desarrollo** | Diseñar e implementar una solución que integre redes, containers, automatización y monitoreo | `templates/template-modalidad-a.md` |
| **B — Artículo de Revisión del Estado del Arte** | Investigar el estado del arte de una tecnología, sus innovaciones emergentes y oportunidades | `templates/template-modalidad-b.md` |
| **C — Trabajo de Campo** | Analizar una red real (o caso de estudio) y proponer mejoras | `templates/template-modalidad-c.md` |

#### ¿Cómo integra cada modalidad las 3 áreas?

| Área | A — Desarrollo | B — Estado del Arte | C — Trabajo de Campo |
|------|----------------|---------------------|----------------------|
| 🔌 **Redes** | Topología + routing + containers **implementados** | Estado del arte de una tecnología de red | Relevamiento de la red real |
| ⚙️ **Operación** | Ansible + monitoreo **automatizados** | Network automation, observabilidad | Propuesta de automatización/monitoreo |
| 🛡️ **Seguridad** | Network policies, segmentación, mTLS | Zero Trust, eBPF security, mTLS | Segmentación + mejoras de seguridad |

> ⚠️ **La seguridad NO es opcional en ninguna modalidad.** Sin importar cuál elijan, el proyecto debe mostrar cómo aborda la seguridad de la red.

> 📖 El detalle de cada modalidad está en su template. El formato del documento (portada UTN, A4, estilo) está en `templates/template-documento.md`.

---

### 3. Arrancar: fork + grupo + colaboradores

#### 3.1. Un integrante hace el fork

1. Ese integrante entra a este repositorio y hace **Fork** (botón arriba a la derecha).
2. Ahora tiene una copia en su cuenta: `tu-usuario/goys-tp4-integrador`.

#### 3.2. Sumar colaboradores (compañeros + docentes)

1. En el fork, ir a **Settings → Collaborators and teams → Add people**.
2. Agregar a **cada integrante** del grupo (por su usuario de GitHub).
3. Agregar también a los **docentes** para que puedan revisar el trabajo:
   - `ofalabel` — **Osvaldo Falabella** (titular de la materia)
   - `rodriguezemautn` — **Emanuel Rodríguez** (bloque Redes/Operación)
4. Cada uno acepta la invitación (llega por mail/notificación).

> ⚠️ **Todos los integrantes deben aparecer como colaboradores y con commits propios.** Si alguien no aparece en el historial de git, no acredita el TP.

#### 3.3. Clonar y configurar identidad

```bash
# Cada integrante clona el fork
git clone https://github.com/<grupo>/goys-tp4-integrador.git
cd goys-tp4-integrador

# Configurar identidad (usar el mail de la facultad)
git config user.name "Apellido, Nombre"
git config user.email "tu-email@alumnos.frlp.utn.edu.ar"
```

---

### 4. Estructura del repositorio

```
goys-tp4-integrador/
├── README.md              # esta guía
├── progreso.md            # bitácora del grupo (qué hizo cada uno)
├── templates/             # templates de modalidad + documento + checklist
├── documento/             # documento final (PDF + fuente)
├── poster/                # póster A1 (editable + PDF) + guía
├── demo/                  # código/scripts de la demo (estación)
├── capturas/              # capturas y evidencias
└── diagramas/             # diagramas de arquitectura/topología
```

---

### 5. Trabajo colaborativo (cómo laburar en grupo)

#### Flujo recomendado (ramas cortas + pull requests)

```bash
# 1. Actualizar antes de empezar
git pull origin main

# 2. Rama por tarea
git checkout -b documento-introduccion

# 3. Trabajar y commitear seguido (mensajes claros)
git add .
git commit -m "documento: escribe introducción y objetivos"

# 4. Subir y abrir PR
git push origin documento-introduccion
# En GitHub: abrir Pull Request → otro integrante revisa → merge

# 5. Volver a main y repetir
git checkout main
git pull origin main
```

#### Reglas de oro

- **Commits de TODOS**: cada integrante commitea con su usuario. Verificar al final con `git log --oneline`.
- **No pushear directo a `main` sin revisar** (usar PRs para el documento y decisiones grandes).
- **Pull antes de push** para no pisar trabajo ajeno.
- **Nada de binarios/secretos**: no subir contraseñas, IPs privadas reales ni archivos pesados (ver `.gitignore`).

---

### 6. Entregables (comunes a las 3 modalidades)

| Elemento | Descripción |
|----------|-------------|
| 📄 **Documento** | 5-7 págs (modalidades A y B) o 6-8 (C), en PDF, en `documento/` |
| 🖼️ **Póster A1** | Sintetiza problema, metodología, resultados y conclusiones. Autocontenido. En `poster/` |
| 💻 **Demo / estación** | Funciona en la laptop del grupo, **offline**. En `demo/` |
| 📂 **Repositorio** | Documento, fuentes, configs, capturas, póster editable + PDF |

> ✅ Checklist completo en `templates/checklist-entrega.md`. Usarlo antes del ensayo y antes de la Feria.

---

### 7. Cronograma

| Momento | Qué pasa |
|---------|----------|
| Clase 2 (jueves 20/8) | Se forman los grupos (3-4), los mismos para toda la cursada |
| Durante la cursada | Cada clase alimenta el TP4; el grupo define modalidad y tema |
| Jueves 29/10 | Muestra TP3 + preparación/ensayos del TP4 |
| Jueves 5/11 | **Feria de Redes** — muestra y defensa |

---

### 8. Evaluación (60%)

La nota combina **dimensión técnica (60%)** y **"Saber Ser" (40%)** — trabajo en equipo, comunicación, compromiso, pensamiento crítico, ética.

- **Promoción directa:** TP4 >= 6 (con todos los TPs >= 6 y 75% de asistencia).
- **Cursada regular:** TP4 >= 4 (más el resto de condiciones).

> ⚠️ **Ausencia injustificada en la Feria = TP4 desaprobado.**

---

**GOYS — UTN FR La Plata** · Titular: Osvaldo Falabella · Bloque Redes/Operación: Emanuel Rodríguez
