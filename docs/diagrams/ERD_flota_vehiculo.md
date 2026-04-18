# 🚚 Módulo: Flota y Vehículos

Visualiza la estructura de la administración de flotas y los vehículos asignados.

```mermaid
erDiagram

flota {
    INT id_flota PK
    INT id_empresa FK
    VARCHAR nombre_flota
    INT id_bodega FK
}
vehiculo {
    INT id_vehiculo PK
    INT id_flota FK
    VARCHAR patente
    VARCHAR marca
    VARCHAR modelo
}

flota ||--o{ vehiculo : "contiene"
```

- Una **flota** representa un grupo de vehículos y está vinculada a una empresa y a una bodega.
- Un **vehículo** pertenece a una flota dada.

[⬅️ Operaciones y Stock](./ERD_operaciones_stock.md)   [⬆️ Índice](./../../Base de datos/README.md)   [➡️ Giros y Relaciones](./ERD_giros.md)