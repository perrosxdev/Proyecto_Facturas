# Proyecto Facturas

## Descripción General
Sistema integral de gestión empresarial diseñado para automatizar la emisión de documentos tributarios, gestión de inventario, clientes, empleados, flota, ventas y compras, con estadísticas y reportes integrados.

## ¿Qué busco solucionar?
El proyecto nace de la necesidad de la distribuidora de huevos de mi familia. El objetivo principal es facilitar la emisión de facturas y la gestión del inventario. Sin embargo, durante la investigación descubrí que no es tan simple: para emitir documentos tributarios es necesario cumplir con los requisitos del SII y tener la empresa constituida formalmente.

Otro desafío importante es que la aplicación debe ser completamente intuitiva para que cualquier persona, incluso sin experiencia tecnológica, pueda utilizarla sin dificultad.

## Funcionalidades Principales
Inicialmente consideré desarrollar una aplicación simple enfocada solo en facturación, pero esto resultaba insuficiente. Por ello, decidí crear un sistema integral que integre todos los procesos empresariales en una sola plataforma, incluyendo:

- **Gestión de empleados**: Agregar, editar y remover personal
- **Gestión de bodegas y locales**: Administración de múltiples puntos de almacenamiento y distribución
- **Gestión de inventario por bodega**: Control de stock independiente en cada bodega/local con sincronización central
- **Control de acceso por bodega**: Cada usuario solo puede ver y operar con datos de su bodega/local asignada (inventario, ventas, compras). No tiene acceso a información de otras bodegas
- **Gestión de productos**: Catálogo centralizado de artículos disponibles
- **Gestión de proveedores**: Registro de proveedores y productos asociados
- **Gestión de ventas**: Registro y seguimiento de transacciones por bodega
- **Gestión de flota**: Especialmente importante para coordinar entregas entre bodegas y hacia clientes

## Fase Inicial: Desarrollo de la Base de Datos
El primer paso es establecer la base de datos fundamental mediante MySQL. Las herramientas que utilizaré son:
- **DBeaver**: Para la conexión y administración de la base de datos
- **MySQL Workbench**: Para diseñar el modelo inicial
- **Diagrama MER**: Para visualizar la estructura entidad-relación del sistema

## Arquitectura Multi-Bodega
Un aspecto clave del sistema es la capacidad de gestionar múltiples bodegas o locales de forma independiente pero integrada. Cada bodega tendrá:
- Inventario propio con sincronización centralizada
- Usuarios asignados con permisos limitados a su bodega (solo ven y modifican datos de su ubicación)
- Transacciones independientes (ventas, compras, movimientos) registradas por bodega
- Reportes y estadísticas específicas por bodega
- Capacidad de transferencia de inventario entre bodegas

Esto permite que distribuidoras con múltiples puntos de venta mantengan control total sobre cada ubicación mientras conservan una visión consolidada del negocio. Es un sistema de **permisos de acceso a datos**, no un requisito de presencia física: los datos se registran en la bodega asignada del usuario, sin importar dónde se ingrese la información.

