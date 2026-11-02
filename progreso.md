# Bitácora del grupo 3 - TP4

> Registro de avances, aportes de cada integrante, decisiones y pendientes.
> Solo se registran como realizadas las actividades efectivamente completadas.

---

## 👥 Integrantes

| Nombre | Usuario de GitHub | Rol en el grupo |
|--------|-------------------|-----------------|
| Facundo Daza | Shelldaza | Implementación de la demo, integración MCP, seguridad, pruebas y documentación técnica |
| Irineo Hiriart | IrineoHiriart215 | Investigación bibliográfica, artículo de revisión y póster |

Ambos participan en la revisión del trabajo, el registro de avances y la defensa.

## 🎯 Proyecto

- **Modalidad:** B — Artículo de Revisión del Estado del Arte.
- **Tema:** Inteligencia artificial aplicada al diagnóstico de redes mediante MCP y gemelos digitales.
- **Problema/objetivo:** Investigar cómo integrar IA y herramientas de administración de redes para diagnosticar problemas y evaluar correcciones en un entorno separado antes de recomendarlas para una red operativa.
- **Demostración:** Dos proyectos independientes en GNS3: EMPRESA, con acceso de lectura para la IA, y GEMELO, donde se permiten modificaciones controladas.

## 🗓️ Registro de avance

| Fecha | Qué se hizo | Quién | Commit |
|-------|-------------|-------|--------|
| Prueba previa - 09/10/2026 | Se implementó una prueba de concepto para ver la viabilidad del proyecto con un servidor MCP en Python conectado por SSH a un router MikroTik en GNS3. Se comprobó su funcionamiento desde ChatGPT mediante un túnel. | Facundo | Realizada localmente, sin commit. |
| Prueba previa - 09/10/2026 | Se cambió manualmente el nombre del router y se volvió a consultar mediante MCP para comprobar que la respuesta provenía del equipo en vivo. | Facundo | Realizada localmente, sin commit. |
| 26/10/2026 | Se definió la modalidad B y el alcance de una demo de diagnóstico con EMPRESA y GEMELO en GNS3. | Facundo | e1015cd |
| 26/10/2026 | Se propuso distribuir las responsabilidades: Facundo desarrolla la demo y aporta evidencias, mientras que Irineo prepara la investigación, el artículo y el póster. | Ambos | e1015cd  |
| 26/10/2026 | Se decidió excluir la sincronización automática del gemelo y el control de proyectos y nodos mediante la IA para reducir la complejidad. | Facundo | e1015cd |
| 27/10/2026 | Se configuró la identidad de Git y se agregaron en documento/fuentes.md las 10 fuentes iniciales con la cobertura de requisitos del artículo. | Irineo | d720509 |
| 27/10/2026 | Se creó demo/DesarrolloDemo.md y se documentó la Fase 0: topología, cableado, direccionamiento previsto, decisiones de diseño, seguridad y criterios de validación. Se definieron las fases restantes de implementación. | Facundo | 360a5e4 |
| 27/10/2026 | Se documentó la Fase 1 en demo/DesarrolloDemo.md y se incorporaron capturas de topología, identidades, IP estáticas, DHCP deshabilitado y acceso SSH. Se verificó que las direcciones de gestión quedan fuera del pool DHCP de VMnet1. | Facundo | bf59f3d |
| 27/10/2026 | Se configuraron las LAN, los enlaces internos, las loopbacks y las VPCS de EMPRESA. Se verificaron los tres enlaces entre routers en ambos sentidos y el acceso de cada host a su gateway, sin pérdidas en las pruebas. Se documentó F2 y se incorporaron ocho capturas. | Facundo | 19820b3 |
| 27/10/2026 | Se configuró OSPFv2 en área 0 con Router ID explícitos, interfaces pasivas y costos que favorecen R1–R3. Se verificaron dos vecinos FULL por router, rutas aprendidas y comunicación entre PC y SRV en ambos sentidos. Se documentó F3 y se incorporaron cinco capturas. | Facundo | 695761c |
| 28/10/2026 | Se configuró y documentó la seguridad de EMPRESA: cuentas y permisos, restricciones de gestión, servicios e interfaces sin uso deshabilitados, filtrado IPv4, bloqueo de entrada y tránsito IPv6 y autenticación OSPF SHA256. Se verificaron tráfico permitido y bloqueado, rechazo de escritura, prueba OSPF con clave incorrecta y recuperación, y acceso al puerto SSH desde orígenes autorizado y no autorizado. Se incorporaron 18 capturas y se documentaron las limitaciones. | Facundo | 64592db |
| 28/10/2026 | Se preparó GEMELO como copia de EMPRESA, con identidades, IP y MAC de gestión y credenciales propias. Se repararon las referencias de interfaces tras cambiar las MAC. Se verificaron ejecución simultánea, acceso SSH, vecinos OSPF Full y tráfico permitido y bloqueado. Se documentó F5 con siete capturas y la comprobación de discos activos distintos en R1. | Facundo | 6795726 |
| 28/10/2026 | Se implementó el inventario fijo, la carga local de credenciales y las conexiones SSH de lectura con verificación de clave de host, identidad y MAC de gestión. | Facundo | 595127e, 3c5c83d |
| 28/10/2026 | Se incorporaron consultas predefinidas, su publicación mediante FastMCP y una prueba de integración del protocolo y sus restricciones iniciales. | Facundo | 7ec2c01, c4b976d, 7dd7700 |
| 29/10/2026 | Se implementó una comparación de las reglas forward del escenario entre EMPRESA-R1 y GEMELO-R1 y se verificó su llamada mediante MCP. Esta herramienta fue retirada posteriormente al adoptar herramientas generales. | Facundo | 095b12d, af94b30 |
| 29/10/2026 | Se habilitaron conexiones administrativas exclusivamente en GEMELO. Se verificaron las conexiones con netadmin y el rechazo local de EMPRESA como destino administrativo. | Facundo | da60d23 |
| 29/10/2026 | Se implementaron y probaron acciones específicas para actualizar y corregir la regla de falla en GEMELO. Esta implementación fue reemplazada posteriormente para evitar un diagnóstico limitado a una solución predefinida. | Facundo | 74c4eb2 |
| 29/10/2026 | Se reemplazaron las consultas y acciones específicas por comandos generales: consultas con mcp_ro en ambos entornos y ejecución administrativa con netadmin exclusivamente en GEMELO. Se verificó la separación de destinos mediante MCP. | Facundo | 7e7c780 |
| 29/10/2026 | Se incorporó acceso mediante MCP a las consolas de GEMELO-PC y GEMELO-SRV. Se verificaron consultas a ambos extremos, rechazo de destinos no permitidos, comunicación PC → SRV y bloqueo hacia la loopback protegida. | Facundo | 8c2549d |
| 29/10/2026 | Se implementó iniciar.py para configurar, diagnosticar e iniciar Secure MCP Tunnel. Se corrigió el tratamiento de rutas Windows y se comprobaron llamadas desde ChatGPT al servidor del repositorio. | Facundo | 6272e95 |
| 29/10/2026 | Se incorporaron y ajustaron instrucciones de actualización, diagnóstico, validación e informes de cierre en Markdown dentro del chat. Se verificó la entrega de las instrucciones mediante la inicialización MCP y se realizaron ensayos desde ChatGPT. | Facundo | ef3da51, 4565d39, 955f52c, 3213e37, a614da7 |
| 29/10/2026 | Se documentó F6 con las herramientas definitivas, separación de accesos, consolas, arranque, verificaciones y limitaciones. Se actualizaron los requisitos de reproducción en demo/README.md. | Facundo | 85b0f0c |
| 29/10/2026 | Se documentó F7: introducción manual del bloqueo en EMPRESA, reproducción en GEMELO, diagnóstico mediante pings y contadores, deshabilitación de la regla únicamente en GEMELO y recuperación de respuestas. Quedó pendiente registrar la conservación del bloqueo hacia la loopback después de la corrección. | Facundo | c38d0af |

Las pruebas previas se registran retrospectivamente. Completar sus fechas y referencias a commits cuando se disponga de esos datos.

## 🚧 Pendientes / decisiones

### Decisiones tomadas

- [x] Elegir modalidad B.
- [x] Definir el tema del trabajo.
- [x] Utilizar GNS3 para representar tanto la red operativa como el gemelo.
- [x] Mantener EMPRESA con acceso de lectura para la IA.
- [x] Permitir pruebas de corrección únicamente en GEMELO.
- [x] Preparar e iniciar los proyectos manualmente.
- [x] Excluir la sincronización continua en segundo plano.
- [x] Permitir actualizar GEMELO mediante la IA a solicitud del usuario o para reproducir el problema investigado, conservando las diferencias intencionales entre entornos.
- [x] Utilizar herramientas generales para investigar y administrar GEMELO, sin incorporar una solución predefinida para la falla.
- [x] Automatizar el acceso a las consolas VPCS de GEMELO mediante MCP.
- [x] Incorporar instrucciones para presentar informes de intervención en el chat, sin agregar escritura de informes en el equipo local.
- [x] Entregar una recomendación sin aplicar cambios automáticamente sobre EMPRESA.

### Pendientes

- [x] Completar el usuario de GitHub de Irineo.
- [x] Confirmar aceptación del reparto de tareas entre ambos.
- [ ] Verificar colaboradores del grupo y docentes en el repositorio.
- [x] Incorporar y revisar el README 
- [x] Documentar el diseño de la demo y las fases de implementación.
- [x] Documentar la Fase 1 e incorporar capturas de la configuración de gestión.
- [x] Configurar el direccionamiento interno, las loopbacks y las VPCS de EMPRESA.
- [x] Verificar y documentar F2 con sus capturas.
- [x] Configurar OSPF y comprobar conectividad entre las LAN.
- [x] Documentar F3 e incorporar sus capturas.
- [x] Configurar y documentar la seguridad de EMPRESA.
- [x] Verificar permisos, filtrado y autenticación OSPF mediante pruebas positivas y negativas.
- [x] Preparar GEMELO y verificar su independencia y equivalencia para el escenario definido.
- [x] Documentar F5 e incorporar sus capturas.
- [x] Aplicar y verificar la separación de acceso: lectura en EMPRESA y administración en GEMELO.
- [x] Implementar y verificar las herramientas MCP definitivas para routers y consolas VPCS.
- [x] Configurar el arranque mediante Secure MCP Tunnel y comprobar la integración desde ChatGPT.
- [x] Documentar F6 y actualizar los requisitos de red y acceso.
- [x] Preparar y ensayar una falla reproducible de firewall.
- [x] Verificar el diagnóstico mediante configuración, pings y contadores, y la recuperación de conectividad después de corregir únicamente GEMELO.
- [x] Documentar el escenario y los resultados observados en F7.
- [ ] Registrar explícitamente la conservación del bloqueo hacia la loopback protegida después de la corrección.
- [ ] Preparar un .env.example sin secretos y completar las instrucciones de instalación del MCP.
- [ ] Validar la reproducción completa en otra computadora.
- [ ] Ejecutar al menos tres pruebas completas y registrar resultados.
- [ ] Preparar capturas y grabación de respaldo.
- [ ] Investigar y seleccionar las referencias bibliográficas.
- [ ] Redactar y revisar el artículo de modalidad B.
- [ ] Diseñar y revisar el póster A1.
- [ ] Completar el checklist oficial y ensayar la presentación.

## 📝 Notas

- La integración MCP está implementada y fue utilizada desde ChatGPT para consultar EMPRESA, administrar GEMELO y operar sus consolas VPCS.
- Ambos proyectos se preparan e inician manualmente. La actualización de configuraciones en GEMELO puede realizarse mediante la IA, conservando las diferencias intencionales de gestión, identidades, MAC y credenciales.
- No se implementó sincronización continua. Una actualización o comparación parcial no demuestra equivalencia completa de ambos escenarios.
- El escenario ensayado consiste en una regla de firewall que bloquea ICMP entre PC y SRV. Las herramientas generales no contienen una función específica para identificarla o corregirla.
- Las pruebas desde VPCS pueden ejecutarse mediante MCP y contrastarse con los contadores del firewall.
- La corrección se prueba exclusivamente en GEMELO. Su aplicación en EMPRESA queda a cargo del administrador.
- Los informes se presentan en el chat mediante instrucciones del servidor. Su formato y completitud se evalúan durante los ensayos; no están garantizados por una plantilla ejecutada desde el código.
- La interacción con ChatGPT mediante el túnel requiere Internet. Se preparará una grabación local como respaldo.
- No se subirán contraseñas, claves, imágenes de máquinas virtuales ni archivos pesados al repositorio.
- Cada integrante registrará sus aportes reales y realizará commits con su propia identidad.
- El artículo y el póster deberán distinguir las funcionalidades implementadas de las propuestas como trabajo futuro.