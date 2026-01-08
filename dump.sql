BEGIN;

-- ============================================================
-- MEDICO (3)
-- ============================================================
INSERT INTO MEDICO VALUES
('MDCRSS80A01F205X','Mario','Rossi','rossi@med.it','333111','Via Roma 1','Uni Bari','1980-01-01','Bari'),
('MDCBNCH75B02F205','Luigi','Bianchi','bianchi@med.it','333112','Via Napoli 2','Uni Roma','1975-02-02','Bari'),
('MDCLVR82C03F205Z','Paolo','Verdi','verdi@med.it','333113','Via Lecce 3','Uni Milano','1982-03-03','Bari');

-- ============================================================
-- NUTRIZIONISTA (3)
-- ============================================================
INSERT INTO NUTRIZIONISTA VALUES
('NTRLCU85A01F205X','Luca','Neri','1985-01-01','333221','luca@nutri.it','Via Dante 1','Via Bari 1'),
('NTRMRC90B02F205Y','Marco','Rosa','1990-02-02','333222','marco@nutri.it','Via Dante 2','Via Bari 2'),
('NTRANN88C03F205Z','Anna','Blu','1988-03-03','333223','anna@nutri.it','Via Dante 3','Via Bari 3');

-- ============================================================
-- ABILITAZIONE (3)
-- ============================================================
INSERT INTO ABILITAZIONE VALUES
('AB01','Ministero','Nutrizione',3),
('AB02','Ministero','Sport',4),
('AB03','Regione','Clinica',5);

-- ============================================================
-- CERTIFICAZIONE (3)
-- ============================================================
INSERT INTO CERTIFICAZIONE VALUES
('NTRLCU85A01F205X','AB01','2015-01-01'),
('NTRMRC90B02F205Y','AB02','2016-01-01'),
('NTRANN88C03F205Z','AB03','2017-01-01');

-- ============================================================
-- DIETA (3)
-- ============================================================
INSERT INTO DIETA VALUES
('Mediterranea','1.0','Dimagrimento','Bilanciata'),
('Chetogenica','1.0','Definizione','Low Carb'),
('Sportiva','1.0','Performance','Iperproteica');

-- ============================================================
-- ALIMENTO (3)
-- ============================================================
INSERT INTO ALIMENTO VALUES
('AL01','Pasta','Glutine',6,2,12,70,350),
('AL02','Riso',NULL,2,1,7,78,360),
('AL03','Pollo',NULL,0,1,23,0,120);

-- ============================================================
-- PAZIENTE (3 – città = Bari)
-- ============================================================
INSERT INTO PAZIENTE VALUES
('PZ00000000000001','Gianni','Verdi','1990-01-01','333301','p1@mail.it',80,1.75,'Via A','2023-01-01','2023-01-10','MDCRSS80A01F205X','NTRLCU85A01F205X','Bari'),
('PZ00000000000002','Laura','Blu','1988-02-02','333302','p2@mail.it',65,1.65,'Via B','2023-01-05','2023-01-12','MDCBNCH75B02F205','NTRMRC90B02F205Y','Bari'),
('PZ00000000000003','Anna','Rosa','1995-03-03','333303','p3@mail.it',70,1.68,'Via C','2023-01-10','2023-01-15','MDCLVR82C03F205Z','NTRANN88C03F205Z','Bari');

-- ============================================================
-- DNA (3)
-- ============================================================
INSERT INTO DNA VALUES
('DNA01','Profilo base','PZ00000000000001'),
('DNA02','Profilo sport','PZ00000000000002'),
('DNA03','Profilo clinico','PZ00000000000003');

-- ============================================================
-- GENE (3)
-- ============================================================
INSERT INTO GENE VALUES
('DNA01','FTO',1,'Metabolismo'),
('DNA02','ACE',1,'Resistenza'),
('DNA03','APOE',1,'Colesterolo');

-- ============================================================
-- RISULTATO TEST GENETICO (3)
-- ============================================================
INSERT INTO RISULTATO_TEST_GENETICO VALUES
('T01','2023-01-01','2024-01-01','OK','PZ00000000000001'),
('T02','2023-01-05','2024-01-05','OK','PZ00000000000002'),
('T03','2023-01-10','2024-01-10','OK','PZ00000000000003');

-- ============================================================
-- REPORT (3 – date dentro test)
-- ============================================================
INSERT INTO REPORT VALUES
('R01','MDCRSS80A01F205X','2023-02-01','Buono'),
('R02','MDCBNCH75B02F205','2023-02-05','Ottimo'),
('R03','MDCLVR82C03F205Z','2023-02-10','Regolare');

-- ============================================================
-- DERIVAZIONE (3)
-- ============================================================
INSERT INTO DERIVAZIONE VALUES
('MDCRSS80A01F205X','R01','T01'),
('MDCBNCH75B02F205','R02','T02'),
('MDCLVR82C03F205Z','R03','T03');

-- ============================================================
-- PIANO_DIETA (3 – no sovrapposizioni)
-- ============================================================
INSERT INTO PIANO_DIETA VALUES
('PZ00000000000001','Piano1','2023-02-10',NULL,'Mediterranea','1.0'),
('PZ00000000000002','Piano2','2023-02-15',NULL,'Chetogenica','1.0'),
('PZ00000000000003','Piano3','2023-02-20',NULL,'Sportiva','1.0');

-- ============================================================
-- COMPOSIZIONE (≥3)
-- ============================================================
INSERT INTO COMPOSIZIONE VALUES
('PZ00000000000001','Piano1','AL01',2,'Consigliato'),
('PZ00000000000002','Piano2','AL02',1,'Fortemente Consigliato'),
('PZ00000000000003','Piano3','AL03',3,'Consigliato');

-- ============================================================
-- REDAZIONE (3 – data dentro test)
-- ============================================================
INSERT INTO REDAZIONE VALUES
('NTRLCU85A01F205X','PZ00000000000001','Piano1','T01','2023-02-15','09:00'),
('NTRMRC90B02F205Y','PZ00000000000002','Piano2','T02','2023-02-20','10:00'),
('NTRANN88C03F205Z','PZ00000000000003','Piano3','T03','2023-02-25','11:00');

-- ============================================================
-- ANALISI (3)
-- ============================================================

INSERT INTO ANALISI
(codice_test, codice_dna, nome_gene, num_prog_gene)
VALUES
('T01','DNA01','FTO',1),
('T02','DNA02','ACE',1),
('T03','DNA03','APOE',1);

-- ============================================================
-- NOTA_TEST (3)
-- ============================================================

INSERT INTO NOTA_TEST
(codice_test, numero, descrizione)
VALUES
('T01', 1, 'Campione integro, analisi completata'),
('T02', 1, 'Nessuna anomalia nei marcatori principali'),
('T03', 1, 'Suggerita conferma con controllo periodico');

-- ============================================================
-- NOTA_PIANO (3)
-- ============================================================

INSERT INTO NOTA_PIANO
(cf_paziente, nome_piano, numero, descrizione)
VALUES
('PZ00000000000001', 'Piano1', 1, 'Bere almeno 2L di acqua al giorno'),
('PZ00000000000002', 'Piano2', 1, 'Ridurre zuccheri semplici e snack'),
('PZ00000000000003', 'Piano3', 1, 'Distribuire le proteine su tutti i pasti');


COMMIT;


-- BEGIN;

-- TRUNCATE TABLE
-- DERIVAZIONE,
-- CONSIGLIO_MEDICO,
-- PREDISPOSIZIONI,
-- REDAZIONE,
-- ANALISI,
-- NOTA_TEST,
-- NOTA_PIANO,
-- COMPOSIZIONE,
-- PIANO_DIETA,
-- REPORT,
-- RISULTATO_TEST_GENETICO,
-- GENE,
-- DNA,
-- CERTIFICAZIONE,
-- PAZIENTE,
-- ALIMENTO,
-- DIETA,
-- ABILITAZIONE,
-- NUTRIZIONISTA,
-- MEDICO
-- CASCADE;

-- COMMIT;

