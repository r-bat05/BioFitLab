BEGIN;

-- ============================================================
-- 0) PULIZIA (DROP)
-- Ordine inverso rispetto alla creazione per evitare errori di dipendenza
-- ============================================================

DROP TABLE IF EXISTS DERIVAZIONE CASCADE;
DROP TABLE IF EXISTS CONSIGLIO_MEDICO CASCADE;
DROP TABLE IF EXISTS PREDISPOSIZIONI CASCADE;
DROP TABLE IF EXISTS REPORT CASCADE;
DROP TABLE IF EXISTS REDAZIONE CASCADE;
DROP TABLE IF EXISTS COMPOSIZIONE CASCADE;
DROP TABLE IF EXISTS NOTA_PIANO CASCADE;
DROP TABLE IF EXISTS PIANO_DIETA CASCADE;
DROP TABLE IF EXISTS ANALISI CASCADE;
DROP TABLE IF EXISTS NOTA_TEST CASCADE;
DROP TABLE IF EXISTS RISULTATO_TEST_GENETICO CASCADE;
DROP TABLE IF EXISTS GENE CASCADE;
DROP TABLE IF EXISTS DNA CASCADE;
DROP TABLE IF EXISTS CERTIFICAZIONE CASCADE;
DROP TABLE IF EXISTS PAZIENTE CASCADE;
DROP TABLE IF EXISTS ALIMENTO CASCADE;
DROP TABLE IF EXISTS DIETA CASCADE;
DROP TABLE IF EXISTS ABILITAZIONE CASCADE;
DROP TABLE IF EXISTS NUTRIZIONISTA CASCADE;
DROP TABLE IF EXISTS MEDICO CASCADE;

-- ============================================================
-- 1) ENTITÀ INDIPENDENTI (Non hanno chiavi esterne verso altri)
-- ============================================================

CREATE TABLE MEDICO (
  cf                VARCHAR(16)  PRIMARY KEY,   
  nome              VARCHAR(50)  NOT NULL,
  cognome           VARCHAR(50)  NOT NULL,
  email             VARCHAR(120) NOT NULL,
  telefono          VARCHAR(30)  NOT NULL,
  indirizzo         VARCHAR(200) NOT NULL,
  universita_studio VARCHAR(120) NOT NULL,
  data_nascita      DATE         NOT NULL,
  CONSTRAINT uq_medico_email UNIQUE (email)
);

CREATE TABLE NUTRIZIONISTA (    
  cf                VARCHAR(16)  PRIMARY KEY,  
  nome              VARCHAR(50)  NOT NULL,
  cognome           VARCHAR(50)  NOT NULL,
  data_nascita      DATE         NOT NULL,
  telefono          VARCHAR(30)  NOT NULL,
  email             VARCHAR(120) NOT NULL,
  indirizzo_studio  VARCHAR(200) NOT NULL,
  indirizzo         VARCHAR(200) NOT NULL,
  CONSTRAINT uq_nutrizionista_email UNIQUE (email)
);

CREATE TABLE ABILITAZIONE (
  codice             VARCHAR(50)  PRIMARY KEY, 
  ente_certificatore VARCHAR(120) NOT NULL,
  ambito             VARCHAR(80)  NOT NULL,
  livello            INTEGER      NOT NULL,
  CONSTRAINT chk_abilitazione_livello CHECK (livello BETWEEN 1 AND 5)
);

CREATE TABLE DIETA (
  nome      VARCHAR(120) NOT NULL,
  versione  VARCHAR(30)  NOT NULL,
  obiettivo VARCHAR(120) NOT NULL,
  tipo      VARCHAR(80)  NOT NULL,
  CONSTRAINT pk_dieta PRIMARY KEY (nome, versione)
);

CREATE TABLE ALIMENTO (
  codice       VARCHAR(50)    PRIMARY KEY,
  nome         VARCHAR(120)   NOT NULL,
  allergeni    VARCHAR(250),
  fibre        NUMERIC(8,2)   NOT NULL,
  grassi       NUMERIC(8,2)   NOT NULL,
  proteine     NUMERIC(8,2)   NOT NULL,
  carboidrati  NUMERIC(8,2)   NOT NULL,
  kcal         NUMERIC(8,2)   NOT NULL
);

-- ============================================================
-- 2) ENTITÀ DI LIVELLO 1 (Dipendono dalle Indipendenti)
-- ============================================================

CREATE TABLE PAZIENTE (
  cf                VARCHAR(16)  PRIMARY KEY, 
  nome              VARCHAR(50)  NOT NULL,
  cognome           VARCHAR(50)  NOT NULL,
  data_nascita      DATE         NOT NULL,
  telefono          VARCHAR(30)  NOT NULL,
  email             VARCHAR(120) NOT NULL,
  peso              NUMERIC(6,2) NOT NULL,
  altezza           NUMERIC(5,2) NOT NULL,
  indirizzo         VARCHAR(200) NOT NULL,
  data_inizio_medico        DATE,
  data_inizio_nutrizionista DATE,
  cf_medico          VARCHAR(16),
  cf_nutrizionista   VARCHAR(16),

  CONSTRAINT uq_paziente_email UNIQUE (email),

  CONSTRAINT fk_paziente_medico
    FOREIGN KEY (cf_medico) REFERENCES MEDICO(cf)
    ON DELETE SET NULL ON UPDATE CASCADE,

  CONSTRAINT fk_paziente_nutrizionista
    FOREIGN KEY (cf_nutrizionista) REFERENCES NUTRIZIONISTA(cf)
    ON DELETE SET NULL ON UPDATE CASCADE
);

CREATE TABLE CERTIFICAZIONE (
  cf_nutrizionista    VARCHAR(16)  NOT NULL,
  codice_abilitazione VARCHAR(50)  NOT NULL,
  data_conseguimento  DATE         NOT NULL,

  CONSTRAINT pk_certificazione PRIMARY KEY (cf_nutrizionista, codice_abilitazione),

  CONSTRAINT fk_cert_nutr
    FOREIGN KEY (cf_nutrizionista) REFERENCES NUTRIZIONISTA(cf)
    ON DELETE CASCADE ON UPDATE CASCADE,

  CONSTRAINT fk_cert_abil
    FOREIGN KEY (codice_abilitazione) REFERENCES ABILITAZIONE(codice)
    ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE REPORT (
  numero         VARCHAR(50)  NOT NULL,
  cf_medico      VARCHAR(16)  NOT NULL,
  data           DATE         NOT NULL,
  valutazione    VARCHAR(800) NOT NULL, 
  
  CONSTRAINT pk_report PRIMARY KEY (cf_medico, numero),

  CONSTRAINT fk_report_medico
    FOREIGN KEY (cf_medico) REFERENCES MEDICO(cf)
    ON DELETE RESTRICT ON UPDATE CASCADE
);

-- ============================================================
-- 3) ENTITÀ DI LIVELLO 2 (Dipendono da Livello 1)
-- ============================================================

CREATE TABLE DNA (
  codice       VARCHAR(50)  PRIMARY KEY,
  descrizione  VARCHAR(200), 
  cf_paziente  VARCHAR(16)  NOT NULL,

  CONSTRAINT uq_dna_paziente UNIQUE (cf_paziente), 

  CONSTRAINT fk_dna_paziente
    FOREIGN KEY (cf_paziente) REFERENCES PAZIENTE(cf)
    ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE RISULTATO_TEST_GENETICO (
  codice          VARCHAR(50)  PRIMARY KEY,
  data_esecuzione DATE         NOT NULL,
  scadenza        DATE         NOT NULL,        
  esito           VARCHAR(500) NOT NULL,
  cf_paziente     VARCHAR(16)  NOT NULL, 

  CONSTRAINT fk_test_paziente
    FOREIGN KEY (cf_paziente) REFERENCES PAZIENTE(cf)
    ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE PIANO_DIETA (
  cf_paziente     VARCHAR(16)  NOT NULL,
  nome            VARCHAR(120) NOT NULL, 
  data_inizio     DATE         NOT NULL,
  data_fine       DATE,                 --se NULL indica che è un piano attuale
  nome_dieta      VARCHAR(120) NOT NULL,
  versione_dieta  VARCHAR(30)  NOT NULL,

  CONSTRAINT pk_piano_dieta PRIMARY KEY (cf_paziente, nome),

  CONSTRAINT fk_piano_paziente
    FOREIGN KEY (cf_paziente) REFERENCES PAZIENTE(cf)
    ON DELETE CASCADE ON UPDATE CASCADE,

  CONSTRAINT fk_piano_dieta_ref
    FOREIGN KEY (nome_dieta, versione_dieta) REFERENCES DIETA(nome, versione)
    ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE PREDISPOSIZIONI (
  cf_medico      VARCHAR(16)  NOT NULL,
  numero_report  VARCHAR(50)  NOT NULL,
  codice         VARCHAR(50)  NOT NULL,
  descrizione    VARCHAR(600) NOT NULL,

  CONSTRAINT pk_predisposizioni PRIMARY KEY (cf_medico, numero_report, codice),

  CONSTRAINT fk_pred_report
    FOREIGN KEY (cf_medico, numero_report) REFERENCES REPORT(cf_medico, numero)
    ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE CONSIGLIO_MEDICO (
  cf_medico        VARCHAR(16)  NOT NULL,
  numero_report    VARCHAR(50)  NOT NULL,
  num_progressivo  INTEGER      NOT NULL,
  titolo           VARCHAR(120) NOT NULL,
  descrizione      VARCHAR(800) NOT NULL,
  priorita         VARCHAR(30),
  tipo_consiglio   VARCHAR(60),
  tipo_allenamento VARCHAR(60),
  durata           VARCHAR(40),
  intensita        VARCHAR(40),
  frequenza        VARCHAR(40),
  tipo_attivita    VARCHAR(60),
  obiettivo        VARCHAR(120),

  CONSTRAINT pk_consiglio_medico PRIMARY KEY (cf_medico, numero_report, num_progressivo),

  CONSTRAINT fk_consiglio_ref
    FOREIGN KEY (cf_medico, numero_report) REFERENCES REPORT(cf_medico, numero)
    ON DELETE CASCADE ON UPDATE CASCADE
);

-- ============================================================
-- 4) ENTITÀ DI LIVELLO 3 (Dipendono da Livello 2)
-- ============================================================

CREATE TABLE GENE (
  codice_dna       VARCHAR(50)  NOT NULL,
  nome             VARCHAR(80)  NOT NULL,
  num_progressivo  INTEGER      NOT NULL,
  funzione_biologica VARCHAR(400) NOT NULL,

  CONSTRAINT pk_gene PRIMARY KEY (codice_dna, nome, num_progressivo),

  CONSTRAINT fk_gene_dna
    FOREIGN KEY (codice_dna) REFERENCES DNA(codice)
    ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE NOTA_TEST (
  codice_test      VARCHAR(50)  NOT NULL,
  numero           INTEGER      NOT NULL,
  descrizione      VARCHAR(600) NOT NULL,

  CONSTRAINT pk_nota_test PRIMARY KEY (codice_test, numero),

  CONSTRAINT fk_nota_test_ref
    FOREIGN KEY (codice_test) REFERENCES RISULTATO_TEST_GENETICO(codice)
    ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE NOTA_PIANO (
  cf_paziente     VARCHAR(16)  NOT NULL,
  nome_piano      VARCHAR(120) NOT NULL,
  numero          INTEGER      NOT NULL,
  descrizione     VARCHAR(600) NOT NULL,

  CONSTRAINT pk_nota_piano PRIMARY KEY (cf_paziente, nome_piano, numero),

  CONSTRAINT fk_nota_piano_ref
    FOREIGN KEY (cf_paziente, nome_piano) REFERENCES PIANO_DIETA(cf_paziente, nome)
    ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE COMPOSIZIONE (
  cf_paziente     VARCHAR(16)  NOT NULL,
  nome_piano      VARCHAR(120) NOT NULL,
  codice_alimento VARCHAR(50)  NOT NULL,
  qta             INTEGER      NOT NULL,     
  tipo_consiglio  VARCHAR(30)  NOT NULL,

  CONSTRAINT pk_composizione PRIMARY KEY (cf_paziente, nome_piano, codice_alimento),

  CONSTRAINT fk_comp_piano
    FOREIGN KEY (cf_paziente, nome_piano) REFERENCES PIANO_DIETA(cf_paziente, nome)
    ON DELETE CASCADE ON UPDATE CASCADE,

  CONSTRAINT fk_comp_alimento
    FOREIGN KEY (codice_alimento) REFERENCES ALIMENTO(codice)
    ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE DERIVAZIONE (
  cf_medico      VARCHAR(16)  NOT NULL,
  numero_report  VARCHAR(50)  NOT NULL,
  codice_test    VARCHAR(50)  NOT NULL,

  CONSTRAINT pk_derivazione PRIMARY KEY (cf_medico, numero_report, codice_test),

  CONSTRAINT fk_deriv_report
    FOREIGN KEY (cf_medico, numero_report) REFERENCES REPORT(cf_medico, numero)
    ON DELETE CASCADE ON UPDATE CASCADE,

  CONSTRAINT fk_deriv_test
    FOREIGN KEY (codice_test) REFERENCES RISULTATO_TEST_GENETICO(codice)
    ON DELETE RESTRICT ON UPDATE CASCADE
);

-- ============================================================
-- 5) ENTITÀ DI LIVELLO 4 (Dipendono da Livello 3 e misti)
-- ============================================================

CREATE TABLE ANALISI (
  codice_test      VARCHAR(50)  NOT NULL,
  codice_dna       VARCHAR(50)  NOT NULL,
  nome_gene        VARCHAR(80)  NOT NULL,
  num_prog_gene    INTEGER      NOT NULL,

  CONSTRAINT pk_analisi PRIMARY KEY (codice_test, codice_dna, nome_gene, num_prog_gene),

  CONSTRAINT fk_analisi_test
    FOREIGN KEY (codice_test) REFERENCES RISULTATO_TEST_GENETICO(codice)
    ON DELETE CASCADE ON UPDATE CASCADE,

  CONSTRAINT fk_analisi_gene
    FOREIGN KEY (codice_dna, nome_gene, num_prog_gene) REFERENCES GENE(codice_dna, nome, num_progressivo)
    ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE REDAZIONE (
  cf_nutrizionista VARCHAR(16)  NOT NULL,
  cf_paziente      VARCHAR(16)  NOT NULL,
  nome_piano       VARCHAR(120) NOT NULL,
  codice_test      VARCHAR(50)  NOT NULL, 
  data_creazione   DATE         NOT NULL,
  ora_creazione    TIME         NOT NULL,

  CONSTRAINT pk_redazione PRIMARY KEY (cf_paziente, nome_piano),

  CONSTRAINT fk_red_nutr
    FOREIGN KEY (cf_nutrizionista) REFERENCES NUTRIZIONISTA(cf)
    ON DELETE RESTRICT ON UPDATE CASCADE,

  CONSTRAINT fk_red_piano
    FOREIGN KEY (cf_paziente, nome_piano) REFERENCES PIANO_DIETA(cf_paziente, nome)
    ON DELETE CASCADE ON UPDATE CASCADE,

  CONSTRAINT fk_red_test
    FOREIGN KEY (codice_test) REFERENCES RISULTATO_TEST_GENETICO(codice)
    ON DELETE RESTRICT ON UPDATE CASCADE
);

COMMIT;