# Cómo levantar el laboratorio del TP4

Este proyecto corre en una sola PC, y es la tuya: tenés el rol 1 (Infraestructura). Los demás integrantes trabajan por git y prueban con vos por pantalla compartida.

El laboratorio tiene 4 VMs: 3 nodos k3s y un router MikroTik CHR. Un servicio web se publica por BGP y sigue atendiendo aunque se caiga un nodo. El tráfico está segmentado con NetworkPolicies y se ve en Grafana.

## Qué leer

| Archivo | Para qué |
|---|---|
| Este `LEEME.md` | Qué hacer, en qué orden y qué devolver |
| [demo/README.md](demo/README.md) | Los comandos de cada paso, el guion de la demo y los problemas conocidos |
| [PLAN.md](PLAN.md) | Quién hace qué y las fechas |
| `TRASPASO.md` | Decisiones ya tomadas y por qué; viene solo en el zip |
| [demo/prueba-ram/RESULTADOS.md](demo/prueba-ram/RESULTADOS.md) | Mediciones hechas y bitácora de fallas |

## Qué necesita tu PC

| Requisito | Detalle |
|---|---|
| Sistema | Windows 10 u 11; los scripts son de PowerShell. Con Linux o Mac, avisá antes de empezar |
| RAM | 8 GB como mínimo; con 16 GB podés usar el perfil `normal` |
| Disco | 20 GB libres donde queden las VMs; si C: no alcanza, se pueden poner en otro disco |
| Programas | VirtualBox 7 y Vagrant, instalados con internet |
| Red | Adaptador host-only de VirtualBox en 192.168.56.1, con DHCP activo |
| Permisos | Poder instalar programas y correr una consola de administrador, para agregar una ruta |

Para revisar el adaptador:

```bash
VBoxManage list hostonlyifs
```

Si tu adaptador no se llama `VirtualBox Host-Only Ethernet Adapter`, pasale el nombre a `crear-chr.ps1` con `-AdaptadorHostOnly`.

Con el laboratorio prendido no uses WSL2 ni Docker Desktop, y apagá otras VMs que usen 192.168.56.x.

## Qué hacer, en orden

1. Descomprimí el zip en una ruta corta, sin espacios ni acentos, por ejemplo `C:\tp4`. Si vas a abrir el proyecto con otra herramienta, que sea desde esa carpeta.
2. Instalá VirtualBox y Vagrant.
3. Abrí PowerShell en la carpeta `demo` y revisá la PC. Este script también genera tu clave SSH del laboratorio. Sumá `-CarpetaVMs D:\VMs` si las VMs tienen que ir a otro disco.

   ```bash
   powershell -ExecutionPolicy Bypass -File windows\preparar-laptop.ps1
   ```

4. Seguí "Puesta en marcha en Windows" de [demo/README.md](demo/README.md), desde `vagrant up`. Tiene 9 pasos.
5. **Medí la RAM** (paso 8): es la decisión que condiciona todo. Si el pico queda debajo del 85 %, se sigue con ese perfil. Si no, cerrá programas o bajá RAM y volvé a medir.
6. Anotá el resultado y cualquier falla en `demo/prueba-ram/RESULTADOS.md`.

Calculá varias horas para la primera vez: se bajan la imagen de Ubuntu, k3s y todas las imágenes de contenedores. La demo final no necesita internet.

## Qué viene y qué no

El zip trae todo el repo, sin la carpeta `.git`. **No trae secretos**, y cada uno se genera en tu PC:

| Falta | Quién lo crea |
|---|---|
| `demo/.claves/` | `preparar-laptop.ps1` |
| `demo/ansible/group_vars/all/vault.yml` | Vos, desde `vault.example.yml` (paso 6) |
| `~/.vault_pass` | Vos, dentro de la VM server (paso 6) |

Elegí tus propias claves. No las subas a git ni las mandes por el chat del grupo.

## Qué está probado y qué no

Conviene saberlo antes de empezar: si algo falla, lo más probable es que sea una de estas partes.

| Parte | Estado |
|---|---|
| YAML, JSON y `kubectl kustomize` de las 4 carpetas | Validado sin clúster |
| Sintaxis de los scripts de shell y PowerShell | Validada |
| `preparar-laptop.ps1` y los dos `medir-corte` | Corridos en una laptop con Windows |
| Las versiones fijadas de cada imagen | Confirmadas: existen |
| Configuraciones de BGP, NetworkPolicies, Grafana y Prometheus | Funcionaron en una réplica con contenedores en una sesión anterior; se recrearon con los fragmentos validados |
| `vagrant up`, instalación de k3s con Ansible y `ansible-lint` | **Sin probar** |
| `routeros/chr-borde.rsc` en un CHR real | **Sin probar**: es lo más probable que necesite ajustes |
| `crear-chr.ps1`, `rutas.ps1` y `medir-ram.ps1` | **Sin correr**; solo sintaxis |
| Captura de BGP en Wireshark | **Sin probar** |
| Scripts de `demo/prueba-ram/` | Reconstruidos y sin correr; no hacen falta para levantar el laboratorio |

Si algo falla, corregilo y anotá en la bitácora de `RESULTADOS.md` qué falló, la causa y la corrección.

## Qué tiene que quedar

| Evidencia | Se usa para |
|---|---|
| Pico y promedio de RAM, con la decisión | Decidir el perfil, y en el informe |
| Salida de `site.yml` corrido dos veces, con `changed=0` en la segunda | Sección 4.3 del informe |
| 3 sesiones BGP establecidas y la ruta 10.10.20.10/32 | Sección 4.1 |
| `prueba-netpol.sh` con 8 de 8 | Sección 4.2 |
| Capturas de Grafana con un nodo caído | Sección 3.4 |
| Rachas de errores de `medir-corte` durante la caída | Sección 4.1 y Limitaciones |

Las capturas van en `capturas/`. La prueba de cada área la hace su dueño con vos, según [PLAN.md](PLAN.md): cada uno sube lo suyo, con su usuario.

## Cómo usar git

La cátedra acredita a cada integrante por sus commits propios: **quien no aparece en el historial no acredita el TP**.

1. Clonate la rama `demo` cuando esté subida:

   ```bash
   git clone -b demo https://github.com/LoLoo03/goys-tp4-integrador.git
   ```

2. Configurá tu identidad en ese clon, con el mail de la facultad:

   ```bash
   git config user.name "Apellido, Nombre"
   ```

   ```bash
   git config user.email "tu-email@alumnos.frlp.utn.edu.ar"
   ```

3. Si cambiaste archivos en la copia del zip, pasalos al clon y commitealos en una rama de nombre simple, como `fix` o `docs`. Después abrí un Pull Request.

No hace falta tirar el laboratorio para cambiar de carpeta: las VMs quedan asociadas a la carpeta `demo` donde corriste `vagrant up`. Podés seguir usando esa copia para correrlo y el clon para commitear.

`TRASPASO.md` no se commitea.

## Reparto y fechas

| Integrante | Área | Sobre qué trabaja |
|---|---|---|
| 1. Infraestructura | Operación | Vagrant, Ansible, scripts de Windows; maneja la demo |
| 2. Red | Redes | CHR, BGP, MetalLB, Wireshark, diagrama |
| 3. Aplicación y alta disponibilidad | Redes y Operación | Frontend, backend, prueba de caída de un nodo, limitaciones |
| 4. Seguridad | Seguridad | NetworkPolicies, firewall del CHR, secretos |
| 5. Monitoreo y comunicación | Operación | Prometheus, Grafana, póster, edición final del informe |

- **Martes 10/11, informe:** el laboratorio tiene que estar arriba el fin de semana, porque el informe necesita resultados reales.
- **Martes 17/11, Feria:** 3 ensayos, con el Wi-Fi apagado en el primero. Hay plan B con video grabado y una segunda laptop de respaldo.

Faltar a la Feria sin justificación desaprueba el TP4, así que tu PC tiene que estar en el aula ese día. El detalle por día está en [PLAN.md](PLAN.md).

## Si usás Claude Code

Abrilo en la raíz del proyecto y pasale el prompt que está al principio de `TRASPASO.md`. Ese documento es la fuente de verdad de lo ya decidido. Se escribió para una laptop de 8 GB: si la tuya tiene más, la medición de RAM decide el perfil. No agregues atribución a Claude en commits ni en PRs.
