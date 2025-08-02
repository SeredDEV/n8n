-- Tabla para rastrear las interacciones de botones de los clientes en WhatsApp
-- Permite mostrar solo los botones que el usuario aún no ha explorado

DROP TABLE IF EXISTS n8n_user_interactions CASCADE;

-- Crear tipo ENUM para los tipos de botones
DROP TYPE IF EXISTS tipo_boton CASCADE;
CREATE TYPE tipo_boton AS ENUM ('COMPRAR', 'CATALOGO', 'OFERTAS', 'CONSULTAR_PEDIDO');

-- Crear la tabla para rastrear interacciones (SIMPLIFICADA)
CREATE TABLE n8n_user_interactions (
    session_id VARCHAR(50) NOT NULL,
    tipo_boton tipo_boton NOT NULL,
    fecha_interaccion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraint para evitar duplicados de la misma interacción en la misma sesión
    PRIMARY KEY (session_id, tipo_boton)
);

-- ========================================
-- ÍNDICES PARA OPTIMIZAR CONSULTAS
-- ========================================

-- Índice principal por session_id para consultas rápidas
CREATE INDEX idx_user_interactions_session_id ON n8n_user_interactions(session_id);

-- Índice por fecha para reportes temporales
CREATE INDEX idx_user_interactions_fecha ON n8n_user_interactions(fecha_interaccion);

-- ========================================
-- FUNCIONES ÚTILES
-- ========================================

-- Función para registrar una nueva interacción (SIMPLIFICADA)
CREATE OR REPLACE FUNCTION registrar_interaccion(
    p_session_id VARCHAR(50),
    p_tipo_boton tipo_boton
) RETURNS BOOLEAN AS $$
BEGIN
    INSERT INTO n8n_user_interactions (session_id, tipo_boton)
    VALUES (p_session_id, p_tipo_boton)
    ON CONFLICT (session_id, tipo_boton) 
    DO UPDATE SET fecha_interaccion = CURRENT_TIMESTAMP;
    
    RETURN TRUE;
EXCEPTION
    WHEN OTHERS THEN
        RETURN FALSE;
END;
$$ LANGUAGE plpgsql;

-- Función para registrar usando el ID del botón (como viene de N8N)
CREATE OR REPLACE FUNCTION registrar_interaccion_por_id(
    p_session_id VARCHAR(50),
    p_boton_id VARCHAR(50)
) RETURNS BOOLEAN AS $$
BEGIN
    -- Si es el menú principal, restablecer y salir
    IF LOWER(p_boton_id) = 'menu' THEN
        DELETE FROM n8n_user_interactions WHERE session_id = p_session_id;
        RETURN TRUE;
    END IF;
    
    -- Para otros botones, registrar normalmente
    INSERT INTO n8n_user_interactions (session_id, tipo_boton)
    VALUES (
        p_session_id, 
        CASE LOWER(p_boton_id)
            WHEN 'comprar' THEN 'COMPRAR'::tipo_boton
            WHEN 'catalogo' THEN 'CATALOGO'::tipo_boton
            WHEN 'ofertas' THEN 'OFERTAS'::tipo_boton
            WHEN 'pedido' THEN 'CONSULTAR_PEDIDO'::tipo_boton
            ELSE NULL
        END
    )
    ON CONFLICT (session_id, tipo_boton) 
    DO UPDATE SET fecha_interaccion = CURRENT_TIMESTAMP;
    
    RETURN TRUE;
EXCEPTION
    WHEN OTHERS THEN
        RETURN FALSE;
END;
$$ LANGUAGE plpgsql;

-- Función para obtener botones NO explorados por un usuario
CREATE OR REPLACE FUNCTION obtener_botones_no_explorados(p_session_id VARCHAR(50))
RETURNS TABLE(boton_disponible tipo_boton) AS $$
BEGIN
    RETURN QUERY
    SELECT b.boton::tipo_boton
    FROM (
        VALUES 
            ('COMPRAR'::tipo_boton),
            ('CATALOGO'::tipo_boton),
            ('OFERTAS'::tipo_boton),
            ('CONSULTAR_PEDIDO'::tipo_boton)
    ) AS b(boton)
    WHERE b.boton NOT IN (
        SELECT tipo_boton 
        FROM n8n_user_interactions 
        WHERE session_id = p_session_id
    );
END;
$$ LANGUAGE plpgsql;

-- Función para obtener botones YA explorados por un usuario (SIMPLIFICADA)
CREATE OR REPLACE FUNCTION obtener_botones_explorados(p_session_id VARCHAR(50))
RETURNS TABLE(
    boton_explorado tipo_boton,
    fecha_exploracion TIMESTAMP
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        tipo_boton,
        fecha_interaccion
    FROM n8n_user_interactions 
    WHERE session_id = p_session_id
    ORDER BY fecha_interaccion DESC;
END;
$$ LANGUAGE plpgsql;

-- Función para obtener estadísticas de uso de botones
CREATE OR REPLACE FUNCTION estadisticas_botones()
RETURNS TABLE(
    tipo_boton tipo_boton,
    total_usos BIGINT,
    usuarios_unicos BIGINT,
    ultima_interaccion TIMESTAMP
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        n8n_user_interactions.tipo_boton,
        COUNT(*) as total_usos,
        COUNT(DISTINCT session_id) as usuarios_unicos,
        MAX(fecha_interaccion) as ultima_interaccion
    FROM n8n_user_interactions
    GROUP BY n8n_user_interactions.tipo_boton
    ORDER BY total_usos DESC;
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- COMENTARIOS Y DOCUMENTACIÓN
-- ========================================

COMMENT ON TABLE n8n_user_interactions IS 'Tabla para rastrear qué botones ha presionado cada cliente en WhatsApp';
COMMENT ON COLUMN n8n_user_interactions.session_id IS 'ID de sesión del cliente (mismo que en n8n_orders)';
COMMENT ON COLUMN n8n_user_interactions.tipo_boton IS 'Tipo de botón presionado: COMPRAR, CATALOGO, OFERTAS, CONSULTAR_PEDIDO';
COMMENT ON COLUMN n8n_user_interactions.fecha_interaccion IS 'Fecha y hora cuando se presionó el botón';

-- ========================================
-- FUNCIONES PARA RESTABLECER INTERACCIONES
-- ========================================

-- Función para restablecer (limpiar) todas las interacciones de un usuario
CREATE OR REPLACE FUNCTION restablecer_interacciones(p_session_id VARCHAR(50))
RETURNS BOOLEAN AS $$
BEGIN
    DELETE FROM n8n_user_interactions WHERE session_id = p_session_id;
    RETURN TRUE;
EXCEPTION
    WHEN OTHERS THEN
        RETURN FALSE;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION registrar_interaccion(VARCHAR, tipo_boton) IS 'Registra una nueva interacción de botón para un usuario';
COMMENT ON FUNCTION registrar_interaccion_por_id(VARCHAR, VARCHAR) IS 'Registra interacción usando el ID del botón (comprar, catalogo, ofertas, pedido, menu)';
COMMENT ON FUNCTION obtener_botones_no_explorados(VARCHAR) IS 'Devuelve los botones que el usuario AÚN NO ha presionado';
COMMENT ON FUNCTION obtener_botones_explorados(VARCHAR) IS 'Devuelve los botones que el usuario YA ha presionado';
COMMENT ON FUNCTION estadisticas_botones() IS 'Devuelve estadísticas de uso de todos los botones';
COMMENT ON FUNCTION restablecer_interacciones(VARCHAR) IS 'Restablece (borra) todas las interacciones de un usuario específico';

-- ========================================
-- FUNCIÓN JSON PARA N8N
-- ========================================

-- Función para obtener botones como JSON con menú principal dinámico
CREATE OR REPLACE FUNCTION obtener_botones_json(p_session_id VARCHAR(50))
RETURNS JSON AS $$
DECLARE
    result JSON;
    tiene_interacciones BOOLEAN;
BEGIN
    -- Verificar si el usuario ya ha presionado algún botón
    SELECT EXISTS (
        SELECT 1 FROM n8n_user_interactions WHERE session_id = p_session_id
    ) INTO tiene_interacciones;
    
    -- Obtener botones no explorados
    WITH botones_disponibles AS (
        SELECT 
            CASE boton_disponible
                WHEN 'COMPRAR' THEN json_build_object('id', 'comprar', 'label', '🛒 Comprar')
                WHEN 'CATALOGO' THEN json_build_object('id', 'catalogo', 'label', '📋 Catálogo')
                WHEN 'OFERTAS' THEN json_build_object('id', 'ofertas', 'label', '🔥 Ofertas')
                WHEN 'CONSULTAR_PEDIDO' THEN json_build_object('id', 'pedido', 'label', '📦 Consultar Pedido')
            END as boton_json
        FROM obtener_botones_no_explorados(p_session_id)
    ),
    todos_botones AS (
        SELECT boton_json FROM botones_disponibles
        UNION ALL
        -- Agregar menú principal solo si ya tiene interacciones
        SELECT json_build_object('id', 'menu', 'label', '🏠 Menú Principal') as boton_json
        WHERE tiene_interacciones = true
    )
    SELECT json_agg(boton_json) INTO result FROM todos_botones;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION obtener_botones_json(VARCHAR) IS 'Devuelve botones disponibles en JSON, agregando menú principal si ya exploró algo';

-- ========================================
-- EJEMPLOS DE USO (COMENTADOS)
-- ========================================

/*
-- EJEMPLOS CON MENÚ PRINCIPAL DINÁMICO:

-- USUARIO NUEVO (sin interacciones):
SELECT obtener_botones_json('session_nuevo');
-- Resultado: [comprar, catalogo, ofertas, pedido] (sin menú principal)

-- REGISTRAR UNA INTERACCIÓN:
SELECT registrar_interaccion_por_id('session_001', 'catalogo');

-- AHORA YA TIENE INTERACCIONES:
SELECT obtener_botones_json('session_001');
-- Resultado: [comprar, ofertas, pedido, menu] (con menú principal al final)

-- REGISTRAR OTRA INTERACCIÓN:
SELECT registrar_interaccion_por_id('session_001', 'ofertas');

-- VER BOTONES DISPONIBLES:
SELECT obtener_botones_json('session_001');
-- Resultado: [comprar, pedido, menu] (solo botones no explorados + menú)

-- PRESIONAR MENÚ PRINCIPAL (restablece todo):
SELECT registrar_interaccion_por_id('session_001', 'menu');

-- DESPUÉS DEL MENÚ, VUELVE AL INICIO:
SELECT obtener_botones_json('session_001');
-- Resultado: [comprar, catalogo, ofertas, pedido] (todos los botones, sin menú)

-- FUNCIONES MANUALES:
SELECT restablecer_interacciones('session_001');
SELECT * FROM obtener_botones_no_explorados('session_001');

-- RESTABLECER USUARIO:
SELECT restablecer_interacciones('session_001');
*/
