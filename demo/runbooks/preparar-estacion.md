# Runbook — Preparar el laboratorio y la estación de monitoreo (H1 y H2)

- **Hitos:** H1 Laboratorio · H2 Conectividad
- **Responsable:** Santiago Natalichio Bestosini
- **Fecha:** 12/11/2026
- **Resultado:** el proyecto GNS3 del TP4 es una copia independiente del TP3, y un container Docker de la estación (`10.20.0.101`) le hace ping al EDGE (`203.0.113.2`).

---

## H1 — Copia del proyecto GNS3

El proyecto del TP3 (`Failover-G11`) **no se toca**: el TP4 trabaja sobre una copia.

1. En GNS3, abrir `Failover-G11.gns3` sin arrancar los nodos.
2. **File → Save project as…** → nombre `TP4-SistemaInmune`, en la carpeta por defecto `C:\Users\<usuario>\GNS3\projects\`. Queda fuera de OneDrive a propósito: OneDrive intenta sincronizar los discos de los routers mientras corren.
3. GNS3 cierra el TP3 y abre la copia.

**Verificación** (`capturas/H1/`):

| Chequeo | Resultado |
|---|---|
| Copia | `GNS3\projects\TP4-SistemaInmune`, con los discos de los 7 CHR y los 5 snapshots |
| Identidad | `project_id` nuevo (`1ac8a4ca…`), distinto del TP3 (`7ea721a8…`): GNS3 los trata como proyectos separados |
| Topología | 11 nodos y 15 enlaces, igual que el TP3 |
| TP3 intacto | SHA-256 de `Failover-G11.gns3` idéntico antes y después de la copia y al cierre de H2: `c3d9be4d0374071c88121ae866a89fc2e89fec97ea746cdb694e65a6e6b84970` |

---

## H2 — Estación de monitoreo conectada a la red

### Diseño final

La estación es una **VM Ubuntu Server 24.04 en VirtualBox**, con Docker, conectada a GNS3 por un **túnel UDP**:

```
VirtualBox: ESTACION-TP4                         GNS3: TP4-SistemaInmune
+-----------------------------+                  +----------------------------+
| enp0s3 10.20.0.101/24  -----+-- UDP 45001 <--> 45000 -- nube ESTACION        |
|  (placa 1, túnel UDP)       |   127.0.0.1      |        |                    |
|                             |                  |        +-- SW-SERVERS e3    |
| enp0s8 10.0.3.15 (NAT) -----+-- Internet       |            (LAN SERVERS)   |
|  (placa 2) SSH :2222        |                  +----------------------------+
|            Grafana :3000    |
|            Prometheus :9090 |
+-----------------------------+
```

- **Placa 1 (`enp0s3`)** → LAN SERVERS, la red de gestión del TP3. IP fija `10.20.0.101/24`, sin ruta por defecto; solo las redes del laboratorio van por el gateway VRRP `10.20.0.1` ([`60-laboratorio.yaml`](../estacion/60-laboratorio.yaml)).
- **Placa 2 (`enp0s8`)** → NAT de VirtualBox: Internet para instalar paquetes y bajar imágenes, y acceso desde Windows por `127.0.0.1` (SSH `2222`, Grafana `3000`, Prometheus `9090`).
- Los containers salen por el NAT de Docker, así que el tráfico llega a la red con la IP de la estación (`10.20.0.101`). Es la IP que el EDGE va a habilitar para el monitoreo (API-SSL de solo lectura).

### Por qué no quedó como decía la propuesta

La propuesta ubicaba la estación en la laptop (Windows) conectada con un nodo *Cloud* sobre una placa de loopback. Se probó y se descartó, con evidencia:

| Intento | Qué pasó | Evidencia |
|---|---|---|
| 1. Cloud sobre la placa *KM-TEST Loopback* de Windows (`GNS3-TP4`, `10.20.0.101`) | Windows **envía** por la placa, pero **descarta lo que llega** desde GNS3: no aprende la MAC del gateway (vecino `10.20.0.1` en *Incomplete*) ni responde el ARP de SRV, aunque la captura muestra que los paquetes llegan a la placa. Npcap inyecta los paquetes marcados como propios y Windows 11 25H2 los ignora. Tampoco se arregló reiniciando la placa ni la PC. | `capturas/H2/H2-01-intento-loopback-ip-rutas.png`, `H2-01b-intento-loopback-nube.png` y capturas con `dumpcap`: entran los VRRP de DIST-2, no sale respuesta |
| 2. Opción `SendToRxAdapters` de Npcap para esa placa | Es la opción prevista para este caso, pero en esta máquina **colgó** los envíos de Npcap (GNS3 y una prueba de inyección quedaron trabados). Se revirtió. | — |
| 3. VM de VirtualBox administrada por GNS3 | Conecta, pero GNS3 **desactiva las placas que no maneja**: la VM se quedó sin NAT, sin Internet y sin acceso desde Windows (no se podría ver Grafana). | `nic2="none"` en `VBoxManage showvminfo` |
| **4. VM gestionada por VirtualBox + túnel UDP a una nube de GNS3** | **Funciona.** No pasa por Npcap y la VM conserva su NAT. | `capturas/H2/H2-02` a `H2-05` |

**Consecuencias para los hitos siguientes:**

- **H3:** Prometheus y Grafana corren en Docker dentro de la VM.
- **H6:** Ansible corre nativo en la VM (Linux), sin WSL.
- **RAM de la laptop:** son 7,4 GB, no 16 GB: los 7 CHR usan unos 1,8 GB y la VM 2 GB. Si falta memoria, la VM puede bajar a 1,5 GB.

### Paso a paso (desde cero)

**1. Crear la VM** (PowerShell en Windows, con el ISO de Ubuntu Server 24.04 descargado):

```powershell
powershell -ExecutionPolicy Bypass -File demo\estacion\crear-vm.ps1 -Iso "$env:USERPROFILE\Downloads\ubuntu-24.04.5-live-server-amd64.iso"
```

**2. Instalar Ubuntu Server.** Iniciar la VM desde VirtualBox y completar el instalador:

- Instalación **Ubuntu Server** (no la *minimized*). Red: dejar `enp0s8` por DHCP (`enp0s3` aparece sin configurar, es lo esperado).
- Disco entero.
- Hostname `estacion`, usuario `goys`.
- Marcar **Install OpenSSH server**. Sin *snaps*.
- Al terminar, si pide sacar el medio de instalación:
  `VBoxManage storageattach ESTACION-TP4 --storagectl SATA --port 1 --device 0 --type dvddrive --medium emptydrive --forceunmount`

**3. Llave SSH desde Windows** (una vez):

```powershell
ssh-keygen -t ed25519 -C goys-estacion-tp4 -f $env:USERPROFILE\.ssh\goys_estacion -N '""'
type $env:USERPROFILE\.ssh\goys_estacion.pub | ssh -p 2222 goys@127.0.0.1 "mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
```

**4. Preparar la estación.** Copiar `demo/estacion/` a la VM y correr el script:

```powershell
scp -i $env:USERPROFILE\.ssh\goys_estacion -P 2222 demo\estacion\preparar-estacion.sh demo\estacion\60-laboratorio.yaml goys@127.0.0.1:
ssh -i $env:USERPROFILE\.ssh\goys_estacion -p 2222 goys@127.0.0.1 "sudo bash ~/preparar-estacion.sh"
```

El script ([`preparar-estacion.sh`](../estacion/preparar-estacion.sh)) estira el disco, pone la hora de Argentina, configura `enp0s3`, instala Docker desde el repositorio oficial y descarga `alpine:3.20` para la demo sin Internet. Se puede correr más de una vez.

**5. Nube ESTACION en GNS3** (proyecto `TP4-SistemaInmune`):

- Agregar un nodo **Cloud** llamado `ESTACION`.
- En **Configure → UDP tunnels**, cargar: name `estacion-vm`, local port `45000`, remote host `127.0.0.1`, remote port `45001`.
- Dejar **sin** placas en *Ethernet interfaces*.
- Cablear `ESTACION (estacion-vm)` ↔ `SW-SERVERS Ethernet3`.

**6. Arranque de cada sesión:** abrir el proyecto en GNS3, iniciar todos los nodos y después la estación:

```powershell
powershell -ExecutionPolicy Bypass -File demo\estacion\iniciar-estacion.ps1
```

### Verificación (`capturas/H2/`)

| Prueba | Comando (en la estación) | Resultado |
|---|---|---|
| IP y rutas | `ip -br a show enp0s3; ip route` | `10.20.0.101/24`, redes del laboratorio vía `10.20.0.1` |
| Gateway VRRP | `ping -c 4 10.20.0.1` | 4/4, ~3 ms |
| EDGE desde la estación | `ping -c 4 203.0.113.2` | 4/4, ttl 62 (DIST-2 → CORE → EDGE) |
| **EDGE desde un container (entregable H2)** | `docker run --rm alpine:3.20 ping -c 5 203.0.113.2` | **5/5, ~6 ms, ttl 61** (un salto más: el bridge de Docker) |
| IP de origen | `sudo tcpdump -ni enp0s3 icmp` mientras corre el container | Los paquetes salen como `10.20.0.101 > 203.0.113.2` |

### Problemas conocidos

- **La estación tiene red del laboratorio solo con el proyecto abierto en GNS3 y los nodos arrancados**: la nube `ESTACION` es la que escucha en el puerto UDP `45000`. Internet y el acceso desde Windows (NAT) funcionan igual con GNS3 cerrado.
- `traceroute` por UDP al EDGE se corta después del CORE: el firewall de entrada del EDGE descarta el UDP (regla «todo lo demás», TP3). Es lo esperado; el ICMP sí responde.
