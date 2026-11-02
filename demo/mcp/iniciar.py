"""Configura, diagnostica e inicia el tunel del MCP del laboratorio."""

import argparse
import os
import subprocess
import sys
from pathlib import Path

from dotenv import dotenv_values

from configuracion import ARCHIVO_ENV, cargar_credenciales


BASE = Path(__file__).resolve().parent
CLIENTE = BASE / "tunnel-client.exe"
SERVIDOR = BASE / "servidor_mcp.py"


def preparar() -> tuple[dict[str, str], dict[str, str]]:
    if not CLIENTE.is_file():
        raise ValueError(
            "Falta tunnel-client.exe dentro de demo/mcp."
        )

    if not SERVIDOR.is_file():
        raise ValueError("No se encontro servidor_mcp.py.")

    if sys.prefix == sys.base_prefix:
        raise ValueError(
            "Ejecutar iniciar.py con el Python del entorno virtual."
        )

    cargar_credenciales()

    archivo = dotenv_values(ARCHIVO_ENV, interpolate=False)
    valores = {}

    for nombre in ("CONTROL_PLANE_API_KEY", "TUNNEL_PROFILE", "TUNNEL_ID"):
        valor = archivo.get(nombre) or os.environ.get(nombre)
        if valor:
            valores[nombre] = valor.strip()

    for nombre in ("CONTROL_PLANE_API_KEY", "TUNNEL_PROFILE"):
        if not valores.get(nombre):
            raise ValueError(f"Falta configurar {nombre}.")

    entorno = os.environ.copy()
    entorno["CONTROL_PLANE_API_KEY"] = valores["CONTROL_PLANE_API_KEY"]
    entorno["PYTHONUNBUFFERED"] = "1"

    return valores, entorno


def ejecutar_cliente(argumentos: list[str], entorno: dict[str, str]) -> int:
    proceso = subprocess.Popen(
        [str(CLIENTE), *argumentos],
        cwd=str(BASE),
        env=entorno,
    )

    try:
        return proceso.wait()

    except KeyboardInterrupt:
        print("\nDeteniendo el cliente del tunel...", flush=True)

        if proceso.poll() is None:
            proceso.terminate()

        try:
            proceso.wait(timeout=10)
        except subprocess.TimeoutExpired:
            proceso.kill()
            proceso.wait()

        return 130


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Arranque local del MCP mediante Secure MCP Tunnel."
    )
    modo = parser.add_mutually_exclusive_group()
    modo.add_argument(
        "--configurar",
        action="store_true",
        help="Crea el perfil local apuntando al servidor de este proyecto.",
    )
    modo.add_argument(
        "--doctor",
        action="store_true",
        help="Diagnostica el perfil sin dejar el tunel en ejecucion.",
    )
    argumentos = parser.parse_args()

    try:
        valores, entorno = preparar()
        perfil = valores["TUNNEL_PROFILE"]

        if argumentos.configurar:
            identificador = valores.get("TUNNEL_ID")
            if not identificador:
                raise ValueError("Falta configurar TUNNEL_ID.")

            python_mcp = Path(sys.executable).resolve().as_posix()
            servidor_mcp = SERVIDOR.as_posix()
            comando_mcp = f'"{python_mcp}" "{servidor_mcp}"'

            print(
                "Configurando el perfil local para el servidor del proyecto.",
                flush=True,
            )
            return ejecutar_cliente(
                [
                    "init",
                    "--sample", "sample_mcp_stdio_local",
                    "--profile", perfil,
                    "--tunnel-id", identificador,
                    "--mcp-command", comando_mcp,
                ],
                entorno,
            )

        if argumentos.doctor:
            return ejecutar_cliente(
                ["doctor", "--profile", perfil, "--explain"],
                entorno,
            )

        print(
            "Iniciando el tunel del MCP. Mantener esta terminal abierta.",
            flush=True,
        )
        print("Para detenerlo: Ctrl+C.", flush=True)

        return ejecutar_cliente(
            ["run", "--profile", perfil],
            entorno,
        )

    except (ValueError, OSError) as error:
        print(f"No se pudo iniciar: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())