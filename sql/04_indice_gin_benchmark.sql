-- ============================================================================
-- BENCHMARK DE DESEMPENHO COM E SEM ÍNDICE GIN
-- Comparando planos de execução via EXPLAIN ANALYZE em 200.003 documentos
-- ============================================================================

-- Garantir que começamos o teste SEM nenhum índice na coluna JSONB
DROP INDEX IF EXISTS idx_produtos_atributos_gin;
DROP INDEX IF EXISTS idx_produtos_atributos_gin_path_ops;

-- ----------------------------------------------------------------------------
-- PASSO 1: Consulta SEM Índice (Varredura Sequencial - Seq Scan)
-- ----------------------------------------------------------------------------
-- Buscando produtos da marca "Corsair", do lote 42, com peso de 1542g.
-- Observe no output: "Seq Scan on produtos" (ou Parallel Seq Scan)
-- Observe o "Execution Time" no final (geralmente entre 40 ms e 80 ms).
EXPLAIN ANALYZE
SELECT id, sku, nome, preco
FROM produtos
WHERE atributos @> '{"marca": "Corsair", "lote": 42, "especificacoes": {"peso_gramas": 1542}}'::jsonb;


-- ----------------------------------------------------------------------------
-- PASSO 2: Criação do Índice GIN (Generalized Inverted Index)
-- ----------------------------------------------------------------------------
-- O índice GIN abre cada documento JSONB e indexa todas as chaves e valores
-- em uma árvore B invertida apontando para os IDs das linhas (TIDs).
CREATE INDEX idx_produtos_atributos_gin 
ON produtos USING GIN (atributos);


-- ----------------------------------------------------------------------------
-- PASSO 3: Mesma Consulta COM Índice GIN
-- ----------------------------------------------------------------------------
-- Observe no output: Mudou para "Bitmap Heap Scan" / "Bitmap Index Scan"
-- Observe o "Execution Time": Cai drasticamente para ~0.08 ms a 0.35 ms!
EXPLAIN ANALYZE
SELECT id, sku, nome, preco
FROM produtos
WHERE atributos @> '{"marca": "Corsair", "lote": 42, "especificacoes": {"peso_gramas": 1542}}'::jsonb;


-- ----------------------------------------------------------------------------
-- BÔNUS TÉCNICO: Comparando tamanho de índice (jsonb_ops vs jsonb_path_ops)
-- ----------------------------------------------------------------------------
-- Criando um segundo índice usando a classe 'jsonb_path_ops' (baseada em hash de caminhos)
CREATE INDEX idx_produtos_atributos_gin_path_ops 
ON produtos USING GIN (atributos jsonb_path_ops);

-- Comparando o tamanho em disco dos dois tipos de índice GIN no PostgreSQL:
-- O jsonb_path_ops consome muito menos espaço em disco e é ainda mais rápido para o operador @>!
SELECT 
    indexrelname AS nome_do_indice,
    pg_size_pretty(pg_relation_size(indexrelid)) AS tamanho_em_disco
FROM pg_stat_user_indexes
WHERE relname = 'produtos';