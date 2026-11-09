#!/bin/bash
# ==============================================================================
# Script de Demostración en Vivo para la Feria de Redes (UTN FRLP GOYS)
# Simulación de Tráfico Legítimo, Ataques Web y Verificación de Remediación
# ==============================================================================

# Colores de salida
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

VICTIM_URL="http://172.28.0.10"
HOST_URL="http://localhost:8080"
ATTACKER_CONTAINER="demo_attacker"

# Función para verificar si el contenedor atacante está activo
check_attacker_container() {
    if docker ps --format '{{.Names}}' | grep -q "^${ATTACKER_CONTAINER}$"; then
        return 0
    else
        return 1
    fi
}

# Ejecutar comando HTTP desde el contenedor atacante (IP 172.28.0.99) o desde host
exec_curl() {
    local endpoint="$1"
    local extra_args="$2"
    if check_attacker_container; then
        docker exec -t "$ATTACKER_CONTAINER" curl -s -m 3 $extra_args "${VICTIM_URL}${endpoint}"
    else
        curl -s -m 3 $extra_args "${HOST_URL}${endpoint}"
    fi
}

exec_curl_status() {
    local endpoint="$1"
    local extra_args="$2"
    if check_attacker_container; then
        docker exec -t "$ATTACKER_CONTAINER" curl -s -m 3 -o /dev/null -w "%{http_code}" $extra_args "${VICTIM_URL}${endpoint}"
    else
        curl -s -m 3 -o /dev/null -w "%{http_code}" $extra_args "${HOST_URL}${endpoint}"
    fi
}

banner() {
    clear
    echo -e "${CYAN}======================================================================${NC}"
    echo -e "${CYAN}        DEMO INTERACTIVA: SOC/NOC AUTÓNOMO CON GROQ LLM           ${NC}"
    echo -e "${CYAN}              Feria de Redes — UTN FRLP (GOYS TP4)                   ${NC}"
    echo -e "${CYAN}======================================================================${NC}"
    echo ""
}

test_legitimate() {
    echo -e "${BLUE}▶ [1/3] Enviando tráfico legítimo al servidor web...${NC}"
    for i in {1..5}; do
        STATUS=$(exec_curl_status "/")
        if [ "$STATUS" == "200" ]; then
            echo -e "  Petición $i: ${GREEN}HTTP 200 OK${NC} (Servicio saludable)"
        else
            echo -e "  Petición $i: ${RED}HTTP $STATUS (Degradado o bloqueado)${NC}"
        fi
        sleep 0.5
    done
    echo ""
}

test_sqli() {
    echo -e "${YELLOW}▶ [2/3] Inyectando Vector Malicioso: Inyección SQL (SQLi)...${NC}"
    echo -e "  Payload: ${CYAN}/?id=1%20UNION%20SELECT%20null,username,password%20FROM%20users${NC}"
    
    exec_curl "/?id=1%20UNION%20SELECT%20null,username,password%20FROM%20users" > /dev/null 2>&1
    echo -e "  ${YELLOW}⚠️  Ataque enviado al sensor Suricata IDS.${NC}"
    echo -e "  Esperando análisis del Agente Groq LLM y aplicación de regla iptables..."
    sleep 2

    echo ""
    echo -e "${BLUE}▶ [3/3] Verificando estado del atacante (Remediación Activa)...${NC}"
    STATUS=$(exec_curl_status "/")
    if [ "$STATUS" == "200" ]; then
        echo -e "  ${RED}❌ FALLO DE MITIGACIÓN: El atacante todavía puede acceder al servidor.${NC}"
    else
        echo -e "  ${GREEN}✅ ÉXITO TOTAL: IP del atacante BLOQUEADA en firewall (Drop/Timeout).${NC}"
    fi
    echo ""
}

test_recon() {
    echo -e "${YELLOW}▶ [Ataque Reconocimiento] Escáner automatizado con User-Agent sospechoso (sqlmap)...${NC}"
    exec_curl "/" "-A 'sqlmap/1.8.2#stable'" > /dev/null 2>&1
    echo -e "  Ataque enviado con User-Agent 'sqlmap'. Esperando remediación..."
    sleep 2

    STATUS=$(exec_curl_status "/")
    if [ "$STATUS" == "200" ]; then
        echo -e "  ${RED}❌ FALLO: No se bloqueó el escáner.${NC}"
    else
        echo -e "  ${GREEN}✅ ÉXITO: Escáner neutralizado y bloqueado en firewall.${NC}"
    fi
    echo ""
}

test_path_traversal() {
    echo -e "${YELLOW}▶ [Ataque LFI] Intento de acceso a archivo del sistema (/etc/passwd)...${NC}"
    exec_curl "/admin/view?file=/etc/passwd" > /dev/null 2>&1
    echo -e "  Payload enviado. Esperando dictamen de la IA..."
    sleep 2

    STATUS=$(exec_curl_status "/")
    if [ "$STATUS" == "200" ]; then
        echo -e "  ${RED}❌ FALLO: No se bloqueó el path traversal.${NC}"
    else
        echo -e "  ${GREEN}✅ ÉXITO: Atacante bloqueado por intento de acceso indebido.${NC}"
    fi
    echo ""
}

check_telemetry() {
    echo -e "${CYAN}▶ Consultando Telemetría del Agente AIOps (http://localhost:8000/status)...${NC}"
    if curl -s -m 2 http://localhost:8000/status > /dev/null; then
        curl -s http://localhost:8000/status
    else
        echo -e "${RED}El agente no tiene el servidor de telemetría activo en el puerto 8000.${NC}"
    fi
    echo ""
}

reset_firewall() {
    echo -e "${YELLOW}▶ Reseteando reglas de filtrado en FORWARD y DOCKER-USER...${NC}"
    sudo iptables -F FORWARD 2>/dev/null
    sudo iptables -F DOCKER-USER 2>/dev/null
    sudo iptables -A DOCKER-USER -j RETURN 2>/dev/null
    curl -s http://localhost:8000/reset > /dev/null 2>&1
    echo -e "${GREEN}✅ Firewall y telemetría reseteados. Todas las IPs pueden acceder nuevamente.${NC}"
    echo ""
}

# Menú interactivo
while true; do
    banner
    echo "Seleccione una opción para la demo:"
    echo "  1) Enviar tráfico legítimo (Línea base NOC)"
    echo "  2) Simular Ataque SQL Injection (Demo Principal para la Feria)"
    echo "  3) Simular Escáner Automatizado (User-Agent sqlmap)"
    echo "  4) Simular Path Traversal (/etc/passwd)"
    echo "  5) Ver Telemetría e Incidentes en vivo (API Agente)"
    echo "  6) Ejecutar Demo Completa Automatizada (1 -> 2 -> Verificación)"
    echo "  7) Resetear Reglas de Firewall (Desbloquear IPs)"
    echo "  0) Salir"
    echo ""
    read -p "Opción [0-7]: " opcion

    case $opcion in
        1)
            test_legitimate
            read -p "Presione ENTER para continuar..."
            ;;
        2)
            test_sqli
            read -p "Presione ENTER para continuar..."
            ;;
        3)
            test_recon
            read -p "Presione ENTER para continuar..."
            ;;
        4)
            test_path_traversal
            read -p "Presione ENTER para continuar..."
            ;;
        5)
            check_telemetry
            read -p "Presione ENTER para continuar..."
            ;;
        6)
            test_legitimate
            sleep 1
            test_sqli
            sleep 1
            check_telemetry
            read -p "Presione ENTER para continuar..."
            ;;
        7)
            reset_firewall
            read -p "Presione ENTER para continuar..."
            ;;
        0)
            echo "Saliendo de la demo."
            exit 0
            ;;
        *)
            echo -e "${RED}Opción inválida.${NC}"
            sleep 1
            ;;
    esac
done
