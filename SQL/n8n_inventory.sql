-- Habilita la extensión pg_trgm para búsquedas fuzzy
CREATE EXTENSION IF NOT EXISTS pg_trgm;

DROP TABLE IF EXISTS n8n_inventory;

CREATE TABLE n8n_inventory (
    id SERIAL PRIMARY KEY,
    nombre_locion VARCHAR(255) NOT NULL,
    marca_fabricante VARCHAR(255),
    descripcion_aroma VARCHAR(255),
    ocasion_principal VARCHAR(255),
    ocasion_secundaria VARCHAR(255),
    categoria VARCHAR(50),
    estacion_recomendada VARCHAR(100),
    momento_dia VARCHAR(100),
    intensidad INTEGER CHECK (intensidad >= 1 AND intensidad <= 10),
    duracion_estimada VARCHAR(100),
    contenido_ml INTEGER,
    precio_venta INTEGER,
    disponible VARCHAR(10),
    url_imagen TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Eliminar índices existentes si existen
DROP INDEX IF EXISTS idx_n8n_inventory_nombre_locion;
DROP INDEX IF EXISTS idx_n8n_inventory_marca_fabricante;
DROP INDEX IF EXISTS idx_n8n_inventory_categoria;
DROP INDEX IF EXISTS idx_n8n_inventory_disponible;
DROP INDEX IF EXISTS idx_n8n_inventory_intensidad;
DROP INDEX IF EXISTS idx_n8n_inventory_nombre_locion_fuzzy;
DROP INDEX IF EXISTS idx_n8n_inventory_marca_fabricante_fuzzy;
DROP INDEX IF EXISTS idx_n8n_inventory_descripcion_aroma_fuzzy;
DROP INDEX IF EXISTS idx_n8n_inventory_ocasion_principal_fuzzy;
DROP INDEX IF EXISTS idx_n8n_inventory_ocasion_secundaria_fuzzy;
DROP INDEX IF EXISTS idx_n8n_inventory_categoria_fuzzy;
DROP INDEX IF EXISTS idx_n8n_inventory_estacion_recomendada_fuzzy;
DROP INDEX IF EXISTS idx_n8n_inventory_momento_dia_fuzzy;

-- Crear índices para búsquedas exactas
CREATE INDEX idx_n8n_inventory_nombre_locion ON n8n_inventory(nombre_locion);
CREATE INDEX idx_n8n_inventory_marca_fabricante ON n8n_inventory(marca_fabricante);
CREATE INDEX idx_n8n_inventory_categoria ON n8n_inventory(categoria);
CREATE INDEX idx_n8n_inventory_disponible ON n8n_inventory(disponible);
CREATE INDEX idx_n8n_inventory_intensidad ON n8n_inventory(intensidad);

-- Crear índices para búsquedas fuzzy usando pg_trgm
CREATE INDEX idx_n8n_inventory_nombre_locion_fuzzy ON n8n_inventory USING gin(nombre_locion gin_trgm_ops);
CREATE INDEX idx_n8n_inventory_marca_fabricante_fuzzy ON n8n_inventory USING gin(marca_fabricante gin_trgm_ops);
CREATE INDEX idx_n8n_inventory_descripcion_aroma_fuzzy ON n8n_inventory USING gin(descripcion_aroma gin_trgm_ops);
CREATE INDEX idx_n8n_inventory_ocasion_principal_fuzzy ON n8n_inventory USING gin(ocasion_principal gin_trgm_ops);
CREATE INDEX idx_n8n_inventory_ocasion_secundaria_fuzzy ON n8n_inventory USING gin(ocasion_secundaria gin_trgm_ops);
CREATE INDEX idx_n8n_inventory_categoria_fuzzy ON n8n_inventory USING gin(categoria gin_trgm_ops);
CREATE INDEX idx_n8n_inventory_estacion_recomendada_fuzzy ON n8n_inventory USING gin(estacion_recomendada gin_trgm_ops);
CREATE INDEX idx_n8n_inventory_momento_dia_fuzzy ON n8n_inventory USING gin(momento_dia gin_trgm_ops);




