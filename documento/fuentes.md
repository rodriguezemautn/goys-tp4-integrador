# Fuentes — apoyo interno (Irineo)

## 1. Network Digital Twin: Concepts and Reference Architecture (draft IRTF)

- **Autores:** Zhou, C. (ed.), Yang, H., Duan, X., Lopez, D., Pastor, A., Wu, Q. (ed.), Boucadair, M. (ed.), Jacquenet, C.
- **Documento:** draft-irtf-nmrg-network-digital-twin-arch-13, IRTF NMRG, 1 de julio de 2026.
- **Enlace:** https://datatracker.ietf.org/doc/draft-irtf-nmrg-network-digital-twin-arch/13/
- **Tipo:** Internet-Draft, estado informativo previsto. No es un RFC y no tiene número.
- **Respalda:** un gemelo digital de red es una representación digital de una red de datos usada para emulación, análisis y control. Sus elementos son datos (fuente de verdad), modelos, mapeo con la red real, interfaces y lógica (análisis, diagnóstico, optimización, control y emulación).

## 2. Model Context Protocol — Specification (2026-07-28)

- **Autor:** Model Context Protocol (proyecto abierto).
- **Fecha:** versión 2026-07-28.
- **Enlace:** https://modelcontextprotocol.io/specification/2026-07-28/index.md
- **Tipo:** documentación técnica oficial.
- **Respalda:** MCP conecta aplicaciones con LLM a datos y herramientas mediante mensajes JSON-RPC 2.0 entre hosts, clientes y servidores. Usa solicitudes autocontenidas, sin estado, con negociación de capacidades en cada solicitud. Los servidores ofrecen recursos, prompts y herramientas. En seguridad, exige consentimiento explícito del usuario antes de invocar herramientas, y la descripción de una herramienta es no confiable salvo que venga de un servidor de confianza. El protocolo no puede imponer estos principios por sí mismo: los implementadores deben construir flujos de consentimiento y autorización y controles de acceso.

## 3. Network Self-Configuration based on Fine-Tuned Small Language Models

- **Autores:** Lira, O. G., Caicedo, O. M., Da Fonseca, N. L. S.
- **Fecha:** diciembre de 2025. arXiv:2512.02861.
- **Enlace:** https://arxiv.org/pdf/2512.02861
- **Tipo:** paper (preprint).
- **Respalda:** framework basado en agente con un modelo de lenguaje pequeño ajustado, ejecutado en el propio equipo. Traduce requisitos en lenguaje natural a configuraciones Cisco IOS y usa un verificador que devuelve los errores para regenerar. Entrenado con unos 5.100 pares de intención y configuración.

## 4. RFC 9315 — Intent-Based Networking: Concepts and Definitions

- **Autores:** Clemm, A., Ciavaglia, L., Granville, L. Z., Tantsura, J.
- **Fecha:** octubre de 2022.
- **Enlace:** https://datatracker.ietf.org/doc/html/rfc9315
- **Tipo:** RFC del IRTF, categoría informativa.
- **Respalda:** una intención es un conjunto de objetivos operativos que la red debe cumplir, definido de forma declarativa. El cumplimiento traduce la intención en acciones y configuración. La garantía (assurance) monitorea el cumplimiento frente a una fuente única de verdad y detecta la desviación de la intención. Un lazo interno autónomo corrige la desviación y uno externo vuelve al usuario.
- **Límite:** el documento no trata la verificación de la intención antes de desplegarla. Solo menciona validar la intención refinada con el usuario.

## 5. GNS3 — API documentation (servidor 3.0.6)

- **Autor:** GNS3.
- **Fecha:** s. f. (consultado el 27/10/2026)
- **Enlace:** https://github.com/GNS3/gns3-server
- **Tipo:** documentación técnica oficial.
- **Respalda:** la API del servidor GNS3 3.0.6 está documentada en una interfaz interactiva que expone el propio servidor. Exige autenticación con usuario y contraseña, y entrega un token de acceso.

## 6. Large Language Models for Zero Touch Network Configuration Management

- **Autores:** Lira, O. G., Caicedo, O. M., da Fonseca, N. L. S.
- **Fecha:** agosto 2024.
- **Enlace:** https://arxiv.org/pdf/2408.13298
- **Tipo:** paper (preprint).
- **Respalda:** LLM-NetCFG ejecuta un modelo local (Zephyr-7B) que convierte intenciones en configuraciones, las verifica con un verificador basado en Batfish y coordina los pasos con un orquestador. Sobre 90 intenciones clasificó correctamente el 92,2%. Las intenciones complejas necesitaron varios ciclos de verificación y tardaron más de 10 minutos.
- **Límites:** los autores describen como alucinación las clasificaciones erróneas, que pueden reducir la verificación a una revisión de sintaxis. Señalan que los LLM son opacos y difíciles de explicar.

## 7. How Helpful is LLM Assistance in Network Operations? A Case Study at a Large Demonstration Network

- **Autores:** Nakamura, R., Eguchi, K. (Universidad de Tokio).
- **Fecha:** mayo 2026.
- **Enlace:** https://arxiv.org/pdf/2605.19627
- **Tipo:** paper (preprint).
- **Respalda:** el estudio se realizó entre el 31 de mayo y el 13 de junio de 2025. 105 ingenieros usaron un chatbot con GPT-4.1, recuperación de documentos, control por CLI de 69 equipos y acceso de solo lectura a tickets, en ShowNet (Interop Tokyo 2025). El 68,1% de 389 respuestas evaluadas fue positivo y el 85,1% de los comandos CLI se ejecutó sin errores de sintaxis.
- **Límites:** generó configuraciones erróneas en plataformas con CLI poco documentada, como suponer IOS XE en un equipo IOS XR. Tuvo dificultades en diagnósticos de varios pasos e inventó respuestas a preguntas sin respuesta. El estudio es de una red temporal, por lo que es difícil de reproducir.

## 8. TwiNet: Connecting Real World Networks to their Digital Twins Through a Live Bidirectional Link

- **Autores:** Robinson, C. P., Lacava, A., Johari, P., Cuomo, F., Melodia, T.
- **Fecha:** 2024, IEEE GLOBECOM 2024.
- **Enlace:** https://arxiv.org/pdf/2411.03503
- **Tipo:** paper.
- **Respalda:** mantiene sincronizado un escenario real (testbed Arena) con su gemelo digital (emulador Colosseum) mediante MQTT y un único broker, con latencia media de unos 14 ms. A diferencia de una simulación o emulación aislada, el gemelo recibe tráfico en vivo y sus evaluaciones pueden informar decisiones sobre la red real.
- **Límites:** la sincronización depende del retardo de red, que sube con el tamaño de la carga (unos 48 ms para 1 MB). Los modelos entrenados con datos del gemelo perdieron cerca de un 2,5% de precisión con datos reales.
- **Alcance:** el caso es de redes inalámbricas, no de redes IP empresariales.

## 9. OWASP Top 10 for LLM Applications 2025 — LLM06: Excessive Agency

- **Autor:** OWASP Gen AI Security Project.
- **Fecha:** edición 2025.
- **Enlace:** https://genai.owasp.org/llmrisk/llm062025-excessive-agency/
- **Tipo:** guía de seguridad.
- **Respalda:** el exceso de agencia es la vulnerabilidad que permite acciones dañinas cuando un LLM produce salidas inesperadas, ambiguas o manipuladas. Sus causas son exceso de funcionalidad, de permisos y de autonomía. Entre las medidas: ofrecer solo las herramientas necesarias y evitar herramientas generales como el acceso arbitrario a una shell, conceder acceso mínimo (por ejemplo roles de solo lectura), exigir aprobación humana en acciones de alto impacto y aplicar la autorización en los sistemas posteriores en lugar de dejarla al LLM. El registro, el monitoreo y la limitación de tasa no previenen el problema, pero ayudan a contener el daño.

## Cobertura de requisitos

- **Cantidad:** 9 referencias, sobre el mínimo de 6.
- **Paper:** fuentes 3, 6, 7 y 8.
- **Documentación técnica oficial:** fuentes 2 y 5.
- **RFC:** fuente 4 (RFC 9315).
- **Trabajos de los últimos tres años:** fuentes 1, 2, 3, 6, 7, 8 y 9.
- **Gemelo digital y diferencia con emulación:** fuentes 1 y 8.
- **Automatización y observabilidad:** fuentes 4 y 7.
- **IA y MCP:** fuentes 2, 3, 6 y 7.
- **Limitaciones (sincronización, fidelidad, errores de IA):** fuentes 4, 6, 7 y 8.
- **Seguridad:** mínimo privilegio y aprobación humana, fuentes 2 y 9. Protección de credenciales, fuente 2. Registro de operaciones, fuente 9.
- **Aislamiento entre entornos:** lo aporta el diseño del proyecto (lectura en EMPRESA, cambios y pruebas en GEMELO) y se presenta como propuesta del grupo, no como resultado de la literatura.