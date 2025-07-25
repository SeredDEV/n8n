DROP TABLE IF EXISTS n8n_update_data_user CASCADE;

CREATE TABLE n8n_update_data_user (
    id SERIAL PRIMARY KEY,
    session_id VARCHAR(255),
    data_id VARCHAR(255)
);

-- Drop y crear índices
DROP INDEX IF EXISTS idx_session_id;
DROP INDEX IF EXISTS idx_data_id;
CREATE INDEX idx_session_id ON n8n_update_data_user(session_id);
CREATE INDEX idx_data_id ON n8n_update_data_user(data_id);

-- Drop y crear función para insertar datos
DROP FUNCTION IF EXISTS insert_n8n_update_data_user(VARCHAR, VARCHAR);
CREATE OR REPLACE FUNCTION insert_n8n_update_data_user(p_session_id VARCHAR, p_data_id VARCHAR)
RETURNS VOID AS $$
DECLARE
    cleaned_data_id VARCHAR;
BEGIN
    -- Limpiar emojis específicos y espacios extra del data_id
    cleaned_data_id := TRIM(p_data_id);

    -- Remover emojis específicos
    cleaned_data_id := REPLACE(cleaned_data_id, '👤 ', '');
    cleaned_data_id := REPLACE(cleaned_data_id, '👤', '');
    cleaned_data_id := REPLACE(cleaned_data_id, '📱 ', '');
    cleaned_data_id := REPLACE(cleaned_data_id, '📱', '');
    cleaned_data_id := REPLACE(cleaned_data_id, '📍 ', '');
    cleaned_data_id := REPLACE(cleaned_data_id, '📍', '');
    cleaned_data_id := REPLACE(cleaned_data_id, '🏙️ ', '');
    cleaned_data_id := REPLACE(cleaned_data_id, '🏙️', '');
    cleaned_data_id := REPLACE(cleaned_data_id, '📧 ', '');
    cleaned_data_id := REPLACE(cleaned_data_id, '📧', '');

    -- Limpiar espacios extra que puedan quedar
    cleaned_data_id := TRIM(cleaned_data_id);

    INSERT INTO n8n_update_data_user (session_id, data_id)
    VALUES (p_session_id, cleaned_data_id);
END;
$$ LANGUAGE plpgsql;

-- Drop y crear función para eliminar datos por session_id
DROP FUNCTION IF EXISTS delete_data_by_session(VARCHAR);
CREATE OR REPLACE FUNCTION delete_data_by_session(p_session_id VARCHAR)
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM n8n_update_data_user
    WHERE session_id = p_session_id;

    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- EJEMPLOS DE USO
-- ========================================

-- Ejemplo 1: Insertar datos con emojis específicos
-- SELECT insert_n8n_update_data_user('session_123', '👤 Juan Pérez');
-- SELECT insert_n8n_update_data_user('session_123', '📱 +1234567890');
-- SELECT insert_n8n_update_data_user('session_123', '📍 Calle Principal 123');
-- SELECT insert_n8n_update_data_user('session_123', '🏙️ Ciudad de México');
-- SELECT insert_n8n_update_data_user('session_123', '📧 usuario@email.com');
-- Resultado: Se guardan los datos sin los emojis

-- Ejemplo 2: Eliminar todos los datos de una sesión
-- SELECT delete_data_by_session('session_123');
-- Resultado: Retorna el número de registros eliminados
-- EJEMPLOS DE USO
-- ========================================

-- Ejemplo 1: Insertar datos con emoji ✏️
-- SELECT insert_n8n_update_data_user('session_123', '✏️ usuario_datos_456');
-- Resultado: Se guarda 'usuario_datos_456' (sin el emoji)

-- Ejemplo 2: Eliminar todos los datos de una sesión
-- SELECT delete_data_by_session('session_123');
-- Resultado: Retorna el número de registros eliminados