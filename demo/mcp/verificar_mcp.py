"""Verifica routers y consolas MCP sin modificar configuraciones."""

import asyncio
import json
import sys
from pathlib import Path

from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client

from operaciones_router import ejecutar_router


BASE = Path(__file__).resolve().parent


def exigir(condicion: bool, mensaje: str) -> None:
    if not condicion:
        raise RuntimeError(mensaje)


def obtener_datos(resultado) -> dict:
    exigir(not resultado.isError, "La herramienta devolvio un error.")

    for bloque in resultado.content:
        if bloque.type == "text":
            datos = json.loads(bloque.text)
            if isinstance(datos, dict):
                return datos

    raise RuntimeError("La herramienta no devolvio el objeto esperado.")


async def verificar() -> None:
    for equipo in ("EMPRESA-R1", "EMPRESA-R2", "EMPRESA-R3"):
        try:
            ejecutar_router(
                equipo,
                ":put 1",
                {},
                administrativo=True,
            )
        except ValueError as error:
            exigir(
                str(error)
                == "La ejecucion administrativa solo esta permitida en GEMELO.",
                "El rechazo administrativo tuvo una causa inesperada.",
            )
        else:
            raise RuntimeError("Se admitio administracion de EMPRESA.")

    print("OK: EMPRESA rechazada en la capa administrativa.", flush=True)

    parametros = StdioServerParameters(
        command=sys.executable,
        args=[str(BASE / "servidor_mcp.py")],
    )

    async with stdio_client(parametros) as (lectura, escritura):
        async with ClientSession(lectura, escritura) as sesion:
            inicio = await sesion.initialize()
            exigir(
                "Cierre de intervenciones" in (inicio.instructions or ""),
                "No se recibieron las instrucciones de cierre.",
            )
            print("OK: instrucciones de cierre recibidas.", flush=True)
            print("OK: sesion MCP inicializada.", flush=True)

            listado = await sesion.list_tools()
            herramientas = {
                herramienta.name: herramienta
                for herramienta in listado.tools
            }

            exigir(
                set(herramientas) == {
                    "listar_routers",
                    "consultar_router",
                    "ejecutar_comando_gemelo",
                    "ejecutar_comando_vpcs",
                },
                "El conjunto de herramientas no coincide.",
            )

            for nombre in ("listar_routers", "consultar_router"):
                anotaciones = herramientas[nombre].annotations
                exigir(
                    anotaciones is not None
                    and anotaciones.readOnlyHint is True,
                    f"Anotaciones incorrectas para {nombre}.",
                )

            destinos_esperados = {
                "ejecutar_comando_gemelo": {
                    "GEMELO-R1", "GEMELO-R2", "GEMELO-R3",
                },
                "ejecutar_comando_vpcs": {
                    "GEMELO-PC", "GEMELO-SRV",
                },
            }

            for nombre, destinos in destinos_esperados.items():
                herramienta = herramientas[nombre]
                anotaciones = herramienta.annotations

                exigir(
                    anotaciones is not None
                    and anotaciones.readOnlyHint is False
                    and anotaciones.destructiveHint is True,
                    f"Anotaciones administrativas incorrectas: {nombre}.",
                )

                equipos = (
                    herramienta.inputSchema["properties"]["equipo"]["enum"]
                )
                exigir(
                    set(equipos) == destinos,
                    f"La herramienta admite equipos inesperados: {nombre}.",
                )

            print("OK: herramientas y separacion de entornos.", flush=True)

            inventario = await sesion.call_tool("listar_routers", {})
            exigir(not inventario.isError, "Fallo listar_routers.")
            print("OK: inventario consultado.", flush=True)

            for equipo in ("EMPRESA-R1", "GEMELO-R1"):
                resultado = await sesion.call_tool(
                    "consultar_router",
                    {
                        "equipo": equipo,
                        "comando": ":put [/system identity get name]",
                    },
                )
                datos = obtener_datos(resultado)
                exigir(
                    datos.get("estado") == "completado"
                    and datos.get("equipo") == equipo
                    and datos.get("salida") == equipo
                    and datos.get("usuario") == "mcp_ro",
                    f"Consulta general incorrecta para {equipo}.",
                )
                print(f"OK: consulta general en {equipo}.", flush=True)

            resultado = await sesion.call_tool(
                "ejecutar_comando_gemelo",
                {
                    "equipo": "GEMELO-R1",
                    "comando": ":put [/system identity get name]",
                },
            )
            datos = obtener_datos(resultado)
            exigir(
                datos.get("estado") == "completado"
                and datos.get("equipo") == "GEMELO-R1"
                and datos.get("salida") == "GEMELO-R1"
                and datos.get("usuario") == "netadmin",
                "Fallo la ejecucion mediante netadmin.",
            )
            print("OK: comando general con netadmin en GEMELO.", flush=True)

            for equipo in ("EMPRESA-R1", "FUERA-DEL-INVENTARIO"):
                resultado = await sesion.call_tool(
                    "ejecutar_comando_gemelo",
                    {"equipo": equipo, "comando": ":put 1"},
                )
                exigir(
                    resultado.isError,
                    "MCP acepto un destino administrativo no permitido.",
                )

            print(
                "OK: destinos administrativos no permitidos rechazados.",
                flush=True,
            )

            for equipo in ("GEMELO-PC", "GEMELO-SRV"):
                resultado = await sesion.call_tool(
                    "ejecutar_comando_vpcs",
                    {"equipo": equipo, "comando": "show ip"},
                )
                datos = obtener_datos(resultado)
                exigir(
                    datos.get("estado") == "completado"
                    and datos.get("equipo") == equipo
                    and "IP/MASK" in datos.get("salida", ""),
                    f"Fallo la consulta de consola para {equipo}.",
                )
                print(
                    f"OK: consola de {equipo} consultada mediante MCP.",
                    flush=True,
                )

            for equipo in ("EMPRESA-PC", "FUERA-DEL-INVENTARIO"):
                resultado = await sesion.call_tool(
                    "ejecutar_comando_vpcs",
                    {"equipo": equipo, "comando": "show ip"},
                )
                exigir(
                    resultado.isError,
                    "MCP acepto una consola fuera de GEMELO.",
                )

            print("OK: consolas no permitidas rechazadas.", flush=True)

    print("Verificacion completada. No se modificaron configuraciones.")


if __name__ == "__main__":
    try:
        asyncio.run(asyncio.wait_for(verificar(), timeout=180))
    except Exception as error:
        print(
            f"Verificacion incompleta: {type(error).__name__}: {error}",
            file=sys.stderr,
        )
        raise SystemExit(1) from None