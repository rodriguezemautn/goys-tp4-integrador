"""Acceso a las consolas Telnet de los VPCS de GEMELO."""

import argparse
import json
import re
import socket
import time
from datetime import datetime, timezone
from threading import Lock

from dotenv import dotenv_values

from configuracion import ARCHIVO_ENV


CONSOLAS = {
    "GEMELO-PC": "GEMELO_PC_CONSOLE_PORT",
    "GEMELO-SRV": "GEMELO_SRV_CONSOLE_PORT",
}

BLOQUEOS = {nombre: Lock() for nombre in CONSOLAS}

ANSI = re.compile(r"\x1b\[[0-?]*[ -/]*[@-~]")
MAX_SALIDA = 1_048_576


class Telnet:
    """Procesa datos y rechaza opciones Telnet que no necesitamos."""

    def __init__(self, conexion):
        self.conexion = conexion
        self.estado = "datos"
        self.operacion = None

    def procesar(self, datos: bytes) -> bytes:
        texto = bytearray()

        for valor in datos:
            if self.estado == "datos":
                if valor == 255:
                    self.estado = "iac"
                else:
                    texto.append(valor)

            elif self.estado == "iac":
                if valor == 255:
                    texto.append(valor)
                    self.estado = "datos"
                elif valor in (251, 252, 253, 254):
                    self.operacion = valor
                    self.estado = "opcion"
                elif valor == 250:
                    self.estado = "sub"
                else:
                    self.estado = "datos"

            elif self.estado == "opcion":
                if self.operacion == 253:
                    self.conexion.sendall(bytes((255, 252, valor)))
                elif self.operacion == 251:
                    self.conexion.sendall(bytes((255, 254, valor)))
                self.estado = "datos"

            elif self.estado == "sub":
                if valor == 255:
                    self.estado = "sub_iac"

            elif self.estado == "sub_iac":
                self.estado = "datos" if valor == 240 else "sub"

        return bytes(texto)


def leer_prompt(conexion, telnet, nombre: str, timeout: float) -> str:
    limite = time.monotonic() + timeout
    datos = bytearray()
    prompt_desde = None
    patron = re.compile(rf"(?m)^{re.escape(nombre)}>[ \t]*\Z")

    while time.monotonic() < limite:
        try:
            bloque = conexion.recv(4096)
        except socket.timeout:
            if (
                prompt_desde is not None
                and time.monotonic() - prompt_desde >= 0.2
            ):
                return texto
            continue

        if not bloque:
            raise ConnectionError("La consola cerro la conexion.")

        datos.extend(telnet.procesar(bloque))

        if len(datos) > MAX_SALIDA:
            raise ValueError("La respuesta excede el limite de salida.")

        texto = ANSI.sub(
            "",
            datos.decode("utf-8", errors="replace"),
        ).replace("\r", "").replace("\x00", "")

        if patron.search(texto):
            if prompt_desde is None:
                prompt_desde = time.monotonic()
        else:
            prompt_desde = None

    raise TimeoutError("No se recibio el prompt esperado.")


def ejecutar_consola(nombre: str, comando: str) -> dict:
    if nombre not in CONSOLAS:
        raise ValueError("Consola fuera del inventario de GEMELO.")

    if not isinstance(comando, str) or not comando.strip():
        raise ValueError("El comando no puede estar vacio.")

    if any(caracter in comando for caracter in ("\r", "\n", "\x00")):
        raise ValueError("Enviar un comando VPCS por llamada.")

    try:
        comando_bytes = comando.strip().encode("ascii")
    except UnicodeEncodeError:
        raise ValueError("Los comandos VPCS deben usar caracteres ASCII.") from None

    archivo = dotenv_values(ARCHIVO_ENV, interpolate=False)
    host = archivo.get("GNS3_CONSOLE_HOST")
    puerto_texto = archivo.get(CONSOLAS[nombre])

    if not host or not puerto_texto:
        raise ValueError("Falta configurar el host o puerto de la consola.")

    try:
        puerto = int(puerto_texto)
    except ValueError:
        raise ValueError("El puerto de consola debe ser numerico.") from None

    if not 1 <= puerto <= 65535:
        raise ValueError("Puerto de consola fuera de rango.")

    enviado = False

    with BLOQUEOS[nombre]:
        try:
            with socket.create_connection((host, puerto), timeout=5) as conexion:
                conexion.settimeout(0.25)
                telnet = Telnet(conexion)

                conexion.sendall(b"\n")
                leer_prompt(conexion, telnet, nombre, timeout=10)

                # Desde este punto, un fallo puede dejar un resultado incierto.
                enviado = True
                conexion.sendall(comando_bytes + b"\n")
                salida = leer_prompt(
                    conexion,
                    telnet,
                    nombre,
                    timeout=40,
                )

            return {
                "estado": "completado",
                "equipo": nombre,
                "fecha_utc": datetime.now(timezone.utc).isoformat(),
                "salida": salida.strip(),
            }

        except (OSError, ValueError):
            return {
                "estado": "inconcluso" if enviado else "error",
                "equipo": nombre,
                "fecha_utc": datetime.now(timezone.utc).isoformat(),
                "detalle": (
                    "No se confirmo el final del comando. "
                    "Consultar el estado antes de repetirlo."
                    if enviado else
                    "No se pudo conectar y verificar el prompt de la consola."
                ),
            }


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Ejecuta un comando en un VPCS de GEMELO."
    )
    parser.add_argument("equipo", choices=sorted(CONSOLAS))
    parser.add_argument("comando")
    argumentos = parser.parse_args()

    try:
        resultado = ejecutar_consola(
            argumentos.equipo,
            argumentos.comando,
        )
    except ValueError as error:
        resultado = {"estado": "error", "detalle": str(error)}

    print(json.dumps(resultado, indent=2, ensure_ascii=False))
    raise SystemExit(0 if resultado["estado"] == "completado" else 1)