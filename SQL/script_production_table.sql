-- ========================================
-- SCRIPT BÁSICO PARA n8n_pro_conversation_states
-- Ed Perfumería - SOLO TABLA
-- ========================================

-- 0. LIMPIAR TODO
DROP TABLE IF EXISTS n8n_pro_conversation_states CASCADE;
DROP FUNCTION IF EXISTS actualizar_estado_pro(VARCHAR, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS estado_saludo_pro(VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS estado_catalogo_pro(VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS estado_ofertas_pro(VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS estado_consulta_pro(VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS estado_ventas_pro(VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS estado_venta_si_pro(VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS estado_venta_no_pro(VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS estado_soporte_pro(VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS estado_soporte_si_pro(VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS estado_soporte_no_pro(VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS obtener_estado_pro(VARCHAR) CASCADE;

-- 1. CREAR LA TABLA PRINCIPAL
CREATE TABLE n8n_pro_conversation_states (
    id SERIAL PRIMARY KEY,
    session_id VARCHAR(50) NOT NULL,
    estado_actual VARCHAR(20) NOT NULL DEFAULT 'saludo',
    fecha_inicio TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ultima_actividad TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Datos básicos del cliente (TODOS OPCIONALES)
    nombre_cliente VARCHAR(100) NULL,
    ciudad VARCHAR(50) NULL,
    producto_interes VARCHAR(200) NULL,
    telefono VARCHAR(20) NULL,
    direccion TEXT NULL,
    email VARCHAR(150) NULL,
    
    -- Contexto como JSON para flexibilidad
    contexto JSONB DEFAULT '{}',
    
    -- Control de conversación
    conversacion_activa BOOLEAN DEFAULT TRUE,
    
    CONSTRAINT uk_pro_session_id UNIQUE(session_id)
);

-- 2. CREAR ÍNDICES BÁSICOS
CREATE INDEX idx_n8n_pro_conversation_session ON n8n_pro_conversation_states(session_id);
CREATE INDEX idx_n8n_pro_conversation_estado ON n8n_pro_conversation_states(estado_actual);
CREATE INDEX idx_n8n_pro_conversation_activa ON n8n_pro_conversation_states(conversacion_activa);
CREATE INDEX idx_n8n_pro_conversation_actividad ON n8n_pro_conversation_states(ultima_actividad);

-- 3. RESTRICCIONES DE VALIDACIÓN
ALTER TABLE n8n_pro_conversation_states 
ADD CONSTRAINT chk_pro_estado_actual 
CHECK (estado_actual IN ('saludo', 'catalogo', 'ofertas', 'consulta', 'ventas', 'venta_si', 'venta_no', 'soporte', 'soporte_si', 'soporte_no'));

ALTER TABLE n8n_pro_conversation_states 
ADD CONSTRAINT chk_pro_session_id_not_empty 
CHECK (LENGTH(TRIM(session_id)) > 0);

-- 4. FUNCIONES PARA ACTUALIZAR ESTADOS

-- FUNCIÓN GENERAL: Actualizar cualquier estado
CREATE OR REPLACE FUNCTION actualizar_estado_pro(
    session_id_param VARCHAR,
    nuevo_estado VARCHAR
)
RETURNS BOOLEAN LANGUAGE plpgsql AS '
DECLARE
    filas_afectadas INTEGER;
BEGIN
    -- Crear sesión si no existe
    INSERT INTO n8n_pro_conversation_states (session_id, estado_actual) 
    VALUES (session_id_param, nuevo_estado) 
    ON CONFLICT (session_id) DO UPDATE SET 
        estado_actual = nuevo_estado,
        ultima_actividad = CURRENT_TIMESTAMP;
    
    GET DIAGNOSTICS filas_afectadas = ROW_COUNT;
    RETURN filas_afectadas > 0;
END;
';

-- FUNCIONES ESPECÍFICAS PARA CADA ESTADO

-- Estado: saludo
CREATE OR REPLACE FUNCTION estado_saludo_pro(session_id_param VARCHAR)
RETURNS BOOLEAN LANGUAGE plpgsql AS '
BEGIN
    RETURN actualizar_estado_pro(session_id_param, ''saludo'');
END;
';

-- Estado: catalogo
CREATE OR REPLACE FUNCTION estado_catalogo_pro(session_id_param VARCHAR)
RETURNS BOOLEAN LANGUAGE plpgsql AS '
BEGIN
    RETURN actualizar_estado_pro(session_id_param, ''catalogo'');
END;
';

-- Estado: ofertas
CREATE OR REPLACE FUNCTION estado_ofertas_pro(session_id_param VARCHAR)
RETURNS BOOLEAN LANGUAGE plpgsql AS '
BEGIN
    RETURN actualizar_estado_pro(session_id_param, ''ofertas'');
END;
';

-- Estado: consulta
CREATE OR REPLACE FUNCTION estado_consulta_pro(session_id_param VARCHAR)
RETURNS BOOLEAN LANGUAGE plpgsql AS '
BEGIN
    RETURN actualizar_estado_pro(session_id_param, ''consulta'');
END;
';

-- Estado: ventas
CREATE OR REPLACE FUNCTION estado_ventas_pro(session_id_param VARCHAR)
RETURNS BOOLEAN LANGUAGE plpgsql AS '
BEGIN
    RETURN actualizar_estado_pro(session_id_param, ''ventas'');
END;
';

-- Estado: venta_si (compró)
CREATE OR REPLACE FUNCTION estado_venta_si_pro(session_id_param VARCHAR)
RETURNS BOOLEAN LANGUAGE plpgsql AS '
BEGIN
    RETURN actualizar_estado_pro(session_id_param, ''venta_si'');
END;
';

-- Estado: venta_no (no compró)
CREATE OR REPLACE FUNCTION estado_venta_no_pro(session_id_param VARCHAR)
RETURNS BOOLEAN LANGUAGE plpgsql AS '
BEGIN
    RETURN actualizar_estado_pro(session_id_param, ''venta_no'');
END;
';

-- Estado: soporte
CREATE OR REPLACE FUNCTION estado_soporte_pro(session_id_param VARCHAR)
RETURNS BOOLEAN LANGUAGE plpgsql AS '
BEGIN
    RETURN actualizar_estado_pro(session_id_param, ''soporte'');
END;
';

-- Estado: soporte_si (resuelto)
CREATE OR REPLACE FUNCTION estado_soporte_si_pro(session_id_param VARCHAR)
RETURNS BOOLEAN LANGUAGE plpgsql AS '
BEGIN
    RETURN actualizar_estado_pro(session_id_param, ''soporte_si'');
END;
';

-- Estado: soporte_no (no resuelto)
CREATE OR REPLACE FUNCTION estado_soporte_no_pro(session_id_param VARCHAR)
RETURNS BOOLEAN LANGUAGE plpgsql AS '
BEGIN
    RETURN actualizar_estado_pro(session_id_param, ''soporte_no'');
END;
';

-- FUNCIÓN PARA CONSULTAR ESTADO ACTUAL
CREATE OR REPLACE FUNCTION obtener_estado_pro(session_id_param VARCHAR)
RETURNS TABLE (
    id INTEGER,
    session_id VARCHAR,
    estado VARCHAR,
    fecha_inicio TIMESTAMP,
    ultima_actividad TIMESTAMP,
    nombre_cliente VARCHAR,
    ciudad VARCHAR,
    producto_interes VARCHAR,
    telefono VARCHAR,
    direccion TEXT,
    email VARCHAR,
    contexto JSONB,
    conversacion_activa BOOLEAN
) LANGUAGE plpgsql AS '
BEGIN
    RETURN QUERY
    SELECT 
        cs.id,
        cs.session_id,
        cs.estado_actual,
        cs.fecha_inicio,
        cs.ultima_actividad,
        cs.nombre_cliente,
        cs.ciudad,
        cs.producto_interes,
        cs.telefono,
        cs.direccion,
        cs.email,
        cs.contexto,
        cs.conversacion_activa
    FROM n8n_pro_conversation_states cs
    WHERE cs.session_id = session_id_param;
END;
';

-- ========================================
-- EJEMPLOS DE USO:
-- ========================================

/*
-- FUNCIÓN GENERAL:
SELECT actualizar_estado_pro('573011284297', 'catalogo');

-- FUNCIONES ESPECÍFICAS:
SELECT estado_saludo_pro('573011284297');
SELECT estado_catalogo_pro('573011284297');
SELECT estado_ofertas_pro('573011284297');
SELECT estado_consulta_pro('573011284297');
SELECT estado_ventas_pro('573011284297');
SELECT estado_venta_si_pro('573011284297');
SELECT estado_venta_no_pro('573011284297');
SELECT estado_soporte_pro('573011284297');
SELECT estado_soporte_si_pro('573011284297');
SELECT estado_soporte_no_pro('573011284297');

-- CONSULTAR ESTADO:
SELECT * FROM obtener_estado_pro('573011284297');
*/