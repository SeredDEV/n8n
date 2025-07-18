-- ========================================
-- SCRIPT BÁSICO PARA n8n_pro_conversation_states
-- Ed Perfumería - SOLO TABLA
-- ========================================

-- 0. LIMPIAR TODO
DROP TABLE IF EXISTS n8n_pro_conversation_states CASCADE;
DROP FUNCTION IF EXISTS actualizar_estado_pro(VARCHAR, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS actualizar_estado_ventas_pro(VARCHAR, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS actualizar_datos_completos_pro(VARCHAR, JSONB, JSONB) CASCADE;
DROP FUNCTION IF EXISTS estado_saludo_pro(VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS estado_catalogo_pro(VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS estado_ofertas_pro(VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS estado_consulta_pro(VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS estado_ventas_pro(VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS estado_soporte_pro(VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS estado_ventas_esperando_pro(VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS estado_ventas_fin_pro(VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS estado_ventas_listo_pro(VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS estado_ventas_limpiar_pro(VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS obtener_estado_pro(VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS obtener_estado_ventas_pro(VARCHAR) CASCADE;

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
    guia VARCHAR(100) NULL,
    
    -- Información de productos (como JSON)
    productos_info JSONB NULL,
    
    -- Estado del proceso de ventas (NULL por defecto)
    estado_ventas VARCHAR(20) NULL,
    
    -- Contexto como JSON para flexibilidad
    contexto JSONB DEFAULT '{}',
    
    -- Control de conversación
    conversacion_activa BOOLEAN DEFAULT TRUE,
    
    CONSTRAINT uk_pro_session_id UNIQUE(session_id)
);

-- 2. CREAR ÍNDICES BÁSICOS
CREATE INDEX idx_n8n_pro_conversation_session ON n8n_pro_conversation_states(session_id);
CREATE INDEX idx_n8n_pro_conversation_estado ON n8n_pro_conversation_states(estado_actual);
CREATE INDEX idx_n8n_pro_conversation_estado_ventas ON n8n_pro_conversation_states(estado_ventas);
CREATE INDEX idx_n8n_pro_conversation_activa ON n8n_pro_conversation_states(conversacion_activa);
CREATE INDEX idx_n8n_pro_conversation_actividad ON n8n_pro_conversation_states(ultima_actividad);

-- 3. RESTRICCIONES DE VALIDACIÓN
ALTER TABLE n8n_pro_conversation_states 
ADD CONSTRAINT chk_pro_estado_actual 
CHECK (estado_actual IN ('saludo', 'catalogo', 'ofertas', 'consulta', 'ventas', 'soporte'));

ALTER TABLE n8n_pro_conversation_states 
ADD CONSTRAINT chk_pro_estado_ventas 
CHECK (estado_ventas IS NULL OR estado_ventas IN ('ESPERANDO', 'FIN', 'LISTO'));

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

-- FUNCIÓN ESPECÍFICA: Actualizar estado de ventas
CREATE OR REPLACE FUNCTION actualizar_estado_ventas_pro(
    session_id_param VARCHAR,
    nuevo_estado_ventas VARCHAR
)
RETURNS BOOLEAN LANGUAGE plpgsql AS '
DECLARE
    filas_afectadas INTEGER;
BEGIN
    -- Actualizar solo el estado de ventas
    UPDATE n8n_pro_conversation_states 
    SET estado_ventas = nuevo_estado_ventas,
        ultima_actividad = CURRENT_TIMESTAMP
    WHERE session_id = session_id_param;
    
    GET DIAGNOSTICS filas_afectadas = ROW_COUNT;
    RETURN filas_afectadas > 0;
END;
';

-- FUNCIÓN ESPECÍFICA: Actualizar datos completos (cliente + productos)
CREATE OR REPLACE FUNCTION actualizar_datos_completos_pro(
    session_id_param VARCHAR,
    cliente_info JSONB DEFAULT NULL,
    productos_info JSONB DEFAULT NULL
)
RETURNS BOOLEAN LANGUAGE plpgsql AS '
DECLARE
    filas_afectadas INTEGER;
BEGIN
    -- Actualizar datos del cliente y productos
    UPDATE n8n_pro_conversation_states 
    SET 
        nombre_cliente = CASE WHEN cliente_info IS NOT NULL THEN COALESCE(cliente_info->>''nombre'', nombre_cliente) ELSE nombre_cliente END,
        ciudad = CASE WHEN cliente_info IS NOT NULL THEN COALESCE(cliente_info->>''ciudad'', ciudad) ELSE ciudad END,
        producto_interes = CASE WHEN cliente_info IS NOT NULL THEN COALESCE(cliente_info->>''producto_interes'', producto_interes) ELSE producto_interes END,
        telefono = CASE WHEN cliente_info IS NOT NULL THEN COALESCE(cliente_info->>''telefono'', telefono) ELSE telefono END,
        direccion = CASE WHEN cliente_info IS NOT NULL THEN COALESCE(cliente_info->>''direccion'', direccion) ELSE direccion END,
        email = CASE WHEN cliente_info IS NOT NULL THEN COALESCE(cliente_info->>''correo'', cliente_info->>''email'', email) ELSE email END,
        guia = CASE WHEN cliente_info IS NOT NULL THEN COALESCE(cliente_info->>''guia'', guia) ELSE guia END,
        productos_info = COALESCE(productos_info, productos_info),
        ultima_actividad = CURRENT_TIMESTAMP
    WHERE session_id = session_id_param;
    
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

-- Estado: soporte
CREATE OR REPLACE FUNCTION estado_soporte_pro(session_id_param VARCHAR)
RETURNS BOOLEAN LANGUAGE plpgsql AS '
BEGIN
    RETURN actualizar_estado_pro(session_id_param, ''soporte'');
END;
';

-- ========================================
-- FUNCIONES PARA ESTADOS DE VENTAS
-- ========================================

-- Estado ventas: ESPERANDO (se enviaron datos al cliente)
CREATE OR REPLACE FUNCTION estado_ventas_esperando_pro(session_id_param VARCHAR)
RETURNS BOOLEAN LANGUAGE plpgsql AS '
BEGIN
    RETURN actualizar_estado_ventas_pro(session_id_param, ''ESPERANDO'');
END;
';

-- Estado ventas: FIN (proceso de venta finalizado)
CREATE OR REPLACE FUNCTION estado_ventas_fin_pro(session_id_param VARCHAR)
RETURNS BOOLEAN LANGUAGE plpgsql AS '
BEGIN
    RETURN actualizar_estado_ventas_pro(session_id_param, ''FIN'');
END;
';

-- Estado ventas: LISTO (todos los datos completos)
CREATE OR REPLACE FUNCTION estado_ventas_listo_pro(session_id_param VARCHAR)
RETURNS BOOLEAN LANGUAGE plpgsql AS '
BEGIN
    RETURN actualizar_estado_ventas_pro(session_id_param, ''LISTO'');
END;
';

-- Limpiar estado de ventas (volver a NULL)
CREATE OR REPLACE FUNCTION estado_ventas_limpiar_pro(session_id_param VARCHAR)
RETURNS BOOLEAN LANGUAGE plpgsql AS '
BEGIN
    RETURN actualizar_estado_ventas_pro(session_id_param, NULL);
END;
';

-- FUNCIÓN PARA CONSULTAR SOLO ESTADO DE VENTAS
CREATE OR REPLACE FUNCTION obtener_estado_ventas_pro(session_id_param VARCHAR)
RETURNS VARCHAR LANGUAGE plpgsql AS '
DECLARE
    estado_ventas_resultado VARCHAR;
BEGIN
    SELECT estado_ventas INTO estado_ventas_resultado
    FROM n8n_pro_conversation_states
    WHERE session_id = session_id_param;
    
    -- Si no encuentra la sesión, retornar NULL
    IF NOT FOUND THEN
        RETURN NULL;
    END IF;
    
    RETURN estado_ventas_resultado;
END;
';

-- FUNCIÓN PARA CONSULTAR ESTADO ACTUAL
CREATE OR REPLACE FUNCTION obtener_estado_pro(session_id_param VARCHAR)
RETURNS TABLE (
    id INTEGER,
    session_id VARCHAR,
    estado VARCHAR,
    estado_ventas VARCHAR,
    fecha_inicio TIMESTAMP,
    ultima_actividad TIMESTAMP,
    nombre_cliente VARCHAR,
    ciudad VARCHAR,
    producto_interes VARCHAR,
    telefono VARCHAR,
    direccion TEXT,
    email VARCHAR,
    guia VARCHAR,
    productos_info JSONB,
    contexto JSONB,
    conversacion_activa BOOLEAN
) LANGUAGE plpgsql AS '
BEGIN
    RETURN QUERY
    SELECT 
        cs.id,
        cs.session_id,
        cs.estado_actual,
        cs.estado_ventas,
        cs.fecha_inicio,
        cs.ultima_actividad,
        cs.nombre_cliente,
        cs.ciudad,
        cs.producto_interes,
        cs.telefono,
        cs.direccion,
        cs.email,
        cs.guia,
        cs.productos_info,
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
-- ========================================
-- EJEMPLOS DE USO:
-- ========================================

-- Estados principales disponibles:
-- ✅ saludo - Estado inicial de saludo
-- ✅ catalogo - Mostrar catálogo de productos
-- ✅ ofertas - Mostrar ofertas especiales
-- ✅ consulta - Cliente hace consulta específica
-- ✅ ventas - Iniciar proceso de ventas
-- ✅ soporte - Cliente necesita soporte técnico

SELECT estado_saludo_pro('573011284297');
SELECT estado_catalogo_pro('573011284297');
SELECT estado_ofertas_pro('573011284297');
SELECT estado_consulta_pro('573011284297');
SELECT estado_ventas_pro('573011284297');
SELECT estado_soporte_pro('573011284297');

-- Estados de ventas disponibles:
-- ✅ ESPERANDO - Cliente recibió formulario de datos
-- ✅ FIN - Proceso de venta finalizado
-- ✅ LISTO - Todos los datos completos
-- ✅ NULL - Sin estado de ventas (limpiado)

SELECT estado_ventas_esperando_pro('573011284297');
SELECT estado_ventas_fin_pro('573011284297');
SELECT estado_ventas_listo_pro('573011284297');
SELECT estado_ventas_limpiar_pro('573011284297');

-- ACTUALIZAR DATOS COMPLETOS (CLIENTE + PRODUCTOS):
SELECT actualizar_datos_completos_pro(
    '573011284297', 
    '{"nombre": "Sergio", "telefono": "30112842597", "direccion": "Cl. 7 Sur #50GG-13", "ciudad": "Guayabal, Medellín"}',
    '[{"nombre": "One Million EDT 100ML", "cantidad": 10, "precio": 35000, "total": 350000}]'
);

-- CONSULTAR SOLO ESTADO DE VENTAS:
SELECT obtener_estado_ventas_pro('573011284297');
*/


