# Fuentes relevadas — investigación bibliográfica

Primera búsqueda de fuentes sobre calidad de alertas, SLI/SLO y fatiga de alarmas. De cada una anotamos los datos en formato IEEE, qué tipo de fuente es y para qué nos sirve en la pregunta de investigación. La numeración es provisional; la final se arma en `documento/referencias.md`.

**Fecha de consulta de los recursos en línea:** 12 de noviembre de 2026.

## 1. Qué cubre cada fuente

| Requisito de la modalidad B | Fuentes |
|-----------------------------|---------|
| Artículo académico | [10], [11], [12], [13], [14] |
| Documentación técnica oficial | [1], [5] |
| RFC o estándar | [6], [7], [8], [9] |
| Avances de los últimos tres años | [9] (2023), [12] (2025), [13] (2024), [14] (2026) |
| Seguridad y protección de registros | [8], [9], [12] |

| Tema | Fuentes |
|------|---------|
| Observabilidad y monitoreo | [1], [2], [7] |
| Alertas accionables | [2], [4] |
| SLI / SLO | [3], [4] |
| Criterios de activación (primer fallo o duración mínima) | [4], [5] |
| Fatiga de alarmas y tormentas de alertas | [10], [11], [12] |
| Innovaciones recientes | [13], [14] |
| Conectividad ICMP (base de la simulación) | [6], [7] |

## 2. Fuentes

### Documentación técnica y libros de referencia

**[1]** OpenTelemetry Authors, "Observability primer," *OpenTelemetry Documentation*. [En línea]. Disponible: https://opentelemetry.io/docs/concepts/observability-primer/
- **Tipo:** documentación técnica oficial. Ya la usamos en el borrador de la introducción.
- **Para qué sirve:** define la observabilidad a partir de las señales que produce un sistema (métricas, logs y trazas). Nos da la base para la introducción.

**[2]** R. Ewaschuk, "Monitoring distributed systems," en *Site Reliability Engineering: How Google Runs Production Systems*, B. Beyer, C. Jones, J. Petoff y N. R. Murphy, Eds. Sebastopol, CA, EE. UU.: O'Reilly Media, 2016, cap. 6. [En línea]. Disponible: https://sre.google/sre-book/monitoring-distributed-systems/
- **Tipo:** libro técnico de referencia en la industria (versión en línea oficial).
- **Para qué sirve:** da principios para armar alertas. Dice que un buen sistema de alertas tiene mucha señal y muy poco ruido, y separa el síntoma ("qué está roto") de la causa ("por qué"). Lo usamos para explicar qué es una alerta accionable y por qué no conviene avisar cosas que no necesitan que alguien actúe.

**[3]** C. Jones, J. Wilkes, N. Murphy y C. Smith, "Service level objectives," en *Site Reliability Engineering: How Google Runs Production Systems*, B. Beyer, C. Jones, J. Petoff y N. R. Murphy, Eds. Sebastopol, CA, EE. UU.: O'Reilly Media, 2016, cap. 4. [En línea]. Disponible: https://sre.google/sre-book/service-level-objectives/
- **Tipo:** libro técnico de referencia en la industria.
- **Para qué sirve:** define SLI (lo que se mide), SLO (el valor objetivo para ese SLI) y SLA (el acuerdo con consecuencias). Nos ayuda a explicar cuándo una falla es lo bastante importante como para justificar una alerta.

**[4]** S. Thurgood *et al.*, "Alerting on SLOs," en *The Site Reliability Workbook: Practical Ways to Implement SRE*, B. Beyer, N. R. Murphy, D. K. Rensin, K. Kawahara y S. Thorne, Eds. Sebastopol, CA, EE. UU.: O'Reilly Media, 2018, cap. 5. [En línea]. Disponible: https://sre.google/workbook/alerting-on-slos/
- **Tipo:** libro técnico de referencia en la industria.
- **Para qué sirve (es la fuente más cercana a nuestra pregunta):**
  - Propone cuatro cosas para evaluar una estrategia de alertas: precisión (qué parte de las alertas corresponde a eventos importantes), exhaustividad o *recall* (qué parte de los eventos importantes generó alerta), tiempo de detección y tiempo de restablecimiento.
  - Compara seis estrategias, de la más simple a la más completa. Va desde el umbral inmediato hasta las alertas con varias ventanas y varias tasas de consumo del presupuesto de error.
  - El umbral inmediato detecta rápido pero tiene poca precisión. Es lo mismo que nuestro **criterio 1** (primer fallo).
  - Pedir que la condición dure un tiempo mínimo mejora la precisión, pero empeora la exhaustividad y el tiempo de detección, porque la espera es la misma sea cual sea la gravedad. Además, si la falla se corta un momento, la cuenta vuelve a cero, así que una falla que va y viene puede no avisar nunca. Es lo mismo que nuestro **criterio 2** (fallos seguidos), y es algo que podemos comprobar en la simulación.
  - Nos sirve de base para la tabla comparativa del estado del arte.

**[5]** Prometheus Authors, "Alerting rules," *Prometheus Documentation*. [En línea]. Disponible: https://prometheus.io/docs/prometheus/latest/configuration/alerting_rules/
- **Tipo:** documentación oficial de una herramienta de monitoreo muy usada.
- **Para qué sirve:** muestra cómo se aplican los dos criterios en una herramienta real. Una regla sin `for` se activa en la primera evaluación en que se cumple la condición (criterio 1). Con `for`, la alerta queda en estado *pending* y solo pasa a *firing* si la condición se mantiene durante ese tiempo (criterio 2). También existe `keep_firing_for`, que mantiene la alerta activa un rato después de que la condición deja de cumplirse. Por otro lado, separa la evaluación de reglas (Prometheus) del envío de notificaciones (Alertmanager), lo que nos ayuda a definir bien qué es una "notificación".

### RFC y estándares

**[6]** J. Postel, "Internet Control Message Protocol," RFC 792, sep. 1981. doi: 10.17487/RFC0792.
- **Tipo:** RFC (Internet Standard, STD 5).
- **Para qué sirve:** define los mensajes ICMP Echo y Echo Reply, que son los que usa el ping de la simulación. Aclara que ICMP informa problemas de la red pero no hace que IP sea confiable: no garantiza que un paquete o un mensaje de control llegue. Por eso un solo ping fallido no alcanza para decir que hay una caída.

**[7]** A. Morton, "Active and Passive Metrics and Methods (with Hybrid Types In-Between)," RFC 7799, may. 2016. doi: 10.17487/RFC7799.
- **Tipo:** RFC (informativo, IETF).
- **Para qué sirve:** distingue la medición activa, que genera sus propios paquetes para medir, de la pasiva, que solo observa el tráfico que ya existe. Nuestra simulación es una medición activa, y esto nos permite comentar que el tráfico de prueba puede afectar lo que se mide.

**[8]** R. Gerhards, "The Syslog Protocol," RFC 5424, mar. 2009. doi: 10.17487/RFC5424.
- **Tipo:** RFC (Proposed Standard).
- **Para qué sirve:** es el estándar para enviar mensajes de eventos. En la parte de seguridad habla, entre otras cosas, de la reproducción de mensajes (*replay*), la entrega confiable, la integridad, la observación de los mensajes y la denegación de servicio. Lo usamos para el apartado sobre cómo proteger los registros en los que se basan las alertas.

**[9]** K. Scarfone y M. Souppaya, "Cybersecurity Log Management Planning Guide," NIST, Gaithersburg, MD, EE. UU., NIST SP 800-92r1 (Initial Public Draft), oct. 2023. doi: 10.6028/NIST.SP.800-92r1.ipd.
- Versión final vigente: K. Kent y M. Souppaya, "Guide to Computer Security Log Management," NIST SP 800-92, sep. 2006. doi: 10.6028/NIST.SP.800-92.
- **Tipo:** guía de un organismo de estándares (NIST).
- **Para qué sirve:** la versión de 2006 define la gestión de registros como el proceso de generar, transmitir, guardar, analizar y descartar los registros de seguridad, y tiene apartados sobre protección y análisis de registros. También dice que la cantidad y variedad de registros creció mucho y que eso hace difícil analizarlos bien, lo que se conecta con la fatiga de alarmas. La revisión de 2023 es una guía para planificar la gestión de registros a nivel de toda la organización; todavía es un borrador, así que hay que citarla así.

### Artículos académicos

**[10]** M. Cvach, "Monitor alarm fatigue: An integrative review," *Biomedical Instrumentation & Technology*, vol. 46, no. 4, pp. 268–277, jul.–ago. 2012. doi: 10.2345/0899-8205-46.4.268.
- **Tipo:** revisión integrativa con revisión por pares (72 artículos).
- **Para qué sirve:** de acá viene el concepto de fatiga de alarmas, en el monitoreo de pacientes. Cuando hay demasiadas alarmas, y muchas son falsas o no importan, el personal se satura y deja de reaccionar. Entre las recomendaciones aparece poner retardos cortos antes de que suene la alarma, pero sin alargarlos tanto que se vuelva peligroso. Es el mismo equilibrio entre ruido y demora que estudiamos nosotros. La usamos como antecedente del concepto, no como evidencia sobre redes.

**[11]** N. Zhao *et al.*, "Understanding and handling alert storm for online service systems," en *Proc. ACM/IEEE 42nd Int. Conf. Software Engineering: Software Engineering in Practice (ICSE-SEIP)*, 2020, pp. 162–171. doi: 10.1145/3377813.3381363.
- **Tipo:** artículo de conferencia con revisión por pares, con datos reales de un banco comercial.
- **Para qué sirve:** es el primer estudio con datos reales sobre las "tormentas de alertas", que pasan cuando una falla viene acompañada de muchísimas alertas a la vez y eso complica el diagnóstico. Proponen detectar la tormenta y resumirla en unas pocas alertas representativas. Muestra que la cantidad de notificaciones es un problema real y que se puede medir.

**[12]** S. Tariq, M. Baruwal Chhetri, S. Nepal y C. Paris, "Alert fatigue in security operations centres: Research challenges and opportunities," *ACM Computing Surveys*, vol. 57, no. 9, art. 224, pp. 1–38, abr. 2025. doi: 10.1145/3723158.
- **Tipo:** revisión sistemática en revista académica.
- **Para qué sirve:** revisa lo que hay en la literatura y en la industria sobre fatiga de alertas en los centros de operaciones de seguridad (SOC). Lo organiza en tres enfoques: automatización, ayuda al analista y colaboración entre personas e IA. Encuentra cuatro causas principales de la fatiga y propone líneas para investigar. Nos aporta la parte de seguridad y de desafíos.

**[13]** J. Kuang *et al.*, "Knowledge-aware alert aggregation in large-scale cloud systems: A hybrid approach," en *Proc. 46th Int. Conf. Software Engineering: Software Engineering in Practice (ICSE-SEIP '24)*, Lisboa, Portugal, 2024. doi: 10.1145/3639477.3639745.
- **Tipo:** artículo de conferencia con revisión por pares.
- **Para qué sirve:** presenta COLA, que agrupa las alertas que vienen de una misma falla. Para eso combina correlaciones entre alertas con un modelo de lenguaje que usa los procedimientos operativos de cada alerta. Es un ejemplo de innovación reciente para reducir notificaciones sin perder información.

**[14]** G. Yu *et al.*, "AlertGuardian: Intelligent alert life-cycle management for large-scale cloud systems," arXiv:2601.14912, ene. 2026 (aceptado en ASE 2025). doi: 10.48550/arXiv.2601.14912.
- **Tipo:** preprint de un artículo aceptado en una conferencia.
- **Para qué sirve:** trata la fatiga de alertas en todo el ciclo de vida de la alerta: se crea la regla, se dispara, alguien la atiende y después se mejora la regla. Usa modelos de grafos para filtrar ruido, modelos de lenguaje para resumir alertas y agentes para mejorar las reglas. Señala que herramientas como Alertmanager se enfocan en configurar y disparar reglas, pero no en si esas reglas son buenas. Representa lo más nuevo del área.

## 3. Lo que falta verificar

- [3]: los autores del capítulo (Jones, Wilkes, Murphy y Smith) los sacamos de un comentario del libro hecho por un SRE de Google; confirmarlos en la página del capítulo o en el libro.
- [7]: abrir https://doi.org/10.17487/RFC7799 para confirmar el DOI (sigue el formato oficial de los RFC, pero no lo vimos impreso en la ficha).
- [11]: abrir https://doi.org/10.1145/3377813.3381363 para confirmar el DOI (lo encontramos como enlace a la ACM Digital Library; las páginas 162–171 están confirmadas en dblp).
- [14]: ver si ya salió la versión publicada en las actas de ASE 2025 y, si salió, citar esa con su DOI.
- [9]: antes de entregar, fijarse si NIST ya publicó la versión final de SP 800-92r1.
- [4], [5]: volver a mirar las páginas cuando redactemos, porque son documentos en línea que pueden cambiar.
- [10]: confirmar en el texto completo lo de los retardos cortos antes de alarmar (lo sacamos de una reseña del artículo).
- [10]: usarla solo como antecedente de la fatiga de alarmas y aclarar que viene del ámbito clínico.
