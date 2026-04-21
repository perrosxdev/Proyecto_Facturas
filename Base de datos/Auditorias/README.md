**Auditorías SQL**

Este README explica la implementación de auditorías contenida en el fichero `Auditorias.sql`.

- **Propósito:**: Registrar en una tabla centralizada (`audit_log`) todos los cambios relevantes en las tablas del modelo (INSERT, UPDATE, DELETE y eventos de borrado lógico/recuperación).

- **Estructura principal:**: La tabla `audit_log` tiene las columnas principales:
	- `id_audit`: PK autoincremental.
	- `tabla`: nombre de la tabla auditada.
	- `accion`: tipo de acción (`INSERT`, `UPDATE`, `DELETE`, `SOFT_DELETE`, `SOFT_RESTORE`).
	- `pk_valor`: valor de la llave primaria afectada.
	- `usuario`: usuario MySQL que ejecutó la operación (`CURRENT_USER()`).
	- `fecha`: timestamp del evento (por defecto `CURRENT_TIMESTAMP`).
	- `valores_antes`: JSON con los valores previos (cuando aplica).
	- `valores_despues`: JSON con los valores nuevos (cuando aplica).

- **Triggers:**: Para cada tabla auditada se crean 3 triggers mínimos:
	- `AFTER INSERT`: inserta un registro con `accion = 'INSERT'` y `valores_despues`.
	- `AFTER UPDATE` (o `AFTER UPDATE` combinado con lógica): inserta `valores_antes` y `valores_despues`. Para tablas con borrado lógico se detecta si el campo `borrado` cambió y se registra `SOFT_DELETE` o `SOFT_RESTORE` en lugar de `UPDATE`.
	- `BEFORE DELETE`: captura estado previo y guarda `accion = 'DELETE'` con `valores_antes`.

- **Manejo de borrado lógico (soft delete):**: En tablas que usan un campo `borrado` (y `fecha_borrado`) los triggers de `UPDATE` comprueban el cambio de ese campo para clasificar la acción como `SOFT_DELETE` o `SOFT_RESTORE`. Esto permite distinguir borrados lógicos de actualizaciones normales.

- **Formato JSON de valores:**: Se usan `JSON_OBJECT(...)` para serializar las columnas relevantes en `valores_antes` y `valores_despues`. Esto facilita consultas por contenido y reconstrucción de cambios.

- **Consultas útiles:**:
	- Ver eventos recientes:
		- `SELECT * FROM audit_log ORDER BY fecha DESC LIMIT 100;`
	- Buscar cambios en una tabla y PK concreta:
		- `SELECT * FROM audit_log WHERE tabla='clientes' AND pk_valor='123' ORDER BY fecha;`
	- Filtrar por tipo de acción:
		- `SELECT * FROM audit_log WHERE accion='SOFT_DELETE'`.

- **Permisos y consideraciones:**:
	- Los triggers ejecutan en el contexto del servidor; `CURRENT_USER()` devuelve el usuario MySQL que ejecutó la sentencia.
	- Asegúrese de que la tabla `audit_log` tenga índices adecuados si planea consultas por `tabla`, `pk_valor` o `fecha`.
	- JSON en MySQL permite búsquedas avanzadas pero puede afectar el tamaño; considere políticas de retención si la actividad es alta.

	- **Restricción de valores en `accion`:** Además del tipo `ENUM`, se añade una restricción `CHECK` en `audit_log` para garantizar que la columna `accion` solo tome los valores `INSERT`, `UPDATE`, `DELETE`, `SOFT_DELETE` o `SOFT_RESTORE`.

- **Extender auditoría a nuevas tablas:**:
	- Añadir triggers `AFTER INSERT`, `AFTER UPDATE` y `BEFORE DELETE` para la nueva tabla.
	- Serializar en JSON las columnas relevantes en `valores_antes`/`valores_despues`.
	- Si la tabla usa borrado lógico, añadir la lógica para `SOFT_DELETE`/`SOFT_RESTORE` en el trigger de `UPDATE`.

- **Restauración y uso práctico:**:
	- Los `valores_antes` permiten reconstruir la fila previa; para restaurar un registro borrado puede extraerse el JSON y generar un `INSERT` con esos valores.
	- Para auditorías externas o informes, exportar `audit_log` a una herramienta de análisis o a un almacén de datos.

- **Notas finales:**:
	- El script `Auditorias.sql` incluye triggers para muchas tablas del modelo (regiones, comunas, empresas, usuarios, roles, login, empleados, clientes, proveedores, producto, inventario, flota, vehiculo, etc.).
	- Revisar periódicamente el tamaño y rendimiento de la tabla de auditoría y archivar registros antiguos si es necesario.

- **Siguientes pasos (opcionales):**:
	- Generar ejemplos de consultas más avanzadas (filtros JSON, reconstrucción de cambios).
	- Añadir índices recomendados sobre `tabla` y `fecha`.

