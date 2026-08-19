# Weekly Insights — agente de vigilancia semanal

Agente que cada **viernes a las 8:00 am (hora Costa Rica)** investiga el estado del arte en
**shopper, consumidor, marcas y tendencias**, y entrega un resumen consolidado a
`jvc.villa@gmail.com`. Si las fuentes están caídas o la semana no trae nada nuevo, **se
detiene y avisa** en vez de rellenar.

| Componente | Dónde vive |
|---|---|
| **Objetivo** — qué resultado | `AGENT.md` §1 |
| **Contexto** — qué debe saber | `AGENT.md` §2 + `fuentes.yml` |
| **Decisión** — qué elige | `AGENT.md` §3 (criterio 3-de-5, condiciones de parada) |
| **Acción** — qué ejecuta | `AGENT.md` §4 + `PROMPT.md` (el prompt que corre) |
| **Evidencia** — cómo se revisa | `evidencia/ledger.csv` + `../../scripts/weekly-insights-ledger.R` |

## Archivos

```
agents/weekly-insights/
├── AGENT.md                 # especificación: los cinco componentes
├── PROMPT.md                # prompt exacto que dispara la Routine cada viernes
├── fuentes.yml              # universo de fuentes por capa y eje temático
├── plantilla-reporte.md     # formato del entregable
└── evidencia/
    ├── ledger.csv           # una fila por corrida — de aquí sale el contador
    └── reportes/            # archivo histórico de reportes entregados
scripts/weekly-insights-ledger.R   # calcula el contador de reportes entregados
```

## Cómo está programado

Corre como **Routine** de Claude Code (sesión nueva en cada disparo, sin memoria previa; por
eso `PROMPT.md` es autocontenido).

- Routine: `trig_01KDJTTCPvHNSMF9jZVKHnSe` — "Weekly Insights — shopper, consumidor, marcas, tendencias"
- Cron: `0 14 * * 5` en UTC = **viernes 08:00 America/Costa_Rica** (UTC-6).
- Entrega: correo directo vía Gmail, no borrador.
- Cada corrida hace commit del reporte y de la fila del ledger en la rama
  `claude/weekly-insights-agent-lj1mei`.

### ⚠️ Paso manual pendiente: conector de Gmail

La Routine se creó **sin el conector de Gmail** porque la organización no permite adjuntar
conectores a un trigger por API. Sin ese conector, la sesión del viernes investiga y escribe
el reporte pero **no puede enviarlo**: el PASO 4(c) del prompt la manda a dejar el reporte en
el repo y registrar `estado=detenido, motivo_parada=sin_acceso_correo`.

Para habilitarlo: **claude.ai → Routines → "Weekly Insights" → habilitar el conector Gmail**.

Cómo saber si quedó: después del primer viernes, revisar el ledger. Si la fila dice
`sin_acceso_correo`, el conector sigue sin estar.

## Cómo verificar que funciona

```bash
Rscript scripts/weekly-insights-ledger.R        # contador + tasa de entrega + acumulado
Rscript scripts/weekly-insights-ledger.R --n    # solo el número
```

La métrica de éxito es simple: **el contador sube una unidad por semana**. Un `estado =
detenido` en el ledger no es una falla del agente — es el agente haciendo lo que se le pidió.
La falla es una semana sin fila ninguna: eso significa que la Routine no disparó.

## Cómo modificar el agente

1. **Cambiar fuentes** → editar `fuentes.yml`. El prompt las lee del repo en cada corrida,
   pero también lleva una copia embebida: si agregás una capa nueva, actualizá ambas.
2. **Cambiar criterio de relevancia, umbral de parada o formato** → editar `AGENT.md` y
   `PROMPT.md`, y luego actualizar la Routine con el nuevo texto del prompt
   (`update_trigger` con el bloque `text` de `PROMPT.md`).
3. **Cambiar el horario** → `update_trigger` con otro cron, recordando que se guarda en UTC.
4. **Pausar** → deshabilitar la Routine (`enabled: false`); el histórico se conserva.

## Resultado de la corrida de prueba (19-ago-2026)

Se ejecutó el procedimiento completo sobre la ventana 12–19 ago 2026. Hallazgos operativos:

- **WebSearch funciona** y alcanza la web abierta: devolvió material fechado dentro de la
  ventana en los cuatro ejes.
- **WebFetch está denegado por la política de egreso del entorno** para *todos* los dominios
  externos probados (22/22: journals, casas de investigación, prensa, incluso census.gov).
  Devuelve 403/407 del proxy, no error de la fuente.
- Por eso se ajustó la sección 3b de `AGENT.md`: **bloqueo de política ≠ fuente caída**. Si
  contara como caída, el agente se detendría todas las semanas por infraestructura y nunca
  entregaría. Ahora el hallazgo sobrevive marcado `[vía buscador]` con la confianza bajada un
  nivel, y se agregó el motivo de parada `busqueda_sin_resultados` para cuando falle el canal
  que sí importa.
- El reporte de esa corrida está en `evidencia/reportes/PRUEBA-2026-W34.md`. **No se registró
  en el ledger**: fue un ensayo, y el contador solo debe contar entregas reales.

Para recuperar la verificación en fuente primaria hay que pedir que la política de egreso del
entorno permita los dominios de `fuentes.yml`. Sin eso el agente sigue siendo útil, pero
ningún hallazgo puede quedar en confianza `alta`.

## Límite conocido

La sesión que dispara cada viernes clona la rama por defecto del repo. Mientras esta rama no
esté en `master`, el PASO 0 del prompt hace `git fetch` + `checkout` de
`claude/weekly-insights-agent-lj1mei` para leer la especificación y escribir la evidencia.
Al fusionar a `master`, ese paso se puede simplificar.
