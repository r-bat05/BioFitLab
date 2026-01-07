-- ============================================================
-- 0) IMPLEMENTAZIONE DEI VINCOLI, PROCEDURE E TRIGGER 
-- ============================================================





-- ============================================================
-- IMPLEMENTAZIONE DEI VINCOLI SCRITTI NEL LATEX 
-- ============================================================

--vincolo 1
ALTER TABLE abilitazione 
DROP CONSTRAINT IF EXISTS chk_abilitazione_livello; --NB: in Postegres IF NOT EXiSTS con constraint non funziona

ALTER TABLE abilitazione
ADD CONSTRAINT chk_abilitazione_livello 
CHECK (livello BETWEEN 1 AND 5);


--vincolo 2
ALTER TABLE medico 
ADD COLUMN citta_locazione_studioMedico VARCHAR(50) NOT NULL;

ALTER TABLE paziente 
ADD COLUMN citta_residenza VARCHAR(50) NOT NULL;


--FUNZIONE CHE SARA' RICHIAMATA DAL TRIGGER
--sintassi Postegres per creare un trigger che richiama una funzione PL/pgSQL
CREATE OR REPLACE FUNCTION fn_check_citta_medico_paziente() -- funzione PL/pgSQL che implementa il trigger
RETURNS TRIGGER AS $$
DECLARE
    var_cittaMedico VARCHAR(50); -- Variabile per salvare la città del medico relativo al paziente
BEGIN

	--controllo sui dati
	--se cf_medico = NULL --> il dato non va bene
    IF NEW.cf_medico IS NULL THEN
        RETURN NEW; --se il medico non c'è, non ha senso fare il controllo sulla città
    END IF;

    SELECT citta_locazione_studioMedico INTO var_cittaMedico
    FROM medico
    WHERE medico.cf = NEW.cf_medico;

	IF var_cittaMedico IS NULL THEN
		RAISE EXCEPTION 'ERRORE: Il codice fiscale del medico cercato non esiste nel database.';
	END IF;

    --nota: UPPER e TRIM servono per evitare problemi dovuti a spazi vuoti o differenze tra maiuscole e minuscole
    IF UPPER(TRIM(var_cittaMedico)) <> UPPER(TRIM(NEW.citta_residenza)) THEN
        RAISE EXCEPTION 'ERRORE: incongruenza tra la residenza del paziente e la locazione dello studio del medico';
    END IF;

    RETURN NEW; --se tutto ok, restituisco il nuovo record
END;
$$ LANGUAGE plpgsql; --indica che la funzione è scritta in PL/pgSQL (sintassi specifica di Postegres)

--TIGGER FINALE
DROP TRIGGER IF EXISTS trg_check_paziente ON paziente;

CREATE TRIGGER trg_check_paziente
BEFORE INSERT OR UPDATE ON paziente
FOR EACH ROW --row level trigger
EXECUTE FUNCTION fn_check_citta_medico_paziente();

/*Se cambia la citta del medico, il medico deve essere cancellato e reinserito. Quando il medico viene cancellato, 
vale il vincolo di integrità referenziale che mette a NULL le chiavi esterne dei pazienti associati a quel medico.*/


--vincolo 3
ALTER TABLE composizione 
DROP CONSTRAINT IF EXISTS chk_qta_max4;

ALTER TABLE composizione
ADD CONSTRAINT chk_qta_max4
	CHECK(qta BETWEEN 1 AND 4);




--vincolo 4: due controlli (su INSERT/UPDATE su DERIVAZIONE e su UPDATE di REPORT)


--controllo sull'inserimento nella tabella DERIVAZIONE
CREATE OR REPLACE FUNCTION trg_derivazione_report_finestra_test_fn()
RETURNS trigger AS $$
DECLARE
	d_report date;
	d_esec   date;
	d_scad   date;
BEGIN
	--Acquisisco le date necessarie per il controllo tramite una query (mi serve la data del report)
	SELECT r.data INTO d_report
	FROM report r
	WHERE r.cf_medico = NEW.cf_medico 
	AND r.numero = NEW.numero_report;

	-- Acquisisco le date di esecuzione e scadenza del test genetico associato alla derivazione 
	SELECT t.data_esecuzione, t.scadenza INTO d_esec, d_scad
	FROM risultato_test_genetico t
	WHERE t.codice = NEW.codice_test;

	-- 3. Controlli di esistenza
	IF d_report IS NULL THEN
		RAISE EXCEPTION 'Report % (Medico %) inesistente o senza data', NEW.numero_report, NEW.cf_medico;
	END IF;

	IF d_esec IS NULL OR d_scad IS NULL THEN
		RAISE EXCEPTION 'Test % inesistente o senza date', NEW.codice_test;
	END IF;

	-- 4. Verifica del Vincolo: il Report deve essere compreso tra data esecuzione e scadenza del testq
	IF d_report < d_esec OR d_report > d_scad THEN
		RAISE EXCEPTION
		'Vincolo 4 violato: Il Report del % è fuori dalla validità del test (Test valido dal % al %)',
		d_report, d_esec, d_scad;
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- TRIGGER SU DERIVAZIONE
DROP TRIGGER IF EXISTS trg_derivazione_report_finestra_test ON derivazione;

CREATE TRIGGER trg_derivazione_report_finestra_test
BEFORE INSERT OR UPDATE ON derivazione
FOR EACH ROW 
EXECUTE FUNCTION trg_derivazione_report_finestra_test_fn();



/*tuttavia, se viene fatto un UPDATE su report bisogna ricontrollare la consistenza dei dati*/
CREATE OR REPLACE FUNCTION function_report_data_check_all_tests()
RETURNS trigger AS $$
DECLARE
  	num_test_invalidi int;
BEGIN
	-- Conto quanti test collegati diventerebbero invalidi con la NUOVA data
	SELECT COUNT(*)
	INTO num_test_invalidi
	FROM derivazione d
	JOIN risultato_test_genetico t ON t.codice = d.codice_test
	WHERE d.cf_medico = NEW.cf_medico 
		AND d.numero_report = NEW.numero
		-- Qui è quando il test è invalido: data report fuori dall'intervallo del test
		AND (NEW.data < t.data_esecuzione OR NEW.data > t.scadenza);

	IF num_test_invalidi > 0 THEN
		RAISE EXCEPTION
		'Vincolo 4 violato: La nuova data report % rende invalidi % collegamenti con i test genetici (Report %)',
		NEW.data, num_test_invalidi, NEW.numero;
	END IF;

	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- TRIGGER SU REPORT
DROP TRIGGER IF EXISTS trg_report_data_check_all_tests ON report;

CREATE TRIGGER trg_report_data_check_all_tests
BEFORE UPDATE ON report 
FOR EACH ROW 
EXECUTE FUNCTION function_report_data_check_all_tests();






--vincolo 5

CREATE OR REPLACE FUNCTION trg_redazione_finestra_test_fn()
RETURNS trigger AS $$
DECLARE
	d_esec date;
	d_scad date;
BEGIN
	--tramite una query ottengo le date di esecuzione e scadenza del test genetico associato alla redazione
	SELECT t.data_esecuzione, t.scadenza INTO d_esec, d_scad
	FROM risultato_test_genetico t
	WHERE t.codice = NEW.codice_test; 

	-- 2. Controllo se il test esiste e ha date valide: se d_esec è NULL, significa che la SELECT non ha trovato il test (o il test ha date nulle)
	IF d_esec IS NULL OR d_scad IS NULL THEN
		RAISE EXCEPTION 'Errore: Il test genetico % non ha date valide o non esiste.', NEW.codice_test;
	END IF;

	-- 3. Verifico se la data di creazione della redazione è compresa tra data esecuzione e scadenza del test
	IF NEW.data_creazione < d_esec OR NEW.data_creazione > d_scad THEN
		RAISE EXCEPTION
		'Vincolo 5 violato: La data redazione (%) deve essere compresa tra esecuzione (%) e scadenza (%) del test %.',
		NEW.data_creazione, d_esec, d_scad, NEW.codice_test;
	END IF;

	RETURN NEW; --se tutto ok, restituisco il nuovo record
END;
$$ LANGUAGE plpgsql;

-- TRIGGER SU REDAZIONE
DROP TRIGGER IF EXISTS trg_redazione_finestra_test ON redazione;

CREATE TRIGGER trg_redazione_finestra_test
BEFORE INSERT OR UPDATE ON redazione
FOR EACH ROW 
EXECUTE FUNCTION trg_redazione_finestra_test_fn();



--vincolo 6

CREATE OR REPLACE FUNCTION trg_piano_no_sovrapposizione_fn()
RETURNS trigger AS $$
DECLARE
	new_range daterange; -- intervallo temporale del nuovo piano (data_inizio, data_fine)
	num_piani_sovrapposti int; 
BEGIN
	IF NEW.data_inizio IS NULL THEN
		RAISE EXCEPTION 'Vincolo violato: è necessario specificare una data di inizio';
	END IF;

	--qui si controlla la correttezza delle date della nuova tupla (data_inizio deve essere < data_fine)
	IF NEW.data_fine IS NOT NULL AND NEW.data_fine < NEW.data_inizio THEN
		RAISE EXCEPTION 'Vincolo violato: data_fine (%) precedente a data_inizio (%)', 
		NEW.data_fine, NEW.data_inizio;
	END IF;

	/*Per vedere se ci sono piani che si sovrappongono bisogna fare un controllo sulle dati e sui range di valori che si hanno nel DB.
	daterange è una funzione di PostgreS che permette di creare un intervallo di tempo. In questo caso l'intervallo di tempo
	indica il periodo di validità del piano dieta che bisogna inserire.*/
	new_range := daterange(
		NEW.data_inizio,
		COALESCE(NEW.data_fine, 'infinity'::date),
		'[]' --estremi inclusi (come in matematica)
	);

	/*L'intervallo di tempo del nuovo piano è quindi: 
		(NEW.data_inizio, infinity) se NEW.data_fine = NULL
		(NEW.data_inizio, NEW.data_fine) se NEW.data_fine != NULL
	*/

	--a questo punto si controlla se ci sono piani già iniziati nell'inervallo di tempo del nuovo piano

	-- 3. Si conta il numero di piani che si sovrappongono
	SELECT COUNT(*) INTO num_piani_sovrapposti
	FROM piano_dieta p
	WHERE p.cf_paziente = NEW.cf_paziente 
	AND p.nome <> NEW.nome --controllo da fare nel caso di UPDATE (per evitare che si confronti con se stesso)
	--&& è l'operatore di sovrapposizione tra intervalli in Postgres (se si sovrappongono restituisce TRUE)
	AND daterange(p.data_inizio, COALESCE(p.data_fine, 'infinity'::date), '[]') && new_range; 

	IF num_piani_sovrapposti > 0 THEN --se ci sono piani che si sovrappongono
		RAISE EXCEPTION 'Vincolo violato: sovrapposizione temporale con un altro piano per il paziente %',
		NEW.cf_paziente;
	END IF;

	RETURN NEW; --se tutto ok, restituisco il nuovo record
END;
$$ LANGUAGE plpgsql;

-- Creazione del Trigger
DROP TRIGGER IF EXISTS trg_piano_no_sovrapposizione ON piano_dieta;

CREATE TRIGGER trg_piano_no_sovrapposizione
BEFORE INSERT OR UPDATE ON piano_dieta
FOR EACH ROW 
EXECUTE FUNCTION trg_piano_no_sovrapposizione_fn();


--vincolo 7
ALTER TABLE composizione 
DROP CONSTRAINT IF EXISTS chk_composizione_tipo_consiglio;

ALTER TABLE composizione
ADD CONSTRAINT chk_composizione_tipo_consiglio
	CHECK(tipo_consiglio IN (
							'Fortemente Consigliato', 
							'Consigliato', 
							'Sconsigliato',
							'Fortemente Sconsigliato'));