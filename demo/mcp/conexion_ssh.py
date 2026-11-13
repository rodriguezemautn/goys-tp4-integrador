"""Conexiones SSH verificadas; escritura exclusiva en GEMELO."""

import argparse
import json
import logging
from contextlib import contextmanager
from pathlib import Path

import paramiko

from configuracion import (
    INVENTARIO,
    cargar_credenciales,
    obtener_equipo,
    seleccionar_credencial,
)


logging.getLogger("paramiko").setLevel(logging.WARNING)

KNOWN_HOSTS = Path.home() / ".ssh" / "known_hosts"


class ErrorSSH(RuntimeError):
    """Error de conexion o validacion, sin incluir secretos."""


def _consultar_texto(cliente: paramiko.SSHClient, comando: str) -> str:
    """Funcion interna; los comandos proceden del codigo del servidor."""
    entrada, salida, errores = cliente.exec_command(comando, timeout=15)
    entrada.close()

    try:
        texto = salida.read().decode("utf-8", errors="replace").strip()
        error = errores.read().decode("utf-8", errors="replace").strip()
        estado = salida.channel.recv_exit_status()

        marcas_error = (
            "failure:",
            "syntax error",
            "bad command name",
            "expected end of command",
            "not enough permissions",
            "input does not match",
        )

        if estado != 0 or error or any(
            marca in texto.lower() for marca in marcas_error
        ):
            raise ErrorSSH("RouterOS rechazo el comando.")

        return texto
    finally:
        salida.channel.close()


@contextmanager
def _conectar(
    nombre: str,
    credenciales: dict[str, str],
    *,
    escritura: bool,
):
    equipo = obtener_equipo(nombre)

    if escritura and equipo.entorno != "GEMELO":
        raise ValueError("La conexion de escritura solo admite GEMELO.")

    credencial = seleccionar_credencial(
        equipo,
        credenciales,
        escritura=escritura,
    )

    if not KNOWN_HOSTS.is_file():
        raise ErrorSSH(
            "No existe known_hosts. Registrar y verificar "
            "las claves de host mediante SSH local."
        )

    cliente = paramiko.SSHClient()

    try:
        cliente.load_host_keys(str(KNOWN_HOSTS))
        cliente.set_missing_host_key_policy(paramiko.RejectPolicy())

        cliente.connect(
            hostname=equipo.ip,
            port=22,
            username=credencial.usuario,
            password=credencial.password,
            look_for_keys=False,
            allow_agent=False,
            timeout=10,
            auth_timeout=10,
            banner_timeout=15,
            channel_timeout=15,
        )

        identidad = _consultar_texto(
            cliente,
            ":put [/system identity get name]",
        )
        mac = _consultar_texto(
            cliente,
            ':put [/interface ethernet get '
            '[find where name="ether1"] mac-address]',
        ).upper()

        if identidad != equipo.nombre:
            raise ErrorSSH("La identidad no coincide con el inventario.")

        if mac != equipo.mac_gestion:
            raise ErrorSSH("La MAC de gestion no coincide con el inventario.")

        yield cliente

    except paramiko.BadHostKeyException:
        raise ErrorSSH(
            "La clave de host cambio. Verificarla localmente."
        ) from None

    except paramiko.AuthenticationException:
        cuenta = "administrativa" if escritura else "de lectura"
        raise ErrorSSH(
            f"Fallo la autenticacion de la cuenta {cuenta}."
        ) from None

    except (paramiko.SSHException, OSError, EOFError):
        raise ErrorSSH(
            "Fallo SSH: comprobar conectividad y clave de host registrada."
        ) from None

    finally:
        cliente.close()


@contextmanager
def conectar_lectura(nombre: str, credenciales: dict[str, str]):
    with _conectar(nombre, credenciales, escritura=False) as cliente:
        yield cliente


@contextmanager
def conectar_escritura(nombre: str, credenciales: dict[str, str]):
    with _conectar(nombre, credenciales, escritura=True) as cliente:
        yield cliente


def verificar_bloqueo_empresa() -> bool:
    """Comprueba el rechazo local sin credenciales ni conexion de red."""
    correcto = True

    for nombre, equipo in INVENTARIO.items():
        if equipo.entorno != "EMPRESA":
            continue

        try:
            with conectar_escritura(nombre, {}):
                pass
        except ValueError as error:
            rechazado = (
                str(error)
                == "La conexion de escritura solo admite GEMELO."
            )
        else:
            rechazado = False

        if not rechazado:
            correcto = False

        print(
            json.dumps(
                {
                    "equipo": nombre,
                    "comprobacion": "rechazo_local_de_escritura",
                    "estado": "verificado" if rechazado else "error",
                },
                ensure_ascii=False,
            ),
            flush=True,
        )

    return correcto


def verificar_conexiones(*, escritura: bool = False) -> bool:
    credenciales = cargar_credenciales()
    correcto = True

    if escritura:
        correcto = verificar_bloqueo_empresa()

    conectar = conectar_escritura if escritura else conectar_lectura

    for nombre, equipo in INVENTARIO.items():
        if escritura and equipo.entorno != "GEMELO":
            continue

        try:
            with conectar(nombre, credenciales):
                resultado = {
                    "equipo": nombre,
                    "ip": equipo.ip,
                    "usuario": "netadmin" if escritura else "mcp_ro",
                    "estado": "verificado",
                    "comprobaciones": [
                        "clave_host",
                        "autenticacion",
                        "identidad",
                        "mac_gestion",
                    ],
                }

        except (ErrorSSH, ValueError) as error:
            correcto = False
            resultado = {
                "equipo": nombre,
                "estado": "error",
                "detalle": str(error),
            }

        print(json.dumps(resultado, ensure_ascii=False), flush=True)

    return correcto


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Verifica conexiones SSH sin modificar configuraciones."
    )
    parser.add_argument(
        "--escritura",
        action="store_true",
        help="Verifica netadmin en GEMELO y el rechazo local de EMPRESA.",
    )
    argumentos = parser.parse_args()

    try:
        exito = verificar_conexiones(escritura=argumentos.escritura)
    except ValueError as error:
        raise SystemExit(str(error)) from None

    raise SystemExit(0 if exito else 1)