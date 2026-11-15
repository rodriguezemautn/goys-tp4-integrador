# Public reference only. Copy privately, remove the guard and set the BGP key before validation.
:error "Public reference only: do not import"

# R1-only RouterOS configuration. Import only after the generated dry-run passes.
# This file intentionally owns no IP, firewall, NAT, identity, or service settings.

:if ([:len [/routing/bgp/instance find where name="tp4-r1"]] > 0) do={:error "R1 BGP instance already exists; stop and reconcile manually"}
:if ([:len [/routing/bgp/connection find where name="tp4-r1-server"]] > 0) do={:error "R1 server peer already exists; stop and reconcile manually"}
:if ([:len [/routing/bgp/connection find where name="tp4-r1-agent1"]] > 0) do={:error "R1 agent1 peer already exists; stop and reconcile manually"}
:if ([:len [/routing/bgp/connection find where name="tp4-r1-agent2"]] > 0) do={:error "R1 agent2 peer already exists; stop and reconcile manually"}
:if ([:len [/routing/filter/rule find where chain="tp4-r1-in"]] > 0) do={:error "R1 input filter chain already exists; stop and reconcile manually"}
:if ([:len [/routing/filter/rule find where chain="tp4-r1-out"]] > 0) do={:error "R1 output filter chain already exists; stop and reconcile manually"}
:if ([:len [/routing/filter/rule find where comment="tp4-r1-in-allow"]] > 0) do={:error "R1 input filter rule already exists; stop and reconcile manually"}
:if ([:len [/routing/filter/rule find where comment="tp4-r1-out-reject"]] > 0) do={:error "R1 output filter rule already exists; stop and reconcile manually"}

/routing/bgp/instance
add name=tp4-r1 as=65000 router-id=10.10.10.1

/routing/filter/rule
add chain=tp4-r1-in comment="tp4-r1-in-allow" rule="if (dst in 10.10.20.0/28 && dst-len==32) { accept } else { reject }"
add chain=tp4-r1-out comment="tp4-r1-out-reject" rule="reject"

/routing/bgp/connection
add name=tp4-r1-server instance=tp4-r1 remote.address=10.10.10.11 remote.as=64512 local.address=10.10.10.1 local.role=ebgp hold-time=9s keepalive-time=3s input.filter=tp4-r1-in output.filter-chain=tp4-r1-out tcp-md5-key="CAMBIAR-CLAVE-BGP"
add name=tp4-r1-agent1 instance=tp4-r1 remote.address=10.10.10.12 remote.as=64512 local.address=10.10.10.1 local.role=ebgp hold-time=9s keepalive-time=3s input.filter=tp4-r1-in output.filter-chain=tp4-r1-out tcp-md5-key="CAMBIAR-CLAVE-BGP"
add name=tp4-r1-agent2 instance=tp4-r1 remote.address=10.10.10.13 remote.as=64512 local.address=10.10.10.1 local.role=ebgp hold-time=9s keepalive-time=3s input.filter=tp4-r1-in output.filter-chain=tp4-r1-out tcp-md5-key="CAMBIAR-CLAVE-BGP"
