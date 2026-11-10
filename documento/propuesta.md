# Servicios en alta disponibilidad con k3s, BGP y segmentación de red

**Universidad Tecnológica Nacional** — Facultad Regional La Plata

**Carrera:** Ingeniería en Sistemas

**Cátedra:** Gestión Operativa y Seguridad en Redes

**Trabajo Práctico N.º 4** — Proyecto Integrador

**Modalidad:** A — Proyecto de Desarrollo

**Grupo:** 4

**Integrantes:**

| Apellido, Nombre | Legajo |
|---|---|
| Bellomo, Lorenzo | 32582 |
| Ferrari, Agustin Nicolas | 32444 |
| Guarino, Naim Hernan | 32683 |
| Kloster, Agustín Ignacio | 32274 |
| Siadore, Valentino | 32473 |

**Fecha de entrega:** 10/11/2026

---

## Idea del proyecto

### Problema

Una PyME corre sus servicios en un solo servidor. Si ese equipo se cae, o hay que apagarlo para actualizarlo, el servicio se corta para todos los usuarios. Además, la red interna es plana: si un atacante compromete un servicio expuesto, puede llegar a los datos internos.

### Solución propuesta

Un clúster **k3s** de tres nodos (un server y dos agents) detrás de un router de borde **MikroTik CHR v7**:

- **MetalLB** le anuncia al CHR por **BGP** las IPs de los servicios. Si un nodo se cae, el CHR deja de usarlo y el servicio sigue atendiendo desde los otros nodos.
- La aplicación de ejemplo (un frontend web y un backend interno) corre con varias réplicas repartidas entre los nodos, y se actualiza sin corte con *rolling update* y *rollback*.
- **Ansible** aprovisiona los nodos y despliega todo de forma reproducible e idempotente.
- **Prometheus y Grafana** muestran en tiempo real el estado de los nodos, de las sesiones BGP y de las réplicas.
- **NetworkPolicies** separan el tráfico en zonas: solo el frontend llega al backend, y el backend no puede iniciar conexiones hacia afuera.

### Cómo integra las tres áreas

| Área | Qué aporta el proyecto |
|---|---|
| Redes | Router de borde CHR, eBGP entre el router y el clúster, anuncio de rutas /32 con MetalLB, retiro de la ruta ante la caída de un nodo |
| Operación | Aprovisionamiento con Ansible, mantenimiento sin corte (`kubectl drain`), rolling update y rollback, monitoreo y alertas con Prometheus y Grafana, backups |
| Seguridad | Segmentación con NetworkPolicies, autenticación MD5 y filtros de prefijos en BGP, firewall en el CHR, secretos cifrados con ansible-vault |

### Demo para la Feria

El laboratorio corre offline en una laptop, con máquinas virtuales. Durante la demo se apaga un nodo mientras un script consulta el servicio cada 0,2 segundos: se ve en Grafana y en Wireshark cómo el router retira la ruta, y se mide cuánto tiempo hay pedidos con error. Después se hace una actualización y un rollback sin perder pedidos, y se muestra qué tráfico bloquean las políticas de seguridad.

En una réplica del laboratorio con contenedores ya se midió que entra en una laptop de 8 GB y que, con la detección de nodo caído ajustada, la ventana con errores baja de unos 43 a unos 14 segundos.
