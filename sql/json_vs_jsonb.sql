-- =============================================================================
-- ROTEIRO DE EXECUÇÃO:
-- 1. Diferença prática: JSON vs JSONB (Formatação, Espaços, Chaves, Ordem)
-- 2. Operações de Consulta e Manipulação (->, ->>, #>, #>>, @>, jsonb_path_query, ?, ||, -, #-)
-- 3. Comparação de Desempenho (EXPLAIN ANALYZE): JSON vs JSONB vs JSONB com GIN
-- =============================================================================

-- =============================================================================
-- PARTE 1: DEMONSTRAÇÃO PRÁTICA: JSON vs JSONB
-- =============================================================================

-- 1.1 Inserção de uma string com:
-- - Espaços em branco excessivos e quebras de linha
-- - Chaves fora de ordem alfabética ("z_obs" antes de "a_codigo")
-- - Chave duplicada ("prioridade": "baixa" e depois "prioridade": "alta")
DROP TABLE IF EXISTS demo_comparacao_tipos;
CREATE TABLE demo_comparacao_tipos (
id SERIAL PRIMARY KEY,
dados_json JSON,
dados_jsonb JSONB
);

INSERT INTO demo_comparacao_tipos (dados_json, dados_jsonb)
VALUES (
'{
"z_obs":    "Cliente relatou falha intermitente",
"prioridade": "baixa",
"a_cod": 105,
"prioridade": "alta"
}',
'{
"z_obs":    "Cliente relatou falha intermitente",
"prioridade": "baixa",
"a_cod": 105,
"prioridade": "alta"
}'
);

SELECT dados_json, dados_jsonb FROM demo_comparacao_tipos;

-- 1.3 Comparação de tamanho em bytes:
SELECT
pg_column_size(dados_json)  AS bytes_armazenamento_json,
pg_column_size(dados_jsonb) AS bytes_armazenamento_jsonb
FROM demo_comparacao_tipos;

DELETE FROM demo_comparacao_tipos;

INSERT INTO demo_comparacao_tipos (dados_json, dados_jsonb)
VALUES (
'{"z_obs":"Cliente relatou falha intermitente","a_cod": 105,"prioridade": "alta"}',
'{"z_obs":"Cliente relatou falha intermitente","a_cod": 105,"prioridade": "alta"}'
);

-- =============================================================================
-- PARTE 2: OPERAÇÕES DE CONSULTA E MANIPULAÇÃO
-- (Executando sobre a tabela 'conserto' da oficina mecânica)
-- =============================================================================

-- 2.1 Operadores -> (retorna JSONB) vs ->> (retorna TEXT)
SELECT
id_conserto,
laudo_jsonb -> 'prioridade'  AS prioridade_como_jsonb,
laudo_jsonb ->> 'prioridade' AS prioridade_como_texto,
laudo_jsonb -> 'telemetria_obd2' -> 'protocolo' AS protocolo_encadeado
FROM conserto
WHERE laudo_jsonb -> 'telemetria_obd2' -> 'protocolo' IS NOT NULL
LIMIT 5;

-- 2.2 Operadores de Caminho: #> (retorna JSONB) vs #>> (retorna TEXT)
-- Permitem descer múltiplos níveis na hierarquia passando um array de caminhos text[]:
SELECT
id_conserto,
laudo_jsonb #> '{telemetria_obd2, parametros}' AS params_jsonb,
laudo_jsonb #>> '{telemetria_obd2, parametros, rpm_falha}' AS rpm_falha_texto,
laudo_jsonb #>> '{pecas_trocadas, 0, fabricante}' AS fabricante_primeira_peca
FROM conserto
WHERE laudo_jsonb ? 'telemetria_obd2'
LIMIT 3;

-- 2.3 Operador de Continência: @> ("Contém")
-- Verifica se o documento da esquerda contém a estrutura do lado direito:
SELECT
id_conserto,
laudo_jsonb -> 'sistema_afetado' AS sistema_afetado,
laudo_jsonb #> '{prioridade}' AS prioridade
FROM conserto
WHERE laudo_jsonb @> '{"sistema_afetado": "Injecao", "prioridade": "alta"}'::jsonb
LIMIT 5;

-- 2.4 SQL/JSON Path com jsonb_path_query
-- Permite aplicar filtros e predicados lógicos internamente nos elementos de arrays:
-- Extrai apenas as peças trocadas cujo valor unitário foi superior a R$ 400,00:
SELECT
id_conserto,
jsonb_path_query(laudo_jsonb, '$.pecas_trocadas[*] ? (@.custo > 400)') AS pecas_custo_alto,
jsonb_path_query(laudo_jsonb, '$.lote_peca ? (@ > 2)') AS lote_peca_maior_2
FROM conserto
WHERE id_conserto <= 5;

-- 2.5 Operador de Existência de Chaves: ? e ?|
-- Verifica se uma determinada chave de primeiro nível existe no documento semiestruturado:
SELECT
id_conserto,
laudo_jsonb ->> 'sistema_afetado' AS sistema,
laudo_jsonb ? 'telemetria_obd2'   AS tem_telemetria,
laudo_jsonb ? 'checklist_mecanico' AS tem_checklist
FROM conserto
LIMIT 5;

-- 2.6 Manipulação: Concatenação/Merge (||), Remoção (-) e Remoção por Caminho (#-)
-- A) Operador ||: adiciona uma nova chave ou substitui o valor de uma chave existente
SELECT
id_conserto,
laudo_jsonb || '{"prioridade": "alta", "garantia_dias": 90, "revisao_pendente": false}'::jsonb AS laudo_atualizado
FROM conserto
WHERE id_conserto = 1;

-- B) Operador -: remove uma chave de primeiro nível do documento
SELECT
id_conserto,
laudo_jsonb - 'aprovado_cliente' AS laudo_sem_aprovacao
FROM conserto
WHERE id_conserto = 1;

-- C) Operador #-: remove um nó ou campo em caminho aninhado profundo
SELECT
id_conserto,
laudo_jsonb #- '{telemetria_obd2, parametros}' AS telemetria_sem_tensao
FROM conserto
WHERE laudo_jsonb ? 'telemetria_obd2'
LIMIT 1;

-- =============================================================================
-- PARTE 3: COMPARAÇÃO DE DESEMPENHO (EXPLAIN ANALYZE)
-- JSON vs JSONB vs JSONB com GIN
-- =============================================================================

DROP INDEX IF EXISTS idx_conserto_laudo_gin;
ANALYZE conserto;

-- CENÁRIO A: Coluna JSON (Texto Puro)
-- No tipo JSON, o operador @> NÃO existe (geraria erro de sintaxe se executado).
-- É obrigatório extrair campo por campo usando ->> e comparar no SQL tradicional.
-- Como o banco armazena texto puro, precisa fazer o re-parse do texto nas linhas.
EXPLAIN ANALYZE
SELECT id_conserto, data
FROM conserto
WHERE laudo_json ->> 'sistema_afetado' = 'Injecao'
AND (laudo_json ->> 'lote_peca')::int = 42
AND laudo_json ->> 'ordem_servico' = 'OS-42';

-- CENÁRIO B: Coluna JSONB (Sem Índice GIN)
-- O tipo JSONB permite usar o operador estrutural @>, comparando árvores binárias.
-- Contudo, como ainda não criamos o índice GIN, o PostgreSQL ainda é forçado
-- a percorrer a tabela toda linha por linha.
EXPLAIN ANALYZE
SELECT id_conserto, data
FROM conserto
WHERE laudo_jsonb @> '{
"sistema_afetado": "Injecao",
"lote_peca": 42,
"ordem_servico": "OS-42"
}'::jsonb;

-- Criação do Índice Invertido GIN
CREATE INDEX idx_conserto_laudo_gin ON conserto USING GIN (laudo_jsonb);

-- CENÁRIO C: Coluna JSONB (Com Índice GIN)
-- Executamos exatamente a mesma query do Cenário B.
-- O otimizador de consultas identifica a presença do índice GIN e do operador @>.
EXPLAIN ANALYZE
SELECT id_conserto, data
FROM conserto
WHERE laudo_jsonb @> '{
"sistema_afetado": "Injecao",
"lote_peca": 42,
"ordem_servico": "OS-42"
}'::jsonb;