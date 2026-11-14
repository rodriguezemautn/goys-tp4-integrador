# Plan del grupo: TP4 Propuesta A

Somos 5 y el proyecto tiene dos entregas: el informe el **martes 10/11** y la Feria el **martes 17/11**. El laboratorio corre en una sola laptop y el resto del trabajo se hace por git, con commits propios de cada integrante.

## Una sola laptop, desarrollo en grupo

El laboratorio se levanta en una sola computadora, la **estación**. Las pautas ya lo piden así: la demo tiene que funcionar offline en la laptop del grupo. Los demás integrantes no necesitan VMs ni Docker: alcanza con git y un editor.

| Quién | Qué hace | Dónde |
|---|---|---|
| Quien opera la estación | Levanta el laboratorio y aplica los cambios ya mergeados con `git pull` | La estación |
| Los otros cuatro | Cambian manifiestos, scripts y texto en ramas cortas con PR | Su computadora |
| Todos | Prueban en las sesiones de laboratorio, por videollamada o en persona | La estación, con pantalla compartida |

Reglas para que esto funcione:

- **Cada uno commitea lo suyo con su usuario.** Quien no aparece en el historial no acredita el TP. La estación no commitea a nombre de otros: comparte las capturas y cada dueño las sube.
- **Toda prueba deja evidencia.** Va en `capturas/` y las mediciones en `demo/prueba-ram/RESULTADOS.md`.
- **Nada de secretos en git:** ni `vault.yml`, ni `.claves/`, ni `.vault_pass`, ni IPs reales.

**Riesgo principal:** si la estación falla el 17/11 no hay demo, y faltar a la Feria desaprueba el TP4. Por eso hay una segunda laptop de respaldo y un video grabado (ver Etapa 2).

## Quién hace qué

| Integrante | Área | Es dueño de | Sección del informe | En la Feria |
|---|---|---|---|---|
| **1. Infraestructura** (quien levanta el laboratorio) | Operación | `Vagrantfile`, `ansible/`, `mac/`, `windows/`, `prueba-ram/` | 2.2 Componentes, 3.3 Automatización, 4.3 Pruebas de automatización | Maneja la demo |
| **2. Red** | Redes | `routeros/`, `k8s/metallb/`, captura de BGP en Wireshark | 2.1 Diagrama, 3.1 Configuración de red, 4.1 Conectividad | Explica BGP y el camino del paquete |
| **3. Aplicación y alta disponibilidad** | Redes y Operación | `k8s/app/`, `scripts/medir-corte.sh`, guion de la falla | 2.3 Flujo de datos, 3.2 Deployments y Services, 5 Limitaciones | Comenta la caída y el rolling update |
| **4. Seguridad** | Seguridad | `k8s/netpol/`, `scripts/prueba-netpol.sh`, firewall del CHR, manejo de secretos | 3.2 Segmentación, 4.2 Pruebas de segmentación | Responde "¿cómo se vincula con seguridad?" |
| **5. Monitoreo, comunicación y backups** (Bellomo, Lorenzo) | Operación | `k8s/monitoring/`, `ansible/backup.yml`, `ansible/restore.yml`, laptop de respaldo, póster, edición final del informe | 1 Resumen, 3.4 Monitoreo, backups de 4.3, 6 Conclusiones, 7 Referencias | Explica el póster y el tablero |

La estación es la PC de quien tiene el rol 1, que recibe el proyecto en un zip y sigue [LEEME.md](LEEME.md).

## Etapa 1: informe, hasta el martes 10/11

El informe necesita resultados reales, así que lo primero es levantar el laboratorio. La decisión que condiciona todo es la medición de RAM del sábado.

| Día | Integrante | Tarea | Listo cuando |
|---|---|---|---|
| Vie 6/11 | Lorenzo | Subir el esqueleto a la rama `demo` y pasar el zip | PR abierto y zip entregado |
| Vie 6/11 | 1 | Instalar VirtualBox y Vagrant, correr `mac/preparar-mac.sh` | Ningún requisito en FALTA |
| Vie 6/11 | Lorenzo | Sumar a los 4 integrantes y a los docentes como colaboradores | Invitaciones aceptadas |
| Vie 6/11 | Todos | Configurar `user.name` y `user.email` en su clon | Primer commit propio en `progreso.md` |
| Vie 6/11 | 5 | Confirmar con los docentes las fechas y el grupo de 5 (el README dice 3-4 y Feria el 5/11) | Respuesta anotada en `progreso.md` |
| Sáb 7/11 | 1 | `vagrant up`, `site.yml` dos veces (`changed=0`) y `deploy.yml` | Salida guardada en `capturas/` |
| Sáb 7/11 | 2 | Crear el CHR y validar `chr-borde.rsc`, que nunca se probó en un CHR real | 3 sesiones BGP establecidas |
| Sáb 7/11 | 1 | **Medir RAM 10 minutos con todo abierto** | Pico anotado; sigue si queda debajo del 85 % |
| Dom 8/11 | 3 | Caída de un agent, rolling update y rollback con `medir-corte` | Rachas de errores medidas |
| Dom 8/11 | 4 | `prueba-netpol.sh` y prueba del firewall del CHR | 8 de 8, con captura |
| Dom 8/11 | 5 | Tablero de Grafana durante la caída | Capturas de los 7 paneles |
| Dom 8/11 | 5 | Correr `backup.yml` y probar `restore.yml` con el rol 1 | Backup hecho y restauración probada, con captura |
| Dom 8/11 | 2 | Captura de BGP en Wireshark, traceroute y diagrama de red | Imagen en `diagramas/` y captura |
| Lun 9/11 | Todos | Borrador de cada sección en `documento/`, por PR | PR de cada uno mergeado |
| Lun 9/11 | 5 | Unir, cortar a 5-7 páginas y aplicar el formato | PDF de prueba |
| Mar 10/11 | Todos | Cada uno lee una sección ajena; el 5 cierra el PDF | `documento/` con el PDF y **entrega hecha** |

Si el 9/11 el laboratorio real no funciona del todo, el informe se apoya en lo medido en la réplica, aclarando qué parte salió de ahí y qué falta validar.

## Etapa 2: Feria, del miércoles 11/11 al martes 17/11

| Día | Integrante | Tarea | Listo cuando |
|---|---|---|---|
| Mié 11 y jue 12 | Todos | Corregir lo que surgió del informe y la devolución docente | PR mergeados |
| Mié 11 y jue 12 | 5 | Primer borrador del póster A1 con QR al repo | Editable en `poster/` |
| Vie 13/11 | 5 | Póster final en PDF y encargo de la impresión | PDF y editable subidos |
| Vie 13/11 | 3 | Guion cronometrado, con versión corta de 30 segundos | Guion en `demo/README.md` |
| Sáb 14/11 | Todos | Ensayo 1 de punta a punta, con Wi-Fi apagado | Tiempo y fallas anotados |
| Sáb 14/11 | 1 y 3 | Grabar el video del plan B | Video guardado fuera de git, enlace en el README |
| Dom 15/11 | 5 | Levantar el laboratorio en la laptop de respaldo con `demo/README.md` | Funciona, o se anota qué faltó |
| Dom 15/11 | Todos | Ensayo 2, con una falla inesperada a propósito | Plan de contingencia probado |
| Lun 16/11 | Todos | Ensayo 3 con cronómetro y preguntas cruzadas | 3 a 5 minutos |
| Lun 16/11 | 4 | Recorrer `templates/checklist-entrega.md` completo | Checklist en verde |
| Mar 17/11 | Todos | Llegar 15 minutos antes y montar la estación, con Claude cerrado | Feria |

## Pendientes

- [x] Elegir la estación: la PC del compañero que tiene el rol 1.
- [x] Elegir la laptop de respaldo: la de Lorenzo, con Windows.
- [x] Definir el rol de Lorenzo: el 5.
- [ ] Completar nombres y usuarios en `progreso.md`.
- [ ] Definir la identidad de los commits: el README pide "Apellido, Nombre" con el mail de la facultad.
- [ ] Llevar al informe, en Limitaciones: un solo server y ~14 s de pedidos sueltos con error ante la caída de un nodo.
