# 🏢 Módulo: Empresas y Recursos

Aquí vemos la columna vertebral del sistema:  
cómo una empresa se vincula con diferentes recursos y entidades operativas.

```mermaid
erDiagram

empresa {
    INT id_empresa PK
    VARCHAR nombre_empresa
    VARCHAR rut_empresa
    VARCHAR calle
    INT numero
    INT id_ciudad FK
}
clientes {
    INT id_cliente PK
    INT id_empresa FK
    VARCHAR nombre_cliente
    VARCHAR rut_cliente
    INT id_ciudad FK
}
bodega {
    INT id_bodega PK
    INT id_empresa FK
    VARCHAR nombre_bodega
    INT id_ciudad FK
}
proveedores {
    INT id_proveedor PK
    INT id_empresa FK
    VARCHAR nombre_proveedor
}
producto {
    INT id_producto PK
    INT id_empresa FK
    VARCHAR nombre_producto
}
flota {
    INT id_flota PK
    INT id_empresa FK
    VARCHAR nombre_flota
    INT id_bodega FK
}

empresa ||--o{ clientes : "provee servicios a"
empresa ||--o{ bodega : "posee"
empresa ||--o{ proveedores : "contrata a"
empresa ||--o{ producto : "fabrica/ofrece"
empresa ||--o{ flota : "administra"
bodega ||--o{ flota : "alberga flota"
```

**Explicación:**
- Una **empresa** puede **poseer varias bodegas**, **administrar flotas**, **fabricar productos** y **proveer servicios a clientes**.
- Una **bodega** está asociada a una empresa y puede **albergar flotas**.