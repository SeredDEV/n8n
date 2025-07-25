-- Active: 1753324294589@@31.97.149.15@5432@n8ndb
-- Eliminar tabla si existe
DROP TABLE IF EXISTS n8n_orders CASCADE;

-- Eliminar tipo enum si existe
DROP TYPE IF EXISTS estado_pedido CASCADE;

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
    productos_info JSONB NULL,

    -- RESTRICCIONES
    CONSTRAINT unique_session_id UNIQUE (session_id)
);

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