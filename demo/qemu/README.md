# Estación de Feria — QEMU

La estación operativa de R1 usa QEMU en un Mac ARM64. VirtualBox y Vagrant quedan como alternativa histórica, no como instrucciones de arranque de esta estación.

## Topología
- Un MikroTik CHR x86_64 con TCG.
- Un proceso QEMU auxiliar sin disco que conecta la LAN del CHR con los tres Ubuntu.
- Tres Ubuntu ARM64 con HVF: un controlador K3s y dos agentes.
- La gestión está ligada a loopback. Este diseño no publica el laboratorio hacia otras computadoras.

## Operación de la estación existente
1. Coordinar una ventana con el operador y comprobar que no haya procesos duplicados usando discos o puertos.
2. Conservar imágenes, variables UEFI, seeds y configuración original. Arrancar CHR, luego el auxiliar, el controlador y finalmente los agentes.
3. Confirmar los tres nodos Ready, las tres sesiones BGP, los diez targets y HTTP 200 de frontend y API.
4. Si se pierde el enlace CHR, no reiniciar los Ubuntu automáticamente. Registrar el incidente con R2 y usar el plan de respaldo de Feria si no se recupera.

No se incluyen el estado privado de la estación ni launchers portátiles validados. Este documento no es un procedimiento de instalación desde cero.

## Evidencia y límites
- El ciclo en frío del 13/11 recuperó el laboratorio con los discos originales. No se probó arrancar una restauración del respaldo completo.
- Pasó el ensayo de aislamiento de los tres Ubuntu. No reemplaza el ensayo completo de Feria sin internet.
- El [despliegue idempotente](../../capturas/r1-idempotencia-replica.json) se verificó en una réplica ARM64 sin tarjeta de red, no en la estación.
- Ver [guion de Feria](ENSAYO-FERIA-R1.md). No ejecutar el despliegue completo durante la preparación: también aplica cambios de R4 y R5.

## Lanzador publicable

`station.py` imprime por defecto el comando (JSON), sin abrir discos ni arrancar QEMU:

```sh
python3 demo/qemu/station.py chr --state ./demo/.qemu/fixture
python3 demo/qemu/station.py server --state ./demo/.qemu/fixture
```

Se requiere Python 3 y QEMU para x86_64 y AArch64. Preparar un directorio **privado y exclusivo**, con un `chr/disk.qcow2`, un `firmware.fd` ARM64 y, para cada uno de `server`, `agent1` y `agent2`, su propio `disk.qcow2`, `vars.fd` y `seed.iso`. Los seeds y discos deben prepararse con la identidad y configuración de cada nodo; el script no los genera. Los roles usan puertos fijos de loopback; no ejecutar junto con la estación existente ni usar sus discos como fixture.

Solo en una ventana autorizada y con los insumos ya preparados, agregar `--start` para arrancar un rol en primer plano. Desde terminales separadas, iniciar `chr`, comprobar que escucha, iniciar `hub`, comprobar sus listeners, e iniciar `server`, `agent1` y `agent2` en ese orden. El lanzador no supervisa procesos ni comprueba que el clúster esté saludable.

Verificación sin VMs: `cd demo/qemu && PYTHONDONTWRITEBYTECODE=1 python3 -m unittest -v test_station`. La prueba cubre argumentos, puertos y rechazo de disco faltante; no certifica arranque.

### Preparar Ubuntu en un directorio nuevo

Se requiere macOS ARM64, Python 3.11 o posterior, `qemu-img` y `hdiutil`. El modo por defecto de `prepare_ubuntu.py` imprime los datos de red sin escribir archivos. Para generar los tres discos independientes, las variables UEFI y los seeds NoCloud:

```sh
python3 demo/qemu/prepare_ubuntu.py --create --state demo/.qemu/fixture \
  --image /path/to/verified-ubuntu-arm64.qcow2 --sha256 VERIFIED_SHA256 \
  --firmware /path/to/edk2-aarch64-code.fd
```

El directorio no debe existir. Preparar aparte `chr/disk.qcow2` a partir de una imagen CHR nueva. Los seeds de prueba configuran IP estática en la LAN (sin ruta por defecto), no instalan K3s y no conceden acceso SSH. Para repetir el arranque descartable sin interferir con la estación, usar el mismo `--isolated --port-offset 2000` en los cinco roles. Verificar primero que ese rango esté libre. No usar archivos ni perfiles del laboratorio.

## Configuración CHR y evidencias publicables

- [Referencia BGP del CHR](../routeros/chr-bgp-qemu-r1.public.rsc): reconstrucción de la plantilla R1, con marcador en lugar de clave y una guarda para impedir importaciones accidentales. No es una exportación del CHR ni reemplaza la validación de una copia privada. No modifica la referencia de RouterOS para Vagrant.
- [Resumen de evidencias de la estación](../../capturas/r1-evidencias-estacion.md): distingue resultados de la estación, resultados de réplicas y pruebas pendientes.
