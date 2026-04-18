# 👥 Módulo: Usuarios, Login y Roles

Describe cómo se gestiona la autenticación y las relaciones laborales en el sistema.

```mermaid
erDiagram

usuarios {
    INT id_usuario PK
    VARCHAR nombres
    VARCHAR apellido_paterno
    VARCHAR apellido_materno
    VARCHAR celular
}

roles {
    INT id_rol PK
    VARCHAR nombre_rol
}

login {
    INT id_login PK
    VARCHAR email
    INT id_usuario FK
    INT id_rol FK
}

empleados {
    INT id_empleado PK
    INT id_usuario FK
    INT id_empresa FK
    VARCHAR cargo
}

usuarios ||--o{ empleados : "puede ser empleado"
usuarios ||--o{ login : "tiene login"
roles ||--o{ login : "define rol de acceso"
```

- Un **usuario** puede ser **empleado de una empresa** y/o **tener acceso de login**.
- La tabla **login** define credenciales y se relaciona también con los **roles de acceso**.

[⬅️ Empresas y Recursos](./ERD_empresas_recursos.md)   [⬆️ Índice](./../../Base%20de%20datos/README.md)   [➡️ Operaciones y Stock](./ERD_operaciones_stock.md)