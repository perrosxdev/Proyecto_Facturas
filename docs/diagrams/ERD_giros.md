# 🔄 Módulo: Giros y Relaciones

Explica cómo las empresas y clientes se asocian a diferentes rubros económicos (giros).

```mermaid
erDiagram

lista_giros {
    INT id_giro PK
    VARCHAR nombre_giro
}

giros_empresa {
    INT id PK
    INT id_giro FK
    INT id_empresa FK
}
clientes {
    INT id_cliente PK
    INT id_empresa FK
    INT id_giro FK
    VARCHAR nombre_cliente
}

giros_empresa }o--|| lista_giros : "debe existir en"
giros_empresa }o--|| empresa : "relaciona"
clientes }o--|| lista_giros : "tiene giro"
```

- Un **giro** representa una actividad económica.
- Una **empresa** puede tener varios giros y un **cliente** está asociado a uno.

[⬅️ Flota y Vehículos](./ERD_flota_vehiculo.md)   [⬆️ Índice](./../../Base%20de%20datos/README.md)