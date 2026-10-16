-- ============================================================================
-- CRIAÇÃO E POPULAÇÃO DO BANCO DE DADOS
-- Caso de Uso: Catálogo de E-commerce com Atributos Variáveis
-- ============================================================================

DROP TABLE IF EXISTS demonstracao_tipos;
DROP TABLE IF EXISTS produtos;

-- 1. Criação da tabela principal com modelagem híbrida:
-- Atributos fixos e transacionais em colunas relacionais;
-- Atributos dinâmicos que mudam conforme a categoria em JSONB.
CREATE TABLE produtos (
    id SERIAL PRIMARY KEY,
    sku VARCHAR(50) UNIQUE NOT NULL,
    nome VARCHAR(150) NOT NULL,
    categoria VARCHAR(50) NOT NULL,
    preco NUMERIC(10, 2) NOT NULL,
    atributos JSONB NOT NULL
);

-- 2. Inserção de documentos ricos e aninhados para demonstração dos operadores
INSERT INTO produtos (sku, nome, categoria, preco, atributos) VALUES
(
    'GPU-RTX4070',
    'Placa de Vídeo RTX 4070 Super',
    'Hardware',
    4299.90,
    '{
        "marca": "NVIDIA",
        "fabricante": "ASUS",
        "codigo_serie": "NV-999999",
        "especificacoes": {
            "vram_gb": 12,
            "tipo_memoria": "GDDR6X",
            "consumo_w": 220,
            "saidas_video": ["HDMI 2.1", "DisplayPort 1.4a"]
        },
        "avaliacoes": [
            {"usuario": "carlos_dev", "nota": 5, "comentario": "Excelente para 1440p"},
            {"usuario": "ana_gamer", "nota": 4, "comentario": "Esquenta um pouco em full load"}
        ],
        "entrega_expressa": true
    }'::jsonb
),
(
    'MON-LG27',
    'Monitor Gamer UltraGear 27"',
    'Periféricos',
    1599.00,
    '{
        "marca": "LG",
        "codigo_serie": "LG-888888",
        "especificacoes": {
            "painel": "IPS",
            "taxa_atualizacao_hz": 144,
            "resolucao": "2560x1440",
            "conexoes": ["HDMI", "DisplayPort", "USB Hub"]
        },
        "avaliacoes": [
            {"usuario": "pedro99", "nota": 5, "comentario": "Cores incríveis e sem ghosting"},
            {"usuario": "lucas_sc", "nota": 3, "comentario": "Base ocupa muito espaço na mesa"}
        ],
        "entrega_expressa": false
    }'::jsonb
),
(
    'NOTE-DELL15',
    'Notebook Dell Inspiron 15',
    'Computadores',
    3899.00,
    '{
        "marca": "Dell",
        "codigo_serie": "DL-777777",
        "especificacoes": {
            "processador": "Intel Core i7",
            "ram_gb": 16,
            "armazenamento": {"tipo": "SSD NVMe", "capacidade_gb": 512}
        },
        "avaliacoes": [
            {"usuario": "mariana_ti", "nota": 5, "comentario": "Ótimo para compilar projetos grandes"}
        ],
        "entrega_expressa": true
    }'::jsonb
);

-- 3. População de 200.000 registros sintéticos para o teste de performance (Índice GIN)
-- Nota: Incluímos o campo "codigo_serie" único e combinações variadas para testar seletividade.
INSERT INTO produtos (sku, nome, categoria, preco, atributos)
SELECT 
    'SKU-' || i,
    'Produto Sintético ' || i,
    CASE WHEN i % 2 = 0 THEN 'Hardware' ELSE 'Periféricos' END,
    ROUND((RANDOM() * 5000 + 100)::numeric, 2),
    jsonb_build_object(
        'marca', (ARRAY['Dell', 'ASUS', 'LG', 'Samsung', 'Logitech', 'Corsair'])[floor(random()*6)+1],
        'lote', i % 1000,
        'codigo_serie', 'SN-' || i,
        'especificacoes', jsonb_build_object(
            'garantia_meses', (ARRAY[12, 24, 36])[floor(random()*3)+1],
            'peso_gramas', (i % 2500) + 100
        ),
        'tags', jsonb_build_array('catalogo_2026', 'tag_' || (i % 200))
    )
FROM generate_series(1, 200000) AS s(i);

-- Atualiza as estatísticas da tabela para o Query Planner do PostgreSQL
ANALYZE produtos;

-- Confirmação da quantidade total de registros (deve retornar 200.003)
SELECT COUNT(*) AS total_produtos_inseridos FROM produtos;