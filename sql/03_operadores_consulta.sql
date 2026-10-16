-- ============================================================================
-- OPERADORES DE CONSULTA EM DOCUMENTOS ANINHADOS
-- Operadores: ->, ->>, #>, #>>, @> e jsonb_path_query
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Operadores -> (retorna JSONB) vs. ->> (retorna TEXT)
-- ----------------------------------------------------------------------------
-- Repare no cabeçalho da coluna no pgAdmin 4 e nas aspas:
-- '->' devolve um objeto/valor JSONB (strings vêm com aspas: "NVIDIA")
-- '->>' extrai o valor escalar como TEXTO puro (sem aspas: NVIDIA)
SELECT 
    sku,
    nome,
    atributos -> 'marca' AS marca_como_jsonb,
    atributos ->> 'marca' AS marca_como_texto,
    atributos -> 'especificacoes' -> 'vram_gb' AS vram_encadeada
FROM produtos
WHERE id <= 3;

-- ----------------------------------------------------------------------------
-- 2. Operadores de Caminho: #> (retorna JSONB) e #>> (retorna TEXT)
-- ----------------------------------------------------------------------------
-- Ideais para navegar diretamente em objetos profundos ou índices de arrays
-- sem precisar encadear vários '->'.
SELECT 
    sku,
    nome,
    -- Navega no objeto aninhado: especificacoes -> armazenamento -> tipo
    atributos #> '{especificacoes, armazenamento}' AS obj_armazenamento_jsonb,
    -- Navega no array de 'avaliacoes', pega o índice 0 (primeira avaliação) e extrai o 'usuario' como texto
    atributos #>> '{avaliacoes, 0, usuario}' AS primeiro_avaliador,
    atributos #>> '{avaliacoes, 0, comentario}' AS comentario_primeiro_avaliador
FROM produtos
WHERE id <= 3;

-- ----------------------------------------------------------------------------
-- 3. Operador de Continência: @> ("Contém")
-- ----------------------------------------------------------------------------
-- Verifica se o documento da esquerda contém o sub-documento JSONB da direita.
-- É o operador mais importante para filtragem pois utiliza índices GIN!
SELECT id, sku, nome, preco, atributos -> 'especificacoes' AS specs
FROM produtos
WHERE atributos @> '{"marca": "NVIDIA", "especificacoes": {"vram_gb": 12}}'::jsonb;

-- ----------------------------------------------------------------------------
-- 4. Consultas Avançadas com SQL/JSON Path: jsonb_path_query
-- ----------------------------------------------------------------------------
-- Permite filtrar arrays internos usando expressões lógicas (como @.nota == 5).
-- Exemplo: Extrair apenas os objetos de avaliação cuja nota seja máxima (5):
SELECT 
    sku,
    nome,
    jsonb_path_query(atributos, '$.avaliacoes[*] ? (@.nota == 5)') AS avaliacoes_nota_5
FROM produtos
WHERE id <= 3;