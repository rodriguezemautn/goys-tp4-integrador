# Demo — Diagnóstico de redes con IA, MCP y GEMELO

La demostración utiliza dos proyectos independientes en GNS3:

- **EMPRESA:** red de referencia que la IA consulta con permisos de lectura.
- **GEMELO:** copia donde la IA puede reproducir problemas, realizar cambios y comprobar sus resultados.

La aplicación de correcciones en EMPRESA queda a cargo de su administrador.

El desarrollo y las pruebas se documentan en [DesarrolloDemo.md](DesarrolloDemo.md). El servidor MCP se encuentra en [mcp/](mcp/).

## 1. Requisitos

Entorno utilizado:

- Windows con Git Bash.
- GNS3 3.0.6 y GNS3 VM sobre VMware.
- MikroTik CHR con RouterOS 7.16.
- VPCS 0.8.3.
- Python 3.13 con entorno virtual.
- Cliente oficial `tunnel-client.exe`.
- Conexión a Internet para ChatGPT y el túnel.
- Cuenta con acceso a conexiones MCP personalizadas y permisos para utilizar Secure MCP Tunnel.

La disponibilidad de la conexión debe comprobarse en la cuenta que utilizará la demo. No se presupone que todas las cuentas o planes dispongan del mismo acceso.

Los comandos de esta guía se ejecutan en Git Bash, desde la raíz del repositorio.

## 2. Proyectos GNS3 y credenciales

Los proyectos EMPRESA y GEMELO se distribuyen mediante
[Archivos-GNS3/](Archivos-GNS3/).

Importar cada proyecto desde GNS3. Si se distribuye como proyecto portable, utilizar la opción de importación correspondiente. Si se entrega una carpeta descomprimida, abrir su archivo `.gns3`.

Deben estar disponibles los discos y recursos referenciados por ambos proyectos. No alcanza con copiar únicamente los archivos de topología.

Las credenciales de laboratorio se entregan al integrante autorizado por un canal privado. No se publican en este README ni en una plantilla de configuración.

Los proyectos completos contienen configuración persistente de los equipos y deben tratarse como material de laboratorio con credenciales incorporadas. No utilizar esas contraseñas fuera del laboratorio.

## 3. Preparar la red de gestión

El laboratorio utiliza la red Host-only `192.168.57.0/24`.

| Componente | Dirección |
|---|---|
| Equipo administrador — adaptador VMware VMnet1 | `192.168.57.1/24` |
| EMPRESA-R1 | `192.168.57.10/24` |
| EMPRESA-R2 | `192.168.57.11/24` |
| EMPRESA-R3 | `192.168.57.12/24` |
| GEMELO-R1 | `192.168.57.20/24` |
| GEMELO-R2 | `192.168.57.21/24` |
| GNS3 VM en el entorno original | `192.168.57.130/24` |

1. Configurar VMnet1 como red Host-only y el adaptador del equipo con `192.168.57.1/24`.
2. Conectar la gestión de los proyectos a esa red mediante la Cloud de GNS3. Comprobar el adaptador utilizado después de importar.
3. Evitar solapamientos con otras redes y comprobar que las IP estáticas estén disponibles y fuera del pool DHCP.
4. Iniciar los dispositivos de ambos proyectos.
5. Habilitar en las propiedades generales de cada proyecto la opción de mantenerlo funcionando en segundo plano al cerrarlo, para permitir su ejecución simultánea.

Las cuentas y el firewall de los routers permiten SSH desde `192.168.57.1`. Si se utiliza otro origen, adaptar ambas restricciones desde la consola de GNS3.

Los segmentos de datos de EMPRESA y GEMELO deben permanecer separados. No conectar entre sí sus LAN ni sus enlaces internos. Pueden conservar las mismas IP internas porque pertenecen a redes aisladas.

Comprobar la gestión:

```bash
for ip in 192.168.57.10 192.168.57.11 192.168.57.12 \
          192.168.57.20 192.168.57.21 192.168.57.22
do
    ping.exe -n 2 "$ip"
done
```

## 4. Preparar Python

```bash
py -3.13 -m venv demo/mcp/.venv

./demo/mcp/.venv/Scripts/python.exe -m pip install -r demo/mcp/requirements.txt
```

No copiar el entorno virtual de otra computadora: crearlo en la instalación de destino.

## 5. Configurar credenciales y consolas

Crear `demo/mcp/.env` y completar estos valores localmente:

```dotenv
# Lectura de EMPRESA
MIKROTIK_R1_READ_PASSWORD=
MIKROTIK_R2_READ_PASSWORD=
MIKROTIK_R3_READ_PASSWORD=

# Lectura de GEMELO
GEMELO_R1_READ_PASSWORD=
GEMELO_R2_READ_PASSWORD=
GEMELO_R3_READ_PASSWORD=

# Administración de GEMELO
GEMELO_R1_NETADMIN_PASSWORD=
GEMELO_R2_NETADMIN_PASSWORD=
GEMELO_R3_NETADMIN_PASSWORD=

# Consolas de GEMELO
GNS3_CONSOLE_HOST=192.168.57.130
GEMELO_PC_CONSOLE_PORT=5010
GEMELO_SRV_CONSOLE_PORT=5012

# Conexión con OpenAI
CONTROL_PLANE_API_KEY=
TUNNEL_PROFILE=tp4-integrador
TUNNEL_ID=
```

Las contraseñas deben coincidir con las configuradas en los proyectos importados. Para valores que contengan caracteres especiales, utilizar comillas simples.

No se necesitan credenciales administrativas de EMPRESA ni claves OSPF en `.env`.

Comprobar en GNS3 la IP actual de la VM y los puertos que figuran como **Console** de GEMELO-PC y GEMELO-SRV. Pueden cambiar al importar los proyectos. No confundirlos con los puertos internos del proceso VPCS.

Las consolas utilizan Telnet sin autenticación propia: mantenerlas dentro de la red de administración, sin exposición a Internet.

Verificar que los archivos locales estén ignorados:

```bash
git check-ignore -v demo/mcp/.env demo/mcp/.venv/pyvenv.cfg
```

## 6. Verificar las claves SSH

Antes de utilizar el MCP, conectar manualmente por SSH a cada router:

```bash
ssh mcp_ro@192.168.57.10
ssh mcp_ro@192.168.57.11
ssh mcp_ro@192.168.57.12
ssh mcp_ro@192.168.57.20
ssh mcp_ro@192.168.57.21
ssh mcp_ro@192.168.57.22
```

Verificar las huellas con el responsable del laboratorio antes de aceptarlas. Salir de cada sesión con `quit`.

Las claves aceptadas quedan registradas en `~/.ssh/known_hosts`.
El servidor rechaza claves desconocidas o diferentes.

Revisar también las identidades y MAC de gestión frente al inventario de [configuracion.py](mcp/configuracion.py). Si la importación alteró las interfaces o sus MAC, corregir la correspondencia antes de continuar.

## 7. Probar el MCP localmente

```bash
./demo/mcp/.venv/Scripts/python.exe demo/mcp/configuracion.py

./demo/mcp/.venv/Scripts/python.exe demo/mcp/conexion_ssh.py

./demo/mcp/.venv/Scripts/python.exe demo/mcp/conexion_ssh.py --escritura

./demo/mcp/.venv/Scripts/python.exe demo/mcp/verificar_mcp.py
```

Estas verificaciones consultan los equipos y comprueban los accesos sin modificar configuraciones. Deben pasar antes de preparar la conexión con ChatGPT.

## 8. Crear el túnel en OpenAI

1. Ingresar a [OpenAI Platform](https://platform.openai.com/) con la cuenta que utilizará la integración.
2. Seleccionar la organización correspondiente.
3. Abrir [Tunnels](https://platform.openai.com/settings/organization/tunnels), crear un túnel y guardar su identificador `tunnel_...` en `TUNNEL_ID`.
4. Asociar el túnel con la organización y el espacio de ChatGPT que lo utilizarán, según las opciones disponibles.
5. Crear una API key de ejecución en [API keys](https://platform.openai.com/settings/organization/api-keys), con los permisos necesarios para utilizar el túnel.
6. Guardarla localmente en `CONTROL_PLANE_API_KEY`. No usar ni compartir una clave administrativa de la organización.

Crear o editar túneles requiere permisos **Tunnels Read + Manage**.
Ejecutar el cliente requiere **Tunnels Read + Use**. El acceso a conexiones MCP en ChatGPT se comprueba por separado.

Descargar el cliente para Windows desde la página de Tunnels o las
[versiones oficiales de tunnel-client](https://github.com/openai/tunnel-client/releases/latest).

Colocar el ejecutable como:

```text
demo/mcp/tunnel-client.exe
```

Comprobarlo:

```bash
git check-ignore -v demo/mcp/tunnel-client.exe
./demo/mcp/tunnel-client.exe help quickstart
```

Documentación oficial:
[Secure MCP Tunnel](https://developers.openai.com/api/docs/guides/secure-mcp-tunnels).

## 9. Configurar e iniciar el túnel local

Crear el perfil:

```bash
./demo/mcp/.venv/Scripts/python.exe demo/mcp/iniciar.py --configurar
```

Si termina correctamente, ejecutar:

```bash
./demo/mcp/.venv/Scripts/python.exe demo/mcp/iniciar.py --doctor
```

Si el diagnóstico termina con `RESULT ok`, iniciar:

```bash
./demo/mcp/.venv/Scripts/python.exe demo/mcp/iniciar.py
```

Mantener esa terminal abierta. Para detenerlo, utilizar `Ctrl+C`.

El cliente del túnel inicia el servidor MCP mediante stdio. No es necesario arrancar `servidor_mcp.py` por separado.

Cada computadora debe crear su perfil local: contiene las rutas de su intérprete Python y del servidor. Si se mueve el repositorio, será necesario adaptar o regenerar ese perfil.

Utilizar un túnel propio para cada instalación independiente evita dirigir accidentalmente las llamadas al laboratorio de otra computadora.

## 10. Conectar con ChatGPT

Con el túnel funcionando:

1. Abrir [Plugins de ChatGPT](https://chatgpt.com/plugins).
2. Seleccionar la opción de agregar un servidor MCP personalizado.
3. Elegir **Tunnel** y seleccionar o introducir el mismo `TUNNEL_ID`.
4. Para este servidor stdio sin OAuth propio, seleccionar la opción de conexión sin autenticación de aplicación. El túnel mantiene su autenticación mediante la API key local y los permisos de OpenAI.
5. Crear e instalar la conexión.
6. Abrir un chat nuevo y habilitar el plugin.

Deben aparecer estas cuatro herramientas:

- `listar_routers`
- `consultar_router`
- `ejecutar_comando_gemelo`
- `ejecutar_comando_vpcs`

Primera prueba sugerida:

> Usá el MCP para listar los routers y consultar la identidad de EMPRESA-R1. No modifiques configuraciones.

La instalación se considera conectada después de una llamada satisfactoria desde ChatGPT, no solamente porque el túnel haya arrancado.

Tras modificar las instrucciones o herramientas del servidor, reiniciar el túnel y actualizar la conexión desde sus detalles en ChatGPT.

## 11. Uso de la demo

Para actualizar el gemelo:

> Compará EMPRESA y GEMELO y actualizá la configuración relevante del gemelo, conservando sus diferencias de gestión, identidades y credenciales. No modifiques EMPRESA.

Para investigar una falla:

> En EMPRESA no funciona el ping de PC a SRV. Investigá la causa mediante MCP, reproducí el problema y probá la corrección únicamente en GEMELO. Comprobá que se mantengan las restricciones previstas.

La preparación de la falla, sus comandos de limpieza y los resultados obtenidos se documentan en la Fase 7 de [DesarrolloDemo.md](DesarrolloDemo.md).

La IA tiene acceso administrativo general en GEMELO. Puede cometer errores o interrumpir su acceso; la consola de GNS3 queda disponible para recuperación manual.

## 12. Problemas frecuentes

| Problema | Qué revisar |
|---|---|
| No responde una IP de gestión | GNS3 VM, nodo encendido, VMnet1, Cloud y direccionamiento |
| Falla la autenticación SSH | Credencial correspondiente al equipo y origen `192.168.57.1` |
| Clave SSH desconocida o diferente | Verificar la huella y revisar `known_hosts`; no desactivar la comprobación |
| Identidad o MAC no coincide | Inventario e interfaces después de importar |
| Falla una consola VPCS | IP de GNS3 VM, puerto Console, nodo iniciado y nombre del prompt |
| Falla el perfil del túnel | `.env`, rutas locales y diagnóstico `--doctor` |
| El túnel no aparece en ChatGPT | Organización, asociación con el espacio y permisos de uso |
| Aparecen herramientas antiguas | Detener clientes anteriores, reiniciar el actual y actualizar la conexión |
| Un comando devuelve resultado inconcluso | Consultar el estado antes de repetir una modificación |

## 13. Alcance de la portabilidad

La integración fue verificada en el equipo de desarrollo. La reproducción completa en otra computadora permanece pendiente de validación.

La red Host-only funciona localmente y no depende del Wi-Fi utilizado para Internet, siempre que no existan conflictos de subred o rutas.

ChatGPT y Secure MCP Tunnel requieren Internet y acceso disponible en la cuenta utilizada.


**Adicional para verificar:**

Los proyectos distribuidos ya tienen MAC de gestión distintas para
EMPRESA y GEMELO. No es necesario regenerarlas al importar.

Comprobar que GNS3 conserve las MAC configuradas en los nodos y que
coincidan con `mcp/configuracion.py`. Las MAC de las interfaces virtuales
se configuraron en GNS3, no únicamente dentro de RouterOS.

Si se regeneran, RouterOS puede reconocer interfaces nuevas y dejar
inválidas las referencias de direcciones, firewall y OSPF, como ocurrió
durante la preparación. Por eso deben conservarse las MAC del proyecto.