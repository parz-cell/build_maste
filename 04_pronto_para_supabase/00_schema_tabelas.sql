CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE IF NOT EXISTS categorias (
    id SMALLSERIAL PRIMARY KEY,
    slug VARCHAR(32) NOT NULL UNIQUE,
    nome VARCHAR(64) NOT NULL,
    obrigatorio_na_build BOOLEAN NOT NULL DEFAULT TRUE,
    criado_em TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO categorias (slug, nome, obrigatorio_na_build) VALUES
    ('CPU', 'Processador', TRUE),
    ('MOTHERBOARD', 'Placa-Mãe', TRUE),
    ('RAM', 'Memória RAM', TRUE),
    ('GPU', 'Placa de Vídeo', FALSE),
    ('STORAGE', 'Armazenamento (SSD/HDD)', TRUE),
    ('CASE', 'Gabinete', TRUE),
    ('PSU', 'Fonte de Alimentação', TRUE),
    ('COOLER', 'Cooler de Processador', TRUE)
ON CONFLICT (slug) DO NOTHING;

CREATE TABLE IF NOT EXISTS componentes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    categoria_slug VARCHAR(32) NOT NULL REFERENCES categorias(slug) ON UPDATE CASCADE,
    nome VARCHAR(255) NOT NULL,
    fabricante VARCHAR(100) NOT NULL,
    part_number VARCHAR(100) UNIQUE,
    preco_centavos INTEGER CHECK (preco_centavos >= 0),
    tdp_watts INTEGER NOT NULL DEFAULT 0 CHECK (tdp_watts >= 0),
    especificacoes JSONB NOT NULL,
    ativo BOOLEAN NOT NULL DEFAULT TRUE,
    criado_em TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    atualizado_em TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_especificacoes_objeto CHECK (jsonb_typeof(especificacoes) = 'object')
);

CREATE INDEX IF NOT EXISTS idx_componentes_specs_gin ON componentes USING GIN (especificacoes jsonb_path_ops);
CREATE INDEX IF NOT EXISTS idx_componentes_socket ON componentes ((especificacoes ->> 'socket')) WHERE categoria_slug IN ('CPU', 'MOTHERBOARD');
CREATE INDEX IF NOT EXISTS idx_componentes_ram_type ON componentes ((especificacoes ->> 'memory_type')) WHERE categoria_slug IN ('MOTHERBOARD', 'RAM');
CREATE INDEX IF NOT EXISTS idx_componentes_categoria_ativo ON componentes (categoria_slug, ativo);
