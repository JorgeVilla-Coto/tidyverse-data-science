# Contador de evidencia del agente Weekly Insights.
# Uso:
#   Rscript scripts/weekly-insights-ledger.R          # imprime el contador y el resumen
#   Rscript scripts/weekly-insights-ledger.R --n      # imprime solo el número (para el pie del correo)
# Especificación del agente: agents/weekly-insights/AGENT.md

library(tidyverse)

ruta_ledger <- "agents/weekly-insights/evidencia/ledger.csv"

ledger <- read_csv(ruta_ledger, col_types = cols(.default = col_character())) %>%
  mutate(fecha_ejecucion = ymd_hms(fecha_ejecucion, quiet = TRUE))

contador <- ledger %>% filter(estado == "entregado") %>% nrow()

if ("--n" %in% commandArgs(trailingOnly = TRUE)) {
  cat(contador, "\n", sep = "")
  quit(save = "no")
}

cat("Reportes entregados a la bandeja de entrada:", contador, "\n\n")

if (nrow(ledger) == 0) {
  cat("El ledger está vacío: el agente todavía no ha corrido.\n")
  quit(save = "no")
}

# Tasa de entrega: de cada corrida, ¿cuántas terminaron en reporte y cuántas en parada?
ledger %>%
  count(estado, motivo_parada) %>%
  arrange(desc(n)) %>%
  print(n = Inf)

cat("\nÚltimas corridas:\n")
ledger %>%
  arrange(desc(fecha_ejecucion)) %>%
  select(semana_iso, estado, hallazgos, fuentes_caidas) %>%
  head(8) %>%
  print(n = Inf)

# La métrica de éxito es que esta serie crezca una unidad por semana.
cat("\nEntregas acumuladas por semana:\n")
ledger %>%
  filter(estado == "entregado") %>%
  arrange(fecha_ejecucion) %>%
  mutate(acumulado = row_number()) %>%
  select(semana_iso, acumulado) %>%
  print(n = Inf)
