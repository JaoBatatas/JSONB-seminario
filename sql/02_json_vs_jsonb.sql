-- ============================================================================
-- DIFERENÇA PRÁTICA ENTRE JSON E JSONB
-- ============================================================================

DROP TABLE IF EXISTS demonstracao_tipos;

CREATE TABLE demonstracao_tipos (
    id SERIAL PRIMARY KEY,
    dados_json JSON,   -- Armazena cópia exata do texto de entrada
    dados_jsonb JSONB  -- Armazena em árvore binária decomposta
);

-- Inserindo exatamente a MESMA string com:
-- 1) Espaços em branco excessivos;
-- 2) Chaves fora de ordem ("z_chave" antes de "a_chave");
-- 3) Chave "preco" duplicada (valor 100 e depois valor 250).
INSERT INTO demonstracao_tipos (dados_json, dados_jsonb)
VALUES (
    '{  "z_chave": "teste",    "preco": 100,   "a_chave": 1,   "preco": 250  }',
    '{  "z_chave": "teste",    "preco": 100,   "a_chave": 1,   "preco": 250  }'
);

-- Compare o resultado abaixo no pgAdmin 4:
-- A coluna JSON manteve os espaços, a ordem original e as duas chaves "preco".
-- A coluna JSONB removeu espaços extras, desduplicou "preco" (manteve 250) e reordenou as chaves!
SELECT 
    dados_json, 
    dados_jsonb,
    pg_column_size(dados_json) AS bytes_json,
    pg_column_size(dados_jsonb) AS bytes_jsonb
FROM demonstracao_tipos;