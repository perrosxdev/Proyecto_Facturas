-- ======================================
-- AUDITORÍA GENERAL PARA TU MODELO
-- ======================================
CREATE TABLE IF NOT EXISTS audit_log (
    id_audit INT AUTO_INCREMENT PRIMARY KEY,
    tabla VARCHAR(64) NOT NULL,
    accion ENUM('INSERT', 'UPDATE', 'DELETE', 'SOFT_DELETE', 'SOFT_RESTORE') NOT NULL,
    pk_valor VARCHAR(64) NOT NULL,
    usuario VARCHAR(128) NOT NULL,
    fecha DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    valores_antes JSON,
    valores_despues JSON
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

DELIMITER $$

-- ======================================
-- region
-- ======================================
CREATE TRIGGER tr_region_insert_audit
AFTER INSERT ON region
FOR EACH ROW
BEGIN
  INSERT INTO audit_log (tabla, accion, pk_valor, usuario, valores_despues)
  VALUES ('region', 'INSERT', NEW.id_region, CURRENT_USER(), JSON_OBJECT('nombre_region', NEW.nombre_region));
END$$

CREATE TRIGGER tr_region_update_audit
AFTER UPDATE ON region
FOR EACH ROW
BEGIN
  INSERT INTO audit_log (tabla, accion, pk_valor, usuario, valores_antes, valores_despues)
  VALUES ('region', 'UPDATE', OLD.id_region, CURRENT_USER(),
    JSON_OBJECT('nombre_region', OLD.nombre_region),
    JSON_OBJECT('nombre_region', NEW.nombre_region)
  );
END$$

CREATE TRIGGER tr_region_delete_audit
BEFORE DELETE ON region
FOR EACH ROW
BEGIN
  INSERT INTO audit_log (tabla, accion, pk_valor, usuario, valores_antes)
  VALUES ('region', 'DELETE', OLD.id_region, CURRENT_USER(),
    JSON_OBJECT('nombre_region', OLD.nombre_region)
  );
END$$

-- ======================================
-- comuna
-- ======================================
CREATE TRIGGER tr_comuna_insert_audit
AFTER INSERT ON comuna
FOR EACH ROW
BEGIN
  INSERT INTO audit_log (tabla, accion, pk_valor, usuario, valores_despues)
  VALUES ('comuna', 'INSERT', NEW.id_comuna, CURRENT_USER(),
    JSON_OBJECT('id_region', NEW.id_region, 'nombre_comuna', NEW.nombre_comuna)
  );
END$$

CREATE TRIGGER tr_comuna_update_audit
AFTER UPDATE ON comuna
FOR EACH ROW
BEGIN
  INSERT INTO audit_log (tabla, accion, pk_valor, usuario, valores_antes, valores_despues)
  VALUES ('comuna', 'UPDATE', OLD.id_comuna, CURRENT_USER(),
    JSON_OBJECT('id_region', OLD.id_region, 'nombre_comuna', OLD.nombre_comuna),
    JSON_OBJECT('id_region', NEW.id_region, 'nombre_comuna', NEW.nombre_comuna)
  );
END$$

CREATE TRIGGER tr_comuna_delete_audit
BEFORE DELETE ON comuna
FOR EACH ROW
BEGIN
  INSERT INTO audit_log (tabla, accion, pk_valor, usuario, valores_antes)
  VALUES ('comuna', 'DELETE', OLD.id_comuna, CURRENT_USER(),
    JSON_OBJECT('id_region', OLD.id_region, 'nombre_comuna', OLD.nombre_comuna)
  );
END$$

-- ======================================
-- ciudad
-- ======================================
CREATE TRIGGER tr_ciudad_insert_audit
AFTER INSERT ON ciudad
FOR EACH ROW
BEGIN
  INSERT INTO audit_log (tabla, accion, pk_valor, usuario, valores_despues)
  VALUES ('ciudad', 'INSERT', NEW.id_ciudad, CURRENT_USER(),
    JSON_OBJECT('id_comuna', NEW.id_comuna, 'nombre_ciudad', NEW.nombre_ciudad)
  );
END$$

CREATE TRIGGER tr_ciudad_update_audit
AFTER UPDATE ON ciudad
FOR EACH ROW
BEGIN
  INSERT INTO audit_log (tabla, accion, pk_valor, usuario, valores_antes, valores_despues)
  VALUES ('ciudad', 'UPDATE', OLD.id_ciudad, CURRENT_USER(),
    JSON_OBJECT('id_comuna', OLD.id_comuna, 'nombre_ciudad', OLD.nombre_ciudad),
    JSON_OBJECT('id_comuna', NEW.id_comuna, 'nombre_ciudad', NEW.nombre_ciudad)
  );
END$$

CREATE TRIGGER tr_ciudad_delete_audit
BEFORE DELETE ON ciudad
FOR EACH ROW
BEGIN
  INSERT INTO audit_log (tabla, accion, pk_valor, usuario, valores_antes)
  VALUES ('ciudad', 'DELETE', OLD.id_ciudad, CURRENT_USER(),
    JSON_OBJECT('id_comuna', OLD.id_comuna, 'nombre_ciudad', OLD.nombre_ciudad)
  );
END$$

-- ======================================
-- empresa (soft delete)
-- ======================================
CREATE TRIGGER tr_empresa_insert_audit
AFTER INSERT ON empresa
FOR EACH ROW
BEGIN
  INSERT INTO audit_log (tabla, accion, pk_valor, usuario, valores_despues)
  VALUES ('empresa', 'INSERT', NEW.id_empresa, CURRENT_USER(),
    JSON_OBJECT('nombre_empresa', NEW.nombre_empresa, 'rut_empresa', NEW.rut_empresa, 'calle', NEW.calle,
    'numero', NEW.numero, 'id_ciudad', NEW.id_ciudad, 'borrado', NEW.borrado, 'fecha_borrado', NEW.fecha_borrado)
  );
END$$

CREATE TRIGGER tr_empresa_update_audit
AFTER UPDATE ON empresa
FOR EACH ROW
BEGIN
  DECLARE tipo_accion ENUM('UPDATE','SOFT_DELETE','SOFT_RESTORE');
  IF (OLD.borrado = 0 AND NEW.borrado = 1) THEN
    SET tipo_accion = 'SOFT_DELETE';
  ELSEIF (OLD.borrado = 1 AND NEW.borrado = 0) THEN
    SET tipo_accion = 'SOFT_RESTORE';
  ELSE
    SET tipo_accion = 'UPDATE';
  END IF;
  INSERT INTO audit_log (tabla, accion, pk_valor, usuario, valores_antes, valores_despues)
  VALUES ('empresa', tipo_accion, OLD.id_empresa, CURRENT_USER(),
    JSON_OBJECT('nombre_empresa', OLD.nombre_empresa, 'rut_empresa', OLD.rut_empresa, 'calle', OLD.calle,
    'numero', OLD.numero, 'id_ciudad', OLD.id_ciudad, 'borrado', OLD.borrado, 'fecha_borrado', OLD.fecha_borrado),
    JSON_OBJECT('nombre_empresa', NEW.nombre_empresa, 'rut_empresa', NEW.rut_empresa, 'calle', NEW.calle,
    'numero', NEW.numero, 'id_ciudad', NEW.id_ciudad, 'borrado', NEW.borrado, 'fecha_borrado', NEW.fecha_borrado)
  );
END$$

CREATE TRIGGER tr_empresa_delete_audit
BEFORE DELETE ON empresa
FOR EACH ROW
BEGIN
  INSERT INTO audit_log (tabla, accion, pk_valor, usuario, valores_antes)
  VALUES ('empresa', 'DELETE', OLD.id_empresa, CURRENT_USER(),
    JSON_OBJECT('nombre_empresa', OLD.nombre_empresa, 'rut_empresa', OLD.rut_empresa, 'calle', OLD.calle,
    'numero', OLD.numero, 'id_ciudad', OLD.id_ciudad, 'borrado', OLD.borrado, 'fecha_borrado', OLD.fecha_borrado)
  );
END$$

-- ======================================
-- usuarios (soft delete)
-- ======================================
CREATE TRIGGER tr_usuarios_insert_audit
AFTER INSERT ON usuarios
FOR EACH ROW
BEGIN
  INSERT INTO audit_log (tabla, accion, pk_valor, usuario, valores_despues)
  VALUES ('usuarios', 'INSERT', NEW.id_usuario, CURRENT_USER(),
    JSON_OBJECT('nombres', NEW.nombres, 'apellido_paterno', NEW.apellido_paterno,
                'apellido_materno', NEW.apellido_materno, 'celular', NEW.celular,
                'borrado', NEW.borrado, 'fecha_borrado', NEW.fecha_borrado)
  );
END$$

CREATE TRIGGER tr_usuarios_update_audit
AFTER UPDATE ON usuarios
FOR EACH ROW
BEGIN
  DECLARE tipo_accion ENUM('UPDATE','SOFT_DELETE','SOFT_RESTORE');
  IF (OLD.borrado = 0 AND NEW.borrado = 1) THEN
    SET tipo_accion = 'SOFT_DELETE';
  ELSEIF (OLD.borrado = 1 AND NEW.borrado = 0) THEN
    SET tipo_accion = 'SOFT_RESTORE';
  ELSE
    SET tipo_accion = 'UPDATE';
  END IF;
  INSERT INTO audit_log (tabla, accion, pk_valor, usuario, valores_antes, valores_despues)
  VALUES ('usuarios', tipo_accion, OLD.id_usuario, CURRENT_USER(),
    JSON_OBJECT('nombres', OLD.nombres, 'apellido_paterno', OLD.apellido_paterno,
                'apellido_materno', OLD.apellido_materno, 'celular', OLD.celular,
                'borrado', OLD.borrado, 'fecha_borrado', OLD.fecha_borrado),
    JSON_OBJECT('nombres', NEW.nombres, 'apellido_paterno', NEW.apellido_paterno,
                'apellido_materno', NEW.apellido_materno, 'celular', NEW.celular,
                'borrado', NEW.borrado, 'fecha_borrado', NEW.fecha_borrado)
  );
END$$

CREATE TRIGGER tr_usuarios_delete_audit
BEFORE DELETE ON usuarios
FOR EACH ROW
BEGIN
  INSERT INTO audit_log (tabla, accion, pk_valor, usuario, valores_antes)
  VALUES ('usuarios', 'DELETE', OLD.id_usuario, CURRENT_USER(),
    JSON_OBJECT('nombres', OLD.nombres, 'apellido_paterno', OLD.apellido_paterno,
                'apellido_materno', OLD.apellido_materno, 'celular', OLD.celular,
                'borrado', OLD.borrado, 'fecha_borrado', OLD.fecha_borrado)
  );
END$$

-- ======================================
-- roles
-- ======================================
CREATE TRIGGER tr_roles_insert_audit
AFTER INSERT ON roles
FOR EACH ROW
BEGIN
  INSERT INTO audit_log (tabla, accion, pk_valor, usuario, valores_despues)
  VALUES ('roles', 'INSERT', NEW.id_rol, CURRENT_USER(),
    JSON_OBJECT('nombre_rol', NEW.nombre_rol)
  );
END$$

CREATE TRIGGER tr_roles_update_audit
AFTER UPDATE ON roles
FOR EACH ROW
BEGIN
  INSERT INTO audit_log (tabla, accion, pk_valor, usuario, valores_antes, valores_despues)
  VALUES ('roles', 'UPDATE', OLD.id_rol, CURRENT_USER(),
    JSON_OBJECT('nombre_rol', OLD.nombre_rol),
    JSON_OBJECT('nombre_rol', NEW.nombre_rol)
  );
END$$

CREATE TRIGGER tr_roles_delete_audit
BEFORE DELETE ON roles
FOR EACH ROW
BEGIN
  INSERT INTO audit_log (tabla, accion, pk_valor, usuario, valores_antes)
  VALUES ('roles', 'DELETE', OLD.id_rol, CURRENT_USER(),
    JSON_OBJECT('nombre_rol', OLD.nombre_rol)
  );
END$$

-- ======================================
-- login (soft delete)
-- ======================================
CREATE TRIGGER tr_login_insert_audit
AFTER INSERT ON login
FOR EACH ROW
BEGIN
  INSERT INTO audit_log (tabla, accion, pk_valor, usuario, valores_despues)
  VALUES ('login', 'INSERT', NEW.id_login, CURRENT_USER(),
    JSON_OBJECT('email', NEW.email, 'password', NEW.password, 'id_usuario', NEW.id_usuario,
                'id_rol', NEW.id_rol, 'verificado', NEW.verificado, 'borrado', NEW.borrado, 'fecha_borrado', NEW.fecha_borrado)
  );
END$$

CREATE TRIGGER tr_login_update_audit
AFTER UPDATE ON login
FOR EACH ROW
BEGIN
  DECLARE tipo_accion ENUM('UPDATE','SOFT_DELETE','SOFT_RESTORE');
  IF (OLD.borrado = 0 AND NEW.borrado = 1) THEN
    SET tipo_accion = 'SOFT_DELETE';
  ELSEIF (OLD.borrado = 1 AND NEW.borrado = 0) THEN
    SET tipo_accion = 'SOFT_RESTORE';
  ELSE
    SET tipo_accion = 'UPDATE';
  END IF;
  INSERT INTO audit_log (tabla, accion, pk_valor, usuario, valores_antes, valores_despues)
  VALUES ('login', tipo_accion, OLD.id_login, CURRENT_USER(),
    JSON_OBJECT('email', OLD.email, 'password', OLD.password, 'id_usuario', OLD.id_usuario,
                'id_rol', OLD.id_rol, 'verificado', OLD.verificado, 'borrado', OLD.borrado, 'fecha_borrado', OLD.fecha_borrado),
    JSON_OBJECT('email', NEW.email, 'password', NEW.password, 'id_usuario', NEW.id_usuario,
                'id_rol', NEW.id_rol, 'verificado', NEW.verificado, 'borrado', NEW.borrado, 'fecha_borrado', NEW.fecha_borrado)
  );
END$$

CREATE TRIGGER tr_login_delete_audit
BEFORE DELETE ON login
FOR EACH ROW
BEGIN
  INSERT INTO audit_log (tabla, accion, pk_valor, usuario, valores_antes)
  VALUES ('login', 'DELETE', OLD.id_login, CURRENT_USER(),
    JSON_OBJECT('email', OLD.email, 'password', OLD.password, 'id_usuario', OLD.id_usuario,
                'id_rol', OLD.id_rol, 'verificado', OLD.verificado, 'borrado', OLD.borrado, 'fecha_borrado', OLD.fecha_borrado)
  );
END$$

-- ======================================
-- empleados (soft delete)
-- ======================================
CREATE TRIGGER tr_empleados_insert_audit
AFTER INSERT ON empleados
FOR EACH ROW
BEGIN
  INSERT INTO audit_log (tabla, accion, pk_valor, usuario, valores_despues)
  VALUES ('empleados', 'INSERT', NEW.id_empleado, CURRENT_USER(),
    JSON_OBJECT('id_usuario', NEW.id_usuario, 'id_empresa', NEW.id_empresa, 'cargo', NEW.cargo,
                'borrado', NEW.borrado, 'fecha_borrado', NEW.fecha_borrado, 'borrado_por', NEW.borrado_por)
  );
END$$

CREATE TRIGGER tr_empleados_update_audit
AFTER UPDATE ON empleados
FOR EACH ROW
BEGIN
  DECLARE tipo_accion ENUM('UPDATE','SOFT_DELETE','SOFT_RESTORE');
  IF (OLD.borrado = 0 AND NEW.borrado = 1) THEN
    SET tipo_accion = 'SOFT_DELETE';
  ELSEIF (OLD.borrado = 1 AND NEW.borrado = 0) THEN
    SET tipo_accion = 'SOFT_RESTORE';
  ELSE
    SET tipo_accion = 'UPDATE';
  END IF;
  INSERT INTO audit_log (tabla, accion, pk_valor, usuario, valores_antes, valores_despues)
  VALUES ('empleados', tipo_accion, OLD.id_empleado, CURRENT_USER(),
    JSON_OBJECT('id_usuario', OLD.id_usuario, 'id_empresa', OLD.id_empresa, 'cargo', OLD.cargo,
                'borrado', OLD.borrado, 'fecha_borrado', OLD.fecha_borrado, 'borrado_por', OLD.borrado_por),
    JSON_OBJECT('id_usuario', NEW.id_usuario, 'id_empresa', NEW.id_empresa, 'cargo', NEW.cargo,
                'borrado', NEW.borrado, 'fecha_borrado', NEW.fecha_borrado, 'borrado_por', NEW.borrado_por)
  );
END$$

CREATE TRIGGER tr_empleados_delete_audit
BEFORE DELETE ON empleados
FOR EACH ROW
BEGIN
  INSERT INTO audit_log (tabla, accion, pk_valor, usuario, valores_antes)
  VALUES ('empleados', 'DELETE', OLD.id_empleado, CURRENT_USER(),
    JSON_OBJECT('id_usuario', OLD.id_usuario, 'id_empresa', OLD.id_empresa, 'cargo', OLD.cargo,
                'borrado', OLD.borrado, 'fecha_borrado', OLD.fecha_borrado, 'borrado_por', OLD.borrado_por)
  );
END$$

-- ======================================
-- lista_giros
-- ======================================
CREATE TRIGGER tr_lista_giros_insert_audit
AFTER INSERT ON lista_giros
FOR EACH ROW
BEGIN
  INSERT INTO audit_log (tabla, accion, pk_valor, usuario, valores_despues)
  VALUES ('lista_giros', 'INSERT', NEW.id_giro, CURRENT_USER(),
    JSON_OBJECT('nombre_giro', NEW.nombre_giro, 'codigo_giro', NEW.codigo_giro)
  );
END$$

CREATE TRIGGER tr_lista_giros_update_audit
AFTER UPDATE ON lista_giros
FOR EACH ROW
BEGIN
  INSERT INTO audit_log (tabla, accion, pk_valor, usuario, valores_antes, valores_despues)
  VALUES ('lista_giros', 'UPDATE', OLD.id_giro, CURRENT_USER(),
    JSON_OBJECT('nombre_giro', OLD.nombre_giro, 'codigo_giro', OLD.codigo_giro),
    JSON_OBJECT('nombre_giro', NEW.nombre_giro, 'codigo_giro', NEW.codigo_giro)
  );
END$$

CREATE TRIGGER tr_lista_giros_delete_audit
BEFORE DELETE ON lista_giros
FOR EACH ROW
BEGIN
  INSERT INTO audit_log (tabla, accion, pk_valor, usuario, valores_antes)
  VALUES ('lista_giros', 'DELETE', OLD.id_giro, CURRENT_USER(),
    JSON_OBJECT('nombre_giro', OLD.nombre_giro, 'codigo_giro', OLD.codigo_giro)
  );
END$$

-- ======================================
-- giros_empresa
-- ======================================
CREATE TRIGGER tr_giros_empresa_insert_audit
AFTER INSERT ON giros_empresa
FOR EACH ROW
BEGIN
  INSERT INTO audit_log (tabla, accion, pk_valor, usuario, valores_despues)
  VALUES ('giros_empresa', 'INSERT', NEW.id, CURRENT_USER(),
    JSON_OBJECT('id_giro', NEW.id_giro, 'id_empresa', NEW.id_empresa)
  );
END$$

CREATE TRIGGER tr_giros_empresa_update_audit
AFTER UPDATE ON giros_empresa
FOR EACH ROW
BEGIN
  INSERT INTO audit_log (tabla, accion, pk_valor, usuario, valores_antes, valores_despues)
  VALUES ('giros_empresa', 'UPDATE', OLD.id, CURRENT_USER(),
    JSON_OBJECT('id_giro', OLD.id_giro, 'id_empresa', OLD.id_empresa),
    JSON_OBJECT('id_giro', NEW.id_giro, 'id_empresa', NEW.id_empresa)
  );
END$$

CREATE TRIGGER tr_giros_empresa_delete_audit
BEFORE DELETE ON giros_empresa
FOR EACH ROW
BEGIN
  INSERT INTO audit_log (tabla, accion, pk_valor, usuario, valores_antes)
  VALUES ('giros_empresa', 'DELETE', OLD.id, CURRENT_USER(),
    JSON_OBJECT('id_giro', OLD.id_giro, 'id_empresa', OLD.id_empresa)
  );
END$$

-- ======================================
-- clientes (soft delete)
-- ======================================
CREATE TRIGGER tr_clientes_insert_audit
AFTER INSERT ON clientes
FOR EACH ROW
BEGIN
  INSERT INTO audit_log (tabla, accion, pk_valor, usuario, valores_despues)
  VALUES ('clientes', 'INSERT', NEW.id_cliente, CURRENT_USER(),
    JSON_OBJECT('id_empresa', NEW.id_empresa, 'nombre_cliente', NEW.nombre_cliente,
                'rut_cliente', NEW.rut_cliente, 'id_giro', NEW.id_giro,
                'calle', NEW.calle, 'numero', NEW.numero, 'id_ciudad', NEW.id_ciudad,
                'borrado', NEW.borrado, 'fecha_borrado', NEW.fecha_borrado)
  );
END$$

CREATE TRIGGER tr_clientes_update_audit
AFTER UPDATE ON clientes
FOR EACH ROW
BEGIN
  DECLARE tipo_accion ENUM('UPDATE','SOFT_DELETE','SOFT_RESTORE');
  IF (OLD.borrado = 0 AND NEW.borrado = 1) THEN
    SET tipo_accion = 'SOFT_DELETE';
  ELSEIF (OLD.borrado = 1 AND NEW.borrado = 0) THEN
    SET tipo_accion = 'SOFT_RESTORE';
  ELSE
    SET tipo_accion = 'UPDATE';
  END IF;
  INSERT INTO audit_log (tabla, accion, pk_valor, usuario, valores_antes, valores_despues)
  VALUES ('clientes', tipo_accion, OLD.id_cliente, CURRENT_USER(),
    JSON_OBJECT('id_empresa', OLD.id_empresa, 'nombre_cliente', OLD.nombre_cliente,
                'rut_cliente', OLD.rut_cliente, 'id_giro', OLD.id_giro,
                'calle', OLD.calle, 'numero', OLD.numero, 'id_ciudad', OLD.id_ciudad,
                'borrado', OLD.borrado, 'fecha_borrado', OLD.fecha_borrado),
    JSON_OBJECT('id_empresa', NEW.id_empresa, 'nombre_cliente', NEW.nombre_cliente,
                'rut_cliente', NEW.rut_cliente, 'id_giro', NEW.id_giro,
                'calle', NEW.calle, 'numero', NEW.numero, 'id_ciudad', NEW.id_ciudad,
                'borrado', NEW.borrado, 'fecha_borrado', NEW.fecha_borrado)
  );
END$$

CREATE TRIGGER tr_clientes_delete_audit
BEFORE DELETE ON clientes
FOR EACH ROW
BEGIN
  INSERT INTO audit_log (tabla, accion, pk_valor, usuario, valores_antes)
  VALUES ('clientes', 'DELETE', OLD.id_cliente, CURRENT_USER(),
    JSON_OBJECT('id_empresa', OLD.id_empresa, 'nombre_cliente', OLD.nombre_cliente,
                'rut_cliente', OLD.rut_cliente, 'id_giro', OLD.id_giro,
                'calle', OLD.calle, 'numero', OLD.numero, 'id_ciudad', OLD.id_ciudad,
                'borrado', OLD.borrado, 'fecha_borrado', OLD.fecha_borrado)
  );
END$$

-- ======================================
-- bodega (soft delete)
-- ======================================
CREATE TRIGGER tr_bodega_insert_audit
AFTER INSERT ON bodega
FOR EACH ROW
BEGIN
  INSERT INTO audit_log (tabla, accion, pk_valor, usuario, valores_despues)
  VALUES ('bodega', 'INSERT', NEW.id_bodega, CURRENT_USER(),
    JSON_OBJECT('id_empresa', NEW.id_empresa, 'nombre_bodega', NEW.nombre_bodega,
                'calle', NEW.calle, 'numero', NEW.numero, 'id_ciudad', NEW.id_ciudad,
                'borrado', NEW.borrado, 'fecha_borrado', NEW.fecha_borrado)
  );
END$$

CREATE TRIGGER tr_bodega_update_audit
AFTER UPDATE ON bodega
FOR EACH ROW
BEGIN
  DECLARE tipo_accion ENUM('UPDATE','SOFT_DELETE','SOFT_RESTORE');
  IF (OLD.borrado = 0 AND NEW.borrado = 1) THEN
    SET tipo_accion = 'SOFT_DELETE';
  ELSEIF (OLD.borrado = 1 AND NEW.borrado = 0) THEN
    SET tipo_accion = 'SOFT_RESTORE';
  ELSE
    SET tipo_accion = 'UPDATE';
  END IF;
  INSERT INTO audit_log (tabla, accion, pk_valor, usuario, valores_antes, valores_despues)
  VALUES ('bodega', tipo_accion, OLD.id_bodega, CURRENT_USER(),
    JSON_OBJECT('id_empresa', OLD.id_empresa, 'nombre_bodega', OLD.nombre_bodega,
                'calle', OLD.calle, 'numero', OLD.numero, 'id_ciudad', OLD.id_ciudad,
                'borrado', OLD.borrado, 'fecha_borrado', OLD.fecha_borrado),
    JSON_OBJECT('id_empresa', NEW.id_empresa, 'nombre_bodega', NEW.nombre_bodega,
                'calle', NEW.calle, 'numero', NEW.numero, 'id_ciudad', NEW.id_ciudad,
                'borrado', NEW.borrado, 'fecha_borrado', NEW.fecha_borrado)
  );
END$$

CREATE TRIGGER tr_bodega_delete_audit
BEFORE DELETE ON bodega
FOR EACH ROW
BEGIN
  INSERT INTO audit_log (tabla, accion, pk_valor, usuario, valores_antes)
  VALUES ('bodega', 'DELETE', OLD.id_bodega, CURRENT_USER(),
    JSON_OBJECT('id_empresa', OLD.id_empresa, 'nombre_bodega', OLD.nombre_bodega,
                'calle', OLD.calle, 'numero', OLD.numero, 'id_ciudad', OLD.id_ciudad,
                'borrado', OLD.borrado, 'fecha_borrado', OLD.fecha_borrado)
  );
END$$

-- ======================================
-- proveedores (soft delete)
-- ======================================
CREATE TRIGGER tr_proveedores_insert_audit
AFTER INSERT ON proveedores
FOR EACH ROW
BEGIN
  INSERT INTO audit_log (tabla, accion, pk_valor, usuario, valores_despues)
  VALUES ('proveedores', 'INSERT', NEW.id_proveedor, CURRENT_USER(),
    JSON_OBJECT('id_empresa', NEW.id_empresa, 'rut_proveedor', NEW.rut_proveedor,
                'nombre_proveedor', NEW.nombre_proveedor, 'nombre_vendedor', NEW.nombre_vendedor,
                'telefono_vendedor', NEW.telefono_vendedor, 'telefono_fijo', NEW.telefono_fijo,
                'email_vendedor', NEW.email_vendedor, 'borrado', NEW.borrado, 'fecha_borrado', NEW.fecha_borrado)
  );
END$$

CREATE TRIGGER tr_proveedores_update_audit
AFTER UPDATE ON proveedores
FOR EACH ROW
BEGIN
  DECLARE tipo_accion ENUM('UPDATE','SOFT_DELETE','SOFT_RESTORE');
  IF (OLD.borrado = 0 AND NEW.borrado = 1) THEN
    SET tipo_accion = 'SOFT_DELETE';
  ELSEIF (OLD.borrado = 1 AND NEW.borrado = 0) THEN
    SET tipo_accion = 'SOFT_RESTORE';
  ELSE
    SET tipo_accion = 'UPDATE';
  END IF;
  INSERT INTO audit_log (tabla, accion, pk_valor, usuario, valores_antes, valores_despues)
  VALUES ('proveedores', tipo_accion, OLD.id_proveedor, CURRENT_USER(),
    JSON_OBJECT('id_empresa', OLD.id_empresa, 'rut_proveedor', OLD.rut_proveedor,
                'nombre_proveedor', OLD.nombre_proveedor, 'nombre_vendedor', OLD.nombre_vendedor,
                'telefono_vendedor', OLD.telefono_vendedor, 'telefono_fijo', OLD.telefono_fijo,
                'email_vendedor', OLD.email_vendedor, 'borrado', OLD.borrado, 'fecha_borrado', OLD.fecha_borrado),
    JSON_OBJECT('id_empresa', NEW.id_empresa, 'rut_proveedor', NEW.rut_proveedor,
                'nombre_proveedor', NEW.nombre_proveedor, 'nombre_vendedor', NEW.nombre_vendedor,
                'telefono_vendedor', NEW.telefono_vendedor, 'telefono_fijo', NEW.telefono_fijo,
                'email_vendedor', NEW.email_vendedor, 'borrado', NEW.borrado, 'fecha_borrado', NEW.fecha_borrado)
  );
END$$

CREATE TRIGGER tr_proveedores_delete_audit
BEFORE DELETE ON proveedores
FOR EACH ROW
BEGIN
  INSERT INTO audit_log (tabla, accion, pk_valor, usuario, valores_antes)
  VALUES ('proveedores', 'DELETE', OLD.id_proveedor, CURRENT_USER(),
    JSON_OBJECT('id_empresa', OLD.id_empresa, 'rut_proveedor', OLD.rut_proveedor,
                'nombre_proveedor', OLD.nombre_proveedor, 'nombre_vendedor', OLD.nombre_vendedor,
                'telefono_vendedor', OLD.telefono_vendedor, 'telefono_fijo', OLD.telefono_fijo,
                'email_vendedor', OLD.email_vendedor, 'borrado', OLD.borrado, 'fecha_borrado', OLD.fecha_borrado)
  );
END$$

-- ======================================
-- producto (soft delete)
-- ======================================
CREATE TRIGGER tr_producto_insert_audit
AFTER INSERT ON producto
FOR EACH ROW
BEGIN
  INSERT INTO audit_log (tabla, accion, pk_valor, usuario, valores_despues)
  VALUES ('producto', 'INSERT', NEW.id_producto, CURRENT_USER(),
    JSON_OBJECT('id_empresa', NEW.id_empresa, 'nombre_producto', NEW.nombre_producto,
                'borrado', NEW.borrado, 'fecha_borrado', NEW.fecha_borrado)
  );
END$$

CREATE TRIGGER tr_producto_update_audit
AFTER UPDATE ON producto
FOR EACH ROW
BEGIN
  DECLARE tipo_accion ENUM('UPDATE','SOFT_DELETE','SOFT_RESTORE');
  IF (OLD.borrado = 0 AND NEW.borrado = 1) THEN
    SET tipo_accion = 'SOFT_DELETE';
  ELSEIF (OLD.borrado = 1 AND NEW.borrado = 0) THEN
    SET tipo_accion = 'SOFT_RESTORE';
  ELSE
    SET tipo_accion = 'UPDATE';
  END IF;
  INSERT INTO audit_log (tabla, accion, pk_valor, usuario, valores_antes, valores_despues)
  VALUES ('producto', tipo_accion, OLD.id_producto, CURRENT_USER(),
    JSON_OBJECT('id_empresa', OLD.id_empresa, 'nombre_producto', OLD.nombre_producto,
                'borrado', OLD.borrado, 'fecha_borrado', OLD.fecha_borrado),
    JSON_OBJECT('id_empresa', NEW.id_empresa, 'nombre_producto', NEW.nombre_producto,
                'borrado', NEW.borrado, 'fecha_borrado', NEW.fecha_borrado)
  );
END$$

CREATE TRIGGER tr_producto_delete_audit
BEFORE DELETE ON producto
FOR EACH ROW
BEGIN
  INSERT INTO audit_log (tabla, accion, pk_valor, usuario, valores_antes)
  VALUES ('producto', 'DELETE', OLD.id_producto, CURRENT_USER(),
    JSON_OBJECT('id_empresa', OLD.id_empresa, 'nombre_producto', OLD.nombre_producto,
                'borrado', OLD.borrado, 'fecha_borrado', OLD.fecha_borrado)
  );
END$$

-- ======================================
-- producto_proveedor (soft delete)
-- ======================================
CREATE TRIGGER tr_producto_proveedor_insert_audit
AFTER INSERT ON producto_proveedor
FOR EACH ROW
BEGIN
  INSERT INTO audit_log (tabla, accion, pk_valor, usuario, valores_despues)
  VALUES ('producto_proveedor', 'INSERT', NEW.id, CURRENT_USER(),
    JSON_OBJECT('id_empresa', NEW.id_empresa, 'id_producto', NEW.id_producto, 'id_proveedor', NEW.id_proveedor,
                'borrado', NEW.borrado, 'fecha_borrado', NEW.fecha_borrado)
  );
END$$

CREATE TRIGGER tr_producto_proveedor_update_audit
AFTER UPDATE ON producto_proveedor
FOR EACH ROW
BEGIN
  DECLARE tipo_accion ENUM('UPDATE','SOFT_DELETE','SOFT_RESTORE');
  IF (OLD.borrado = 0 AND NEW.borrado = 1) THEN
    SET tipo_accion = 'SOFT_DELETE';
  ELSEIF (OLD.borrado = 1 AND NEW.borrado = 0) THEN
    SET tipo_accion = 'SOFT_RESTORE';
  ELSE
    SET tipo_accion = 'UPDATE';
  END IF;
  INSERT INTO audit_log (tabla, accion, pk_valor, usuario, valores_antes, valores_despues)
  VALUES ('producto_proveedor', tipo_accion, OLD.id, CURRENT_USER(),
    JSON_OBJECT('id_empresa', OLD.id_empresa, 'id_producto', OLD.id_producto, 'id_proveedor', OLD.id_proveedor,
                'borrado', OLD.borrado, 'fecha_borrado', OLD.fecha_borrado),
    JSON_OBJECT('id_empresa', NEW.id_empresa, 'id_producto', NEW.id_producto, 'id_proveedor', NEW.id_proveedor,
                'borrado', NEW.borrado, 'fecha_borrado', NEW.fecha_borrado)
  );
END$$

CREATE TRIGGER tr_producto_proveedor_delete_audit
BEFORE DELETE ON producto_proveedor
FOR EACH ROW
BEGIN
  INSERT INTO audit_log (tabla, accion, pk_valor, usuario, valores_antes)
  VALUES ('producto_proveedor', 'DELETE', OLD.id, CURRENT_USER(),
    JSON_OBJECT('id_empresa', OLD.id_empresa, 'id_producto', OLD.id_producto, 'id_proveedor', OLD.id_proveedor,
                'borrado', OLD.borrado, 'fecha_borrado', OLD.fecha_borrado)
  );
END$$

-- ======================================
-- inventario (soft delete)
-- ======================================
CREATE TRIGGER tr_inventario_insert_audit
AFTER INSERT ON inventario
FOR EACH ROW
BEGIN
  INSERT INTO audit_log (tabla, accion, pk_valor, usuario, valores_despues)
  VALUES ('inventario', 'INSERT', NEW.id_inventario, CURRENT_USER(),
    JSON_OBJECT('id_empresa', NEW.id_empresa, 'id_bodega', NEW.id_bodega, 'id_producto', NEW.id_producto,
                'stock', NEW.stock, 'borrado', NEW.borrado, 'fecha_borrado', NEW.fecha_borrado)
  );
END$$

CREATE TRIGGER tr_inventario_update_audit
AFTER UPDATE ON inventario
FOR EACH ROW
BEGIN
  DECLARE tipo_accion ENUM('UPDATE','SOFT_DELETE','SOFT_RESTORE');
  IF (OLD.borrado = 0 AND NEW.borrado = 1) THEN
    SET tipo_accion = 'SOFT_DELETE';
  ELSEIF (OLD.borrado = 1 AND NEW.borrado = 0) THEN
    SET tipo_accion = 'SOFT_RESTORE';
  ELSE
    SET tipo_accion = 'UPDATE';
  END IF;
  INSERT INTO audit_log (tabla, accion, pk_valor, usuario, valores_antes, valores_despues)
  VALUES ('inventario', tipo_accion, OLD.id_inventario, CURRENT_USER(),
    JSON_OBJECT('id_empresa', OLD.id_empresa, 'id_bodega', OLD.id_bodega, 'id_producto', OLD.id_producto,
                'stock', OLD.stock, 'borrado', OLD.borrado, 'fecha_borrado', OLD.fecha_borrado),
    JSON_OBJECT('id_empresa', NEW.id_empresa, 'id_bodega', NEW.id_bodega, 'id_producto', NEW.id_producto,
                'stock', NEW.stock, 'borrado', NEW.borrado, 'fecha_borrado', NEW.fecha_borrado)
  );
END$$

CREATE TRIGGER tr_inventario_delete_audit
BEFORE DELETE ON inventario
FOR EACH ROW
BEGIN
  INSERT INTO audit_log (tabla, accion, pk_valor, usuario, valores_antes)
  VALUES ('inventario', 'DELETE', OLD.id_inventario, CURRENT_USER(),
    JSON_OBJECT('id_empresa', OLD.id_empresa, 'id_bodega', OLD.id_bodega, 'id_producto', OLD.id_producto,
                'stock', OLD.stock, 'borrado', OLD.borrado, 'fecha_borrado', OLD.fecha_borrado)
  );
END$$

-- ======================================
-- flota (soft delete)
-- ======================================
CREATE TRIGGER tr_flota_insert_audit
AFTER INSERT ON flota
FOR EACH ROW
BEGIN
  INSERT INTO audit_log (tabla, accion, pk_valor, usuario, valores_despues)
  VALUES ('flota', 'INSERT', NEW.id_flota, CURRENT_USER(),
    JSON_OBJECT('id_empresa', NEW.id_empresa, 'nombre_flota', NEW.nombre_flota, 'id_bodega', NEW.id_bodega, 'borrado', NEW.borrado, 'fecha_borrado', NEW.fecha_borrado)
  );
END$$

CREATE TRIGGER tr_flota_update_audit
AFTER UPDATE ON flota
FOR EACH ROW
BEGIN
  DECLARE tipo_accion ENUM('UPDATE','SOFT_DELETE','SOFT_RESTORE');
  IF (OLD.borrado = 0 AND NEW.borrado = 1) THEN
    SET tipo_accion = 'SOFT_DELETE';
  ELSEIF (OLD.borrado = 1 AND NEW.borrado = 0) THEN
    SET tipo_accion = 'SOFT_RESTORE';
  ELSE
    SET tipo_accion = 'UPDATE';
  END IF;
  INSERT INTO audit_log (tabla, accion, pk_valor, usuario, valores_antes, valores_despues)
  VALUES ('flota', tipo_accion, OLD.id_flota, CURRENT_USER(),
    JSON_OBJECT('id_empresa', OLD.id_empresa, 'nombre_flota', OLD.nombre_flota, 'id_bodega', OLD.id_bodega, 'borrado', OLD.borrado, 'fecha_borrado', OLD.fecha_borrado),
    JSON_OBJECT('id_empresa', NEW.id_empresa, 'nombre_flota', NEW.nombre_flota, 'id_bodega', NEW.id_bodega, 'borrado', NEW.borrado, 'fecha_borrado', NEW.fecha_borrado)
  );
END$$

CREATE TRIGGER tr_flota_delete_audit
BEFORE DELETE ON flota
FOR EACH ROW
BEGIN
  INSERT INTO audit_log (tabla, accion, pk_valor, usuario, valores_antes)
  VALUES ('flota', 'DELETE', OLD.id_flota, CURRENT_USER(),
    JSON_OBJECT('id_empresa', OLD.id_empresa, 'nombre_flota', OLD.nombre_flota, 'id_bodega', OLD.id_bodega, 'borrado', OLD.borrado, 'fecha_borrado', OLD.fecha_borrado)
  );
END$$

-- ======================================
-- vehiculo (soft delete)
-- ======================================
CREATE TRIGGER tr_vehiculo_insert_audit
AFTER INSERT ON vehiculo
FOR EACH ROW
BEGIN
  INSERT INTO audit_log (tabla, accion, pk_valor, usuario, valores_despues)
  VALUES ('vehiculo', 'INSERT', NEW.id_vehiculo, CURRENT_USER(),
    JSON_OBJECT('id_empresa', NEW.id_empresa, 'id_flota', NEW.id_flota,
                'marca', NEW.marca, 'modelo', NEW.modelo, 'anio', NEW.anio,
                'fecha_ingreso', NEW.fecha_ingreso, 'fecha_salida', NEW.fecha_salida,
                'patente', NEW.patente, 'borrado', NEW.borrado, 'fecha_borrado', NEW.fecha_borrado)
  );
END$$

CREATE TRIGGER tr_vehiculo_update_audit
AFTER UPDATE ON vehiculo
FOR EACH ROW
BEGIN
  DECLARE tipo_accion ENUM('UPDATE','SOFT_DELETE','SOFT_RESTORE');
  IF (OLD.borrado = 0 AND NEW.borrado = 1) THEN
    SET tipo_accion = 'SOFT_DELETE';
  ELSEIF (OLD.borrado = 1 AND NEW.borrado = 0) THEN
    SET tipo_accion = 'SOFT_RESTORE';
  ELSE
    SET tipo_accion = 'UPDATE';
  END IF;
  INSERT INTO audit_log (tabla, accion, pk_valor, usuario, valores_antes, valores_despues)
  VALUES ('vehiculo', tipo_accion, OLD.id_vehiculo, CURRENT_USER(),
    JSON_OBJECT('id_empresa', OLD.id_empresa, 'id_flota', OLD.id_flota,
                'marca', OLD.marca, 'modelo', OLD.modelo, 'anio', OLD.anio,
                'fecha_ingreso', OLD.fecha_ingreso, 'fecha_salida', OLD.fecha_salida,
                'patente', OLD.patente, 'borrado', OLD.borrado, 'fecha_borrado', OLD.fecha_borrado),
    JSON_OBJECT('id_empresa', NEW.id_empresa, 'id_flota', NEW.id_flota,
                'marca', NEW.marca, 'modelo', NEW.modelo, 'anio', NEW.anio,
                'fecha_ingreso', NEW.fecha_ingreso, 'fecha_salida', NEW.fecha_salida,
                'patente', NEW.patente, 'borrado', NEW.borrado, 'fecha_borrado', NEW.fecha_borrado)
  );
END$$

CREATE TRIGGER tr_vehiculo_delete_audit
BEFORE DELETE ON vehiculo
FOR EACH ROW
BEGIN
  INSERT INTO audit_log (tabla, accion, pk_valor, usuario, valores_antes)
  VALUES ('vehiculo', 'DELETE', OLD.id_vehiculo, CURRENT_USER(),
    JSON_OBJECT('id_empresa', OLD.id_empresa, 'id_flota', OLD.id_flota,
                'marca', OLD.marca, 'modelo', OLD.modelo, 'anio', OLD.anio,
                'fecha_ingreso', OLD.fecha_ingreso, 'fecha_salida', OLD.fecha_salida,
                'patente', OLD.patente, 'borrado', OLD.borrado, 'fecha_borrado', OLD.fecha_borrado)
  );
END$$

DELIMITER ;