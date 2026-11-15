> **Estación de Feria:** el laboratorio operativo usa [QEMU](qemu/README.md).

# Demo: servicios en alta disponibilidad con k3s

Un servicio web corre en un clúster k3s de 3 nodos y se publica por BGP hacia un router MikroTik CHR. Si se cae un nodo, el router deja de usarlo a los 9 s y el servicio sigue atendiendo. El tráfico entre namespaces está segmentado con NetworkPolicies y todo se ve en Grafana.

La demo corre en una sola PC, sin internet. Lo único que necesita internet es la instalación. Si es tu primera vez, empezá por [LEEME.md](../LEEME.md).

## Topología

```mermaid
flowchart LR
  L["Laptop Windows<br/>192.168.56.1"] -- "host-only" --> CHR["CHR<br/>ether1 192.168.56.2<br/>ether2 10.10.10.1<br/>AS 65000"]
  CHR -- "intnet lab-cluster<br/>BGP con MD5" --> S["k3s-server<br/>10.10.10.11"]
  CHR --> A1["k3s-agent1<br/>10.10.10.12"]
  CHR --> A2["k3s-agent2<br/>10.10.10.13"]
  S & A1 & A2 -. "anuncian 10.10.20.10/32<br/>AS 64512" .-> CHR
```

Recorrido de un pedido: laptop → CHR (ruta /32 aprendida por BGP) → cualquier nodo → kube-proxy → pod `frontend` (namespace `web`) → `/api/` → pod `backend` (namespace `datos`). Cada VM tiene además una NIC en NAT, que usa Vagrant y que da internet para instalar.

| Qué | Valor |
|---|---|
| Laptop (host-only de VirtualBox) | 192.168.56.1 |
| CHR | 192.168.56.2 (ether1, clientes) · 10.10.10.1 (ether2, clúster) |
| k3s-server / agent1 / agent2 | 10.10.10.11 / .12 / .13 |
| Pool de servicios de MetalLB | 10.10.20.0/28; el frontend usa 10.10.20.10 |
| Grafana | http://10.10.10.11:30300 |
| ASN | CHR 65000 · clúster 64512 |

## Perfiles de RAM

| Perfil | Server | Agents | CHR | Cuándo |
|---|---|---|---|---|
| `chico` (por defecto) | 1,5 GB | 768 MB | 256 MB | Laptop de 8 GB |
| `normal` | 2 GB | 1 GB | 256 MB | Laptop de 16 GB, con `$env:PERFIL_RAM="normal"` |

## Puesta en marcha en Windows

Con Mac, los comandos que cambian están en [En Mac](#en-mac).

Requisitos: VirtualBox 7, Vagrant y 20 GB libres en el disco de las VMs. Con el laboratorio levantado no se usan WSL2 ni Docker Desktop; antes de empezar: `wsl --shutdown`. Las VMs de otras materias que usen 192.168.56.x tienen que estar apagadas.

Todos los comandos salen de la carpeta `demo`. Si Windows no deja correr los scripts: `powershell -ExecutionPolicy Bypass -File windows\<script>.ps1`.

1. Revisar la laptop y generar la clave SSH. Si C: no tiene lugar, sumar `-CarpetaVMs D:\VMs`.

   ```powershell
   windows\preparar-laptop.ps1
   ```

2. Levantar los 3 nodos.

   ```powershell
   vagrant up
   ```

3. Crear el CHR. En su consola: usuario `admin`, definir una clave y ver la IP de DHCP con `/ip address print`.

   ```powershell
   windows\crear-chr.ps1
   ```

4. Configurar el CHR con una copia temporal del `.rsc`. La sesión se corta al final del import y es lo esperado. Después, borrar el archivo del router porque tiene la clave BGP.

   ```powershell
   (Get-Content routeros\chr-borde.rsc) -replace 'CAMBIAR-CLAVE-BGP','<clave BGP>' | Set-Content -Encoding ascii $env:TEMP\chr-borde.rsc
   scp $env:TEMP\chr-borde.rsc admin@<IP de DHCP>:chr-borde.rsc
   ssh admin@<IP de DHCP> "/import file-name=chr-borde.rsc"
   ssh admin@192.168.56.2 "/file remove chr-borde.rsc"
   Remove-Item $env:TEMP\chr-borde.rsc
   ```

5. Agregar la ruta hacia el laboratorio, en una consola de administrador.

   ```powershell
   windows\rutas.ps1
   ```

6. Crear los secretos, con la misma clave BGP del paso 4.

   ```bash
   vagrant ssh k3s-server
   cd /vagrant/ansible/group_vars/all
   cp vault.example.yml vault.yml
   nano vault.yml
   (umask 077; read -rsp 'Clave del vault: ' c; echo; echo "$c" > ~/.vault_pass)
   ANSIBLE_CONFIG=/vagrant/ansible/ansible.cfg ansible-vault encrypt vault.yml
   ```

7. Instalar k3s dos veces (la segunda tiene que dar `changed=0`) y desplegar.

   ```bash
   /vagrant/ansible/run.sh site.yml
   /vagrant/ansible/run.sh site.yml
   /vagrant/ansible/run.sh deploy.yml
   ```

8. **Decisión de RAM.** Con todo levantado, Grafana abierto, Wireshark capturando y Claude abierto. Si el pico queda debajo del 85 %, se sigue con este perfil.

   ```powershell
   windows\medir-ram.ps1 -Minutos 10
   ```

9. Verificar.

   | Dónde | Qué | Esperado |
   |---|---|---|
   | CHR | `/routing bgp session print` | 3 sesiones establecidas |
   | CHR | `/ip route print where bgp` | 10.10.20.10/32 |
   | Navegador | http://10.10.20.10/ y http://10.10.20.10/api/ | Responden frontend y backend |
   | Navegador | http://10.10.10.11:30300 | Tablero del TP4 |
   | Server | `sudo /vagrant/scripts/prueba-netpol.sh` | 8 de 8 |

## Backups

`backup.yml` guarda dos cosas en `demo/backups/`, una carpeta compartida con el host: está fuera de git y sobrevive a un `vagrant destroy`.

| Archivo | Contenido | Protección |
|---|---|---|
| `chr-export-<fecha>.rsc` | Configuración del CHR | Se le quita la clave BGP antes de guardarlo |
| `k3s-<fecha>.tar.gz.enc` | Base de datos y token de k3s | Cifrado con la clave del vault |

Conserva los últimos 5 de cada uno. **Sin la clave del vault, el backup de k3s no se puede abrir**: guardala fuera de la VM.

No incluye las VMs ni las imágenes. Tampoco hace falta restaurar la aplicación desde el backup si se reconstruye todo, porque los manifiestos están en git.

Preparar el CHR, una sola vez, desde la carpeta `demo`. El usuario `backup` solo puede leer y entra con la clave del laboratorio; el firewall deja pasar SSH únicamente desde 10.10.10.11.

```bash
scp .claves/lab_ed25519.pub admin@192.168.56.2:lab_ed25519.pub
ssh admin@192.168.56.2 "/user add name=backup group=read password=<clave larga>"
ssh admin@192.168.56.2 "/user ssh-keys import user=backup public-key-file=lab_ed25519.pub"
```

Hacer un backup, en el server. El playbook revisa la integridad de la base y prueba abrir el paquete cifrado.

```bash
/vagrant/ansible/run.sh backup.yml
```

Probar la restauración: se hace un backup, se borra el frontend y se restaura. Mientras tanto, http://10.10.20.10/ deja de responder y después vuelve.

```bash
/vagrant/ansible/run.sh backup.yml
sudo k3s kubectl -n web delete deployment frontend
/vagrant/ansible/run.sh restore.yml -e confirmar=si
sudo k3s kubectl -n web rollout status deployment/frontend
```

`restore.yml` usa el backup más nuevo; para otro, sumá `-e archivo=k3s-<fecha>.tar.gz.enc`. La base anterior queda en `/var/lib/rancher/k3s/server/db.antes-<fecha>`. Vuelve atrás solo el clúster: las VMs tienen que existir y k3s tiene que estar instalado.

Para restaurar el CHR se vuelve a importar `routeros/chr-borde.rsc`, que es la fuente de verdad. La exportación sirve para ver si la configuración real se apartó de ese archivo.

## En Mac

Los pasos son los mismos y cambian estos comandos. Los scripts detectan si el Mac es Intel o Apple Silicon. Nunca se corrieron en un Mac real: anotá en `prueba-ram/RESULTADOS.md` lo que falle.

| Paso | Comando en Mac |
|---|---|
| 1. Revisar y generar la clave | `bash mac/preparar-mac.sh` (si hace falta, `--carpeta-vms /ruta`) |
| 2. Levantar los nodos | `vagrant up` |
| 3. Crear el CHR | `bash mac/crear-chr.sh` |
| 5. Agregar la ruta | `bash mac/rutas.sh`; hay que repetirlo después de cada reinicio |
| 6 y 7. Secretos y Ansible | Iguales: corren dentro de la VM server |
| 8. Medir la RAM | `bash mac/medir-ram.sh 10` |
| Guion: medir el corte | `sh scripts/medir-corte.sh http://10.10.20.10/ 200` |
| Guion: apagar y prender el agent | Los mismos comandos `VBoxManage` |

Paso 4, configurar el CHR:

```bash
sed 's/CAMBIAR-CLAVE-BGP/<clave BGP>/' routeros/chr-borde.rsc > /tmp/chr-borde.rsc
scp /tmp/chr-borde.rsc admin@<IP de DHCP>:chr-borde.rsc
ssh admin@<IP de DHCP> "/import file-name=chr-borde.rsc"
ssh admin@192.168.56.2 "/file remove chr-borde.rsc"
rm /tmp/chr-borde.rsc
```

| Mac | Qué tener en cuenta |
|---|---|
| Intel | VirtualBox puede pedir permiso en Ajustes > Privacidad y seguridad; hay que aceptarlo y reiniciar |
| Apple Silicon | Todo corre en VMs ARM: existen la caja de Ubuntu, el CHR y las imágenes, pero es la combinación menos probada |
| Apple Silicon | La red host-only es de otro tipo (`hostonlynet`) y la IP del Mac aparece cuando el CHR está prendido |

Si el CHR no arranca en Apple Silicon, no sigas probando variantes: avisale al grupo, porque habría que decidir cómo reemplazarlo o usar otra PC.

## Guion de la demo (3 a 5 minutos)

Tiempos medidos el 15/11 en la réplica con contenedores ([capturas](../capturas/r3-pruebas-aplicacion.md)), porque la estación QEMU no estaba funcionando. Lo marcado [confirmar] depende de la estación que se use el 17/11.

### Comandos según la estación

En el guion, `k` es `kubectl` en el server.

| Paso | Estación QEMU (Mac de R1) | Réplica (Mac de Naim) | Laptop de respaldo (VirtualBox) |
|---|---|---|---|
| Medir (B) | [confirmar: la Mac no llega a 10.10.20.10; hace falta un cliente del otro lado del CHR] | `medir-corte.sh` desde el contenedor `cliente` [confirmar comando con Naim] | `windows\medir-corte.ps1 -Segundos 300` |
| Entrar al server (C) | [confirmar] | `colima ssh --profile tp4 -- docker exec -it k3s-server sh` (`kubectl` directo) | `vagrant ssh k3s-server` (`sudo k3s kubectl`) |
| Apagar `agent1` | Matar el proceso de QEMU de `agent1` [confirmar comando] | `./lab.sh caer-nodo agent1` | `VBoxManage controlvm tp4-k3s-agent1 poweroff` |
| Prender `agent1` | Relanzar `agent1` [confirmar comando] | `./lab.sh levantar-nodo agent1` | `VBoxManage startvm tp4-k3s-agent1 --type headless` |
| Segmentación | `sudo bash ~/prueba-netpol.sh` en el controlador | `./lab.sh netpol` | `sudo /vagrant/scripts/prueba-netpol.sh` en el server |

### Preflight, antes de cada tanda

- Tres nodos `Ready`, 3 sesiones BGP y `frontend` en v1 (`k -n web get deploy frontend -o jsonpath='{.spec.template.spec.containers[0].env}'`).
- **Hay un frontend en `agent1`** (`k -n web get pods -o wide`). Si no hay, la caída da 0 errores: sirve igual, pero hay que explicarla distinto (ver 0:45). Para repartirlos: `k -n web rollout restart deployment/frontend` y volver a mirar.
- QEMU: R1 copió `prueba-netpol.sh` al home del controlador. En todas las estaciones, la imagen `rancher/mirrored-library-busybox:1.37.0` tiene que estar en los nodos (`sudo k3s crictl images | grep busybox`): sin internet no se descarga, y `prueba-netpol.sh` espera hasta 90 s y corta sin resultado.

Ventanas abiertas: **A** Grafana (tablero del TP4), **B** la medición lista para arrancar, **C** el server con `k get nodes -w`, y **D** la terminal para apagar y prender `agent1`.

### Guion

| Tiempo | Quién | Qué se hace | Qué se muestra y qué se dice |
|---|---|---|---|
| 0:00 | R5 / R2 | Póster y topología | A: 3 nodos y 3 sesiones BGP. "El router aprende por BGP que el servicio está en los tres nodos" |
| 0:30 | R3 | Arrancar la medición en B | Un pedido cada 0,2 s; B muestra `responde v1` |
| 0:45 | R3 | Apagar `agent1` en D | El router saca la ruta enseguida (1 s en la réplica; hasta 9 s con VMs). B: errores **sueltos**, no un corte. A los ~18 s, C muestra `agent1` `NotReady` y los errores paran |
| | | | "¿Por qué hay errores si el router ya lo sacó? Los otros nodos siguen mandando algunos pedidos al frontend que estaba en `agent1` hasta que Kubernetes lo da por muerto. Llegar a 0 pediría BFD y `externalTrafficPolicy: Local`" |
| 1:30 | R3 | Prender `agent1` en D | `Ready` en 2–5 s y BGP de nuevo a los ~4 s |
| 1:45 | R3 | Rolling update en C: `k -n web set env deployment/frontend APP_VERSION=v2` | Tarda ~3 s. B: `cambia de v1 a v2`, sin errores nuevos. "Crea una réplica nueva antes de bajar una vieja" |
| 2:15 | R3 | Rollback en C: `k -n web rollout undo deployment/frontend` | ~3 s; por 2 s responden v1 y v2 mezclados y después B muestra `cambia de v2 a v1`. Sin errores |
| 2:45 | R4 | Segmentación (ver la tabla) y explicar las zonas mientras corre: los primeros ~30 s son de espera | 8 de 8: qué pasa y qué se bloquea. Tarda de 45 s a 1:15 (estimado por R4, falta medirlo) |
| 4:00 | R3 | Cortar B con Ctrl+C | El informe: todos los errores son de la caída (en la réplica, 12 de 674); el update y el rollback, 0 |
| 4:15 | Todos | Cierre y preguntas | — |

Si preguntan por mantenimiento: `k drain k3s-agent2 --ignore-daemonsets --delete-emptydir-data` muestra cómo el PDB frena un desalojo ("Cannot evict pod...") hasta que hay reemplazo. Tarda ~12 s y da 0 errores. Después, `k uncordon k3s-agent2`.

### Versión de 30 segundos

Para quien pasa rápido. B queda corriendo todo el tiempo (con 3600 s) y Grafana a la vista.

1. (10 s) "El servicio corre en tres nodos y el router aprende por BGP por dónde llegar."
2. (15 s) Rolling update y señalar B: "Actualizamos a v2 sin perder un pedido: Kubernetes levanta la réplica nueva antes de bajar la vieja." Se ve en 3 s y no deja nada para reponer.
3. (5 s) "Y si se cae un nodo, el servicio sigue: perdemos unos pocos pedidos durante ~18 s. Lo mostramos en la demo completa."

Antes de la próxima persona, volver a v1 con `k -n web rollout undo deployment/frontend`.

### Si algo falla en vivo

No reiniciar VMs ni cambiar configuración delante del público para tapar el error (ver [ENSAYO-FERIA-R1](qemu/ENSAYO-FERIA-R1.md)). Pasar al plan B y seguir con la explicación.

| Falla | Señal | Qué hacer | Quién |
|---|---|---|---|
| Se cierra o se cuelga el CHR | B da errores en todos los pedidos; A: 0 sesiones BGP | Decir "esto es justamente un punto único de falla: el router de borde" y pasar al video. Al terminar la tanda, R1 y R2 lo recuperan según [confirmar con R2] | R2 |
| `agent1` no vuelve | Sigue `NotReady` después de 30 s (lo normal es 2–5 s) | Seguir con dos nodos: el servicio anda igual (PDB mínimo 2). Avisar a R1 | R1 |
| La caída da 0 errores | No había un frontend en `agent1` | No es una falla: explicar que el router lo sacó y que Kubernetes no tenía réplicas ahí | R3 |
| El rolling update se traba | `rollout status` no termina en 60 s | `k -n web rollout undo deployment/frontend` | R3 |
| `prueba-netpol.sh` no da resultado | Sale sin las 8 líneas o se queda esperando los pods | Ctrl+C y mostrar la captura del 8 de 8; explicar las políticas con `k get netpol -A` | R4 |
| Grafana no carga | Pantalla en blanco | Mostrar `k get nodes` y `k -n web get pods -o wide` en C | R5 |
| La estación no arranca | — | Video grabado y capturas locales; la réplica o la laptop de respaldo de Lorenzo | Todos |

El día de la Feria, Claude queda cerrado y hay plan B grabado.

### Wireshark (sin probar)

El BGP va por la red interna y no se ve desde Windows. El CHR puede copiarlo hacia la laptop; se captura en el adaptador host-only con el filtro `bgp`.

```routeros
/tool sniffer set filter-interface=ether2 filter-port=bgp streaming-enabled=yes streaming-server=192.168.56.1
/tool sniffer start
```

Si el nodo se apaga de golpe no manda UPDATE, y `bgp.type == 2` no muestra nada. Conviene `bgp.type == 3 || bgp.type == 4`: se cortan los KEEPALIVE y a los 9 s llega el NOTIFICATION.

## Problemas conocidos

| Problema | Qué hacer |
|---|---|
| Ansible ignora `ansible.cfg` en `/vagrant` (vboxsf es world-writable) | Usar siempre `run.sh`, que exporta `ANSIBLE_CONFIG` |
| Un pod recién creado saltea las NetworkPolicies unos segundos | `prueba-netpol.sh` ya espera 15 s |
| Hay ~14 s de pedidos sueltos con error ante la caída de un nodo | Limitación conocida: para llegar a 0 hace falta BFD, que usa más RAM |
| Un solo server: no hay HA del plano de control | Limitación conocida: si cae el server, no se puede administrar el clúster |
| Hay un hipervisor activo (Hyper-V, WSL2, Integridad de memoria) | VirtualBox anda más lento; no apagar protecciones de un equipo administrado |

Las mediciones y los errores encontrados están en [prueba-ram/RESULTADOS.md](prueba-ram/RESULTADOS.md).
