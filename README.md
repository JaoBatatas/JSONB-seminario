# Seminário BAN2002 — Tema 01: JSONB e Dados Semiestruturados no PostgreSQL

Repositório contendo os artefatos práticos do seminário da disciplina **Banco de Dados II (BAN2002)** do curso de Ciência da Computação da **UDESC Joinville (CCT)**, ministrada pelo Prof. Fabiano Baldo.

## 📌 Sobre o Tema
O PostgreSQL suporta nativamente o armazenamento de documentos JSON por meio dos tipos `JSON` e `JSONB`. Este repositório demonstra na prática:
1. A diferença interna e comportamental entre `JSON` (texto puro) e `JSONB` (binário decomposto).
2. Modelagem híbrida (Relacional + Documento) aplicada a um **Catálogo de E-commerce com Atributos Variáveis**, substituindo o complexo padrão relacional EAV (*Entity-Attribute-Value*).
3. Consultas em documentos aninhados utilizando os operadores `->`, `->>`, `#>`, `#>>`, `@>` e expressões SQL/JSON Path com `jsonb_path_query`.
4. Análise de desempenho (`EXPLAIN ANALYZE`) comparando varreduras sequenciais (*Seq Scan*) com buscas indexadas via **GIN Index** (*Generalized Inverted Index*).

---

## 📂 Estrutura dos Scripts SQL

Os scripts na pasta `/sql` foram numerados na ordem exata de execução:

* **`01_setup_e_populacao.sql`**: Cria a tabela `produtos`, insere os produtos reais de demonstração e gera **200.000 documentos sintéticos** para o teste de carga e performance.
* **`02_json_vs_jsonb.sql`**: Demonstra na prática a diferença de armazenamento (espaços em branco, ordenação de chaves e chaves duplicadas) entre as colunas `JSON` e `JSONB`.
* **`03_operadores_consulta.sql`**: Exemplos práticos e comentados de todos os operadores exigidos (`->`, `->>`, `#>`, `#>>`, `@>` e `jsonb_path_query`).
* **`04_indice_gin_benchmark.sql`**: Script de benchmark com `EXPLAIN ANALYZE` demonstrando a queda no tempo de execução de dezenas de milissegundos para menos de **1 ms** após a criação do índice GIN.

---

## 🚀 Como Executar (pgAdmin 4)

1. Abra o **pgAdmin 4** e crie um novo banco de dados (ex: `seminario_jsonb`).
2. Clique com o botão direito sobre o banco criado e selecione **Query Tool**.
3. Abra e execute primeiro o arquivo `sql/01_setup_e_populacao.sql` (`F5`) para preparar o ambiente.
4. Abra os arquivos `02`, `03` e `04` em abas separadas da *Query Tool*, selecionando os blocos de código individualmente e pressionando `F5` para executar passo a passo.

---

## 📊 Resumo dos Resultados do Benchmark (200.000 Registros)

| Cenário | Plano de Execução (PostgreSQL) | Tempo Médio de Execução |
| :--- | :--- | :--- |
| **Sem Índice** | `Seq Scan` / `Parallel Seq Scan` (Varredura completa da tabela) | ~45 ms a 75 ms |
| **Com Índice GIN (`jsonb_ops`)** | `Bitmap Heap Scan` + `Bitmap Index Scan` | **~0.08 ms a 0.35 ms** |

---

## 📚 Referências Principais
* [PostgreSQL Documentation — JSON Types (8.14)](https://www.postgresql.org/docs/current/datatype-json.html)
* [PostgreSQL Documentation — JSON Functions and Operators (9.16)](https://www.postgresql.org/docs/current/functions-json.html)
* [Mastering PostgreSQL JSONB type in one article — Logto Blog](https://blog.logto.io/mastering-postgresql-jsonb)
* [PostgreSQL as a JSON Database: Advanced Patterns — AWS Database Blog](https://aws.amazon.com/blogs/database/postgresql-as-a-json-database-advanced-patterns-and-best-practices/)