# 🗄️ Diagramas de Base de Datos - Módulos

Bienvenido/a al visualizador de la arquitectura de datos de este sistema.  
Aquí encontrarás el modelo relacional dividido en módulos lógicos para facilitar la comprensión y mantención.

## Diagrama completo (DBdiagram)

[Visualizar Diagrama ER ](https://dbdiagram.io/d/Facturin-Diagram-69e2e7520aa78f6bc1026567)

## Diagrama por modulos (Mermaid)

La simbología empleada es la estándar de [Mermaid ERD](https://mermaid.js.org/syntax/entity-relationship-diagram.html), que GitHub renderiza automáticamente en los `.md` compatibles.

---

### Índice de módulos

1. [🌍 Geografía](../docs/diagrams/ERD_geografia.md)  
    Tablas para regiones, comunas y ciudades, base para ubicaciones.

2. [🏢 Empresas y Recursos](../docs/diagrams/ERD_empresas_recursos.md)  
    Cómo una empresa se relaciona con clientes, bodegas, productos, proveedores y flotas.

3. [👥 Usuarios, Login y Roles](../docs/diagrams/ERD_usuarios_roles.md)  
    Gestión de usuarios, acceso, roles y relaciones laborales.

4. [📦 Operaciones y Stock](../docs/diagrams/ERD_operaciones_stock.md)  
    Cómo se maneja el inventario, los proveedores y el flujo de productos.

5. [🚚 Flota y Vehículos](../docs/diagrams/ERD_flota_vehiculo.md)  
    Estructura de la gestión de flotas y sus vehículos.

6. [🔄 Giros y Relaciones](../docs/diagrams/ERD_giros.md)  
    Organización de los giros comerciales y su vínculo con empresas/clientes.

---

**Cómo leer los diagramas:**
- **Tablas**: Cada bloque es una tabla con sus columnas principales.
- **Conexiones**: Las flechas llevan frases que explican el significado del vínculo.
- **Relaciones**: “||--o{” significa “uno a muchos”; “}o--||” es “muchos a uno”.
- **Frases**: Lee la leyenda de la flecha como “A [frase] B”; por ejemplo:  
  `empresa ||--o{ bodega : "posee"` → “Una empresa posee muchas bodegas”.

---