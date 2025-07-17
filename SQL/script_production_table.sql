-- ========================================
-- SCRIPT COMPLETO PARA n8n_pro_conversation_states
-- Ed Perfumería - TODAS LAS FUNCIONES
-- ========================================

-- 0. LIMPIAR TODO
DROP TABLE IF EXISTS n8n_pro_conversation_states CASCADE;
DROP FUNCTION IF EXISTS obtener_crear_estado_cliente_pro(VARCHAR);
DROP FUNCTION IF EXISTS actualizar_estado_cliente_pro(VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, TEXT, VARCHAR);
DROP FUNCTION IF EXISTS actualizar_datos_cliente_pro(VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, TEXT, VARCHAR);
DROP FUNCTION IF EXISTS cambiar_estado_conversacion_pro(VARCHAR, BOOLEAN);
DROP FUNCTION IF EXISTS buscar_cliente_pro(VARCHAR, VARCHAR);
DROP FUNCTION IF EXISTS reactivar_conversacion_si_inactiva_pro(VARCHAR);
DROP FUNCTION IF EXISTS limpiar_conversaciones_inactivas_pro(INTEGER);
DROP FUNCTION IF EXISTS activar_conversacion_con_condicion_pro(VARCHAR, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS activar_conversacion_con_condicion_pro(VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS habilitar_conversacion_activa_pro(VARCHAR, INTEGER);
DROP FUNCTION IF EXISTS habilitar_conversacion_simple_pro(VARCHAR, BOOLEAN);
DROP FUNCTION IF EXISTS verificar_estado_conversacion_pro(VARCHAR);

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
CHECK (estado_actual IN ('saludo', 'ventas', 'soporte'));

ALTER TABLE n8n_pro_conversation_states 
ADD CONSTRAINT chk_pro_session_id_not_empty 
CHECK (LENGTH(TRIM(session_id)) > 0);

-- 4. FUNCIÓN PRINCIPAL: OBTENER O CREAR CLIENTE
CREATE OR REPLACE FUNCTION obtener_crear_estado_cliente_pro(session_id_param VARCHAR)
RETURNS TABLE (
    estado VARCHAR,
    nombre VARCHAR,
    ciudad VARCHAR,
    producto_interes VARCHAR,
    telefono VARCHAR,
    direccion TEXT,
    email VARCHAR,
    conversacion_activa BOOLEAN,
    contexto JSONB
) LANGUAGE plpgsql AS '
BEGIN
    -- Insertar si no existe
    INSERT INTO n8n_pro_conversation_states (session_id, estado_actual) 
    VALUES (session_id_param, ''saludo'') 
    ON CONFLICT (session_id) DO NOTHING;
    
    -- Retornar datos actuales
    RETURN QUERY
    SELECT 
        cs.estado_actual,
        cs.nombre_cliente,
        cs.ciudad,
        cs.producto_interes,
        cs.telefono,
        cs.direccion,
        cs.email,
        cs.conversacion_activa,
        cs.contexto
    FROM n8n_pro_conversation_states cs
    WHERE cs.session_id = session_id_param;
END;
';

-- 5. FUNCIÓN: ACTUALIZAR ESTADO DEL CLIENTE
CREATE OR REPLACE FUNCTION actualizar_estado_cliente_pro(
    session_id_param VARCHAR,
    nuevo_estado VARCHAR,
    nombre_param VARCHAR DEFAULT NULL,
    ciudad_param VARCHAR DEFAULT NULL,
    producto_param VARCHAR DEFAULT NULL,
    telefono_param VARCHAR DEFAULT NULL,
    direccion_param TEXT DEFAULT NULL,
    email_param VARCHAR DEFAULT NULL
)
RETURNS VOID LANGUAGE plpgsql AS '
BEGIN
    UPDATE n8n_pro_conversation_states 
    SET 
        estado_actual = nuevo_estado,
        nombre_cliente = COALESCE(nombre_param, nombre_cliente),
        ciudad = COALESCE(ciudad_param, ciudad),
        producto_interes = COALESCE(producto_param, producto_interes),
        telefono = COALESCE(telefono_param, telefono),
        direccion = COALESCE(direccion_param, direccion),
        email = COALESCE(email_param, email),
        ultima_actividad = CURRENT_TIMESTAMP
    WHERE session_id = session_id_param;
END;
';

-- 6. FUNCIÓN: ACTUALIZAR SOLO DATOS PERSONALES (SIN CAMBIAR ESTADO)
CREATE OR REPLACE FUNCTION actualizar_datos_cliente_pro(
    session_id_param VARCHAR,
    nombre_param VARCHAR DEFAULT NULL,
    ciudad_param VARCHAR DEFAULT NULL,
    producto_param VARCHAR DEFAULT NULL,
    telefono_param VARCHAR DEFAULT NULL,
    direccion_param TEXT DEFAULT NULL,
    email_param VARCHAR DEFAULT NULL
)
RETURNS VOID LANGUAGE plpgsql AS '
BEGIN
    UPDATE n8n_pro_conversation_states 
    SET 
        nombre_cliente = COALESCE(nombre_param, nombre_cliente),
        ciudad = COALESCE(ciudad_param, ciudad),
        producto_interes = COALESCE(producto_param, producto_interes),
        telefono = COALESCE(telefono_param, telefono),
        direccion = COALESCE(direccion_param, direccion),
        email = COALESCE(email_param, email),
        ultima_actividad = CURRENT_TIMESTAMP
    WHERE session_id = session_id_param;
END;
';

-- 7B. FUNCIÓN ALTERNATIVA: CAMBIAR ESTADO CON BIGINT
CREATE OR REPLACE FUNCTION cambiar_estado_conversacion_pro(
    session_id_param BIGINT,
    activa BOOLEAN
)
RETURNS TABLE (
    session_id_resultado VARCHAR,
    estado_anterior BOOLEAN,
    estado_nuevo BOOLEAN,
    actualizado BOOLEAN,
    mensaje TEXT
) LANGUAGE plpgsql AS '
BEGIN
    -- Llamar a la función principal convirtiendo BIGINT a VARCHAR
    RETURN QUERY
    SELECT * FROM cambiar_estado_conversacion_pro(session_id_param::VARCHAR, activa);
END;
';

-- 7. FUNCIÓN MEJORADA: CAMBIAR ESTADO CONVERSACIÓN (CON RESPUESTA)
CREATE OR REPLACE FUNCTION cambiar_estado_conversacion_pro(
    session_id_param VARCHAR,
    activa BOOLEAN
)
RETURNS TABLE (
    session_id_resultado VARCHAR,
    estado_anterior BOOLEAN,
    estado_nuevo BOOLEAN,
    actualizado BOOLEAN,
    mensaje TEXT
) LANGUAGE plpgsql AS '
DECLARE
    estado_previo BOOLEAN;
    filas_afectadas INTEGER;
BEGIN
    -- Obtener estado anterior
    SELECT cs.conversacion_activa INTO estado_previo
    FROM n8n_pro_conversation_states cs
    WHERE cs.session_id = session_id_param;
    
    -- Si no existe la sesión
    IF NOT FOUND THEN
        RETURN QUERY
        SELECT 
            session_id_param,
            NULL::BOOLEAN,
            NULL::BOOLEAN,
            FALSE,
            ''Sesión no encontrada''::TEXT;
        RETURN;
    END IF;
    
    -- Actualizar el estado
    UPDATE n8n_pro_conversation_states 
    SET conversacion_activa = activa,
        ultima_actividad = CURRENT_TIMESTAMP
    WHERE session_id = session_id_param;
    
    GET DIAGNOSTICS filas_afectadas = ROW_COUNT;
    
    -- Retornar resultado
    RETURN QUERY
    SELECT 
        session_id_param,
        estado_previo,
        activa,
        (filas_afectadas > 0),
        CASE 
            WHEN estado_previo = activa THEN ''Sin cambios - ya estaba en ese estado''
            WHEN activa THEN ''Conversación activada exitosamente''
            ELSE ''Conversación desactivada exitosamente''
        END::TEXT;
END;
';

-- 8. FUNCIÓN: BUSCAR CLIENTE POR TELÉFONO O EMAIL
CREATE OR REPLACE FUNCTION buscar_cliente_pro(
    telefono_param VARCHAR DEFAULT NULL,
    email_param VARCHAR DEFAULT NULL
)
RETURNS TABLE (
    session_id VARCHAR,
    estado VARCHAR,
    nombre VARCHAR,
    ciudad VARCHAR,
    telefono VARCHAR,
    direccion TEXT,
    email VARCHAR,
    conversacion_activa BOOLEAN
) LANGUAGE plpgsql AS '
BEGIN
    RETURN QUERY
    SELECT 
        cs.session_id,
        cs.estado_actual,
        cs.nombre_cliente,
        cs.ciudad,
        cs.telefono,
        cs.direccion,
        cs.email,
        cs.conversacion_activa
    FROM n8n_pro_conversation_states cs
    WHERE (telefono_param IS NOT NULL AND cs.telefono = telefono_param)
       OR (email_param IS NOT NULL AND cs.email = email_param)
    ORDER BY cs.ultima_actividad DESC;
END;
';

-- 9. FUNCIÓN: REACTIVAR CONVERSACIÓN SI ESTÁ INACTIVA
CREATE OR REPLACE FUNCTION reactivar_conversacion_si_inactiva_pro(session_id_param VARCHAR)
RETURNS BOOLEAN LANGUAGE plpgsql AS '
DECLARE
    filas_afectadas INTEGER;
BEGIN
    -- Reactivar solo si ha pasado más de 1 minuto
    UPDATE n8n_pro_conversation_states 
    SET conversacion_activa = TRUE,
        estado_actual = ''saludo'',
        ultima_actividad = CURRENT_TIMESTAMP
    WHERE session_id = session_id_param
      AND ultima_actividad < NOW() - INTERVAL ''1 minute'';
    
    GET DIAGNOSTICS filas_afectadas = ROW_COUNT;
    RETURN filas_afectadas > 0;
END;
';

-- 10. FUNCIÓN: LIMPIEZA AUTOMÁTICA DE CONVERSACIONES INACTIVAS
CREATE OR REPLACE FUNCTION limpiar_conversaciones_inactivas_pro(
    minutos_inactividad INTEGER DEFAULT 60
)
RETURNS TABLE (
    total_eliminadas INTEGER,
    total_desactivadas INTEGER,
    detalles TEXT
) LANGUAGE plpgsql AS '
DECLARE
    filas_eliminadas INTEGER := 0;
    filas_desactivadas INTEGER := 0;
    mensaje TEXT;
BEGIN
    -- Opción 1: Eliminar conversaciones muy antiguas (más de X minutos)
    DELETE FROM n8n_pro_conversation_states 
    WHERE ultima_actividad < NOW() - (minutos_inactividad || '' minutes'')::INTERVAL
      AND conversacion_activa = FALSE;
    
    GET DIAGNOSTICS filas_eliminadas = ROW_COUNT;
    
    -- Opción 2: Desactivar conversaciones menos antiguas
    UPDATE n8n_pro_conversation_states 
    SET conversacion_activa = FALSE
    WHERE ultima_actividad < NOW() - ((minutos_inactividad / 2) || '' minutes'')::INTERVAL
      AND conversacion_activa = TRUE;
    
    GET DIAGNOSTICS filas_desactivadas = ROW_COUNT;
    
    -- Crear mensaje informativo
    mensaje := ''Eliminadas: '' || filas_eliminadas || '' | Desactivadas: '' || filas_desactivadas || '' | Tiempo: '' || minutos_inactividad || '' min'';
    
    -- Retornar resultado
    RETURN QUERY
    SELECT 
        filas_eliminadas,
        filas_desactivadas,
        mensaje;
END;
';

-- 11. ⭐ FUNCIÓN PRINCIPAL: ACTIVAR CONVERSACIÓN CON VALIDACIÓN DE TIEMPO
CREATE OR REPLACE FUNCTION activar_conversacion_con_condicion_pro(
    session_id_param VARCHAR,
    minutos_requeridos INTEGER DEFAULT 1
)
RETURNS TABLE (
    session_id_resultado VARCHAR,
    fecha_ultima_actividad TIMESTAMP,
    fecha_actual TIMESTAMP,
    tiempo_transcurrido INTERVAL,
    minutos_transcurridos NUMERIC,
    condicion_cumplida BOOLEAN,
    conversacion_activada BOOLEAN,
    estado_anterior BOOLEAN,
    estado_nuevo BOOLEAN,
    mensaje TEXT
) LANGUAGE plpgsql AS '
DECLARE
    rec RECORD;
    filas_afectadas INTEGER;
    tiempo_diferencia INTERVAL;
    minutos_diff NUMERIC;
    cumple_condicion BOOLEAN := FALSE;
    se_activo BOOLEAN := FALSE;
    fecha_actual_sin_zona TIMESTAMP;
    fecha_actividad_sin_zona TIMESTAMP;
BEGIN
    -- Obtener fecha actual sin zona horaria
    fecha_actual_sin_zona := NOW()::TIMESTAMP;
    
    -- Obtener datos actuales de la sesión
    SELECT 
        cs.session_id,
        cs.ultima_actividad::TIMESTAMP as ultima_act_sin_zona,
        cs.conversacion_activa,
        fecha_actual_sin_zona - cs.ultima_actividad::TIMESTAMP as diferencia_tiempo
    INTO rec
    FROM n8n_pro_conversation_states cs
    WHERE cs.session_id = session_id_param;
    
    -- Si no existe la sesión
    IF NOT FOUND THEN
        RETURN QUERY
        SELECT 
            session_id_param,
            NULL::TIMESTAMP,
            fecha_actual_sin_zona,
            NULL::INTERVAL,
            NULL::NUMERIC,
            FALSE,
            FALSE,
            NULL::BOOLEAN,
            NULL::BOOLEAN,
            ''ERROR: Sesión no encontrada''::TEXT;
        RETURN;
    END IF;
    
    -- Calcular diferencia en minutos
    tiempo_diferencia := rec.diferencia_tiempo;
    minutos_diff := EXTRACT(EPOCH FROM tiempo_diferencia) / 60.0;
    
    -- Validar condición: ¿Ha pasado el tiempo requerido?
    cumple_condicion := (minutos_diff >= minutos_requeridos);
    
    -- Si cumple la condición Y la conversación NO está activa, activarla
    IF cumple_condicion AND rec.conversacion_activa = FALSE THEN
        UPDATE n8n_pro_conversation_states 
        SET 
            conversacion_activa = TRUE,
            ultima_actividad = CURRENT_TIMESTAMP
        WHERE session_id = session_id_param;
        
        GET DIAGNOSTICS filas_afectadas = ROW_COUNT;
        se_activo := (filas_afectadas > 0);
    END IF;
    
    -- Retornar resultado detallado
    RETURN QUERY
    SELECT 
        session_id_param,
        rec.ultima_act_sin_zona,
        fecha_actual_sin_zona,
        tiempo_diferencia,
        ROUND(minutos_diff, 2),
        cumple_condicion,
        se_activo,
        rec.conversacion_activa, -- Estado anterior
        CASE WHEN se_activo THEN TRUE ELSE rec.conversacion_activa END, -- Estado nuevo
        CASE 
            WHEN NOT cumple_condicion THEN 
                ''Condición NO cumplida. Faltan '' || ROUND((minutos_requeridos - minutos_diff), 2) || '' minutos''
            WHEN rec.conversacion_activa = TRUE THEN 
                ''Condición cumplida pero conversación YA estaba activa''
            WHEN se_activo THEN 
                ''✅ Conversación ACTIVADA exitosamente tras '' || ROUND(minutos_diff, 2) || '' minutos''
            ELSE 
                ''ERROR: No se pudo activar la conversación''
        END::TEXT;
END;
';

-- 11B. FUNCIÓN ALTERNATIVA: ACTIVAR CON BIGINT
CREATE OR REPLACE FUNCTION activar_conversacion_con_condicion_pro(
    session_id_param BIGINT,
    minutos_requeridos INTEGER DEFAULT 1
)
RETURNS TABLE (
    session_id VARCHAR,
    fecha_ultima_actividad TIMESTAMP,
    fecha_actual TIMESTAMP,
    tiempo_transcurrido INTERVAL,
    minutos_transcurridos NUMERIC,
    condicion_cumplida BOOLEAN,
    conversacion_activada BOOLEAN,
    estado_anterior BOOLEAN,
    estado_nuevo BOOLEAN,
    mensaje TEXT
) LANGUAGE plpgsql AS '
BEGIN
    -- Llamar a la función principal convirtiendo BIGINT a VARCHAR
    RETURN QUERY
    SELECT * FROM activar_conversacion_con_condicion_pro(session_id_param::VARCHAR, minutos_requeridos);
END;
';

-- 12. FUNCIÓN: HABILITAR CONVERSACIÓN ACTIVA (MASIVA O INDIVIDUAL)
CREATE OR REPLACE FUNCTION habilitar_conversacion_activa_pro(
    session_id_param VARCHAR DEFAULT NULL,
    minutos_inactividad INTEGER DEFAULT 1
)
RETURNS TABLE (
    session_id_actualizado VARCHAR,
    estado_anterior VARCHAR,
    estado_nuevo VARCHAR,
    tiempo_inactividad INTERVAL,
    resultado TEXT
) LANGUAGE plpgsql AS '
DECLARE
    rec RECORD;
    total_actualizadas INTEGER := 0;
BEGIN
    -- Si se proporciona un session_id específico, actualizar solo ese
    IF session_id_param IS NOT NULL THEN
        -- Verificar si existe y necesita reactivación
        SELECT 
            cs.session_id,
            cs.estado_actual,
            cs.conversacion_activa,
            NOW() - cs.ultima_actividad as tiempo_inactivo
        INTO rec
        FROM n8n_pro_conversation_states cs
        WHERE cs.session_id = session_id_param
          AND cs.conversacion_activa = FALSE
          AND cs.ultima_actividad < NOW() - (minutos_inactividad || '' minutes'')::INTERVAL;
        
        IF FOUND THEN
            -- Actualizar la conversación específica
            UPDATE n8n_pro_conversation_states 
            SET 
                conversacion_activa = TRUE,
                estado_actual = ''saludo'',
                ultima_actividad = CURRENT_TIMESTAMP
            WHERE session_id = session_id_param;
            
            -- Retornar resultado
            RETURN QUERY
            SELECT 
                session_id_param,
                rec.estado_actual,
                ''saludo''::VARCHAR,
                rec.tiempo_inactivo,
                ''Conversación reactivada exitosamente''::TEXT;
        ELSE
            -- No se encontró o no necesita reactivación
            RETURN QUERY
            SELECT 
                session_id_param,
                NULL::VARCHAR,
                NULL::VARCHAR,
                NULL::INTERVAL,
                ''No se encontró la sesión o no requiere reactivación''::TEXT;
        END IF;
    ELSE
        -- Actualizar todas las conversaciones inactivas
        FOR rec IN 
            SELECT 
                cs.session_id,
                cs.estado_actual,
                NOW() - cs.ultima_actividad as tiempo_inactivo
            FROM n8n_pro_conversation_states cs
            WHERE cs.conversacion_activa = FALSE
              AND cs.ultima_actividad < NOW() - (minutos_inactividad || '' minutes'')::INTERVAL
        LOOP
            -- Actualizar cada conversación
            UPDATE n8n_pro_conversation_states 
            SET 
                conversacion_activa = TRUE,
                estado_actual = ''saludo'',
                ultima_actividad = CURRENT_TIMESTAMP
            WHERE session_id = rec.session_id;
            
            total_actualizadas := total_actualizadas + 1;
            
            -- Retornar cada resultado
            RETURN QUERY
            SELECT 
                rec.session_id,
                rec.estado_actual,
                ''saludo''::VARCHAR,
                rec.tiempo_inactivo,
                (''Conversación '' || total_actualizadas || '' reactivada'')::TEXT;
        END LOOP;
        
        -- Si no se encontraron conversaciones para reactivar
        IF total_actualizadas = 0 THEN
            RETURN QUERY
            SELECT 
                NULL::VARCHAR,
                NULL::VARCHAR,
                NULL::VARCHAR,
                NULL::INTERVAL,
                ''No se encontraron conversaciones inactivas para reactivar''::TEXT;
        END IF;
    END IF;
END;
';

-- 13. FUNCIÓN: HABILITAR CONVERSACIÓN SIMPLE (TRUE/FALSE)
CREATE OR REPLACE FUNCTION habilitar_conversacion_simple_pro(
    session_id_param VARCHAR,
    forzar_reactivacion BOOLEAN DEFAULT FALSE
)
RETURNS BOOLEAN LANGUAGE plpgsql AS '
DECLARE
    filas_afectadas INTEGER;
    condicion_tiempo BOOLEAN;
BEGIN
    -- Verificar si ha pasado suficiente tiempo o si se fuerza la reactivación
    IF forzar_reactivacion THEN
        condicion_tiempo := TRUE;
    ELSE
        SELECT EXISTS(
            SELECT 1 FROM n8n_pro_conversation_states 
            WHERE session_id = session_id_param 
              AND ultima_actividad < NOW() - INTERVAL ''1 minute''
        ) INTO condicion_tiempo;
    END IF;
    
    -- Solo actualizar si se cumple la condición
    IF condicion_tiempo THEN
        UPDATE n8n_pro_conversation_states 
        SET 
            conversacion_activa = TRUE,
            ultima_actividad = CURRENT_TIMESTAMP
        WHERE session_id = session_id_param;
        
        GET DIAGNOSTICS filas_afectadas = ROW_COUNT;
        RETURN filas_afectadas > 0;
    END IF;
    
    RETURN FALSE;
END;
';

-- 14. FUNCIÓN: VERIFICAR ESTADO DE CONVERSACIÓN
CREATE OR REPLACE FUNCTION verificar_estado_conversacion_pro(session_id_param VARCHAR)
RETURNS TABLE (
    session_id VARCHAR,
    estado_actual VARCHAR,
    conversacion_activa BOOLEAN,
    tiempo_inactividad INTERVAL,
    requiere_reactivacion BOOLEAN,
    ultima_actividad TIMESTAMP
) LANGUAGE plpgsql AS '
BEGIN
    RETURN QUERY
    SELECT 
        cs.session_id,
        cs.estado_actual,
        cs.conversacion_activa,
        NOW() - cs.ultima_actividad as tiempo_inactividad,
        (cs.conversacion_activa = FALSE AND cs.ultima_actividad < NOW() - INTERVAL ''1 minute'') as requiere_reactivacion,
        cs.ultima_actividad
    FROM n8n_pro_conversation_states cs
    WHERE cs.session_id = session_id_param;
END;
';

-- ========================================
-- EJEMPLOS DE USO:
-- ========================================

/*
-- FUNCIÓN PRINCIPAL RECOMENDADA (CORREGIDA):
-- Tu consulta exacta que estaba fallando:
SELECT * FROM activar_conversacion_con_condicion_pro(
  SPLIT_PART('573011284297@s.whatsapp.net', '@', 1)
);

-- Otras variaciones:
SELECT * FROM activar_conversacion_con_condicion_pro('573011284297');
SELECT * FROM activar_conversacion_con_condicion_pro('573011284297', 1);
SELECT * FROM activar_conversacion_con_condicion_pro('573011284297', 2);

-- OTRAS FUNCIONES ÚTILES:
-- Habilitar TODAS las conversaciones después de 1 minuto
SELECT * FROM habilitar_conversacion_activa_pro(NULL, 1);

-- Cambiar estado con información detallada
SELECT * FROM cambiar_estado_conversacion_pro('573011284297', TRUE);

-- Verificar estado antes de hacer cambios
SELECT * FROM verificar_estado_conversacion_pro('573011284297');

-- Actualizar solo datos personales
SELECT actualizar_datos_cliente_pro('573011284297', 'Juan Pérez', 'Medellín');

-- Buscar cliente por teléfono
SELECT * FROM buscar_cliente_pro('573011284297', NULL);

-- FUNCIÓN SIMPLE PARA CASOS BÁSICOS:
SELECT habilitar_conversacion_simple_pro('573011284297');
*/