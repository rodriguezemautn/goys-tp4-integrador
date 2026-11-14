# H3 Tablero: acceso de monitoreo de solo lectura para Prometheus (mktxp).
# Se aplica en EDGE, CORE-1, CORE-2, DIST-1 y DIST-2, entrando con admin.
# Antes de aplicarlo: /export file=pre-H3
# <CLAVE_MONITOREO_H3> esta en la base .kdbx: se reemplaza en la consola, nunca en este archivo.
# En common-name va el nombre del router (EDGE, CORE-1, CORE-2, DIST-1 o DIST-2).

# Grupo con permisos minimos: leer y usar la API
/user group add name=monitoreo policy=read,api comment="H3: solo lectura para Prometheus"

# Usuario de monitoreo, que solo puede entrar desde la estacion
/user add name=prometheus group=monitoreo address=10.20.0.101/32 password="<CLAVE_MONITOREO_H3>" comment="H3: mktxp"

# Certificado para la API-SSL, firmado por una CA local del router.
# RouterOS 7.21 no autofirma un certificado tls-server ("failure: CA not found"): primero se firma la CA.
# Esperar la marca K en los dos (/certificate print) antes de seguir.
/certificate add name=ca-local common-name=CA-EDGE days-valid=3650 key-usage=key-cert-sign,crl-sign
/certificate sign ca-local
/certificate add name=api-ssl common-name=EDGE days-valid=3650 key-usage=digital-signature,key-encipherment,tls-server
/certificate sign api-ssl ca=ca-local

# API-SSL solo para la estacion; la API sin cifrar (api) sigue apagada
/ip service set api-ssl certificate=api-ssl address=10.20.0.101/32 disabled=no

# Solo en el EDGE: aceptar la API-SSL de la estacion antes de la regla final de input
/ip firewall filter add chain=input protocol=tcp dst-port=8729 src-address=10.20.0.101 action=accept \
    comment="input: API-SSL de monitoreo solo desde la estacion" \
    place-before=[find comment="input: todo lo demas"]
