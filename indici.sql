Perfetto: quella query è un classico caso “piani attuali”. Qui l’indice **sensato** non è su `data_fine` da sola, ma **parziale** (perché la condizione è `data_fine IS NULL`) e meglio ancora **sulla FK usata nella join** così l’engine filtra subito i piani attuali e poi join-a velocemente sui pazienti.

### ✅ Indice consigliato (non-PK, non-UNIQUE)

```sql
CREATE INDEX idx_piano_attuale_cf_paziente
ON piano_dieta (cf_paziente)
WHERE data_fine IS NULL;
```

Perché così:

* la tua query filtra `pd.data_fine IS NULL` → l’indice contiene **solo** quei record
* la join usa `pd.cf_paziente = p.cf` → avere `cf_paziente` indicizzato dentro l’indice è perfetto

> Un indice su **solo `data_fine`** spesso è meno efficace, perché stai cercando un valore “speciale” (NULL) e poi comunque ti serve `cf_paziente` per la join.

---

# Step-by-step da fare nel video (pgAdmin 4)

## 0) (Consiglio) prepara il contesto

Nel Query Tool esegui:

```sql
ANALYZE;
```

Dì: “Aggiorno le statistiche così il planner sceglie in modo coerente.”

---

## 1) Mostra la query **PRIMA** dell’indice

Esegui:

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT DISTINCT
    p.cf,
    p.nome,
    p.cognome
FROM paziente p
JOIN piano_dieta pd ON pd.cf_paziente = p.cf
WHERE pd.data_fine IS NULL;
```

### Cosa guardare / dire

* Cerca nel piano una riga tipo **`Seq Scan on piano_dieta`**
* Nota la sezione **`Buffers:`** (shared hit/read)
* Se vedi anche `Hash Join`/`Nested Loop`, va bene: il punto è *come* trova le righe di `piano_dieta`.

---

## 2) Crea l’indice (parziale)

Esegui:

```sql
CREATE INDEX idx_piano_attuale_cf_paziente
ON piano_dieta (cf_paziente)
WHERE data_fine IS NULL;
```

Poi subito:

```sql
ANALYZE piano_dieta;
```

Nel video dì:
“Creo un indice **parziale** che contiene solo i piani **attuali** (`data_fine IS NULL`). È piccolo e mirato.”

---

## 3) Riesegui la query **DOPO** l’indice

Rilancia lo stesso identico EXPLAIN:

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT DISTINCT
    p.cf,
    p.nome,
    p.cognome
FROM paziente p
JOIN piano_dieta pd ON pd.cf_paziente = p.cf
WHERE pd.data_fine IS NULL;
```

### Cosa dovresti vedere

Nel piano (non sempre garantito, dipende dai volumi) qualcosa tipo:

* `Bitmap Index Scan` / `Index Scan using idx_piano_attuale_cf_paziente on piano_dieta`
* e **Buffers** più bassi rispetto a prima

---

# Extra: come rendere la differenza più “visibile” (se il prof vuole numeri)

Se i dati sono pochi, Postgres può comunque scegliere Seq Scan. Per far “esplodere” la differenza **senza cambiare query**, nel video puoi fare una cosa molto pulita:

### Ripeti l’EXPLAIN 2–3 volte e confronta i Buffers

* la prima volta può “scaldare” cache
* ma i **Buffers** e il tipo di scan rimangono un confronto valido

### E se ancora non usa l’indice?

Prova (solo per demo) a disattivare il seq scan **temporaneamente** per far vedere che l’indice è effettivamente utile:

```sql
SET enable_seqscan = off;

EXPLAIN (ANALYZE, BUFFERS)
SELECT DISTINCT
    p.cf,
    p.nome,
    p.cognome
FROM paziente p
JOIN piano_dieta pd ON pd.cf_paziente = p.cf
WHERE pd.data_fine IS NULL;

RESET enable_seqscan;
```

Nel video lo presenti così:
“Qui forzo il planner a considerare l’indice per mostrare il piano che diventa possibile grazie all’indicizzazione; in condizioni reali, con volumi maggiori, il planner lo sceglierebbe naturalmente.”

---

# Se vuoi proprio un indice “su data_fine”

È meno elegante, ma te lo dico per completezza:

```sql
CREATE INDEX idx_piano_data_fine_null
ON piano_dieta (data_fine)
WHERE data_fine IS NULL;
```

Però per la tua query è meglio quello su `cf_paziente` **parziale** perché subito dopo devi fare la join.

---

Se mi incolli l’output dell’`EXPLAIN (ANALYZE, BUFFERS)` **prima** e **dopo** (anche solo le righe principali: tipo Scan/Join/Buffers/Execution Time), ti dico esattamente cosa evidenziare nel video e se conviene aggiungere anche un indice composto tipo `(cf_paziente) WHERE data_fine IS NULL` (già ok) oppure `(data_fine, cf_paziente)` (di solito no).








-- -- ============================================================
-- -- NOTE:
-- -- 1) Esegui questo file DOPO aver creato lo schema/tabelle e caricato i dati.
-- -- 2) Dopo la creazione degli indici, è consigliato lanciare ANALYZE.
-- -- 3) Gli indici qui sotto sono pensati per PostgreSQL (B-Tree di default).
-- -- ============================================================

-- BEGIN;

-- -- ------------------------------------------------------------
-- -- A) Operazione 11: "Dato un modello di dieta, visualizzare i piani dieta associati"
-- -- Filtro tipico: WHERE nome_dieta = ? AND versione_dieta = ?
-- -- ------------------------------------------------------------
-- CREATE INDEX IF NOT EXISTS idx_piano_dieta_modello
-- ON public.piano_dieta (nome_dieta, versione_dieta);

-- -- ------------------------------------------------------------
-- -- B) Operazione 14: "Piani dieta passati di un paziente"
-- -- Filtro tipico: WHERE cf_paziente = ? AND data_fine IS NOT NULL
-- -- Spesso con ORDER BY data_fine DESC
-- -- Indice PARZIALE: contiene solo i record "passati"
-- -- ------------------------------------------------------------
-- CREATE INDEX IF NOT EXISTS idx_piano_passati_paziente_datafine
-- ON public.piano_dieta (cf_paziente, data_fine DESC)
-- WHERE data_fine IS NOT NULL;

-- -- ------------------------------------------------------------
-- -- C) Operazione 13: "Dato un nutrizionista, mostrare i suoi dati e il numero di piani redatti"
-- -- Conteggio su REDAZIONE filtrando cf_nutrizionista
-- -- ------------------------------------------------------------
-- CREATE INDEX IF NOT EXISTS idx_redazione_nutrizionista
-- ON public.redazione (cf_nutrizionista);

-- -- ------------------------------------------------------------
-- -- D) Operazione 19: "Dato un risultato test, visualizzare su quali report esso deriva"
-- -- Filtro tipico: WHERE codice_test = ?
-- -- NOTA: la PK di DERIVAZIONE (cf_medico, numero_report, codice_test) non è ideale
-- --       per ricerche "per codice_test" (perché codice_test è l'ultimo attributo).
-- -- ------------------------------------------------------------
-- CREATE INDEX IF NOT EXISTS idx_derivazione_codice_test
-- ON public.derivazione (codice_test);

-- -- Opzionale "coprente": riduce i lookup durante join verso REPORT
-- -- (Toglilo se vuoi mantenere gli indici al minimo assoluto)
-- CREATE INDEX IF NOT EXISTS idx_derivazione_codice_test_cover
-- ON public.derivazione (codice_test, cf_medico, numero_report);

-- -- ------------------------------------------------------------
-- -- E) Operazioni paziente ↔ test: "visualizzare test di un paziente"
-- -- Filtro tipico: WHERE cf_paziente = ?
-- -- ------------------------------------------------------------
-- CREATE INDEX IF NOT EXISTS idx_test_cf_paziente
-- ON public.risultato_test_genetico (cf_paziente);

-- -- ------------------------------------------------------------
-- -- G) Look-up su relazioni di gestione paziente
-- -- Query tipiche: "pazienti di un medico" / "pazienti di un nutrizionista"
-- -- (Volumi non enormi, ma indici naturali e utili per filtri/join)
-- -- ------------------------------------------------------------
-- CREATE INDEX IF NOT EXISTS idx_paziente_cf_medico
-- ON public.paziente (cf_medico);

-- CREATE INDEX IF NOT EXISTS idx_paziente_cf_nutrizionista
-- ON public.paziente (cf_nutrizionista);

-- COMMIT;

-- -- Aggiorna le statistiche per aiutare l'optimizer a scegliere Index Scan dove conviene
-- ANALYZE;

-- -- ============================================================
-- -- Fine file indici
-- -- ============================================================


-- -- ho questi indici, dimmi passo passo come devo fare nel video per mostrare le differenze di costo, con explain analyze, vogliamo mostrare il tempo a video cioè il guadagno prestazionale ottenuto con gli indici


