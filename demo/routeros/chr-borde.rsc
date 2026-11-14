# chr-borde.rsc - router de borde del laboratorio TP4 (RouterOS v7)
# Antes de importar: reemplazar CAMBIAR-CLAVE-BGP en una copia temporal, nunca en este archivo.
# La IP fija y el borrado del cliente DHCP van al final porque cortan la sesion SSH del import.

/system identity set name=chr-borde

/ip address
add address=10.10.10.1/24 interface=ether2 comment="cluster"

# --- BGP: del cluster solo se aceptan /32 del pool de servicios y no se anuncia nada ---
/routing filter rule
add chain=k3s-in rule="if (dst in 10.10.20.0/28 && dst-len == 32) { accept }"
add chain=k3s-in rule="reject"
add chain=k3s-out rule="reject"

/routing bgp connection
add name=k3s-server as=65000 router-id=10.10.10.1 local.role=ebgp local.address=10.10.10.1 \
    remote.address=10.10.10.11 remote.as=64512 hold-time=9s keepalive-time=3s \
    tcp-md5-key="CAMBIAR-CLAVE-BGP" input.filter=k3s-in output.filter-chain=k3s-out
add name=k3s-agent1 as=65000 router-id=10.10.10.1 local.role=ebgp local.address=10.10.10.1 \
    remote.address=10.10.10.12 remote.as=64512 hold-time=9s keepalive-time=3s \
    tcp-md5-key="CAMBIAR-CLAVE-BGP" input.filter=k3s-in output.filter-chain=k3s-out
add name=k3s-agent2 as=65000 router-id=10.10.10.1 local.role=ebgp local.address=10.10.10.1 \
    remote.address=10.10.10.13 remote.as=64512 hold-time=9s keepalive-time=3s \
    tcp-md5-key="CAMBIAR-CLAVE-BGP" input.filter=k3s-in output.filter-chain=k3s-out

# --- Firewall ---
/ip firewall filter
add chain=input connection-state=established,related action=accept comment="sesiones ya abiertas"
add chain=input connection-state=invalid action=drop
add chain=input in-interface=ether2 src-address=10.10.10.0/24 protocol=tcp dst-port=179 action=accept comment="BGP desde el cluster"
add chain=input in-interface=ether1 src-address=192.168.56.1 protocol=tcp dst-port=22,8291 action=accept comment="SSH y Winbox desde la laptop"
add chain=input in-interface=ether2 src-address=10.10.10.11 protocol=tcp dst-port=22 action=accept comment="SSH del usuario backup desde el nodo de control"
add chain=input action=drop comment="resto"
add chain=forward connection-state=established,related action=accept comment="sesiones ya abiertas"
add chain=forward connection-state=invalid action=drop
add chain=forward in-interface=ether1 dst-address=10.10.20.0/28 protocol=tcp dst-port=80 action=accept comment="HTTP a los servicios"
add chain=forward in-interface=ether1 src-address=192.168.56.1 dst-address=10.10.10.11 protocol=tcp dst-port=30300 action=accept comment="Grafana desde la laptop"
add chain=forward in-interface=ether1 src-address=192.168.56.1 protocol=icmp action=accept comment="ping desde la laptop"
add chain=forward action=drop comment="resto"

# --- Servicios cerrados ---
/ip service
set telnet disabled=yes
set ftp disabled=yes
set www disabled=yes
set api disabled=yes
set api-ssl disabled=yes

/ip neighbor discovery-settings set discover-interface-list=none
/tool mac-server set allowed-interface-list=none
/tool mac-server mac-winbox set allowed-interface-list=none

# --- Ultimo: IP fija hacia la laptop. Aca se corta la sesion SSH y es lo esperado ---
/ip address add address=192.168.56.2/24 interface=ether1 comment="clientes"
/ip dhcp-client remove [find interface=ether1]
