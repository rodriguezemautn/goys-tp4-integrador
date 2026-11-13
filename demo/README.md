## Requisitos de red y acceso

El laboratorio utiliza una red de gestión Host-only
`192.168.57.0/24`. Las cuentas y el firewall de los routers permiten
acceso SSH únicamente desde el equipo administrador
`192.168.57.1`.

| Componente | Direcciones |
|---|---|
| EMPRESA-R1, R2 y R3 | `192.168.57.10`, `.11` y `.12` |
| GEMELO-R1, R2 y R3 | `192.168.57.20`, `.21` y `.22` |
| Servidor GNS3 VM utilizado | `192.168.57.130` |

EMPRESA y GEMELO deben conservar separados sus segmentos de datos.
Pueden utilizar las mismas direcciones internas porque pertenecen
a escenarios aislados. Sus direcciones y MAC de gestión son distintas
para permitir su ejecución simultánea.

### Preparación en otra computadora

1. Instalar GNS3 y un entorno de virtualización compatible.
2. Importar ambos proyectos con sus discos y recursos necesarios.
3. Configurar el adaptador Host-only del equipo administrador con
   `192.168.57.1/24` y conectar las interfaces de gestión mediante
   la Cloud correspondiente de GNS3.
4. Comprobar que la subred no se solape con otras redes del equipo
   y que las direcciones estáticas estén disponibles.
5. Habilitar la ejecución en segundo plano de los proyectos para
   mantener EMPRESA y GEMELO encendidos simultáneamente.
6. Verificar las identidades, direcciones y MAC de los routers
   frente al inventario de `mcp/configuracion.py`.
7. Preparar el entorno virtual de Python e instalar las dependencias
   de `mcp/requirements.txt`.
8. Crear `mcp/.env` con las credenciales y los parámetros locales
   del túnel y las consolas. Este archivo no se incluye en el repositorio.
9. Registrar y verificar localmente las claves de host SSH en
   `known_hosts`. El MCP rechaza claves desconocidas o diferentes.
10. Comprobar los puertos de consola de GEMELO-PC y GEMELO-SRV
    en GNS3 y adaptar sus valores en `.env`.

Si se utiliza otra dirección para el administrador, deben adaptarse
las restricciones de las cuentas y las reglas del firewall.
Estos cambios deben realizarse desde la consola de GNS3 para evitar
perder el acceso remoto.

### Acceso mediante MCP

La integración dispone de consultas con `mcp_ro` en ambos entornos
y ejecución administrativa con `netadmin` exclusivamente en GEMELO.
También permite operar las consolas de GEMELO-PC y GEMELO-SRV.

El archivo `.env` contiene únicamente las credenciales de lectura
de EMPRESA y las de lectura y administración de GEMELO, además de
los parámetros de conexión. No requiere credenciales administrativas
de EMPRESA ni claves de autenticación OSPF.

Las consolas VPCS utilizan Telnet sin autenticación propia y deben
permanecer accesibles únicamente desde la red de administración.
En el entorno validado se utilizan los puertos `5010` y `5012` del
servidor GNS3 VM; pueden variar al importar los proyectos.

Para conectar el servidor MCP con ChatGPT se necesita
`tunnel-client.exe`, un túnel habilitado para la cuenta o espacio
de trabajo correspondiente y su clave de ejecución.
El ejecutable y los secretos no se incluyen en el repositorio.

Cada computadora debe configurar su perfil local mediante
`mcp/iniciar.py --configurar`, utilizando el Python del entorno
virtual. El perfil contiene rutas propias de esa instalación;
no debe reutilizarse sin adaptar las rutas de otra computadora.

El túnel debe permanecer en ejecución durante el uso desde ChatGPT.
Su dirección identifica la conexión con el servidor MCP que lo
atiende; no selecciona automáticamente el GNS3 de cada usuario.

### Verificación y alcance de la portabilidad

Antes de utilizar la integración, ejecutar `mcp/verificar_mcp.py`
con el Python del entorno virtual. La prueba comprueba consultas
a routers, acceso a las consolas y rechazo de destinos administrativos
fuera de GEMELO, sin modificar configuraciones.

La integración y la ejecución simultánea de ambos proyectos fueron
verificadas en el equipo de desarrollo. La reproducción completa
en otra computadora permanece pendiente de validación.