import os
import json
import time
import subprocess
import threading
import re
from http.server import ThreadingHTTPServer, BaseHTTPRequestHandler

# Intentar importar el SDK oficial de Groq
try:
    from groq import Groq
    GROQ_AVAILABLE = True
except ImportError:
    GROQ_AVAILABLE = False

LOG_FILE = os.getenv("LOG_FILE", "/var/log/suricata/eve.json")
GROQ_API_KEY = os.getenv("GROQ_API_KEY", "").strip()
GROQ_MODEL = os.getenv("GROQ_MODEL", "qwen/qwen3.8-27b")
VICTIM_IP = os.getenv("VICTIM_IP", "172.28.0.10")

# IPs protegidas que NUNCA deben ser bloqueadas bajo ninguna circunstancia
WHITELIST_IPS = {
    "127.0.0.1",
    "localhost",
    "172.28.0.1",   # Gateway del bridge Docker
    "172.28.0.10",  # IP del servidor víctima
    "172.28.0.20",  # IP de Prometheus
    "172.28.0.30",  # IP de Grafana
    "8.8.8.8",
    "1.1.1.1"
}

BLOCKED_IPS = set()
INCIDENT_HISTORY = []

# Cliente Groq si hay API Key disponible
groq_client = None
if GROQ_API_KEY and GROQ_AVAILABLE:
    try:
        groq_client = Groq(api_key=GROQ_API_KEY)
        print(f"[SecOps Agent] Cliente Groq inicializado con modelo '{GROQ_MODEL}'.")
    except Exception as e:
        print(f"[SecOps Agent] Error inicializando cliente Groq: {e}")
else:
    print("[SecOps Agent] AVISO: GROQ_API_KEY no detectada. Operando en modo de contingencia heurística local.")

def query_groq_decision(event):
    """
    Envía el evento de Suricata a Groq para análisis agéntico en tiempo real.
    Devuelve un diccionario con {decision, severity, confidence, reason}.
    """
    if not groq_client:
        return fallback_heuristic(event)

    alert_data = event.get("alert", {})
    http_data = event.get("http", {})
    
    prompt = (
        f"Analyze this IDS security event:\n"
        f"- Source IP: {event.get('src_ip')}:{event.get('src_port')}\n"
        f"- Target IP: {event.get('dest_ip')}:{event.get('dest_port')}\n"
        f"- Signature: {alert_data.get('signature', 'N/A')}\n"
        f"- Category: {alert_data.get('category', 'N/A')}\n"
        f"- Severity: {alert_data.get('severity', 'N/A')}\n"
        f"- HTTP URL: {http_data.get('url', 'N/A')}\n"
        f"- HTTP Method: {http_data.get('http_method', 'N/A')}\n"
        f"- User-Agent: {http_data.get('http_user_agent', 'N/A')}\n"
    )
    
    try:
        start_time = time.time()
        completion = groq_client.chat.completions.create(
            model=GROQ_MODEL,
            messages=[
                {
                    "role": "system",
                    "content": (
                        "You are an automated SecOps AI agent. Analyze the IDS event and output ONLY a raw json object "
                        "with keys: decision (BLOCK or ALLOW), severity (CRITICAL, HIGH, MEDIUM, LOW), "
                        "confidence (float), reason (technical spanish explanation in 1 sentence). No markdown."
                    )
                },
                {"role": "user", "content": prompt}
            ],
            temperature=0.0,
            max_tokens=300
        )
        latency = (time.time() - start_time) * 1000
        raw_response = completion.choices[0].message.content.strip()
        print(f"[SecOps Agent Groq Raw] {raw_response}")
        match = re.search(r'\{.*\}', raw_response, re.DOTALL)
        if match:
            analysis = json.loads(match.group(0))
        else:
            analysis = json.loads(raw_response)

        analysis["latency_ms"] = round(latency, 1)
        analysis["model"] = GROQ_MODEL
        return analysis
    except Exception as e:
        print(f"[SecOps Agent] Error consultando Groq API ({e}). Usando contingencia local.")
        return fallback_heuristic(event)

def fallback_heuristic(event):
    """Modo de resiliencia local en caso de desconexión de red o contingencia."""
    alert_msg = event.get("alert", {}).get("signature", "").lower()
    severity = event.get("alert", {}).get("severity", 3)
    
    is_malicious = (
        severity <= 2 or 
        "sqli" in alert_msg or 
        "injection" in alert_msg or 
        "escaneo" in alert_msg or 
        "ráfaga" in alert_msg or
        "traversal" in alert_msg
    )
    
    return {
        "decision": "BLOCK" if is_malicious else "ALLOW",
        "severity": "HIGH" if is_malicious else "LOW",
        "confidence": 0.85,
        "reason": f"Regla heurística de contingencia activada por firma '{alert_msg}'",
        "latency_ms": 0.5,
        "model": "local-fallback"
    }

def ban_ip(ip, reason="Comportamiento anómalo detectado"):
    """Ejecuta el aislamiento de la IP a nivel de firewall del kernel usando FORWARD y DOCKER-USER."""
    if ip in BLOCKED_IPS:
        return False
    if ip in WHITELIST_IPS:
        print(f"[SecOps Agent] IP {ip} está en la lista blanca de infraestructura. No se bloquea.")
        return False

    print(f"\n[REMEDIACIÓN ACTIVA] Neutralizando amenaza. Bloqueando IP: {ip}")
    cmd_forward = f"iptables -I FORWARD 1 -s {ip} -j DROP"
    cmd_docker = f"iptables -I DOCKER-USER 1 -s {ip} -j DROP"
    try:
        subprocess.run(cmd_forward, shell=True, check=True)
        subprocess.run(cmd_docker, shell=True, stderr=subprocess.DEVNULL)
        BLOCKED_IPS.add(ip)
        print(f"[REMEDIACIÓN ACTIVA] IP {ip} aislada con éxito en FORWARD y DOCKER-USER.")
        return True
    except subprocess.CalledProcessError as e:
        print(f"[ERROR FIREWALL] No se pudo ejecutar iptables: {e}")
        return False

def follow_eve(filepath):
    """Monitorea el archivo eve.json de Suricata de forma continua (estilo tail -F)."""
    while not os.path.exists(filepath):
        print(f"[SecOps Agent] Esperando creación de {filepath}...")
        time.sleep(1)
    
    print(f"[SecOps Agent] Conectado a {filepath}. Escuchando flujo de eventos...")
    with open(filepath, "r") as f:
        f.seek(0, os.SEEK_END)
        while True:
            line = f.readline()
            if not line:
                time.sleep(0.2)
                continue
            yield line

# Servidor HTTP interno de telemetría para NOC / Grafana
class TelemetryHandler(BaseHTTPRequestHandler):
    def address_string(self):
        # Desactivar resolución DNS reversa para evitar retardos o bloqueos
        return str(self.client_address[0])

    def do_GET(self):
        if self.path == "/status" or self.path == "/":
            data = {
                "status": "online",
                "blocked_ips_count": len(BLOCKED_IPS),
                "blocked_ips": list(BLOCKED_IPS),
                "incidents_count": len(INCIDENT_HISTORY),
                "recent_incidents": INCIDENT_HISTORY[-10:]
            }
            body = json.dumps(data, indent=2).encode("utf-8")
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(body)))
            self.send_header("Connection", "close")
            self.send_header("Access-Control-Allow-Origin", "*")
            self.end_headers()
            self.wfile.write(body)
        elif self.path == "/reset":
            for ip in list(BLOCKED_IPS):
                subprocess.run(f"iptables -D FORWARD -s {ip} -j DROP", shell=True, stderr=subprocess.DEVNULL)
                subprocess.run(f"iptables -D DOCKER-USER -s {ip} -j DROP", shell=True, stderr=subprocess.DEVNULL)
            BLOCKED_IPS.clear()
            body = b'{"status": "reset_successful"}'
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(body)))
            self.send_header("Connection", "close")
            self.end_headers()
            self.wfile.write(body)
        elif self.path == "/metrics":
            # Formato Prometheus para consumo del NOC
            output = [
                "# HELP agent_blocked_ips_total Total de direcciones IP bloqueadas",
                "# TYPE agent_blocked_ips_total gauge",
                f"agent_blocked_ips_total {len(BLOCKED_IPS)}",
                "# HELP agent_incidents_total Total de incidentes procesados",
                "# TYPE agent_incidents_total counter",
                f"agent_incidents_total {len(INCIDENT_HISTORY)}"
            ]
            body = ("\n".join(output) + "\n").encode("utf-8")
            self.send_response(200)
            self.send_header("Content-Type", "text/plain; version=0.0.4")
            self.send_header("Content-Length", str(len(body)))
            self.send_header("Connection", "close")
            self.end_headers()
            self.wfile.write(body)
        else:
            body = b"Not Found"
            self.send_response(404)
            self.send_header("Content-Type", "text/plain")
            self.send_header("Content-Length", str(len(body)))
            self.send_header("Connection", "close")
            self.end_headers()
            self.wfile.write(body)

    def log_message(self, format, *args):
        pass # Silenciar logs HTTP estándar

def start_telemetry_server(port=8000):
    server = ThreadingHTTPServer(("0.0.0.0", port), TelemetryHandler)
    server.serve_forever()

def main():
    print("=" * 70)
    print(" SOC/NOC AUTÓNOMO — AGENTE DE REMEDIACIÓN AIOps (GOYS TP4)")
    print(f" LLM en uso: {GROQ_MODEL} (Groq API)")
    print(f" Telemetría expuesta en http://localhost:8000/status y /metrics")
    print("=" * 70)

    # Iniciar servidor de métricas NOC en segundo plano
    t = threading.Thread(target=start_telemetry_server, daemon=True)
    t.start()

    for line in follow_eve(LOG_FILE):
        try:
            event = json.loads(line)
            if event.get("event_type") == "alert":
                src_ip = event.get("src_ip")
                signature = event.get("alert", {}).get("signature", "Sin firma")
                
                print("\n" + "-" * 70)
                print(f"[ALERTA SOC] Detectada firma: '{signature}' | Origen: {src_ip}")
                
                # Análisis mediante Groq LLM
                print("[AIOps] Consultando modelo para análisis contextual...")
                analysis = query_groq_decision(event)
                decision = str(analysis.get("decision", "ALLOW")).upper()
                severity = analysis.get("severity", "MEDIUM")
                reason = analysis.get("reason", "Sin razón")
                latency = analysis.get("latency_ms", 0)

                print(f"[DICTAMEN LLM] Decisión: {decision} | Severidad: {severity} | Latencia: {latency}ms")
                print(f"[JUSTIFICACIÓN] {reason}")

                incident_record = {
                    "timestamp": time.strftime("%Y-%m-%d %H:%M:%S"),
                    "src_ip": src_ip,
                    "signature": signature,
                    "decision": decision,
                    "severity": severity,
                    "reason": reason,
                    "latency_ms": latency
                }
                INCIDENT_HISTORY.append(incident_record)

                if decision == "BLOCK":
                    ban_ip(src_ip, reason=reason)
                else:
                    print(f"[AIOps] Tráfico catalogado como no crítico. No se bloquea.")

        except json.JSONDecodeError:
            continue
        except Exception as e:
            print(f"[SecOps Agent] Error procesando evento: {e}")

if __name__ == "__main__":
    main()
