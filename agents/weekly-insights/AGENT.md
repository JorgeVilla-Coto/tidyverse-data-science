# Agente: Weekly Insights (shopper · consumidor · marcas · tendencias)

Especificación del agente según los cinco componentes: **Objetivo → Contexto → Decisión → Acción → Evidencia**.
Si falta uno, el agente se cae. Este documento es la fuente de verdad; el prompt operativo vive en `PROMPT.md`.

---

## 1. Objetivo — qué resultado

Cada viernes a las 8:00 am (hora Costa Rica, UTC-6) recibir en la bandeja de entrada
(`jvc.villa@gmail.com`) **un resumen consolidado del estado del arte** en shopper,
consumidor, marcas y tendencias, construido a partir de repositorios en línea, artículos
de investigación y bases de datos web.

Resultado esperado, en una frase: *mantenerme actualizado sin invertir horas en búsquedas
manuales*.

No es objetivo del agente: hacer un clipping de noticias, resumir prensa de negocios
genérica, ni producir un boletín largo. El entregable es corto, jerarquizado y accionable.

**Ventana de cobertura:** los 7 días previos a la ejecución (viernes anterior 8:00 am →
viernes actual 8:00 am).

---

## 2. Contexto — qué debe saber

### Quién lo lee
Un profesional de investigación de mercados y consultoría en Centroamérica / LatAm. Lee en
español, tolera anglicismos del oficio (shopper, path to purchase, brand equity), y le
sirve el dato solo si viene con la implicación para el negocio o para el diseño de estudios.

### Universo de fuentes
Definido en `fuentes.yml`, agrupado en cuatro capas:

1. **Académica** — journals y repositorios peer-reviewed (Journal of Marketing, JMR, JCR,
   Journal of Retailing, JRCS, SSRN, NBER, Marketing Science Institute).
2. **Industria** — casas de investigación y consultoras (Kantar, NIQ, Circana, Ipsos, GfK,
   Euromonitor, McKinsey, Bain, BCG, Deloitte, PwC, EY, Accenture, WARC, Think with Google).
3. **Prensa especializada** — Retail Dive, Marketing Dive, Ad Age, Campaign, Marketing Week,
   Path to Purchase / Store Brands.
4. **Datos duros y contexto regional** — World Bank, CEPAL, INEC Costa Rica, bancos centrales,
   cámaras de comercio y retail de la región.

### Qué debe saber sobre el histórico
Antes de investigar, el agente lee `evidencia/ledger.csv` y los últimos reportes en
`evidencia/reportes/` para **no repetir hallazgos ya entregados**. Un estudio ya reportado
solo reaparece si hay desarrollo nuevo y material.

### Restricciones
- Nada de paywall pirateado: si la fuente es de pago, se reporta el abstract público y se
  marca `[paywall]`.
- Todo hallazgo lleva enlace verificable. Sin enlace, no entra.
- Sin cifras inventadas. Si el dato no se pudo verificar en la fuente, se omite o se marca
  `[no verificado]`.

---

## 3. Decisión — qué elige

El agente decide tres cosas, con reglas explícitas:

### a) Qué entra al reporte (criterio de relevancia)
Un hallazgo entra si cumple **≥ 3 de 5**:
| Criterio | Umbral |
|---|---|
| Novedad | Publicado dentro de la ventana de 7 días |
| Rigor | Peer-reviewed, muestra declarada, o metodología pública |
| Aplicabilidad | Cambia una decisión de marca, shopper o diseño de estudio |
| Relevancia regional | Aplica a LatAm/CAM o es generalizable a estos mercados |
| No redundancia | No fue reportado en las últimas 8 semanas |

Máximo **7 hallazgos** por reporte, ordenados por impacto. Mejor 4 sólidos que 12 tibios.

### b) Cuándo NO entrega (condición de parada)
El agente **se detiene y avisa** —no fabrica un reporte de relleno— si:
- **Fuentes caídas:** ≥ 40% de las fuentes prioritarias no responden o devuelven error.
- **Semana seca:** menos de 3 hallazgos superan el criterio de relevancia.
- **Sin acceso a Gmail:** no puede entregar; deja el reporte en el repo y avisa por el canal
  disponible.

#### Fuente caída ≠ dominio bloqueado por política
Verificado en la corrida de prueba del 19-ago-2026: el proxy de egreso del entorno deniega
por política (403/407) **todos** los dominios externos vía WebFetch, mientras que WebSearch
sí alcanza la web abierta. Si esa denegación contara como "fuente caída", el agente se
detendría todas las semanas por una razón de infraestructura, no de contenido.

Por eso la distinción es parte de la decisión:
| Situación | Cómo se trata |
|---|---|
| Bloqueo de egreso (403/407/EGRESS_BLOCKED) al abrir la fuente | **No** es fuente caída. El hallazgo se conserva, se marca `[vía buscador]` y **baja un nivel de confianza** (alta→media, media→exploratoria). |
| La fuente responde pero con error, timeout o vacía | Sí cuenta como fuente caída. |
| WebSearch no devuelve resultados utilizables en ≥40% de las combinaciones eje × capa | Parada por `busqueda_sin_resultados` — el canal efectivo se cayó. |

Un reporte construido **solo** con buscador es válido, pero debe decirlo en el encabezado y
ningún hallazgo puede quedar en confianza `alta`.

En parada envía un **aviso corto** (asunto `[Weekly Insights] Sin entrega — <motivo>`) que
dice qué falló, qué fuentes revisó y cuándo reintenta. El aviso **no** cuenta como reporte
entregado en el contador.

### c) Cómo clasifica
Cada hallazgo se etiqueta en exactamente un eje: `shopper` · `consumidor` · `marcas` ·
`tendencias`, y con un nivel de confianza `alta` / `media` / `exploratoria`.

---

## 4. Acción — qué ejecuta

Secuencia por corrida (detalle operativo en `PROMPT.md`):

1. **Preparar** — leer `fuentes.yml` y el histórico del `ledger.csv`; fijar la ventana de fechas.
2. **Barrer** — búsqueda por capa de fuente y por eje temático (4 ejes × 4 capas), registrando
   qué fuente respondió, cuál falló y cuál quedó bloqueada por política de egreso.
3. **Verificar** — abrir la fuente primaria de cada candidato; confirmar fecha, autoría y cifras.
   Si el dominio está bloqueado, verificar hasta donde llegue el buscador y marcar `[vía buscador]`.
4. **Filtrar** — aplicar el criterio de relevancia y la deduplicación contra las últimas 8 semanas.
5. **Decidir entrega o parada** — evaluar las condiciones de parada.
6. **Redactar** — armar el reporte con la plantilla `plantilla-reporte.md`.
7. **Entregar** — enviar el correo a `jvc.villa@gmail.com` (asunto
   `[Weekly Insights] Semana <ISO> — <titular>`).
8. **Registrar** — guardar el reporte en `evidencia/reportes/AAAA-Www.md`, agregar la fila al
   `ledger.csv` y hacer commit/push.

---

## 5. Evidencia — cómo se revisa

**Métrica de éxito declarada:** el contador de reportes semanales entregados en la bandeja
de entrada aumenta.

Ese contador se materializa en `evidencia/ledger.csv`, una fila por corrida:

| Columna | Significado |
|---|---|
| `fecha_ejecucion` | Timestamp UTC de la corrida |
| `semana_iso` | Semana ISO cubierta (ej. `2026-W34`) |
| `estado` | `entregado` \| `detenido` \| `prueba` |
| `motivo_parada` | Vacío si `entregado`; si no: `fuentes_caidas` \| `semana_seca` \| `sin_acceso_correo` \| `busqueda_sin_resultados` |
| `fuentes_consultadas` | Cantidad de fuentes efectivamente consultadas |
| `fuentes_caidas` | Cantidad que no respondió |
| `hallazgos` | Hallazgos incluidos en el reporte |
| `asunto` | Asunto exacto del correo enviado |
| `ruta_reporte` | Ruta del reporte archivado |
| `notas` | Observaciones de la corrida |

`prueba` es para corridas manuales de validación: quedan registradas como evidencia de que el
circuito funciona, pero **no cuentan** para el contador.

**Contador:** `nrow(filter(ledger, estado == "entregado"))`. Se calcula con
`scripts/weekly-insights-ledger.R` (tidyverse, consistente con el resto del repo) y se
imprime en el pie de cada correo — así el contador viaja dentro de la evidencia misma.

**Revisión mensual sugerida:** de los hallazgos entregados en el mes, ¿cuántos derivaron en
una acción concreta (propuesta, hipótesis de estudio, ajuste de cuestionario)? Si la
respuesta es cero dos meses seguidos, el criterio de relevancia está mal calibrado y hay que
ajustar la sección 3a — no la frecuencia de entrega.
