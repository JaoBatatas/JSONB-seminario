-- ============================================================================
-- ARQUIVO 04: ÍNDICE GIN E EXPLAIN ANALYZE NA TABELA CONSERTO (Requisito 3)
-- ============================================================================

DROP INDEX IF EXISTS idx_conserto_laudo_gin;

-- ----------------------------------------------------------------------------
-- PASSO 1: Busca SEM Índice GIN (Sequential Scan)
-- ----------------------------------------------------------------------------
-- Procurando consertos do sistema de "Injecao", lote de peça 42, 
-- onde o código OBD2 foi "P0142" e temperatura do motor 112°C.
-- Observe o "Seq Scan" e o tempo na casa de ~50ms a ~90ms:
EXPLAIN ANALYZE
SELECT id_conserto, codm, codv, data
FROM conserto
WHERE laudo_jsonb @> '{
    "sistema_afetado": "Injecao",
    "lote_peca": 42,
    "telemetria_obd2": {"codigo_principal": "P0142", "temp_motor_c": 112}
}'::jsonb;


-- ----------------------------------------------------------------------------
-- PASSO 2: Tentativa de criar índice GIN na coluna JSON comum (Demonstração)
-- ----------------------------------------------------------------------------
-- Se descomentar abaixo, dará ERRO: data type json has no default operator class for access method "gin"
-- Isso prova na prática por que JSONB é indispensável para bancos de documentos!
-- CREATE INDEX idx_erro_json ON conserto USING GIN (laudo_json);


-- ----------------------------------------------------------------------------
-- PASSO 3: Criando o Índice GIN na coluna JSONB
-- ----------------------------------------------------------------------------
CREATE INDEX idx_conserto_laudo_gin 
ON conserto USING GIN (laudo_jsonb);


-- ----------------------------------------------------------------------------
-- PASSO 4: Mesma Busca COM Índice GIN (Bitmap Index Scan)
-- ----------------------------------------------------------------------------
-- Observe a mudança para "Bitmap Heap Scan" / "Bitmap Index Scan"
-- e a queda drástica do Execution Time para ~0.08ms a 0.35ms!
EXPLAIN ANALYZE
SELECT id_conserto, codm, codv, data
FROM conserto
WHERE laudo_jsonb @> '{
    "sistema_afetado": "Injecao",
    "lote_peca": 42,
    "telemetria_obd2": {"codigo_principal": "P0142", "temp_motor_c": 112}
}'::jsonb;