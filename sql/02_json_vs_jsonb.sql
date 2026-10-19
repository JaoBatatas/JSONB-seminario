-- ============================================================================
-- ARQUIVO 02: COMPARAÇÃO DIRETA ENTRE JSON E JSONB NA TABELA CONSERTO (Requisito 1)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Diferença Estrutural (Formatação, Ordem das Chaves e Duplicatas)
-- ----------------------------------------------------------------------------
-- Observe no primeiro conserto inserido:
-- * laudo_json: Manteve quebras de linha, espaços, "z_observacao" no topo e DUAS chaves "prioridade".
-- * laudo_jsonb: Removeu espaços, ordenou chaves e manteve apenas a última chave ("prioridade": "alta").
SELECT 
    id_conserto,
    laudo_json,
    laudo_jsonb
FROM conserto
WHERE id_conserto = 1;

-- ----------------------------------------------------------------------------
-- 2. Diferença de Desempenho de Leitura SEM ÍNDICE (Parse de Texto vs Binário)
-- ----------------------------------------------------------------------------
-- Mesmo SEM nenhum índice criado ainda, veja a diferença de velocidade ao extrair
-- um campo aninhado nos 200.002 registros:

-- A) Lendo da coluna JSON (Mais lento: precisa fazer o parse do texto em todas as 200k linhas)
-- EXPLAIN ANALYZE
SELECT count(*) 
FROM conserto 
WHERE laudo_json #>> '{telemetria_obd2, codigo_principal}' = 'P0420';

-- B) Lendo da coluna JSONB (Mais rápido: navega direto nos ponteiros da árvore binária)
-- EXPLAIN ANALYZE
SELECT count(*) 
FROM conserto 
WHERE laudo_jsonb #>> '{telemetria_obd2, codigo_principal}' = 'P0420';