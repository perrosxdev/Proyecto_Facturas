# 📦 Módulo: Operaciones y Stock

Describe el flujo de productos y gestión de inventario.

```mermaid
erDiagram

bodega {
    INT id_bodega PK
    INT id_empresa FK
    VARCHAR nombre_bodega
}

producto {
    INT id_producto PK
    INT id_empresa FK
    VARCHAR nombre_producto
}

proveedores {
    INT id_proveedor PK
    INT id_empresa FK
    VARCHAR nombre_proveedor
}

producto_proveedor {
    INT id PK
    INT id_empresa FK
    INT id_producto FK
    INT id_proveedor FK
}

inventario {
    INT id_inventario PK
    INT id_empresa FK
    INT id_bodega FK
    INT id_producto FK
    INT stock
}

producto ||--o{ producto_proveedor : "tiene proveedor"
proveedores ||--o{ producto_proveedor : "provee"
bodega ||--o{ inventario : "almacena stock"
producto ||--o{ inventario : "cuenta stock en"
```

- Un **producto** puede tener varios **proveedores** y almacenarse en diferentes **bodegas**.
- El **inventario** vincula productos y bodegas para saber dónde y cuánto hay.

[⬅️ Usuarios, Login y Roles](./ERD_usuarios_roles.md)   [⬆️ Índice](../../Base de datos/README.md)   [➡️ Flota y Vehículos](./ERD_flota_vehiculo.md)