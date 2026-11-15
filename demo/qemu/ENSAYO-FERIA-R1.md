# Ensayo de Feria R1 — pendiente de ejecución

**Objetivo:** demostrar el guion completo en la estación QEMU sin depender de internet. El ensayo de aislamiento de Ubuntu y el ciclo en frío con la red disponible son evidencias separadas.

| Momento | Acción y verificación | Responsable |
|---|---|---|
| Antes del ensayo | Confirmar API, tres nodos Ready, BGP 3/3, 10/10 objetivos y HTTP 200 en frontend y API. Confirmar imágenes locales, proyector y video disponible sin internet. | R1 con R2 y R5 |
| Ensayo, 3–5 min | Desactivar Wi-Fi solo en una ventana acordada y comprobar que no haya otra salida a internet; conservar la red local del laboratorio. Ejecutar el guion acordado con R3, observar BGP y monitoreo y registrar tiempos. La falla y la segmentación requieren coordinación con R3 y R4; no improvisar cambios durante el ensayo. | R1 opera; R2, R3, R4 y R5 validan sus partes |
| Si falla CHR o la demo | No repetir arranques ni cambiar configuración para ocultar el fallo. Registrar la fase y usar el video y las capturas locales. Recuperar la conectividad del Mac al terminar o abortar. | R1 con R2 y R5 |
| Cierre | Guardar duración, resultado y evidencias sin secretos. Registrar si se completó sin internet o se usó el plan B. Completar las tres pasadas del checklist del grupo. | Todos |

**No ejecutado:** esta guía no autoriza apagar el Wi-Fi ni intervenir en las VMs. Ver [checklist de entrega](../../templates/checklist-entrega.md).
