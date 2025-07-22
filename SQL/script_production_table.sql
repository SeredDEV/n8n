-- ========================================
-- SCRIPT BÁSICO PARA n8n_pro_conversation_states
-- Ed Perfumería - SOLO TABLA
-- ========================================

-- 0. LIMPIAR TODO
DROP TABLE IF EXISTS n8n_pro_conversation_states CASCADE;
DROP FUNCTION IF EXISTS actualizar_estado_pro(VARCHAR, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS actualizar_estado_ventas_pro(VARCHAR, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS actualizar_datos_completos_pro(VARCHAR, JSONB, JSONB) CASCADE;
DROP FUNCTION IF EXISTS actualizar_estado_principal_pro(VARCHAR, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS actualizar_estado_ventas_principal_pro(VARCHAR, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS actualizar_totales_pro(VARCHAR, INTEGER, INTEGER, JSONB) CASCADE;
DROP FUNCTION IF EXISTS actualizar_datos_cliente_pro(VARCHAR, JSONB) CASCADE;
DROP FUNCTION IF EXISTS actualizar_pago_pro(VARCHAR, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS actualizar_pago_total_pro(VARCHAR, VARCHAR, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS actualizar_pago_envio_pro(VARCHAR, VARCHAR, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS estado_saludo_pro(VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS estado_catalogo_pro(VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS estado_ofertas_pro(VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS estado_consulta_pro(VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS estado_ventas_pro(VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS estado_soporte_pro(VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS estado_ventas_cotizando_pro(VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS estado_ventas_recolectando_pro(VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS estado_ventas_esperando_pro(VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS estado_ventas_fin_pro(VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS estado_ventas_listo_pro(VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS estado_ventas_limpiar_pro(VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS obtener_estado_pro(VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS obtener_estado_ventas_pro(VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS obtener_historial_sesion_pro(VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS debug_registro_bloqueado_pro(VARCHAR) CASCADE;

-- 1. CREAR LA TABLA PRINCIPAL
CREATE TABLE n8n_pro_conversation_states (
    -- IDENTIFICACIÓN Y CONTROL DE SESIÓN
    id SERIAL PRIMARY KEY,
    session_id VARCHAR(50) NOT NULL,
    fecha_inicio TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ultima_actividad TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    conversacion_activa BOOLEAN DEFAULT TRUE,
    
    -- ESTADOS DE LA CONVERSACIÓN
    estado_actual VARCHAR(20) NOT NULL DEFAULT 'SALUDO',
    estado_ventas VARCHAR(20) NULL,
    
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
    ,
    -- ESTADO DE MODIFICACIÓN DE PRODUCTO
    estado_modificacion_producto VARCHAR(20) NULL
);

-- 2. CREAR ÍNDICES BÁSICOS (ordenados por importancia y uso)

-- Índices principales para consultas frecuentes
CREATE INDEX idx_n8n_pro_conversation_session ON n8n_pro_conversation_states(session_id);
CREATE INDEX idx_n8n_pro_conversation_actividad ON n8n_pro_conversation_states(ultima_actividad);
CREATE INDEX idx_n8n_pro_conversation_activa ON n8n_pro_conversation_states(conversacion_activa);

-- Índices para estados
CREATE INDEX idx_n8n_pro_conversation_estado ON n8n_pro_conversation_states(estado_actual);
CREATE INDEX idx_n8n_pro_conversation_estado_ventas ON n8n_pro_conversation_states(estado_ventas);

-- Índices para información comercial
CREATE INDEX idx_n8n_pro_conversation_pago ON n8n_pro_conversation_states(pago);
CREATE INDEX idx_n8n_pro_conversation_total_producto ON n8n_pro_conversation_states(total_producto);
CREATE INDEX idx_n8n_pro_conversation_total_envio ON n8n_pro_conversation_states(total_envio);
CREATE INDEX idx_n8n_pro_conversation_cantidad_total ON n8n_pro_conversation_states(cantidad_total);

-- 3. RESTRICCIONES DE VALIDACIÓN (ordenadas por tipo)

-- Validación de datos obligatorios
ALTER TABLE n8n_pro_conversation_states 
ADD CONSTRAINT chk_pro_session_id_not_empty 
CHECK (LENGTH(TRIM(session_id)) > 0);

-- Validación de estados principales
ALTER TABLE n8n_pro_conversation_states 
ADD CONSTRAINT chk_pro_estado_actual 
CHECK (estado_actual IN ('SALUDO', 'CATALOGO', 'OFERTAS', 'CONSULTA', 'VENTAS', 'SOPORTE'));

-- Validación de estados de ventas
ALTER TABLE n8n_pro_conversation_states 
ADD CONSTRAINT chk_pro_estado_ventas 
CHECK (estado_ventas IS NULL OR estado_ventas IN ('COTIZANDO', 'RECOLECTANDO', 'ESPERANDO', 'LISTO', 'FIN'));

ALTER TABLE n8n_pro_conversation_states 
ADD CONSTRAINT chk_pro_pago 
CHECK (pago IS NULL OR pago IN ('TRANSFERENCIA', 'CONTRA ENTREGA', 'INTERRAPIDÍSIMO'));

ALTER TABLE n8n_pro_conversation_states 
ADD CONSTRAINT chk_pro_estado_modificacion_producto 
CHECK (
  estado_modificacion_producto IS NULL OR 
  estado_modificacion_producto IN ('EDIT_CANTIDAD', 'EDIT_PRODUCTO', 'MODIFICAR_TODO', 'AGREGAR_PRODUCTOS')
);

-- 4. FUNCIONES PARA ACTUALIZAR ESTADOS

-- FUNCIÓN GENERAL: Actualizar cualquier estado
CREATE OR REPLACE FUNCTION actualizar_estado_pro(
    session_id_param VARCHAR,
    nuevo_estado VARCHAR
)
RETURNS BOOLEAN LANGUAGE plpgsql AS '
DECLARE
    filas_afectadas INTEGER;
    registro_bloqueado BOOLEAN := FALSE;
    ultimo_estado_actual VARCHAR;
    ultimo_estado_ventas VARCHAR;
BEGIN
    -- Verificar el estado del registro más reciente
    SELECT estado_actual, estado_ventas 
    INTO ultimo_estado_actual, ultimo_estado_ventas
    FROM n8n_pro_conversation_states 
    WHERE session_id = session_id_param 
    ORDER BY ultima_actividad DESC 
    LIMIT 1;
    
    -- Si existe un registro, verificar si está bloqueado
    IF ultimo_estado_actual IS NOT NULL THEN
        registro_bloqueado := (ultimo_estado_actual = ''VENTAS'' AND ultimo_estado_ventas = ''FIN'');
    END IF;
    
    -- Si está bloqueado, SIEMPRE crear nuevo registro
    IF registro_bloqueado THEN
        INSERT INTO n8n_pro_conversation_states (session_id, estado_actual) 
        VALUES (session_id_param, nuevo_estado);
        GET DIAGNOSTICS filas_afectadas = ROW_COUNT;
        RETURN filas_afectadas > 0;
    END IF;
    
    -- Si no está bloqueado y existe registro, actualizar
    IF ultimo_estado_actual IS NOT NULL THEN
        UPDATE n8n_pro_conversation_states 
        SET estado_actual = nuevo_estado,
            ultima_actividad = CURRENT_TIMESTAMP
        WHERE id = (
            SELECT id FROM n8n_pro_conversation_states 
            WHERE session_id = session_id_param 
            ORDER BY ultima_actividad DESC 
            LIMIT 1
        );
    ELSE
        -- Si no existe registro, crear uno nuevo
        INSERT INTO n8n_pro_conversation_states (session_id, estado_actual) 
        VALUES (session_id_param, nuevo_estado);
    END IF;
    
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
    ultimo_registro_id INTEGER;
    ultimo_estado_actual VARCHAR;
    ultimo_estado_ventas VARCHAR;
BEGIN
    -- Obtener información del registro más reciente
    SELECT id, estado_actual, estado_ventas 
    INTO ultimo_registro_id, ultimo_estado_actual, ultimo_estado_ventas
    FROM n8n_pro_conversation_states 
    WHERE session_id = session_id_param 
    ORDER BY ultima_actividad DESC 
    LIMIT 1;
    
    -- Si no existe registro, no hacer nada
    IF ultimo_registro_id IS NULL THEN
        RETURN FALSE;
    END IF;
    
    -- Si el registro está bloqueado (ventas + FIN), no actualizar
    IF ultimo_estado_actual = ''VENTAS'' AND ultimo_estado_ventas = ''FIN'' THEN
        RETURN FALSE;
    END IF;
    
    -- Actualizar el estado de ventas del registro más reciente
    UPDATE n8n_pro_conversation_states 
    SET estado_ventas = nuevo_estado_ventas,
        ultima_actividad = CURRENT_TIMESTAMP
    WHERE id = ultimo_registro_id;
    
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
    -- Actualizar datos del cliente y productos solo en registro activo (no bloqueado)
    UPDATE n8n_pro_conversation_states 
    SET 
        nombre_cliente = CASE WHEN cliente_info IS NOT NULL THEN COALESCE(cliente_info->>''nombre'', nombre_cliente) ELSE nombre_cliente END,
        ciudad = CASE WHEN cliente_info IS NOT NULL THEN COALESCE(cliente_info->>''ciudad'', ciudad) ELSE ciudad END,
        telefono = CASE WHEN cliente_info IS NOT NULL THEN COALESCE(cliente_info->>''telefono'', telefono) ELSE telefono END,
        direccion = CASE WHEN cliente_info IS NOT NULL THEN COALESCE(cliente_info->>''direccion'', direccion) ELSE direccion END,
        email = CASE WHEN cliente_info IS NOT NULL THEN COALESCE(cliente_info->>''correo'', cliente_info->>''email'', email) ELSE email END,
        guia = CASE WHEN cliente_info IS NOT NULL THEN COALESCE(cliente_info->>''guia'', guia) ELSE guia END,
        pago = CASE WHEN cliente_info IS NOT NULL THEN COALESCE(cliente_info->>''pago'', pago) ELSE pago END,
        total_producto = CASE WHEN cliente_info IS NOT NULL THEN COALESCE((cliente_info->>''total_producto'')::INTEGER, total_producto) ELSE total_producto END,
        total_envio = CASE WHEN cliente_info IS NOT NULL THEN COALESCE((cliente_info->>''total_envio'')::INTEGER, total_envio) ELSE total_envio END,
        productos_info = COALESCE(actualizar_datos_completos_pro.productos_info, n8n_pro_conversation_states.productos_info),
        ultima_actividad = CURRENT_TIMESTAMP
    WHERE session_id = session_id_param 
    AND NOT (estado_actual = ''VENTAS'' AND estado_ventas = ''FIN'')
    AND id = (
        SELECT id FROM n8n_pro_conversation_states 
        WHERE session_id = session_id_param 
        ORDER BY ultima_actividad DESC 
        LIMIT 1
    );
    
    GET DIAGNOSTICS filas_afectadas = ROW_COUNT;
    RETURN filas_afectadas > 0;
END;
';

-- FUNCIONES ESPECÍFICAS PARA CADA ESTADO

-- FUNCIÓN UNIFICADA: Actualizar cualquier estado principal
CREATE OR REPLACE FUNCTION actualizar_estado_principal_pro(
    session_id_param VARCHAR,
    estado_param VARCHAR
)
RETURNS BOOLEAN LANGUAGE plpgsql AS '
BEGIN
    -- Validar que el estado sea válido (convertir a mayúscula)
    IF UPPER(estado_param) NOT IN (''SALUDO'', ''CATALOGO'', ''OFERTAS'', ''CONSULTA'', ''VENTAS'', ''SOPORTE'') THEN
        RAISE EXCEPTION ''Estado no válido: %. Estados permitidos: SALUDO, CATALOGO, OFERTAS, CONSULTA, VENTAS, SOPORTE'', UPPER(estado_param);
    END IF;
    
    -- Llamar a la función general con el estado en mayúscula
    RETURN actualizar_estado_pro(session_id_param, UPPER(estado_param));
END;
';

-- ========================================
-- FUNCIONES PARA ESTADOS DE VENTAS
-- ========================================

-- FUNCIÓN UNIFICADA: Actualizar cualquier estado de ventas
CREATE OR REPLACE FUNCTION actualizar_estado_ventas_principal_pro(
    session_id_param VARCHAR,
    estado_ventas_param VARCHAR
)
RETURNS BOOLEAN LANGUAGE plpgsql AS '
BEGIN
    -- Validar que el estado de ventas sea válido (convertir a mayúscula)
    IF estado_ventas_param IS NOT NULL AND UPPER(estado_ventas_param) NOT IN (''COTIZANDO'', ''RECOLECTANDO'', ''ESPERANDO'', ''LISTO'', ''FIN'') THEN
        RAISE EXCEPTION ''Estado de ventas no válido: %. Estados permitidos: COTIZANDO, RECOLECTANDO, ESPERANDO, LISTO, FIN, NULL'', UPPER(estado_ventas_param);
    END IF;
    
    -- Llamar a la función general con el estado de ventas en mayúscula (o NULL)
    IF estado_ventas_param IS NULL THEN
        RETURN actualizar_estado_ventas_pro(session_id_param, NULL);
    ELSE
        RETURN actualizar_estado_ventas_pro(session_id_param, UPPER(estado_ventas_param));
    END IF;
END;
';

-- FUNCIÓN ESPECÍFICA: Actualizar campos de totales (opcionales)
CREATE OR REPLACE FUNCTION actualizar_totales_pro(
    session_id_param VARCHAR,
    total_producto_param INTEGER DEFAULT NULL,
    cantidad_total_param INTEGER DEFAULT NULL,
    productos_info_param JSONB DEFAULT NULL
)
RETURNS BOOLEAN LANGUAGE plpgsql AS '
DECLARE
    filas_afectadas INTEGER;
    ultimo_registro_id INTEGER;
    ultimo_estado_actual VARCHAR;
    ultimo_estado_ventas VARCHAR;
BEGIN
    -- Obtener información del registro más reciente
    SELECT id, estado_actual, estado_ventas 
    INTO ultimo_registro_id, ultimo_estado_actual, ultimo_estado_ventas
    FROM n8n_pro_conversation_states 
    WHERE session_id = session_id_param 
    ORDER BY ultima_actividad DESC 
    LIMIT 1;
    
    -- Si no existe registro, no hacer nada
    IF ultimo_registro_id IS NULL THEN
        RETURN FALSE;
    END IF;
    
    -- Si el registro está bloqueado (ventas + FIN), no actualizar
    IF ultimo_estado_actual = ''VENTAS'' AND ultimo_estado_ventas = ''FIN'' THEN
        RETURN FALSE;
    END IF;
    
    -- Actualizar los campos, permitiendo que todos sean NULL
    UPDATE n8n_pro_conversation_states 
    SET 
        total_producto = total_producto_param,
        cantidad_total = cantidad_total_param,
        productos_info = productos_info_param,
        ultima_actividad = CURRENT_TIMESTAMP
    WHERE id = ultimo_registro_id;
    
    GET DIAGNOSTICS filas_afectadas = ROW_COUNT;
    RETURN filas_afectadas > 0;
END;
';

-- FUNCIÓN ESPECÍFICA: Actualizar datos del cliente
CREATE OR REPLACE FUNCTION actualizar_datos_cliente_pro(
    session_id_param VARCHAR,
    datos_cliente_param JSONB
)
RETURNS BOOLEAN LANGUAGE plpgsql AS '
DECLARE
    filas_afectadas INTEGER;
    ultimo_registro_id INTEGER;
    ultimo_estado_actual VARCHAR;
    ultimo_estado_ventas VARCHAR;
BEGIN
    -- Verificar que se proporcionó información del cliente
    IF datos_cliente_param IS NULL THEN
        RAISE EXCEPTION ''Debe proporcionar los datos del cliente en formato JSON'';
    END IF;
    
    -- Obtener información del registro más reciente
    SELECT id, estado_actual, estado_ventas 
    INTO ultimo_registro_id, ultimo_estado_actual, ultimo_estado_ventas
    FROM n8n_pro_conversation_states 
    WHERE session_id = session_id_param 
    ORDER BY ultima_actividad DESC 
    LIMIT 1;
    
    -- Si no existe registro, no hacer nada
    IF ultimo_registro_id IS NULL THEN
        RETURN FALSE;
    END IF;
    
    -- Si el registro está bloqueado (ventas + FIN), no actualizar
    IF ultimo_estado_actual = ''VENTAS'' AND ultimo_estado_ventas = ''FIN'' THEN
        RETURN FALSE;
    END IF;
    
    -- Actualizar los datos del cliente que no sean NULL en el JSON
    UPDATE n8n_pro_conversation_states 
    SET 
        nombre_cliente = CASE 
            WHEN datos_cliente_param->''nombre'' IS NOT NULL AND datos_cliente_param->>''nombre'' != '''' THEN 
                datos_cliente_param->>''nombre'' 
            ELSE nombre_cliente 
        END,
        telefono = CASE 
            WHEN datos_cliente_param->''telefono'' IS NOT NULL AND datos_cliente_param->>''telefono'' != '''' THEN 
                datos_cliente_param->>''telefono'' 
            ELSE telefono 
        END,
        email = CASE 
            WHEN datos_cliente_param->''correo'' IS NOT NULL AND datos_cliente_param->>''correo'' != '''' THEN 
                datos_cliente_param->>''correo'' 
            WHEN datos_cliente_param->''email'' IS NOT NULL AND datos_cliente_param->>''email'' != '''' THEN 
                datos_cliente_param->>''email''
            ELSE email 
        END,
        direccion = CASE 
            WHEN datos_cliente_param->''direccion'' IS NOT NULL AND datos_cliente_param->>''direccion'' != '''' THEN 
                datos_cliente_param->>''direccion'' 
            ELSE direccion 
        END,
        ciudad = CASE 
            WHEN datos_cliente_param->''ciudad'' IS NOT NULL AND datos_cliente_param->>''ciudad'' != '''' THEN 
                datos_cliente_param->>''ciudad'' 
            ELSE ciudad 
        END,
        pago = CASE 
            WHEN datos_cliente_param->''metodoPago'' IS NOT NULL AND datos_cliente_param->>''metodoPago'' != '''' THEN 
                UPPER(datos_cliente_param->>''metodoPago'')
            WHEN datos_cliente_param->''pago'' IS NOT NULL AND datos_cliente_param->>''pago'' != '''' THEN 
                UPPER(datos_cliente_param->>''pago'')
            ELSE pago 
        END,
        ultima_actividad = CURRENT_TIMESTAMP
    WHERE id = ultimo_registro_id;
    
    GET DIAGNOSTICS filas_afectadas = ROW_COUNT;
    RETURN filas_afectadas > 0;
END;
';

-- FUNCIÓN ESPECÍFICA: Actualizar método de pago
CREATE OR REPLACE FUNCTION actualizar_pago_pro(
    session_id_param VARCHAR,
    pago_param VARCHAR
)
RETURNS BOOLEAN LANGUAGE plpgsql AS '
DECLARE
    filas_afectadas INTEGER;
    ultimo_registro_id INTEGER;
    ultimo_estado_actual VARCHAR;
    ultimo_estado_ventas VARCHAR;
BEGIN
    -- Validar que el método de pago sea válido (convertir a mayúscula)
    IF pago_param IS NOT NULL AND UPPER(pago_param) NOT IN (''TRANSFERENCIA'', ''CONTRA ENTREGA'', ''INTERRAPIDÍSIMO'') THEN
        RAISE EXCEPTION ''Método de pago no válido: %. Métodos permitidos: TRANSFERENCIA, CONTRA ENTREGA, INTERRAPIDÍSIMO'', UPPER(pago_param);
    END IF;
    
    -- Obtener información del registro más reciente
    SELECT id, estado_actual, estado_ventas 
    INTO ultimo_registro_id, ultimo_estado_actual, ultimo_estado_ventas
    FROM n8n_pro_conversation_states 
    WHERE session_id = session_id_param 
    ORDER BY ultima_actividad DESC 
    LIMIT 1;
    
    -- Si no existe registro, no hacer nada
    IF ultimo_registro_id IS NULL THEN
        RETURN FALSE;
    END IF;
    
    -- Si el registro está bloqueado (ventas + FIN), no actualizar
    IF ultimo_estado_actual = ''VENTAS'' AND ultimo_estado_ventas = ''FIN'' THEN
        RETURN FALSE;
    END IF;
    
    -- Actualizar el método de pago del registro más reciente
    UPDATE n8n_pro_conversation_states 
    SET 
        pago = CASE WHEN pago_param IS NULL THEN NULL ELSE UPPER(pago_param) END,
        ultima_actividad = CURRENT_TIMESTAMP
    WHERE id = ultimo_registro_id;
    
    GET DIAGNOSTICS filas_afectadas = ROW_COUNT;
    RETURN filas_afectadas > 0;
END;
';

-- FUNCIÓN ESPECÍFICA: Actualizar método de pago y total de envío
CREATE OR REPLACE FUNCTION actualizar_pago_envio_pro(
    session_id_param VARCHAR,
    pago_param VARCHAR DEFAULT NULL,
    total_envio_param INTEGER DEFAULT NULL
)
RETURNS BOOLEAN LANGUAGE plpgsql AS '
DECLARE
    filas_afectadas INTEGER;
    ultimo_registro_id INTEGER;
    ultimo_estado_actual VARCHAR;
    ultimo_estado_ventas VARCHAR;
BEGIN
    -- Verificar que al menos uno de los parámetros tenga valor
    IF pago_param IS NULL AND total_envio_param IS NULL THEN
        RAISE EXCEPTION ''Debe proporcionar al menos un valor: pago o total_envio'';
    END IF;
    
    -- Validar que el método de pago sea válido (convertir a mayúscula)
    IF pago_param IS NOT NULL AND UPPER(pago_param) NOT IN (''TRANSFERENCIA'', ''CONTRA ENTREGA'', ''INTERRAPIDÍSIMO'') THEN
        RAISE EXCEPTION ''Método de pago no válido: %. Métodos permitidos: TRANSFERENCIA, CONTRA ENTREGA, INTERRAPIDÍSIMO'', UPPER(pago_param);
    END IF;
    
    -- Obtener información del registro más reciente
    SELECT id, estado_actual, estado_ventas 
    INTO ultimo_registro_id, ultimo_estado_actual, ultimo_estado_ventas
    FROM n8n_pro_conversation_states 
    WHERE session_id = session_id_param 
    ORDER BY ultima_actividad DESC 
    LIMIT 1;
    
    -- Si no existe registro, no hacer nada
    IF ultimo_registro_id IS NULL THEN
        RETURN FALSE;
    END IF;
    
    -- Si el registro está bloqueado (ventas + FIN), no actualizar
    IF ultimo_estado_actual = ''VENTAS'' AND ultimo_estado_ventas = ''FIN'' THEN
        RETURN FALSE;
    END IF;
    
    -- Actualizar los campos que tienen valor
    UPDATE n8n_pro_conversation_states 
    SET 
        pago = CASE 
            WHEN pago_param IS NULL THEN pago 
            WHEN pago_param = '''' THEN NULL 
            ELSE UPPER(pago_param) 
        END,
        total_envio = COALESCE(total_envio_param, total_envio),
        ultima_actividad = CURRENT_TIMESTAMP
    WHERE id = ultimo_registro_id;
    
    GET DIAGNOSTICS filas_afectadas = ROW_COUNT;
    RETURN filas_afectadas > 0;
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
    WHERE session_id = session_id_param
    ORDER BY ultima_actividad DESC
    LIMIT 1;
    
    -- Si no encuentra la sesión, retornar NULL
    IF NOT FOUND THEN
        RETURN NULL;
    END IF;
    
    RETURN estado_ventas_resultado;
END;
';

-- FUNCIÓN PARA CONSULTAR TODOS LOS REGISTROS DE UNA SESIÓN (para debugging)
CREATE OR REPLACE FUNCTION obtener_historial_sesion_pro(session_id_param VARCHAR)
RETURNS TABLE (
    id INTEGER,
    session_id VARCHAR,
    estado VARCHAR,
    estado_ventas VARCHAR,
    fecha_inicio TIMESTAMP,
    ultima_actividad TIMESTAMP,
    nombre_cliente VARCHAR,
    ciudad VARCHAR,
    telefono VARCHAR,
    direccion TEXT,
    email VARCHAR,
    guia VARCHAR,
    pago VARCHAR,
    total_producto INTEGER,
    total_envio INTEGER,
    cantidad_total INTEGER,
    productos_info JSONB,
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
        cs.telefono,
        cs.direccion,
        cs.email,
        cs.guia,
        cs.pago,
        cs.total_producto,
        cs.total_envio,
        cs.cantidad_total,
        cs.productos_info,
        cs.conversacion_activa
    FROM n8n_pro_conversation_states cs
    WHERE cs.session_id = session_id_param
    ORDER BY cs.ultima_actividad DESC;
END;
';

-- FUNCIÓN DE DEBUG: Verificar si un registro está bloqueado
CREATE OR REPLACE FUNCTION debug_registro_bloqueado_pro(session_id_param VARCHAR)
RETURNS TABLE (
    id INTEGER,
    session_id VARCHAR,
    estado_actual VARCHAR,
    estado_ventas VARCHAR,
    esta_bloqueado BOOLEAN,
    es_mas_reciente BOOLEAN
) LANGUAGE plpgsql AS '
BEGIN
    RETURN QUERY
    WITH ultimo_registro AS (
        SELECT id as ultimo_id
        FROM n8n_pro_conversation_states 
        WHERE session_id = session_id_param 
        ORDER BY ultima_actividad DESC 
        LIMIT 1
    )
    SELECT 
        cs.id,
        cs.session_id,
        cs.estado_actual,
        cs.estado_ventas,
        (cs.estado_actual = ''VENTAS'' AND cs.estado_ventas = ''FIN'') as esta_bloqueado,
        (cs.id = ur.ultimo_id) as es_mas_reciente
    FROM n8n_pro_conversation_states cs
    CROSS JOIN ultimo_registro ur
    WHERE cs.session_id = session_id_param
    ORDER BY cs.ultima_actividad DESC;
END;
';

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
    telefono VARCHAR,
    direccion TEXT,
    email VARCHAR,
    guia VARCHAR,
    pago VARCHAR,
    total_producto INTEGER,
    total_envio INTEGER,
    cantidad_total INTEGER,
    productos_info JSONB,
    estado_modificacion_producto VARCHAR,
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
        cs.telefono,
        cs.direccion,
        cs.email,
        cs.guia,
        cs.pago,
        cs.total_producto,
        cs.total_envio,
        cs.cantidad_total,
        cs.productos_info,
        cs.estado_modificacion_producto,
        cs.conversacion_activa
    FROM n8n_pro_conversation_states cs
    WHERE cs.session_id = session_id_param
    ORDER BY cs.ultima_actividad DESC
    LIMIT 1;
END;
';

DROP FUNCTION IF EXISTS actualizar_estado_modificacion_producto_pro(VARCHAR, VARCHAR) CASCADE;
CREATE OR REPLACE FUNCTION actualizar_estado_modificacion_producto_pro(
    session_id_param VARCHAR,
    nuevo_estado_modificacion VARCHAR
)
RETURNS BOOLEAN LANGUAGE plpgsql AS '
DECLARE
    filas_afectadas INTEGER;
    ultimo_registro_id INTEGER;
    ultimo_estado_actual VARCHAR;
    ultimo_estado_ventas VARCHAR;
BEGIN
    -- Validar que el estado de modificación sea válido
    IF nuevo_estado_modificacion IS NOT NULL AND UPPER(nuevo_estado_modificacion) NOT IN (''EDIT_CANTIDAD'', ''EDIT_PRODUCTO'', ''MODIFICAR_TODO'', ''AGREGAR_PRODUCTOS'') THEN
        RAISE EXCEPTION ''Estado de modificación de producto no válido: %. Estados permitidos: EDIT_CANTIDAD, EDIT_PRODUCTO, MODIFICAR_TODO, AGREGAR_PRODUCTOS, NULL'', UPPER(nuevo_estado_modificacion);
    END IF;

    -- Obtener información del registro más reciente
    SELECT id, estado_actual, estado_ventas 
    INTO ultimo_registro_id, ultimo_estado_actual, ultimo_estado_ventas
    FROM n8n_pro_conversation_states 
    WHERE session_id = session_id_param 
    ORDER BY ultima_actividad DESC 
    LIMIT 1;

    -- Si no existe registro, no hacer nada
    IF ultimo_registro_id IS NULL THEN
        RETURN FALSE;
    END IF;

    -- Si el registro está bloqueado (ventas + FIN), no actualizar
    IF ultimo_estado_actual = ''VENTAS'' AND ultimo_estado_ventas = ''FIN'' THEN
        RETURN FALSE;
    END IF;

    -- Actualizar el estado_modificacion_producto del registro más reciente
    UPDATE n8n_pro_conversation_states 
    SET estado_modificacion_producto = CASE WHEN nuevo_estado_modificacion IS NULL THEN NULL ELSE UPPER(nuevo_estado_modificacion) END,
        ultima_actividad = CURRENT_TIMESTAMP
    WHERE id = ultimo_registro_id;

    GET DIAGNOSTICS filas_afectadas = ROW_COUNT;
    RETURN filas_afectadas > 0;
END;
';


/*


SELECT actualizar_estado_principal_pro('573011284297', 'SALUDO');
SELECT actualizar_estado_principal_pro('573011284297', 'CATALOGO');
SELECT actualizar_estado_principal_pro('573011284297', 'OFERTAS');
SELECT actualizar_estado_principal_pro('573011284297', 'CONSULTA');
SELECT actualizar_estado_principal_pro('573011284297', 'VENTAS');
SELECT actualizar_estado_principal_pro('573011284297', 'SOPORTE');


SELECT actualizar_estado_ventas_principal_pro('573011284297', 'COTIZANDO');
SELECT actualizar_estado_ventas_principal_pro('573011284297', 'RECOLECTANDO');
SELECT actualizar_estado_ventas_principal_pro('573011284297', 'ESPERANDO');
SELECT actualizar_estado_ventas_principal_pro('573011284297', 'LISTO');
SELECT actualizar_estado_ventas_principal_pro('573011284297', 'FIN');
SELECT actualizar_estado_ventas_principal_pro('573011284297', NULL); -- Limpiar estado


-- ✅ EDIT_CANTIDAD - Editar cantidad de un producto
-- ✅ EDIT_PRODUCTO - Editar información de un producto
-- ✅ MODIFICAR_TODO - Modificar todos los productos
-- ✅ AGREGAR_PRODUCTOS - Agregar productos nuevos
-- ✅ NULL - Sin estado de modificación (limpiado)

SELECT actualizar_estado_modificacion_producto_pro('573011284297', 'EDIT_CANTIDAD');
SELECT actualizar_estado_modificacion_producto_pro('573011284297', 'EDIT_PRODUCTO');
SELECT actualizar_estado_modificacion_producto_pro('573011284297', 'MODIFICAR_TODO');
SELECT actualizar_estado_modificacion_producto_pro('573011284297', 'AGREGAR_PRODUCTOS');
SELECT actualizar_estado_modificacion_producto_pro('573011284297', NULL); -- Limpiar estado

-- ACTUALIZAR DATOS COMPLETOS (CLIENTE + PRODUCTOS):
SELECT actualizar_datos_completos_pro(
    '573011284297', 
    '{"nombre": "Sergio", "telefono": "30112842597", "direccion": "Cl. 7 Sur #50GG-13", "ciudad": "Guayabal, Medellín", "pago": "TRANSFERENCIA", "total_producto": "350000", "total_envio": "15000"}',
    '[{"nombre": "One Million EDT 100ML", "cantidad": 10, "precio": 35000, "total": 350000}]'
);

-- ACTUALIZAR SOLO TOTALES (OPCIONALES):
-- Solo total de producto:
SELECT actualizar_totales_pro('573011284297', 450000, NULL, NULL);

-- Solo cantidad total:
SELECT actualizar_totales_pro('573011284297', NULL, 15, NULL);

-- Total de producto y cantidad:
SELECT actualizar_totales_pro('573011284297', 450000, 15, NULL);

-- Solo productos_info:
SELECT actualizar_totales_pro('573011284297', NULL, NULL, '{"productos": [{"id": 1, "nombre": "Producto 1", "precio": 25000, "cantidad": 2}]}');

-- Total, cantidad y productos_info:
SELECT actualizar_totales_pro('573011284297', 450000, 15, '{"productos": [{"id": 1, "nombre": "Producto 1", "precio": 25000, "cantidad": 2}]}');

-- ACTUALIZAR SOLO DATOS DEL CLIENTE:
-- Ejemplo con datos completos del cliente:
SELECT actualizar_datos_cliente_pro('573011284297', '{"nombre":"Sergio Eduardo Rodriguez","telefono":"30112842597","direccion":"Cl. 7 Sur #50GG-13","ciudad":"Medellín","metodoPago":"CONTRA ENTREGA","correo":"sergio@email.com"}');

-- Ejemplo con datos parciales (algunos null):
SELECT actualizar_datos_cliente_pro('573011284297', '{"nombre":null,"telefono":null,"direccion":"Cl. 7 Sur #50GG-13","ciudad":"Medellín","metodoPago":"CONTRA ENTREGA","correo":null}');

-- Solo actualizar dirección y ciudad:
SELECT actualizar_datos_cliente_pro('573011284297', '{"direccion":"Cra 50 #7-25","ciudad":"Guayabal, Medellín"}');

-- Solo actualizar método de pago:
SELECT actualizar_datos_cliente_pro('573011284297', '{"metodoPago":"TRANSFERENCIA"}');

-- Actualizar email usando 'correo':
SELECT actualizar_datos_cliente_pro('573011284297', '{"correo":"cliente@example.com"}');

-- ACTUALIZAR SOLO MÉTODO DE PAGO:
-- Transferencia bancaria:
SELECT actualizar_pago_pro('573011284297', 'TRANSFERENCIA');

-- Pago contra entrega:
SELECT actualizar_pago_pro('573011284297', 'CONTRA ENTREGA');

-- Pago con Interrapidísimo:
SELECT actualizar_pago_pro('573011284297', 'INTERRAPIDÍSIMO');

-- Limpiar método de pago (poner NULL):
SELECT actualizar_pago_pro('573011284297', NULL);

-- ACTUALIZAR PAGO Y TOTAL DE ENVÍO:
-- Solo método de pago:
SELECT actualizar_pago_envio_pro('573011284297', 'TRANSFERENCIA', NULL);

-- Solo total de envío:
SELECT actualizar_pago_envio_pro('573011284297', NULL, 15000);

-- Pago y total de envío:
SELECT actualizar_pago_envio_pro('573011284297', 'CONTRA ENTREGA', 15000);

-- Cambiar método de pago y total de envío:
SELECT actualizar_pago_envio_pro('573011284297', 'INTERRAPIDÍSIMO', 25000);

-- Limpiar solo el pago (mantener total de envío):
SELECT actualizar_pago_envio_pro('573011284297', '', NULL);

-- CONSULTAR SOLO ESTADO DE VENTAS:
SELECT obtener_estado_ventas_pro('573011284297');
*/


