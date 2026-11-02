"""Inventario fijo y carga de credenciales locales."""

import json
import os
from dataclasses import dataclass, field
from pathlib import Path

from dotenv import dotenv_values


BASE = Path(__file__).resolve().parent
ARCHIVO_ENV = BASE / ".env"


@dataclass(frozen=True)
class Equipo:
    nombre: str
    entorno: str
    ip: str
    mac_gestion: str
    variable_lectura: str
    variable_escritura: str | None = None


INVENTARIO = {
    "EMPRESA-R1": Equipo(
        "EMPRESA-R1", "EMPRESA", "192.168.57.10",
        "0C:44:67:0D:00:00", "MIKROTIK_R1_READ_PASSWORD",
    ),
    "EMPRESA-R2": Equipo(
        "EMPRESA-R2", "EMPRESA", "192.168.57.11",
        "0C:C2:C8:CE:00:00", "MIKROTIK_R2_READ_PASSWORD",
    ),
    "EMPRESA-R3": Equipo(
        "EMPRESA-R3", "EMPRESA", "192.168.57.12",
        "0C:A3:9A:DF:00:00", "MIKROTIK_R3_READ_PASSWORD",
    ),
    "GEMELO-R1": Equipo(
        "GEMELO-R1", "GEMELO", "192.168.57.20",
        "02:47:4D:00:01:01", "GEMELO_R1_READ_PASSWORD",
        "GEMELO_R1_NETADMIN_PASSWORD",
    ),
    "GEMELO-R2": Equipo(
        "GEMELO-R2", "GEMELO", "192.168.57.21",
        "02:47:4D:00:02:01", "GEMELO_R2_READ_PASSWORD",
        "GEMELO_R2_NETADMIN_PASSWORD",
    ),
    "GEMELO-R3": Equipo(
        "GEMELO-R3", "GEMELO", "192.168.57.22",
        "02:47:4D:00:03:01", "GEMELO_R3_READ_PASSWORD",
        "GEMELO_R3_NETADMIN_PASSWORD",
    ),
}


@dataclass(frozen=True)
class Credencial:
    usuario: str
    password: str = field(repr=False)


def obtener_equipo(nombre: str) -> Equipo:
    try:
        return INVENTARIO[nombre]
    except KeyError:
        raise ValueError("Equipo fuera del inventario permitido.") from None


def cargar_credenciales() -> dict[str, str]:
    """Carga solo las variables de acceso necesarias para los routers."""
    archivo = dotenv_values(ARCHIVO_ENV, interpolate=False)
    credenciales = {}
    faltantes = []

    for equipo in INVENTARIO.values():
        variables = (
            equipo.variable_lectura,
            equipo.variable_escritura,
        )
        for variable in variables:
            if variable is None:
                continue

            valor = archivo.get(variable) or os.environ.get(variable)
            if not valor:
                faltantes.append(variable)
            else:
                credenciales[variable] = valor

    if faltantes:
        raise ValueError(
            "Faltan variables de credenciales: "
            + ", ".join(sorted(faltantes))
        )

    return credenciales


def seleccionar_credencial(
    equipo: Equipo,
    credenciales: dict[str, str],
    *,
    escritura: bool = False,
) -> Credencial:
    if escritura:
        if equipo.entorno != "GEMELO" or not equipo.variable_escritura:
            raise ValueError("La escritura solo esta permitida en GEMELO.")

        variable = equipo.variable_escritura
        usuario = "netadmin"
    else:
        variable = equipo.variable_lectura
        usuario = "mcp_ro"

    valor = credenciales.get(variable)
    if not valor:
        raise ValueError(f"Falta configurar {variable}.")

    return Credencial(usuario=usuario, password=valor)


def verificar_configuracion() -> None:
    credenciales = cargar_credenciales()
    resumen = []

    for equipo in INVENTARIO.values():
        seleccionar_credencial(equipo, credenciales)

        if equipo.entorno == "GEMELO":
            seleccionar_credencial(
                equipo, credenciales, escritura=True
            )

        resumen.append({
            "equipo": equipo.nombre,
            "ip": equipo.ip,
            "usuario_consulta": "mcp_ro",
            "escritura_permitida": equipo.entorno == "GEMELO",
        })

    print(json.dumps(resumen, indent=2, ensure_ascii=False))
    print("Configuracion local valida. No se conectaron routers.")


if __name__ == "__main__":
    try:
        verificar_configuracion()
    except ValueError as error:
        raise SystemExit(str(error)) from None