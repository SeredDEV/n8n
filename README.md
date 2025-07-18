# 🌟 ED PERFUMERÍA - Sistema de Ventas Automatizado con n8n

## 📋 Descripción del Proyecto

Este proyecto implementa un **sistema de ventas automatizado** para ED PERFUMERÍA utilizando **n8n** como plataforma de automatización. El sistema cuenta con múltiples agentes especializados que trabajan en conjunto para brindar una experiencia completa de venta de perfumes y fragancias a través de WhatsApp.

## 🤖 Arquitectura del Sistema

### Agentes Especializados

El sistema está compuesto por **5 agentes principales** que trabajan de forma coordinada:

#### 1. 🚦 **Router Agent Sales** (`Router Agent Sales.md`)
- **Función**: Agente principal que analiza las consultas y las dirige al especialista correcto
- **Características**:
  - Ejecuta **SOLO UNA HERRAMIENTA** por consulta
  - Mantiene memoria de conversación mediante PostgreSQL
  - Detecta procesos de venta activos
  - Dirige el flujo de conversación

#### 2. 📦 **Inventory Agent** (`inventory_agent.md`)
- **Función**: Especialista en consultas de inventario y disponibilidad
- **Responsabilidades**:
  - Consultar sistema de inventario en Google Sheets
  - Verificar disponibilidad de productos
  - Proporcionar precios actualizados
  - Información de marcas y contenidos

#### 3. 💡 **Recommendation Agent** (`recommendation_agent.md`)
- **Función**: Consultor experto en recomendaciones personalizadas
- **Capacidades**:
  - Analizar preferencias del cliente
  - Recomendar fragancias según ocasión y estilo
  - Considerar presupuesto del cliente
  - Proporcionar consejos especializados

#### 4. ⚖️ **Product Comparator Agent** (`product_comparator_agent.md`)
- **Función**: Analista especializado en comparaciones técnicas
- **Servicios**:
  - Comparar productos específicos
  - Análisis detallado de características
  - Ayudar en decisiones informadas
  - Evaluación objetiva de opciones

#### 5. 💰 **Sales Specialist Agent** (`sales_specialist_agent.md`)
- **Función**: Especialista en cierre de ventas y transacciones
- **Funciones clave**:
  - Aplicar promociones automáticamente
  - Calcular descuentos y totales
  - Gestionar métodos de pago
  - Coordinar entregas
  - Finalizar compras

## 🗂️ Estructura del Proyecto

```
📁 Proyecto ED PERFUMERÍA/
├── 📁 Prompt/                          # Prompts de configuración de agentes
│   ├── 📄 Router Agent Sales.md        # Agente router principal
│   ├── 📄 inventory_agent.md           # Agente de inventario
│   ├── 📄 recommendation_agent.md      # Agente de recomendaciones
│   ├── 📄 product_comparator_agent.md  # Agente comparador
│   └── 📄 sales_specialist_agent.md    # Agente de ventas
├── 📁 SQL/                             # Scripts de base de datos
│   └── 📄 script_production_table.sql  # Configuración PostgreSQL
├── 📁 workflows/                       # Flujos de trabajo n8n
│   ├── 📄 My Sub Inventory Agent.json
│   ├── 📄 My Sub Product Comparator Agent.json
│   ├── 📄 My Sub Recommendation Agent.json
│   ├── 📄 My Sub Sales Specialist Agent.json
│   └── 📄 z-Api.json                   # API principal
└── 📄 README.md                        # Este archivo
```

## 🛠️ Tecnologías Utilizadas

- **🔄 n8n**: Plataforma de automatización principal
- **🐘 PostgreSQL**: Base de datos para memoria conversacional
- **📊 Google Sheets**: Sistema de inventario
- **📱 WhatsApp API**: Canal de comunicación con clientes
- **🤖 AI/LLM**: Procesamiento de lenguaje natural
- **📋 JSON**: Formato de intercambio de datos

## 🔧 Funcionalidades Principales

### 💬 Gestión de Conversaciones
- Memoria persistente de conversaciones
- Detección de contexto y seguimiento de ventas
- Manejo de estados de conversación

### 📦 Gestión de Inventario
- Consulta en tiempo real a Google Sheets
- Verificación de disponibilidad
- Información de precios actualizada
- Categorización por género y marca

### 🎯 Recomendaciones Inteligentes
- Análisis de preferencias del cliente
- Recomendaciones personalizadas
- Consideración de presupuesto y ocasión

### 🔍 Comparación de Productos
- Análisis técnico detallado
- Comparaciones objetivas
- Ayuda en la toma de decisiones

### 💳 Proceso de Ventas
- Aplicación automática de promociones
- Cálculo de descuentos por cantidad
- Múltiples métodos de pago
- Gestión de envíos
- Confirmación de pedidos

## 🗄️ Base de Datos

### Tabla Principal: `n8n_pro_conversation_states`

Almacena el estado y contexto de cada conversación:

```sql
- session_id: Identificador único de sesión
- estado_actual: Estado actual de la conversación
- nombre_cliente: Nombre del cliente (opcional)
- ciudad: Ciudad del cliente (opcional)
- producto_interes: Producto de interés
- telefono: Número de teléfono
- direccion: Dirección de entrega
- contexto: Información adicional en formato JSON
```

## 🚀 Flujo de Trabajo

1. **🎯 Recepción**: Cliente envía mensaje por WhatsApp
2. **🔍 Análisis**: Router Agent analiza la consulta
3. **📡 Derivación**: Se dirige al agente especializado correcto
4. **⚙️ Procesamiento**: Agente especializado procesa la solicitud
5. **📊 Consulta**: Se accede a la base de datos/inventario según necesidad
6. **💬 Respuesta**: Se genera respuesta personalizada
7. **📝 Registro**: Se actualiza el estado de la conversación

## 📋 Estados de Conversación

- `saludo`: Estado inicial de bienvenida
- `catalogo`: Navegación por productos
- `ofertas`: Consulta de promociones
- `consulta`: Consultas generales
- `ventas`: Proceso de venta activo
- `soporte`: Atención al cliente

## 🎯 Características Especiales

### 🔄 Memoria Conversacional
- Mantiene contexto entre mensajes
- Reconoce referencias a productos anteriores
- Detecta procesos de venta en curso

### 🎁 Sistema de Promociones
- Descuentos automáticos por cantidad (6+ lociones)
- Precios mayoristas
- Ofertas especiales

### 📱 Integración WhatsApp
- Respuestas automáticas
- Procesamiento de mensajes de texto
- Soporte para diferentes tipos de mensaje

## 🔧 Configuración y Uso

1. **Configurar n8n** con los workflows proporcionados
2. **Configurar PostgreSQL** usando el script SQL
3. **Conectar Google Sheets** con el inventario
4. **Configurar WhatsApp API** para comunicación
5. **Activar workflows** en n8n

## 📞 Contacto y Soporte

Este sistema está diseñado para **ED PERFUMERÍA** y maneja automáticamente:
- Consultas de productos
- Recomendaciones personalizadas
- Procesos de venta completos
- Soporte al cliente
- Gestión de inventario

---

*Desarrollado con ❤️ para automatizar y mejorar la experiencia de venta de perfumes y fragancias.*
