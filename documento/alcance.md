# Alcance del trabajo

**Título:** De las métricas a las acciones: calidad de las alertas y detección de fallas en servicios
**Modalidad:** B — Artículo de Revisión del Estado del Arte, con una mini simulación

## 1. Tema

Observabilidad de servicios: criterios de alertado para detectar fallas y reducir notificaciones innecesarias. Nos concentramos en el paso que va de la métrica a la notificación que le llega a quien opera la red, y en cómo ese paso cambia la calidad de las alertas.

## 2. Pregunta de investigación

¿Cómo influyen los criterios de activación de alertas en la cantidad de notificaciones y en el tiempo de detección de una falla?

## 3. Objetivos

### 3.1. Objetivo general

Analizar cómo se relacionan el criterio que activa una alerta, la cantidad de notificaciones que genera y lo que tarda en detectar una falla. Para eso usamos bibliografía técnica y académica y una mini simulación.

### 3.2. Objetivos específicos

1. Explicar qué hace que una alerta sea accionable y cómo se mide su calidad (precisión, exhaustividad, tiempo de detección y tiempo de restablecimiento).
2. Describir para qué sirven los SLI y SLO a la hora de decidir cuándo alertar.
3. Resumir qué se sabe sobre la fatiga de alarmas y las tormentas de alertas, y qué consecuencias tienen en la operación y en la seguridad.
4. Identificar innovaciones de los últimos tres años para reducir, agrupar y priorizar alertas.
5. Comparar, con los mismos registros de conectividad de GNS3, un criterio que avisa con el primer fallo y otro que espera varios fallos seguidos.
6. Discutir ventajas, limitaciones y desafíos de cada criterio, incluyendo cómo proteger los registros en los que se basan las alertas.

## 4. Partes del trabajo

### 4.1. Revisión del estado del arte

- Observabilidad: métricas, registros (logs) y trazas.
- Alertas accionables: síntomas y causas, señal y ruido.
- SLI, SLO y presupuesto de error para decidir qué falla es importante.
- Estrategias de alertado: umbral inmediato, tiempo mínimo que tiene que durar la condición, ventanas de evaluación y tasas de consumo del presupuesto de error.
- Fatiga de alarmas y tormentas de alertas.
- Innovaciones recientes: agrupar, reducir y priorizar alertas con aprendizaje automático y modelos de lenguaje.
- Seguridad: que los registros sean íntegros, estén disponibles y tengan control de acceso; alertas de seguridad y fatiga.
- Desafíos que siguen abiertos.

### 4.2. Mini simulación

- Topología chica en GNS3 con un cliente, un servidor y los equipos intermedios que hagan falta.
- Comprobaciones de conectividad con ping (ICMP Echo) cada cierto intervalo.
- Escenarios: funcionamiento normal, interrupción breve, caída sostenida y recuperación.
- Cada escenario se corre al menos tres veces.
- Los dos criterios se aplican sobre los mismos registros originales.
- Medimos notificaciones emitidas, incidentes detectados y demora de detección.

El protocolo (intervalo entre pings, duración de las interrupciones, cuántos fallos seguidos usa el criterio 2 y cómo se calcula cada valor) está en `demo/README.md`.

## 5. Términos que usamos

| Término | Qué significa en este trabajo |
|---------|-------------------------------|
| Comprobación | Un ping del cliente al servidor; puede dar éxito o fallo. |
| Notificación | Un aviso que daría el criterio en un momento determinado. |
| Incidente | Una interrupción que, según lo que acordemos antes de medir, necesita que alguien intervenga. |
| Demora de detección | El tiempo entre que empieza la interrupción y la primera notificación que le corresponde. |
| Criterio 1 | Avisar con el primer fallo. |
| Criterio 2 | Avisar después de *N* fallos seguidos; el valor de *N* se fija en el protocolo de la simulación. |

Antes de aplicar los criterios definimos qué interrupciones necesitan intervención. Por eso una interrupción breve no cuenta automáticamente como falso positivo: depende de esa definición.

## 6. Límites

- El artículo es una revisión del estado del arte. La simulación lo complementa, no lo reemplaza.
- La simulación se hace en un laboratorio controlado, con una sola métrica (conectividad por ICMP) y pocas repeticiones. Sirve para mostrar cómo se comportan los criterios, pero no para generalizar a redes o servicios reales.
- Que el ping responda no quiere decir que el servicio funcione. Un servidor puede contestar el ping y tener caído el servicio, o al revés, si ICMP está filtrado.
- Si los criterios se aplican a mano sobre una tabla de registros, lo decimos así. No decimos que implementamos un sistema de alertas automático.
- No evaluamos herramientas comerciales ni comparamos productos.
- Informamos los valores que realmente obtuvimos, junto con las limitaciones y cosas raras que aparezcan.

## 7. Seguridad

La seguridad la vemos desde dos lados:

1. **Los registros como evidencia:** las alertas y las conclusiones dependen de registros con la hora correcta, que no se hayan modificado ni perdido.
2. **Alertas de seguridad:** la fatiga de alarmas también pasa en los centros de operaciones de seguridad (SOC), donde tener demasiados avisos puede hacer que se pase por alto un incidente real.
