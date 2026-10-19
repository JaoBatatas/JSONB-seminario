-- ============================================================================
-- ARQUIVO 01: SETUP DA BASE OFICINA MECÂNICA COM JSON E JSONB
-- ============================================================================

DROP TABLE IF EXISTS conserto;
DROP TABLE IF EXISTS veiculo;
DROP TABLE IF EXISTS cliente;
DROP TABLE IF EXISTS mecanico;
DROP TABLE IF EXISTS setor;

-- 1. Tabela Setor
CREATE TABLE setor (
  cods integer NOT NULL,
  nome character varying(50),
  CONSTRAINT setor_pkey PRIMARY KEY (cods)
);

-- 2. Tabela Mecânico
CREATE TABLE mecanico (
  codm serial NOT NULL,
  cpf char(11),
  nome character varying(50),
  idade integer,
  endereco character varying(500),
  cidade character varying(500),
  funcao character varying(50),
  cods integer,
  CONSTRAINT mecanico_pkey PRIMARY KEY (codm),
  CONSTRAINT mecanico_cods_fkey FOREIGN KEY (cods)
      REFERENCES setor (cods) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE SET NULL
);

-- 3. Tabela Cliente
CREATE TABLE cliente (
  codc integer NOT NULL,
  cpf char(11),
  nome character varying(50),
  idade integer,
  endereco character varying(500),
  cidade character varying(500),
  CONSTRAINT cliente_pkey PRIMARY KEY (codc) 
);

-- 4. Tabela Veículo
CREATE TABLE veiculo (
  codv integer NOT NULL,
  renavam char(10),
  modelo character varying(50),
  marca character varying(50),
  ano integer,
  quilometragem float,
  codc integer,
  CONSTRAINT veiculo_pkey PRIMARY KEY (codv),
  CONSTRAINT veiculo_codc_fkey FOREIGN KEY (codc)
      REFERENCES cliente (codc) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE SET NULL
);

-- 5. Tabela Conserto (ADAPTADA COM LAUDO EM JSON E JSONB)
-- Adicionamos um id_conserto serial para facilitar buscas diretas e mantivemos
-- os mesmos dados nas duas colunas (laudo_json e laudo_jsonb) para comparação.
CREATE TABLE conserto (
  id_conserto serial NOT NULL,
  codm integer NOT NULL,
  codv integer NOT NULL,
  data date NOT NULL,
  hora time without time zone,
  laudo_json JSON,     -- Armazena como texto puro
  laudo_jsonb JSONB,   -- Armazena em formato binário decomposto
  CONSTRAINT consulta_pkey PRIMARY KEY (codm, codv, data),
  CONSTRAINT consulta_codm_fkey FOREIGN KEY (codm)
      REFERENCES mecanico (codm) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT consulta_codv_fkey FOREIGN KEY (codv)
      REFERENCES veiculo (codv) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE CASCADE
);

-- ============================================================================
-- POPULAÇÃO DAS TABELAS BASE
-- ============================================================================

INSERT INTO setor (cods, nome) VALUES 
(1, 'Motor e Transmissão'),
(2, 'Injeção Eletrônica e Diagnóstico'),
(3, 'Suspensão e Freios');

INSERT INTO mecanico (codm, cpf, nome, idade, endereco, cidade, funcao, cods) VALUES
(1, '11111111111', 'Carlos Silva', 38, 'Rua XV de Novembro, 100', 'Joinville', 'Especialista em Injeção', 2),
(2, '22222222222', 'Marcos Oliveira', 45, 'Av. Beira Rio, 500', 'Joinville', 'Mecânico Chefe', 1),
(3, '33333333333', 'Roberto Souza', 29, 'Rua Blumenau, 250', 'Joinville', 'Alinhador', 3);

INSERT INTO cliente (codc, cpf, nome, idade, endereco, cidade) VALUES
(1, '44444444444', 'João Paulo', 22, 'Rua Dona Francisca, 1200', 'Joinville'),
(2, '55555555555', 'Ana Beatriz', 31, 'Rua das Palmeiras, 45', 'Florianópolis');

-- Inserindo 200 veículos para distribuir os consertos
INSERT INTO veiculo (codv, renavam, modelo, marca, ano, quilometragem, codc)
SELECT 
    i,
    LPAD(i::text, 10, '0'),
    (ARRAY['Civic', 'Corolla', 'Golf', 'Onix', 'Compass', 'Ranger'])[floor(random()*6)+1],
    (ARRAY['Honda', 'Toyota', 'VW', 'Chevrolet', 'Jeep', 'Ford'])[floor(random()*6)+1],
    2015 + (i % 11),
    (i * 1500.5),
    CASE WHEN i % 2 = 0 THEN 1 ELSE 2 END
FROM generate_series(1, 200) AS s(i);

-- ============================================================================
-- INSERÇÃO DOS CONSERTOS DETALHADOS (COM ESPELHAMENTO JSON E JSONB)
-- ============================================================================

-- Inserindo 2 consertos reais ricos em detalhes (com espaços extras e chaves duplicadas
-- propositais na string de entrada para demonstrar a diferença entre JSON e JSONB)
WITH dados_entrada AS (
    SELECT 
        1 AS codm, 1 AS codv, '2026-01-01'::date AS data, '08:30:00'::time AS hora,
        '{
            "z_observacao": "Cliente relatou perda de potencia",
            "prioridade": "baixa",
            "prioridade": "alta",
            "telemetria_obd2": {
                "protocolo": "CAN_11BIT_500K",
                "codigos_falha_dtc": ["P0300", "P0171"],
                "parametros": {"rpm_falha": 3200, "temp_motor_c": 98}
            },
            "pecas_trocadas": [
                {"nome": "Jogo de Velas Iridium", "fabricante": "NGK", "custo": 280.00},
                {"nome": "Bico Injetor", "fabricante": "Bosch", "custo": 450.00}
            ],
            "aprovado_cliente": true
        }' AS doc_texto
    UNION ALL
    SELECT 
        2, 2, '2026-01-02'::date, '14:00:00'::time,
        '{
            "z_observacao": "Barulho na suspensao dianteira",
            "prioridade": "media",
            "checklist_suspensao": {
                "amortecedores": "condenados",
                "buchas_bandeja": "ok",
                "folga_axial_mm": 2.5
            },
            "pecas_trocadas": [
                {"nome": "Par Amortecedor Dianteiro", "fabricante": "Cofap", "custo": 890.00},
                {"nome": "Kit Batente", "fabricante": "Axios", "custo": 140.00}
            ],
            "aprovado_cliente": true
        }'
)
INSERT INTO conserto (codm, codv, data, hora, laudo_json, laudo_jsonb)
SELECT codm, codv, data, hora, doc_texto::json, doc_texto::jsonb FROM dados_entrada;

-- ============================================================================
-- POPULAÇÃO EM MASSA: 200.000 CONSERTOS PARA BENCHMARK (JSON vs JSONB)
-- ============================================================================
-- Gerando 200.000 registros combinando 200 veículos x 1.000 datas diferentes
INSERT INTO conserto (codm, codv, data, hora, laudo_json, laudo_jsonb)
SELECT 
    (i % 3) + 1 AS codm,
    (i % 200) + 1 AS codv,
    ('2020-01-01'::date + ((i / 200) || ' days')::interval)::date AS data,
    '10:00:00'::time AS hora,
    doc::json AS laudo_json,
    doc::jsonb AS laudo_jsonb
FROM (
    SELECT 
        i,
        jsonb_build_object(
            'ordem_servico', 'OS-' || i,
            'sistema_afetado', (ARRAY['Injecao', 'Freios', 'Motor', 'Transmissao', 'Eletrica'])[floor(random()*5)+1],
            'lote_peca', i % 500,
            'telemetria_obd2', jsonb_build_object(
                'codigo_principal', 'P0' || ((i % 899) + 100),
                'tensao_bateria_v', ROUND((11.5 + random() * 3)::numeric, 1),
                'temp_motor_c', (i % 60) + 70
            ),
            'pecas_trocadas', jsonb_build_array(
                jsonb_build_object(
                    'nome', 'Componente_' || (i % 50),
                    'fabricante', (ARRAY['Bosch', 'NGK', 'Cofap', 'Delphi', 'Mahle'])[floor(random()*5)+1],
                    'custo', ROUND((random() * 900 + 50)::numeric, 2)
                )
            )
        )::text AS doc
    FROM generate_series(1, 200000) AS s(i)
) sub;

ANALYZE conserto;

SELECT COUNT(*) AS total_consertos FROM conserto;