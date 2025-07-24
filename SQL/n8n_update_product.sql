DROP TABLE IF EXISTS n8n_update_product;

CREATE TABLE n8n_update_product (
    id SERIAL PRIMARY KEY,
    session_id VARCHAR(255),
    product VARCHAR(255)
);

CREATE INDEX idx_session_id ON n8n_update_product(session_id);
CREATE INDEX idx_product ON n8n_update_product(product);

-- Función para insertar un registro en n8n_update_product
-- Ahora limpia automáticamente el emoji '🧴 ' del producto
CREATE OR REPLACE FUNCTION insert_n8n_update_product(p_session_id VARCHAR, p_product VARCHAR)
RETURNS VOID AS $$
BEGIN
    INSERT INTO n8n_update_product (session_id, product)
    VALUES (p_session_id, TRIM(REPLACE(p_product, '🧴 ', '')));
END;
$$ LANGUAGE plpgsql;

-- Insertar varios productos para diferentes sesiones
-- SELECT insert_n8n_update_product('session_456', 'iPhone 14 Pro');

-- 1. Function to query products by session_id
CREATE OR REPLACE FUNCTION get_products_by_session(p_session_id VARCHAR)
RETURNS TABLE(
    id INTEGER,
    session_id VARCHAR(255),
    product VARCHAR(255)
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        n.id,
        n.session_id,
        n.product
    FROM n8n_update_product n
    WHERE n.session_id = p_session_id
    ORDER BY n.id;
END;
$$ LANGUAGE plpgsql;

-- 2. Function to delete products by session_id
CREATE OR REPLACE FUNCTION delete_products_by_session(p_session_id VARCHAR)
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM n8n_update_product
    WHERE session_id = p_session_id;

    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;



