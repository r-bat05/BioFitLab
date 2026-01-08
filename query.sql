-- ============================================================
-- QUERY DIMOSTRATIVE BIOFITLAB (parametriche con GUC custom)
-- Modifica SOLO i SET qui sotto
-- ============================================================


-- Definiamo delle variabili così basta modificare queste per influenzare le selezioni nelle query senza modificarle una a una
SET myvars.cf_paziente   = 'PZ00000000000001';
SET myvars.cf_medico     = 'MD0000000000001';   -- metti il tuo CF medico
SET myvars.cognome_medico = 'Rossi';
SET myvars.codice_test   = 'T01';
SET myvars.kcal_soglia   = '2000';              -- come stringa va bene, castiamo nelle query

-- ============================================================
-- QUERY SULLA VISTA 1: view_storico_report_paziente
-- ============================================================

-- Q1) Tutti i report di un paziente (storico clinico)
SELECT
    cf_paziente,
    cognome_paziente,
    data_report,
    medico_redattore,
    codice_test_usato,
    esito_medico
FROM view_storico_report_paziente
WHERE cf_paziente = current_setting('myvars.cf_paziente');

-- Q2) Numero di report per ogni paziente
SELECT
    cf_paziente,
    cognome_paziente,
    COUNT(*) AS numero_report
FROM view_storico_report_paziente
GROUP BY cf_paziente, cognome_paziente
HAVING COUNT(*) >= 1;


-- ============================================================
-- QUERY SULLA VISTA 2: view_pazienti_associati
-- ============================================================

-- Q3) Tutti i pazienti seguiti da uno specifico medico (per cognome)
SELECT
    cf_paziente,
    nome_paziente,
    cognome_paziente,
    nome_medico,
    cognome_medico,
    nome_nutrizionista,
    cognome_nutrizionista
FROM view_pazienti_associati
WHERE cognome_medico = current_setting('myvars.cognome_medico');

-- Variante migliore (se nella vista esiste cf_medico):
-- WHERE cf_medico = current_setting('myvars.cf_medico');

-- Q4) Numero di pazienti per ogni medico
SELECT
    cognome_medico,
    COUNT(*) AS numero_pazienti
FROM view_pazienti_associati
GROUP BY cognome_medico;


-- ============================================================
-- QUERY SULLA VISTA 3: view_dettaglio_geni_test
-- ============================================================

-- Q5) Tutti i geni analizzati in un test genetico
SELECT
    codice_test,
    nome_gene,
    funzione_biologica,
    nota_specifica_test
FROM view_dettaglio_geni_test
WHERE codice_test = current_setting('myvars.codice_test');

-- Q6) Numero di geni analizzati per ciascun test
SELECT
    codice_test,
    COUNT(nome_gene) AS numero_geni
FROM view_dettaglio_geni_test
GROUP BY codice_test;


-- ============================================================
-- QUERY SULLA VISTA 4: view_piano_nutrizionale_totale
-- ============================================================

-- Q7) Piano nutrizionale attivo di un paziente
SELECT
    cf_paziente,
    nome_piano,
    nome_dieta,
    totale_kcal,
    totale_proteine,
    totale_carboidrati,
    totale_grassi
FROM view_piano_nutrizionale_totale
WHERE cf_paziente = current_setting('myvars.cf_paziente');

-- Q8) Piani nutrizionali con più di una soglia kcal (parametrica)
SELECT
    cf_paziente,
    nome_piano,
    totale_kcal
FROM view_piano_nutrizionale_totale
WHERE totale_kcal > current_setting('myvars.kcal_soglia')::numeric;


-- ============================================================
-- QUERY NORMALI (SENZA VISTE)
-- ============================================================

-- Q9) Tutti i pazienti che hanno almeno un piano dieta attivo
SELECT DISTINCT
    p.cf,
    p.nome,
    p.cognome
FROM paziente p
JOIN piano_dieta pd ON pd.cf_paziente = p.cf
WHERE pd.data_fine IS NULL;

-- Variante parametrica (solo un paziente):
-- WHERE p.cf = current_setting('myvars.cf_paziente') AND pd.data_fine IS NULL;

-- Q10) Numero di alimenti presenti in ciascun piano dieta
SELECT
    cf_paziente,
    nome_piano,
    COUNT(codice_alimento) AS numero_alimenti
FROM composizione
GROUP BY cf_paziente, nome_piano;


-- ============================================================
-- QUERY DI VERIFICA DEI VINCOLI (DIMOSTRATIVE)
-- ============================================================

-- Q11) Verifica che non esistano piani dieta sovrapposti
-- Se il trigger funziona, questa query NON deve restituire righe
-- (versione robusta: controlla sovrapposizione di intervalli, non solo data_fine NULL)
SELECT
    p1.cf_paziente,
    p1.nome AS piano1,
    p2.nome AS piano2
FROM piano_dieta p1
JOIN piano_dieta p2
  ON p1.cf_paziente = p2.cf_paziente
 AND p1.nome <> p2.nome
WHERE daterange(p1.data_inizio, COALESCE(p1.data_fine, 'infinity'::date), '[]')
   && daterange(p2.data_inizio, COALESCE(p2.data_fine, 'infinity'::date), '[]');

-- Variante filtrata su un solo paziente:
-- AND p1.cf_paziente = current_setting('myvars.cf_paziente');
