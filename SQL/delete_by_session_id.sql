-- =====================================================
-- QUERIES PARA BORRAR REGISTROS POR SESSION_ID
-- Tabla: n8n_pro_conversation_states
-- =====================================================

-- 1. BORRAR UN REGISTRO ESPECÍFICO POR SESSION_ID (SIN FILTRO DE FECHA)
-- Reemplaza 'TU_SESSION_ID_AQUI' con el session_id que quieres borrar
DELETE FROM n8n_pro_conversation_states 
WHERE session_id = 'TU_SESSION_ID_AQUI';

-- =====================================================

-- 2. BORRAR REGISTROS POR SESSION_ID QUE TENGAN MÁS DE 1 DÍA DE ANTIGÜEDAD
-- Esta query borra registros que sean más antiguos que 1 día
DELETE FROM n8n_pro_conversation_states 
WHERE session_id = 'TU_SESSION_ID_AQUI' 
  AND fecha_inicio < (CURRENT_TIMESTAMP - INTERVAL '1 day');

-- =====================================================

-- 3. BORRAR REGISTROS POR SESSION_ID QUE TENGAN MÁS DE 1 DÍA DESDE LA ÚLTIMA ACTIVIDAD
-- Esta query usa ultima_actividad en lugar de fecha_inicio
DELETE FROM n8n_pro_conversation_states 
WHERE session_id = 'TU_SESSION_ID_AQUI' 
  AND ultima_actividad < (CURRENT_TIMESTAMP - INTERVAL '1 day');

-- =====================================================

-- 4. BORRAR TODOS LOS REGISTROS QUE TENGAN MÁS DE 1 DÍA (SIN IMPORTAR SESSION_ID)
-- Esta query borra TODOS los registros antiguos de más de 1 día
DELETE FROM n8n_pro_conversation_states 
WHERE fecha_inicio < (CURRENT_TIMESTAMP - INTERVAL '1 day');

-- =====================================================

-- 5. BORRAR CON DIFERENTES INTERVALOS DE TIEMPO
-- Más de 1 día
DELETE FROM n8n_pro_conversation_states 
WHERE session_id = 'TU_SESSION_ID_AQUI' 
  AND fecha_inicio < (CURRENT_TIMESTAMP - INTERVAL '1 day');

-- Más de 1 hora
DELETE FROM n8n_pro_conversation_states 
WHERE session_id = 'TU_SESSION_ID_AQUI' 
  AND fecha_inicio < (CURRENT_TIMESTAMP - INTERVAL '1 hour');

-- Más de 30 minutos
DELETE FROM n8n_pro_conversation_states 
WHERE session_id = 'TU_SESSION_ID_AQUI' 
  AND fecha_inicio < (CURRENT_TIMESTAMP - INTERVAL '30 minutes');

-- =====================================================

-- 6. VERIFICAR ANTES DE BORRAR - CONSULTAR REGISTROS QUE SE VAN A ELIMINAR
-- Ver qué registros tienen más de 1 día de antigüedad
SELECT session_id, fecha_inicio, ultima_actividad,
       CURRENT_TIMESTAMP - fecha_inicio as antiguedad
FROM n8n_pro_conversation_states 
WHERE session_id = 'TU_SESSION_ID_AQUI' 
  AND fecha_inicio < (CURRENT_TIMESTAMP - INTERVAL '1 day');

-- =====================================================

-- 7. FUNCIÓN PARA BORRAR REGISTROS ANTIGUOS POR SESSION_ID
CREATE OR REPLACE FUNCTION borrar_registros_antiguos_por_session(
    session_id_param VARCHAR,
    dias_antiguedad INTEGER DEFAULT 1
)
RETURNS INTEGER LANGUAGE plpgsql AS $$
DECLARE
    registros_borrados INTEGER;
BEGIN
    DELETE FROM n8n_pro_conversation_states 
    WHERE session_id = session_id_param 
      AND fecha_inicio < (CURRENT_TIMESTAMP - (dias_antiguedad || ' days')::INTERVAL);
    
    GET DIAGNOSTICS registros_borrados = ROW_COUNT;
    
    RAISE NOTICE 'Se borraron % registros antiguos (más de % días) para session_id: %', 
                 registros_borrados, dias_antiguedad, session_id_param;
    
    RETURN registros_borrados;
END;
$$;

-- Ejemplos de uso de la función:
-- SELECT borrar_registros_antiguos_por_session('TU_SESSION_ID_AQUI', 1);  -- Más de 1 día
-- SELECT borrar_registros_antiguos_por_session('TU_SESSION_ID_AQUI', 7);  -- Más de 7 días

-- =====================================================

-- 8. BORRAR CON BACKUP PREVIO (MUY RECOMENDADO)
-- Crear tabla de respaldo si no existe
CREATE TABLE IF NOT EXISTS n8n_pro_conversation_states_backup AS 
SELECT * FROM n8n_pro_conversation_states WHERE 1=0;

-- Hacer backup de los registros que se van a borrar
INSERT INTO n8n_pro_conversation_states_backup 
SELECT * FROM n8n_pro_conversation_states 
WHERE session_id = 'TU_SESSION_ID_AQUI' 
  AND fecha_inicio < (CURRENT_TIMESTAMP - INTERVAL '1 day');

-- Luego borrar los registros originales
DELETE FROM n8n_pro_conversation_states 
WHERE session_id = 'TU_SESSION_ID_AQUI' 
  AND fecha_inicio < (CURRENT_TIMESTAMP - INTERVAL '1 day');

-- =====================================================

-- 9. LIMPIEZA AUTOMÁTICA - BORRAR TODOS LOS REGISTROS ANTIGUOS
-- Esta query borra TODOS los registros de CUALQUIER session_id que tengan más de 1 día
DELETE FROM n8n_pro_conversation_states 
WHERE fecha_inicio < (CURRENT_TIMESTAMP - INTERVAL '1 day');

-- =====================================================

-- 10. VERIFICAR RESULTADOS
-- Contar cuántos registros quedan para el session_id
SELECT COUNT(*) as registros_restantes 
FROM n8n_pro_conversation_states 
WHERE session_id = 'TU_SESSION_ID_AQUI';

-- Ver todos los registros restantes para el session_id
SELECT session_id, fecha_inicio, ultima_actividad, estado_actual, estado_ventas
FROM n8n_pro_conversation_states 
WHERE session_id = 'TU_SESSION_ID_AQUI'
ORDER BY fecha_inicio DESC;