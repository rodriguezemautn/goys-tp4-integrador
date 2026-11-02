"""Ejecucion de comandos RouterOS con credenciales segun el entorno."""

import time
from datetime import datetime, timezone

import paramiko

from configuracion import obtener_equipo
from conexion_ssh import conectar_escritura, conectar_lectura


TIEMPO_MAXIMO = 30
MAX_BYTES_POR_SALIDA = 1_048_576


def _ejecutar(cliente, comando: str) -> dict:
    canal = None
    salida = bytearray()
    errores = bytearray()
    truncada = False
    codigo = None
    estado = "inconcluso"
    detalle = None

    def guardar(destino: bytearray, datos: bytes) -> None:
        nonlocal truncada
        espacio = MAX_BYTES_POR_SALIDA - len(destino)
        destino.extend(datos[:espacio])
        if len(datos) > espacio:
            truncada = True

    try:
        entrada, stdout, stderr = cliente.exec_command(
            comando,
            timeout=15,
        )
        canal = stdout.channel
        entrada.close()
        limite = time.monotonic() + TIEMPO_MAXIMO

        while True:
            if time.monotonic() >= limite:
                detalle = (
                    "Tiempo de espera agotado. El comando podria haberse "
                    "aplicado; consultar el estado antes de repetirlo."
                )
                break

            if canal.recv_ready():
                guardar(salida, canal.recv(32768))

            if canal.recv_stderr_ready():
                guardar(errores, canal.recv_stderr(32768))

            if (
                canal.exit_status_ready()
                and not canal.recv_ready()
                and not canal.recv_stderr_ready()
            ):
                codigo = canal.recv_exit_status()

                if codigo == -1:
                    detalle = "La conexion termino sin codigo de retorno."
                else:
                    estado = "completado" if codigo == 0 else "error"

                break

            time.sleep(0.02)

    except (paramiko.SSHException, OSError, EOFError):
        detalle = (
            "La comunicacion se interrumpio durante la ejecucion. "
            "No se puede confirmar si el comando se aplico."
        )

    finally:
        if canal is not None:
            canal.close()

    return {
        "estado": estado,
        "codigo_salida": codigo,
        "salida": salida.decode("utf-8", errors="replace").strip(),
        "errores": errores.decode("utf-8", errors="replace").strip(),
        "salida_truncada": truncada,
        "detalle": detalle,
    }


def ejecutar_router(
    nombre: str,
    comando: str,
    credenciales: dict[str, str],
    *,
    administrativo: bool = False,
) -> dict:
    equipo = obtener_equipo(nombre)

    if administrativo and equipo.entorno != "GEMELO":
        raise ValueError(
            "La ejecucion administrativa solo esta permitida en GEMELO."
        )

    if not isinstance(comando, str) or not comando.strip():
        raise ValueError("El comando no puede estar vacio.")

    conectar = conectar_escritura if administrativo else conectar_lectura

    with conectar(nombre, credenciales) as cliente:
        resultado = _ejecutar(cliente, comando.strip())

    return {
        "equipo": equipo.nombre,
        "ip": equipo.ip,
        "usuario": "netadmin" if administrativo else "mcp_ro",
        "fecha_utc": datetime.now(timezone.utc).isoformat(),
        **resultado,
    }