-- ============================================================
-- QUERY DIMOSTRATIVE BIOFITLAB
-- (SQL standard: SELECT, JOIN, GROUP BY, HAVING)
-- ============================================================


-- ============================================================
-- QUERY SULLA VISTA 1: view_storico_report_paziente
-- ============================================================

-- Q1) Tutti i report di un paziente (storico clinico)
-- Caso d’uso: il medico o il paziente vuole vedere tutti i report
SELECT
    cf_paziente,
    cognome_paziente,
    data_report,
    medico_redattore,
    codice_test_usato,
    esito_medico
FROM view_storico_report_paziente
WHERE cf_paziente = 'CF_PAZIENTE';


-- Q2) Numero di report per ogni paziente
-- Caso d’uso: capire quali pazienti sono seguiti più frequentemente
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

-- Q3) Tutti i pazienti seguiti da uno specifico medico
-- Caso d’uso: il medico visualizza i propri pazienti
SELECT
    cf_paziente,
    nome_paziente,
    cognome_paziente,
    nome_medico,
    cognome_medico,
    nome_nutrizionista,
    cognome_nutrizionista
FROM view_pazienti_associati
WHERE cognome_medico = 'ROSSI';


-- Q4) Numero di pazienti per ogni medico
-- Caso d’uso: analisi del carico di lavoro dei medici
SELECT
    cognome_medico,
    COUNT(*) AS numero_pazienti
FROM view_pazienti_associati
GROUP BY cognome_medico;



-- ============================================================
-- QUERY SULLA VISTA 3: view_dettaglio_geni_test
-- ============================================================

-- Q5) Tutti i geni analizzati in un test genetico
-- Caso d’uso: referto genetico per un paziente
SELECT
    codice_test,
    nome_gene,
    funzione_biologica,
    nota_specifica_test
FROM view_dettaglio_geni_test
WHERE codice_test = 'CODICE_TEST';


-- Q6) Numero di geni analizzati per ciascun test
-- Caso d’uso: verifica completezza dei test genetici
SELECT
    codice_test,
    COUNT(nome_gene) AS numero_geni
FROM view_dettaglio_geni_test
GROUP BY codice_test;



-- ============================================================
-- QUERY SULLA VISTA 4: view_piano_nutrizionale_totale
-- ============================================================

-- Q7) Piano nutrizionale attivo di un paziente
-- Caso d’uso: nutrizionista o paziente visualizza il piano
SELECT
    cf_paziente,
    nome_piano,
    nome_dieta,
    totale_kcal,
    totale_proteine,
    totale_carboidrati,
    totale_grassi
FROM view_piano_nutrizionale_totale
WHERE cf_paziente = 'CF_PAZIENTE';


-- Q8) Piani nutrizionali con più di 2000 kcal
-- Caso d’uso: individuare piani ad alto apporto calorico
SELECT
    cf_paziente,
    nome_piano,
    totale_kcal
FROM view_piano_nutrizionale_totale
WHERE totale_kcal > 2000;



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


-- Q10) Numero di alimenti presenti in ciascun piano dieta
-- Caso d’uso: capire la complessità dei piani
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
SELECT
    p1.cf_paziente,
    p1.nome AS piano1,
    p2.nome AS piano2
FROM piano_dieta p1
JOIN piano_dieta p2
  ON p1.cf_paziente = p2.cf_paziente
 AND p1.nome <> p2.nome
WHERE p1.data_fine IS NULL
  AND p2.data_fine IS NULL;
