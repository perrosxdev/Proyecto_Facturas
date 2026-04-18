# 🌍 Módulo: Geografía

Este módulo representa la estructura jerárquica de ubicación utilizada en el sistema:  
**Región > Comuna > Ciudad**.  
Sirve como base para ubicar empresas, clientes y bodegas.

```mermaid
erDiagram

region {
    INT id_region PK
    VARCHAR nombre_region
}

comuna {
    INT id_comuna PK
    INT id_region FK
    VARCHAR nombre_comuna
}

ciudad {
    INT id_ciudad PK
    INT id_comuna FK
    VARCHAR nombre_ciudad
}

region ||--o{ comuna : "incluye"
comuna ||--o{ ciudad : "incluye"
```
- **region incluye comunas:** Una región puede tener muchas comunas.
- **comuna incluye ciudades:** Una comuna puede tener muchas ciudades.