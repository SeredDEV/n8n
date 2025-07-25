-- Active: 1753324294589@@31.97.149.15@5432@n8ndb
-- Eliminar tabla si existe
DROP TABLE IF EXISTS n8n_orders CASCADE;

-- Eliminar tipo enum si existe
DROP TYPE IF EXISTS estado_pedido CASCADE;

-- Eliminar funciones si existen
DROP FUNCTION IF EXISTS cambiar_estado_pedido(VARCHAR, estado_pedido) CASCADE;
DROP FUNCTION IF EXISTS cambiar_estado_pedido_por_id(INTEGER, estado_pedido) CASCADE;

-- Crear el tipo ENUM para los estados de pedidos
CREATE TYPE estado_pedido AS ENUM ('CREADO', 'GENERANDO', 'ENVIADO');

-- Crear la tabla n8n_orders
CREATE TABLE n8n_orders (
    id SERIAL PRIMARY KEY,
    session_id VARCHAR(50) NOT NULL,
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    estado estado_pedido DEFAULT 'CREADO',

    -- DATOS DEL CLIENTE
    nombre_cliente VARCHAR(100) NULL,
    telefono VARCHAR(20) NULL,
    email VARCHAR(150) NULL,
    ciudad VARCHAR(50) NULL,
    direccion TEXT NULL,

    -- INFORMACIÓN DE VENTA
    pago VARCHAR(30) NULL,
    total_producto INTEGER NULL,
    total_envio INTEGER NULL,
    cantidad_total INTEGER NULL,
    guia VARCHAR(100) NULL,

    -- DATOS DE PRODUCTOS (JSON)
    productos_info JSONB NULL

    -- NOTA: Se permite múltiples pedidos con el mismo session_id
);

-- ========================================
-- VALIDAR Y ELIMINAR RESTRICCIÓN UNIQUE SI EXISTE
-- ========================================

DO $$
BEGIN
    -- Verificar si existe la restricción unique_session_id
    IF EXISTS (
        SELECT 1
        FROM information_schema.table_constraints
        WHERE constraint_name = 'unique_session_id'
        AND table_name = 'n8n_orders'
        AND table_schema = current_schema()
    ) THEN
        -- Eliminar la restricción si existe
        ALTER TABLE n8n_orders DROP CONSTRAINT unique_session_id;
        RAISE NOTICE 'ÉXITO: Restricción unique_session_id eliminada - Ahora se permiten múltiples pedidos por session_id';
    ELSE
        RAISE NOTICE 'INFO: La restricción unique_session_id no existe - Múltiples pedidos permitidos';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'ADVERTENCIA: Error al verificar/eliminar restricción unique_session_id: % - %', SQLSTATE, SQLERRM;
END $$;

-- Crear índices para mejorar rendimiento
CREATE INDEX idx_n8n_orders_session_id ON n8n_orders(session_id);
CREATE INDEX idx_n8n_orders_fecha ON n8n_orders(fecha);
CREATE INDEX idx_n8n_orders_estado ON n8n_orders(estado);
CREATE INDEX idx_n8n_orders_email ON n8n_orders(email);
CREATE INDEX idx_n8n_orders_telefono ON n8n_orders(telefono);

-- Función auxiliar para cambiar estados
CREATE OR REPLACE FUNCTION cambiar_estado_pedido(
    p_session_id VARCHAR(50),
    p_nuevo_estado estado_pedido
) RETURNS BOOLEAN AS $$
BEGIN
    UPDATE n8n_orders
    SET estado = p_nuevo_estado,
        fecha = CURRENT_TIMESTAMP
    WHERE session_id = p_session_id;

    RETURN FOUND;
END;
$$ LANGUAGE plpgsql;

-- Función auxiliar para cambiar estado de UN PEDIDO ESPECÍFICO por ID
CREATE OR REPLACE FUNCTION cambiar_estado_pedido_por_id(
    p_pedido_id INTEGER,
    p_nuevo_estado estado_pedido
) RETURNS BOOLEAN AS $$
BEGIN
    UPDATE n8n_orders
    SET estado = p_nuevo_estado,
        fecha = CURRENT_TIMESTAMP
    WHERE id = p_pedido_id;

    RETURN FOUND;
END;
$$ LANGUAGE plpgsql;