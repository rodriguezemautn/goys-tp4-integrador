# Guía de Demostración en Vivo — Plataforma Integrada NOC/SOC (GOYS TP4)

> **Feria de Redes 2026** · Gestión Operativa y Seguridad en Redes
> Esta guía explica paso a paso cómo levantar el laboratorio, cómo disponer las pantallas y cómo defender la demo frente a los profesores y jurados.

---

## 1. ¿Qué demuestra este proyecto?

Este laboratorio demuestra la convergencia entre **NOC** (monitoreo de infraestructura y disponibilidad), **SOC** (detección de intrusiones en tiempo real) y **Automatización de Respuesta** (SecOps con LLM de apoyo y reglas en kernel):

1. **Monitoreo Continuo:** El portal web corporativo opera con métricas estables (NOC en verde).
2. **Detección en Tiempo Real:** El sensor IDS (**Suricata 8.0**) inspecciona el tráfico de red del bridge virtual y detecta intentos de ataque web (inyección SQL, escaneo automatizado o path traversal).
3. **Análisis Contextual con LLM:** Un script en Python toma el evento estructurado de Suricata, consulta la **API de Groq** (`qwen/qwen3.8-27b`), clasifica la gravedad técnica y emite una sentencia estructurada (`BLOCK`) con justificación técnica.
4. **Respuesta Activa:** El agente aplica reglas `DROP` inmediatas en el firewall del kernel (`iptables FORWARD` y `DOCKER-USER`).
5. **Aislamiento Comprobado:** El atacante queda bloqueado (0 bps / Timeout), mientras que los clientes legítimos continúan navegando el sitio web normalmente con código HTTP 200 OK.
6. **Observabilidad:** El panel de **Grafana** y **Prometheus** refleja el incidente y la contención en tiempo real.

---

## 2. Puesta en Marcha Inicial (Setup en 2 Minutos)

### Paso 1: Configurar la API Key de Groq
Dentro del directorio `lab/`, asegurarse de que exista el archivo `.env`:
```bash
cd /home/gns3/goys-tp4-integrador/lab
cat .env
```
Debe contener:
```ini
GROQ_API_KEY=tu_api_key_de_groq_aqui
GROQ_MODEL=qwen/qwen3.8-27b
```
*(Si no hay internet en la feria, el agente tiene un modo de contingencia local que seguirá funcionando automáticamente sin internet).*

### Paso 2: Levantar los Contenedores
```bash
# Habilitar filtrado de iptables sobre bridges virtuales Linux (requerido para L2->L3)
sudo modprobe br_netfilter
sudo sysctl -w net.bridge.bridge-nf-call-iptables=1

docker compose up -d
```

### Paso 3: Verificar que todos los servicios estén en estado "Up"
```bash
docker compose ps
```
Deben aparecer 6 contenedores activos:
- `web_target`: Servidor Nginx víctima (`172.28.0.10:8080`)
- `soc_suricata`: Sensor IDS en modo sniffer sobre `br-monitored`
- `aiops_agent`: Agente de remediación y telemetría (`:8000`)
- `noc_prometheus`: Scraper de métricas (`:9090`)
- `noc_grafana`: Panel de observabilidad (`:3000`)
- `demo_attacker`: Contenedor atacante de pruebas (`172.28.0.99`)

---

## 3. Disposición de Pantalla para la Feria (Setup Visual)

Para lograr el **máximo impacto visual** en la estación de la feria, armen 3 ventanas visibles en la pantalla de la laptop o monitor:

```
┌─────────────────────────────────┬─────────────────────────────────┐
│ VENTANA 1: Script de Demo       │ VENTANA 2: Logs del Agente IA   │
│ ./demo/simular_ataque.sh        │ docker logs -f aiops_agent      │
│ (Menú interactivo con colores)  │ (Muestra a Groq razonando)      │
├─────────────────────────────────┼─────────────────────────────────┤
│ VENTANA 3: Dashboard Grafana    │ VENTANA 4: Web de la Víctima    │
│ http://<IP_VM>:3000             │ http://<IP_VM>:8080             │
│ (Métricas e incidentes NOC)     │ (Portal corporativo 200 OK)     │
└─────────────────────────────────┴─────────────────────────────────┘
```

> **Nota sobre las URLs:**  
> Si estás accediendo desde el navegador de tu computadora anfitriona (Windows/Mac) a través de la VM, reemplazá `localhost` por la IP de la VM (por ejemplo `http://192.168.133.130:3000`).

---

## 4. Guion de la Demo Frente a los Profesores

Cuando se acerque el docente o visitante al stand, sigan estos pasos:

### Acto 1: La Línea Base (Todo en verde)
- **Qué decir:** *"Acá vemos el portal corporativo funcionando normalmente y el panel de Grafana en verde sin alertas."*
- **Qué hacer:** En la **Ventana 1**, elegí la **Opción 1** (Enviar tráfico legítimo). Verán peticiones con **HTTP 200 OK**.

### Acto 2: Inyección del Ataque
- **Qué decir:** *"Ahora simulamos que un atacante externo lanza una inyección SQL compleja buscando extraer credenciales de usuarios."*
- **Qué hacer:** En la **Ventana 1**, elegí la **Opción 2** (Simular Ataque SQL Injection).

### Acto 3: El Razonamiento Agéntico (AIOps)
- **Qué decir:** *"Suricata detecta la firma al instante y le pasa el paquete al agente. El modelo de IA analiza el payload, dictamina que es una amenaza crítica y ordena el bloqueo en firewall."*
- **Qué señalar:** En la **Ventana 2 (Logs)**, mostrale al docente:
  - La firma detectada: `ALERTA SOC - Intento de SQL Injection (UNION SELECT)`
  - El dictamen: `BLOCK | Severidad: HIGH`
  - La latencia: `~700ms - 1800ms`
  - La **Justificación técnica** redactada por el LLM.

### Acto 4: Verificación del Aislamiento y Resiliencia
- **Qué decir:** *"El firewall aisló la IP agresora. El atacante ahora experimenta timeout total, pero miren el servidor víctima: sigue respondiendo en verde para todos los demás."*
- **Qué mostrar:**
  - En la **Ventana 1**, el script confirmará: `ÉXITO TOTAL: IP del atacante BLOQUEADA en firewall (Drop/Timeout)`.
  - En la **Ventana 3 (Grafana)**, el contador de **IPs Neutralizadas** sube a `1` y el gráfico marca el incidente.
  - En la **Ventana 4**, refrescá el portal web (`:8080`): responde instantáneamente con **HTTP 200 OK**.

### Acto 5: Reset para el Siguiente Profesor
- **Qué hacer:** En la **Ventana 1**, elegí la **Opción 7** (Resetear Reglas de Firewall).
- **Qué hace:** Limpia las reglas de `iptables` y vacía la telemetría del agente en 1 segundo, dejando todo listo para repetir la demo con otra persona.

---

## 5. Menú de Ataques Disponibles en el Script

Al ejecutar `./demo/simular_ataque.sh`, podés probar diferentes vectores:

| Opción | Tipo de Prueba | Descripción |
| :---: | :--- | :--- |
| **`1`** | **Tráfico Legítimo** | Peticiones HTTP normales para mostrar la línea base saludable. |
| **`2`** | **Inyección SQL (SQLi)** | Payload `UNION SELECT null,username,password FROM users`. (Demo principal). |
| **`3`** | **Escáner Automatizado** | Ataque con User-Agent sospechoso (`sqlmap/1.8.2`). |
| **`4`** | **Path Traversal (LFI)** | Intento de lectura no autorizada de `/etc/passwd`. |
| **`5`** | **Telemetría en Vivo** | Consulta el endpoint JSON del agente (`:8000/status`). |
| **`6`** | **Demo Completa Automática** | Ejecuta Tráfico Legítimo ➔ Ataque SQLi ➔ Verificación de bloqueo de un solo tirón. |
| **`7`** | **Resetear Firewall** | Desbloquea todas las IPs y resetea las métricas para reiniciar la demo. |

---

## 6. Preguntas Frecuentes y Contingencias

### ¿Qué pasa si el día de la feria se corta el WiFi del stand?
**No hay que preocuparse:** El agente tiene programado un **modo de resiliencia heurística local**. Si la llamada a la nube de Groq falla, el agente evalúa la firma de Suricata en 0.5 ms de forma local y bloquea la IP igualmente. La demo **nunca se va a caer en vivo**.

### ¿Cómo verifico manualmente qué IPs están bloqueadas en el firewall?
```bash
sudo iptables -L FORWARD -n -v
sudo iptables -L DOCKER-USER -n -v
```
Verás la regla `-s 172.28.0.99 -j DROP` con el contador de paquetes descartados subiendo.

### ¿Cómo reseteo todo manualmente si cerré el script?
```bash
sudo iptables -F FORWARD && sudo iptables -F DOCKER-USER && sudo iptables -A DOCKER-USER -j RETURN
curl -s http://127.0.0.1:8000/reset
```

### Credenciales de Acceso:
- **Grafana:** `http://<IP_VM>:3000` (Usuario: `admin` | Password: `admin`)
- **Portal Víctima:** `http://<IP_VM>:8080`
- **Telemetría Agente:** `http://<IP_VM>:8000/status`
- **Prometheus:** `http://<IP_VM>:9090`
