-- ============================================================
-- NOTE:
-- 1) Esegui questo file DOPO aver creato lo schema/tabelle e caricato i dati.
-- 2) Dopo la creazione degli indici, è consigliato lanciare ANALYZE.
-- 3) Gli indici qui sotto sono pensati per PostgreSQL (B-Tree di default).
-- ============================================================

BEGIN;

-- ------------------------------------------------------------
-- A) Operazione 11: "Dato un modello di dieta, visualizzare i piani dieta associati"
-- Filtro tipico: WHERE nome_dieta = ? AND versione_dieta = ?
-- ------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_piano_dieta_modello
ON public.piano_dieta (nome_dieta, versione_dieta);

-- ------------------------------------------------------------
-- B) Operazione 14: "Piani dieta passati di un paziente"
-- Filtro tipico: WHERE cf_paziente = ? AND data_fine IS NOT NULL
-- Spesso con ORDER BY data_fine DESC
-- Indice PARZIALE: contiene solo i record "passati"
-- ------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_piano_passati_paziente_datafine
ON public.piano_dieta (cf_paziente, data_fine DESC)
WHERE data_fine IS NOT NULL;

-- ------------------------------------------------------------
-- C) Operazione 13: "Dato un nutrizionista, mostrare i suoi dati e il numero di piani redatti"
-- Conteggio su REDAZIONE filtrando cf_nutrizionista
-- ------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_redazione_nutrizionista
ON public.redazione (cf_nutrizionista);

-- ------------------------------------------------------------
-- D) Operazione 19: "Dato un risultato test, visualizzare su quali report esso deriva"
-- Filtro tipico: WHERE codice_test = ?
-- NOTA: la PK di DERIVAZIONE (cf_medico, numero_report, codice_test) non è ideale
--       per ricerche "per codice_test" (perché codice_test è l'ultimo attributo).
-- ------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_derivazione_codice_test
ON public.derivazione (codice_test);

-- Opzionale "coprente": riduce i lookup durante join verso REPORT
-- (Toglilo se vuoi mantenere gli indici al minimo assoluto)
CREATE INDEX IF NOT EXISTS idx_derivazione_codice_test_cover
ON public.derivazione (codice_test, cf_medico, numero_report);

-- ------------------------------------------------------------
-- E) Operazioni paziente ↔ test: "visualizzare test di un paziente"
-- Filtro tipico: WHERE cf_paziente = ?
-- ------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_test_cf_paziente
ON public.risultato_test_genetico (cf_paziente);

-- ------------------------------------------------------------
-- G) Look-up su relazioni di gestione paziente
-- Query tipiche: "pazienti di un medico" / "pazienti di un nutrizionista"
-- (Volumi non enormi, ma indici naturali e utili per filtri/join)
-- ------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_paziente_cf_medico
ON public.paziente (cf_medico);

CREATE INDEX IF NOT EXISTS idx_paziente_cf_nutrizionista
ON public.paziente (cf_nutrizionista);

COMMIT;

-- Aggiorna le statistiche per aiutare l'optimizer a scegliere Index Scan dove conviene
ANALYZE;

-- ============================================================
-- Fine file indici
-- ============================================================
