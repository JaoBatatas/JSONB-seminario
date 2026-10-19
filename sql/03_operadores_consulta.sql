-- ============================================================================
-- ARQUIVO 03: OPERADORES DE CONSULTA NO LAUDO DO CONSERTO (Requisito 2 e 4)
-- Operadores: ->, ->>, #>, #>>, @> e jsonb_path_query
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Operadores -> (retorna JSONB) e ->> (retorna TEXT) com JOIN Relacional
-- ----------------------------------------------------------------------------
-- Cruzando tabelas relacionais (mecanico, veiculo) com atributos dentro do JSONB:
SELECT 
    m.nome AS mecanico,
    v.modelo AS veiculo,
    c.data,
    c.laudo_jsonb -> 'telemetria_obd2' AS objeto_telemetria_jsonb, -- Retorna JSONB
    c.laudo_jsonb ->> 'prioridade' AS prioridade_texto             -- Retorna TEXT (sem aspas)
FROM conserto c
JOIN mecanico m ON m.codm = c.codm
JOIN veiculo v ON v.codv = c.codv
WHERE c.id_conserto <= 2;

-- ----------------------------------------------------------------------------
-- 2. Operadores de Caminho: #> (retorna JSONB) e #>> (retorna TEXT)
-- ----------------------------------------------------------------------------
-- Acessando elementos profundamente aninhados (objetos e arrays de peças):
SELECT 
    id_conserto,
    -- Extrai o RPM no momento da falha como JSONB
    laudo_jsonb #> '{telemetria_obd2, parametros, rpm_falha}' AS rpm_falha_jsonb,
    -- Extrai o nome e fabricante da primeira peça trocada (índice 0 do array) como TEXTO
    laudo_jsonb #>> '{pecas_trocadas, 0, nome}' AS primeira_peca_trocada,
    laudo_jsonb #>> '{pecas_trocadas, 0, fabricante}' AS fabricante_peca
FROM conserto
WHERE id_conserto <= 2;

-- ----------------------------------------------------------------------------
-- 3. Operador de Continência: @> ("Contém")
-- ----------------------------------------------------------------------------
-- Buscando todos os consertos onde o scanner OBD2 acusou a falha "P0300" (Falha de ignição)
-- E utilizou alguma peça do fabricante "Bosch":
SELECT id_conserto, codm, codv, data, laudo_jsonb -> 'pecas_trocadas' AS pecas
FROM conserto
WHERE laudo_jsonb @> '{
    "telemetria_obd2": {"codigos_falha_dtc": ["P0300"]},
    "pecas_trocadas": [{"fabricante": "Bosch"}]
}'::jsonb;

-- ----------------------------------------------------------------------------
-- 4. Consulta Avançada com SQL/JSON Path: jsonb_path_query
-- ----------------------------------------------------------------------------
-- Filtrando internamente no array de peças trocadas apenas aquelas cujo custo
-- foi superior a R$ 300,00:
SELECT 
    id_conserto,
    data,
    jsonb_path_query(laudo_jsonb, '$.pecas_trocadas[*] ? (@.custo > 300)') AS pecas_caras
FROM conserto
WHERE id_conserto <= 2;