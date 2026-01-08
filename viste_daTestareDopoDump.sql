-- ============================================================
-- 0) IMPLEMENTAZIONE DELLE VISTE 
-- ============================================================


/*Vista 1

Cosa fa: questa vista fa vedere per ogni paziente tutti i report medici scritti per lui 
(catena di join: medico (chi ha scritto) -> derivazione -> test -> paziente)
*/
CREATE VIEW view_storico_report_paziente AS
SELECT 
    p.cf AS cf_paziente,
    p.cognome AS cognome_paziente,
    r.data AS data_report,
    r.numero AS numero_report,
    m.cognome AS medico_redattore,
    t.codice AS codice_test_usato,
    t.data_esecuzione AS data_test,
    r.valutazione AS esito_medico
FROM report r
JOIN medico m ON r.cf_medico = m.cf
JOIN derivazione der ON der.cf_medico = r.cf_medico AND der.numero_report = r.numero
JOIN risultato_test_genetico t ON t.codice = der.codice_test
JOIN paziente p ON t.cf_paziente = p.cf;


/*Vista 2
Cosa fa: Mostra tutti i pazienti a cui sono stati assegnati sia un medico che un nutrizionista
*/
CREATE VIEW view_pazienti_associati AS
SELECT 
    -- Dati Paziente
    p.cf AS cf_paziente,
    p.nome AS nome_paziente,
    p.cognome AS cognome_paziente,
    -- Dati Medico
    m.nome AS nome_medico,
    m.cognome AS cognome_medico,
    m.email AS email_medico,
    p.data_inizio_medico, -- data inizio associazione medico-paziente 
    -- Dati Nutrizionista
    n.nome As nome_nutrizionista,
    n.cognome AS cognome_nutrizionista,
    n.email AS email_nutrizionista,
    p.data_inizio_nutrizionista -- data inizio associazione nutrizionista-paziente (cioè quando il nutrizionista ha preso in carico il paziente)
FROM paziente p
JOIN medico m ON p.cf_medico = m.cf          
JOIN nutrizionista n ON p.cf_nutrizionista = n.cf;


/*Vista 3
Cosa fa: L'idea è quella di dare al paziente il resoconto del test genetico in cui vengono mostrati i geni analizzati
*/
CREATE VIEW view_dettaglio_geni_test AS
SELECT 
    t.codice AS codice_test,
    p.cognome AS cognome_paziente,
    a.nome_gene,
    g.funzione_biologica,
    nt.descrizione AS nota_specifica_test
FROM risultato_test_genetico t
JOIN paziente p ON t.cf_paziente = p.cf
JOIN analisi a ON a.codice_test = t.codice
JOIN gene g ON a.codice_dna = g.codice_dna 
            AND a.nome_gene = g.nome 
            AND a.num_prog_gene = g.num_progressivo
JOIN nota_test nt ON nt.codice_test = t.codice; --Se si vogliono mostrare anche i test senza note --> left join



/*Vista 4
Cosa fa: Questa vista fornisce un riepilogo nutrizionale totale per ogni piano dieta attivo di ogni paziente,
mostrando le quantità totali di calorie, proteine, carboidrati e grassi derivanti dagli alimenti inclusi nel piano.
*/

CREATE VIEW view_piano_nutrizionale_totale AS
SELECT
    p.cf AS cf_paziente,
    p.nome AS nome_paziente,
    p.cognome AS cognome_paziente,
    pd.nome AS nome_piano,
    d.nome AS nome_dieta,
    d.tipo AS tipo_dieta,
    -- Calcolo dei Macros Totali per il piano
    --NB: Se SUM restituisce NULL (cioè non ci sono alimenti associati al piano) --> COALESCE lo trasforma in 0
    COALESCE(SUM((c.qta * a.kcal) / 100.0), 0) AS totale_kcal,
    COALESCE(SUM((c.qta * a.proteine) / 100.0), 0) AS totale_proteine,
    COALESCE(SUM((c.qta * a.carboidrati) / 100.0), 0) AS totale_carboidrati,
    COALESCE(SUM((c.qta * a.grassi) / 100.0), 0) AS totale_grassi,
    COUNT(c.codice_alimento) AS numero_alimenti
FROM piano_dieta pd
JOIN paziente p ON p.cf = pd.cf_paziente
JOIN dieta d ON d.nome = pd.nome_dieta AND d.versione = pd.versione_dieta --la PK di dieta è (nome, versione)
JOIN composizione c ON c.cf_paziente = pd.cf_paziente AND c.nome_piano = pd.nome --la PK di composizione è (cf_paziente, nome_piano, codice_alimento)
JOIN alimento a ON a.codice = c.codice_alimento
WHERE pd.data_fine IS NULL --SOLO PIANO ATTIVO
GROUP BY p.cf, p.nome, p.cognome, pd.nome, d.nome, d.tipo;


