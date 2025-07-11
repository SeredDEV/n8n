-- ========================================
-- SCRIPT COMPLETO PARA n8n_conversation_states
-- Ed Perfumería - Gestión de Estados de Conversación
-- ========================================

-- 1. CREAR LA TABLA PRINCIPAL
CREATE TABLE n8n_conversation_states (
    id SERIAL PRIMARY KEY,
    session_id VARCHAR(50) NOT NULL,
    estado_actual VARCHAR(20) NOT NULL DEFAULT 'saludo',
    fecha_inicio TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ultima_actividad TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Datos básicos del cliente
    nombre_cliente VARCHAR(100),
    ciudad VARCHAR(50),
    producto_interes VARCHAR(200),
    
    -- Contexto como JSON para flexibilidad
    contexto JSONB DEFAULT '{}',
    
    -- Control de conversación
    conversacion_activa BOOLEAN DEFAULT TRUE,
    
    CONSTRAINT uk_session_id UNIQUE(session_id)
);

-- 2. CREAR ÍNDICES PARA OPTIMIZACIÓN
CREATE INDEX idx_n8n_conversation_session ON n8n_conversation_states(session_id);
CREATE INDEX idx_n8n_conversation_estado ON n8n_conversation_states(estado_actual);
CREATE INDEX idx_n8n_conversation_actividad ON n8n_conversation_states(ultima_actividad);
CREATE INDEX idx_n8n_conversation_activa ON n8n_conversation_states(conversacion_activa);

-- 3. AGREGAR RESTRICCIONES DE VALIDACIÓN
ALTER TABLE n8n_conversation_states 
ADD CONSTRAINT chk_estado_actual 
CHECK (estado_actual IN ('saludo', 'ventas', 'soporte'));

ALTER TABLE n8n_conversation_states 
ADD CONSTRAINT chk_session_id_not_empty 
CHECK (LENGTH(TRIM(session_id)) > 0);

ALTER TABLE n8n_conversation_states 
ADD CONSTRAINT chk_conversacion_activa 
CHECK (conversacion_activa IN (true, false));

-- 4. CREAR FUNCIÓN PARA ACTUALIZAR ACTIVIDAD AUTOMÁTICAMENTE
CREATE OR REPLACE FUNCTION actualizar_actividad()
RETURNS TRIGGER AS 
$$
BEGIN
    NEW.ultima_actividad = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ 
LANGUAGE plpgsql;

-- 5. CREAR TRIGGER PARA ACTUALIZACIÓN AUTOMÁTICA
CREATE TRIGGER trigger_actualizar_actividad
    BEFORE UPDATE ON n8n_conversation_states
    FOR EACH ROW
    EXECUTE FUNCTION actualizar_actividad();

-- 6. CREAR FUNCIÓN: OBTENER O CREAR ESTADO DEL CLIENTE
CREATE OR REPLACE FUNCTION obtener_crear_estado_cliente(session_id_param VARCHAR)
RETURNS TABLE (
    estado VARCHAR,
    nombre VARCHAR,
    ciudad VARCHAR,
    producto_interes VARCHAR,
    contexto JSONB
) AS 
$$
BEGIN
    -- Insertar si no existe
    INSERT INTO n8n_conversation_states (session_id, estado_actual) 
    VALUES (session_id_param, 'saludo') 
    ON CONFLICT (session_id) DO NOTHING;
    
    -- Retornar datos actuales
    RETURN QUERY
    SELECT 
        cs.estado_actual,
        cs.nombre_cliente,
        cs.ciudad,
        cs.producto_interes,
        cs.contexto
    FROM n8n_conversation_states cs
    WHERE cs.session_id = session_id_param;
END;
$$ 
LANGUAGE plpgsql;

-- 7. CREAR FUNCIÓN: ACTUALIZAR ESTADO DEL CLIENTE
CREATE OR REPLACE FUNCTION actualizar_estado_cliente(
    session_id_param VARCHAR,
    nuevo_estado VARCHAR,
    nombre_param VARCHAR DEFAULT NULL,
    ciudad_param VARCHAR DEFAULT NULL,
    producto_param VARCHAR DEFAULT NULL
)
RETURNS VOID AS 
$$
BEGIN
    UPDATE n8n_conversation_states 
    SET 
        estado_actual = nuevo_estado,
        nombre_cliente = COALESCE(nombre_param, nombre_cliente),
        ciudad = COALESCE(ciudad_param, ciudad),
        producto_interes = COALESCE(producto_param, producto_interes)
    WHERE session_id = session_id_param;
END;
$$ 
LANGUAGE plpgsql;

-- 8. CREAR FUNCIÓN: LIMPIAR CONVERSACIONES INACTIVAS
CREATE OR REPLACE FUNCTION limpiar_conversaciones_inactivas()
RETURNS INTEGER AS 
$$
DECLARE
    filas_actualizadas INTEGER;
BEGIN
    UPDATE n8n_conversation_states 
    SET estado_actual = 'saludo', 
        conversacion_activa = FALSE
    WHERE ultima_actividad < NOW() - INTERVAL '24 hours'
      AND conversacion_activa = TRUE;
    
    GET DIAGNOSTICS filas_actualizadas = ROW_COUNT;
    RETURN filas_actualizadas;
END;
$$ 
LANGUAGE plpgsql;

-- 9. AGREGAR COMENTARIOS A LA TABLA
COMMENT ON TABLE n8n_conversation_states IS 'Estado actual de cada conversación de cliente para control del flujo del chatbot';
COMMENT ON COLUMN n8n_conversation_states.session_id IS 'Identificador único de la conversación (compatible con n8n_chat_histories)';
COMMENT ON COLUMN n8n_conversation_states.estado_actual IS 'Estado actual: saludo, ventas, soporte';
COMMENT ON COLUMN n8n_conversation_states.contexto IS 'Información adicional en formato JSON';

-- 10. INSERTAR DATOS DE EJEMPLO
INSERT INTO n8n_conversation_states (session_id, estado_actual, nombre_cliente, ciudad, producto_interes) 
VALUES ('573011284297', 'ventas', 'Sergio Eduardo Rodriguez Morales', 'Medellín', 'Dior Sauvage');

-- ========================================
-- CONSULTAS PARA USAR EN N8N
-- ========================================

-- FUNCIÓN PRINCIPAL (Recomendada):
-- SELECT * FROM obtener_crear_estado_cliente('{{ $json.session_id }}');

-- CAMBIAR ESTADO:
-- SELECT actualizar_estado_cliente('{{ $json.session_id }}', 'ventas');

-- GUARDAR DATOS DEL CLIENTE:
-- SELECT actualizar_estado_cliente('{{ $json.session_id }}', 'ventas', '{{ $json.nombre }}', '{{ $json.ciudad }}', '{{ $json.producto }}');

-- LIMPIAR CONVERSACIONES VIEJAS:
-- SELECT limpiar_conversaciones_inactivas();

-- CONSULTAS DIRECTAS (Alternativas):
-- SELECT estado_actual FROM n8n_conversation_states WHERE session_id = '{{ $json.session_id }}';
-- UPDATE n8n_conversation_states SET estado_actual = 'ventas' WHERE session_id = '{{ $json.session_id }}';

-- VER ESTADÍSTICAS:
-- SELECT estado_actual, COUNT(*) as cantidad FROM n8n_conversation_states WHERE conversacion_activa = true GROUP BY estado_actual;

-- VER TODAS LAS CONVERSACIONES ACTIVAS:
-- SELECT * FROM n8n_conversation_states WHERE conversacion_activa = true ORDER BY ultima_actividad DESC;

-- VERIFICAR RESTRICCIONES:
-- SELECT constraint_name, constraint_type, check_clause FROM information_schema.table_constraints tc LEFT JOIN information_schema.check_constraints cc ON tc.constraint_name = cc.constraint_name WHERE tc.table_name = 'n8n_conversation_states';

-- ========================================
-- VERIFICACIÓN FINAL
-- ========================================

-- Verificar que la tabla se creó correctamente
SELECT 'Tabla creada exitosamente' as mensaje, COUNT(*) as registros_ejemplo FROM n8n_conversation_states;

-- Verificar que las funciones funcionan
SELECT 'Función funcionando' as mensaje, * FROM obtener_crear_estado_cliente('test_cliente_123');

-- Limpiar cliente de prueba
DELETE FROM n8n_conversation_states WHERE session_id = 'test_cliente_123';