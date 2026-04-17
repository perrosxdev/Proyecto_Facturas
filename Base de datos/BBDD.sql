SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION';

DROP SCHEMA IF EXISTS `distribution`;
CREATE SCHEMA IF NOT EXISTS `distribution` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE `distribution`;

-- =========================
-- CATÁLOGO GEO (sin soft delete)
-- =========================
CREATE TABLE region (
  id_region INT AUTO_INCREMENT PRIMARY KEY,
  nombre_region VARCHAR(45) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE comuna (
  id_comuna INT AUTO_INCREMENT PRIMARY KEY,
  id_region INT NOT NULL,
  nombre_comuna VARCHAR(45) NOT NULL,
  KEY idx_comuna_id_region (id_region),
  CONSTRAINT fk_comuna_region
    FOREIGN KEY (id_region) REFERENCES region(id_region)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE ciudad (
  id_ciudad INT AUTO_INCREMENT PRIMARY KEY,
  id_comuna INT NOT NULL,
  nombre_ciudad VARCHAR(45) NOT NULL,
  KEY idx_ciudad_id_comuna (id_comuna),
  CONSTRAINT fk_ciudad_comuna
    FOREIGN KEY (id_comuna) REFERENCES comuna(id_comuna)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =========================
-- EMPRESA (tenant) soft delete
-- rut_empresa NO único global (solo índice)
-- =========================
CREATE TABLE empresa (
  id_empresa INT AUTO_INCREMENT PRIMARY KEY,
  nombre_empresa VARCHAR(50) NOT NULL,
  rut_empresa VARCHAR(12) NOT NULL,
  calle VARCHAR(50) NOT NULL,
  numero INT,
  id_ciudad INT NOT NULL,

  borrado TINYINT NOT NULL DEFAULT 0,
  fecha_borrado DATETIME NULL,

  KEY idx_empresa_rut (rut_empresa),
  KEY idx_empresa_ciudad (id_ciudad),
  KEY idx_empresa_borrado (borrado),

  CONSTRAINT fk_empresa_ciudad
    FOREIGN KEY (id_ciudad) REFERENCES ciudad(id_ciudad)
    ON DELETE RESTRICT ON UPDATE CASCADE,

  CONSTRAINT ck_empresa_softdelete
    CHECK (
      (borrado = 0 AND fecha_borrado IS NULL) OR
      (borrado = 1 AND fecha_borrado IS NOT NULL)
    )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =========================
-- USUARIOS / ROLES / LOGIN
-- =========================
CREATE TABLE usuarios (
  id_usuario INT AUTO_INCREMENT PRIMARY KEY,
  nombres VARCHAR(45) NOT NULL,
  apellido_paterno VARCHAR(45) NOT NULL,
  apellido_materno VARCHAR(45),
  celular VARCHAR(15) NOT NULL,

  borrado TINYINT NOT NULL DEFAULT 0,
  fecha_borrado DATETIME NULL,

  celular_activo VARCHAR(15)
    GENERATED ALWAYS AS (CASE WHEN borrado = 0 THEN celular ELSE NULL END) STORED,

  UNIQUE KEY uq_usuarios_celular_activo (celular_activo),
  KEY idx_usuarios_borrado (borrado),

  CONSTRAINT ck_usuarios_softdelete
    CHECK (
      (borrado = 0 AND fecha_borrado IS NULL) OR
      (borrado = 1 AND fecha_borrado IS NOT NULL)
    )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE roles (
  id_rol INT AUTO_INCREMENT PRIMARY KEY,
  nombre_rol VARCHAR(50) NOT NULL,
  UNIQUE KEY uq_roles_nombre (nombre_rol)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE login (
  id_login INT AUTO_INCREMENT PRIMARY KEY,
  email VARCHAR(256) NOT NULL,
  password VARCHAR(255) NOT NULL,
  id_usuario INT NOT NULL,
  id_rol INT NOT NULL,
  verificado TINYINT NOT NULL DEFAULT 0,
  fecha_creacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_modificacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  borrado TINYINT NOT NULL DEFAULT 0,
  fecha_borrado DATETIME NULL,

  email_activo VARCHAR(256)
    GENERATED ALWAYS AS (CASE WHEN borrado = 0 THEN email ELSE NULL END) STORED,

  UNIQUE KEY uq_login_email_activo (email_activo),
  UNIQUE KEY uq_login_id_usuario (id_usuario),

  KEY idx_login_rol (id_rol),
  KEY idx_login_borrado (borrado),

  CONSTRAINT fk_login_usuario
    FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_login_rol
    FOREIGN KEY (id_rol) REFERENCES roles(id_rol)
    ON DELETE RESTRICT ON UPDATE CASCADE,

  CONSTRAINT ck_login_softdelete
    CHECK (
      (borrado = 0 AND fecha_borrado IS NULL) OR
      (borrado = 1 AND fecha_borrado IS NOT NULL)
    )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

DELIMITER $$
CREATE TRIGGER trg_usuarios_softdelete_login
AFTER UPDATE ON usuarios
FOR EACH ROW
BEGIN
  IF (OLD.borrado = 0 AND NEW.borrado = 1) THEN
    UPDATE login
      SET borrado = 1,
          fecha_borrado = COALESCE(fecha_borrado, NOW())
    WHERE id_usuario = NEW.id_usuario AND borrado = 0;
  END IF;

  IF (OLD.borrado = 1 AND NEW.borrado = 0) THEN
    UPDATE login
      SET borrado = 0,
          fecha_borrado = NULL
    WHERE id_usuario = NEW.id_usuario AND borrado = 1;
  END IF;
END$$
DELIMITER ;

-- =========================
-- EMPLEADOS (soft delete)
-- 1 empleo activo por usuario
-- =========================
CREATE TABLE empleados (
  id_empleado INT AUTO_INCREMENT PRIMARY KEY,
  id_usuario INT NOT NULL,
  id_empresa INT NOT NULL,
  cargo VARCHAR(100) NOT NULL,

  borrado TINYINT NOT NULL DEFAULT 0,
  fecha_borrado DATETIME NULL,
  borrado_por INT NULL,

  id_usuario_activo INT
    GENERATED ALWAYS AS (CASE WHEN borrado = 0 THEN id_usuario ELSE NULL END) STORED,

  UNIQUE KEY uq_empleados_usuario_activo (id_usuario_activo),

  KEY idx_empleados_empresa (id_empresa),
  KEY idx_empleados_usuario (id_usuario),
  KEY idx_empleados_borrado (borrado),
  KEY idx_empleados_borrado_por (borrado_por),

  CONSTRAINT fk_empleados_usuario
    FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_empleados_empresa
    FOREIGN KEY (id_empresa) REFERENCES empresa(id_empresa)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_empleados_borrado_por
    FOREIGN KEY (borrado_por) REFERENCES usuarios(id_usuario)
    ON DELETE SET NULL ON UPDATE CASCADE,

  CONSTRAINT ck_empleados_softdelete
    CHECK (
      (borrado = 0 AND fecha_borrado IS NULL) OR
      (borrado = 1 AND fecha_borrado IS NOT NULL)
    )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =========================
-- GIROS
-- =========================
CREATE TABLE lista_giros (
  id_giro INT AUTO_INCREMENT PRIMARY KEY,
  nombre_giro VARCHAR(256) NOT NULL,
  codigo_giro INT,
  UNIQUE KEY uq_lista_giros_codigo (codigo_giro)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE giros_empresa (
  id INT AUTO_INCREMENT PRIMARY KEY,
  id_giro INT NOT NULL,
  id_empresa INT NOT NULL,
  UNIQUE KEY uq_giros_empresa (id_giro, id_empresa),
  KEY idx_giros_empresa_empresa (id_empresa),
  CONSTRAINT fk_giros_empresa_giro
    FOREIGN KEY (id_giro) REFERENCES lista_giros(id_giro)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_giros_empresa_empresa
    FOREIGN KEY (id_empresa) REFERENCES empresa(id_empresa)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =========================
-- CLIENTES (soft delete) UNIQUE activo por empresa+rut
-- =========================
CREATE TABLE clientes (
  id_cliente INT AUTO_INCREMENT PRIMARY KEY,
  id_empresa INT NOT NULL,
  nombre_cliente VARCHAR(100) NOT NULL,
  rut_cliente VARCHAR(12) NOT NULL,
  id_giro INT NULL,
  calle VARCHAR(50) NOT NULL,
  numero INT,
  id_ciudad INT NOT NULL,

  borrado TINYINT NOT NULL DEFAULT 0,
  fecha_borrado DATETIME NULL,

  rut_cliente_activo VARCHAR(12)
    GENERATED ALWAYS AS (CASE WHEN borrado = 0 THEN rut_cliente ELSE NULL END) STORED,

  UNIQUE KEY uq_clientes_empresa_rut_activo (id_empresa, rut_cliente_activo),

  KEY idx_clientes_empresa_borrado (id_empresa, borrado),
  KEY idx_clientes_ciudad (id_ciudad),
  KEY idx_clientes_giro (id_giro),

  CONSTRAINT fk_clientes_empresa
    FOREIGN KEY (id_empresa) REFERENCES empresa(id_empresa)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_clientes_giro
    FOREIGN KEY (id_giro) REFERENCES lista_giros(id_giro)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT fk_clientes_ciudad
    FOREIGN KEY (id_ciudad) REFERENCES ciudad(id_ciudad)
    ON DELETE RESTRICT ON UPDATE CASCADE,

  CONSTRAINT ck_clientes_softdelete
    CHECK (
      (borrado = 0 AND fecha_borrado IS NULL) OR
      (borrado = 1 AND fecha_borrado IS NOT NULL)
    )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =========================
-- BODEGA (soft delete)
-- Multi-tenant: UNIQUE (id_empresa,id_bodega) para FK compuesta
-- =========================
CREATE TABLE bodega (
  id_bodega INT AUTO_INCREMENT PRIMARY KEY,
  id_empresa INT NOT NULL,
  nombre_bodega VARCHAR(45) NOT NULL,
  calle VARCHAR(45) NOT NULL,
  numero INT,
  id_ciudad INT NOT NULL,

  borrado TINYINT NOT NULL DEFAULT 0,
  fecha_borrado DATETIME NULL,

  nombre_bodega_activo VARCHAR(45)
    GENERATED ALWAYS AS (CASE WHEN borrado = 0 THEN nombre_bodega ELSE NULL END) STORED,

  UNIQUE KEY uq_bodega_empresa_id (id_empresa, id_bodega),
  UNIQUE KEY uq_bodega_empresa_nombre_activo (id_empresa, nombre_bodega_activo),

  KEY idx_bodega_empresa_borrado (id_empresa, borrado),
  KEY idx_bodega_ciudad (id_ciudad),

  CONSTRAINT fk_bodega_empresa
    FOREIGN KEY (id_empresa) REFERENCES empresa(id_empresa)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_bodega_ciudad
    FOREIGN KEY (id_ciudad) REFERENCES ciudad(id_ciudad)
    ON DELETE RESTRICT ON UPDATE CASCADE,

  CONSTRAINT ck_bodega_softdelete
    CHECK (
      (borrado = 0 AND fecha_borrado IS NULL) OR
      (borrado = 1 AND fecha_borrado IS NOT NULL)
    )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =========================
-- PROVEEDORES (soft delete)
-- =========================
CREATE TABLE proveedores (
  id_proveedor INT AUTO_INCREMENT PRIMARY KEY,
  id_empresa INT NOT NULL,
  rut_proveedor VARCHAR(12) NOT NULL,
  nombre_proveedor VARCHAR(45) NOT NULL,
  nombre_vendedor VARCHAR(45),
  telefono_vendedor VARCHAR(15),
  telefono_fijo VARCHAR(15),
  email_vendedor VARCHAR(256),

  borrado TINYINT NOT NULL DEFAULT 0,
  fecha_borrado DATETIME NULL,

  rut_proveedor_activo VARCHAR(12)
    GENERATED ALWAYS AS (CASE WHEN borrado = 0 THEN rut_proveedor ELSE NULL END) STORED,

  UNIQUE KEY uq_proveedores_empresa_id (id_empresa, id_proveedor),
  UNIQUE KEY uq_proveedores_empresa_rut_activo (id_empresa, rut_proveedor_activo),

  KEY idx_proveedores_empresa_borrado (id_empresa, borrado),

  CONSTRAINT fk_proveedores_empresa
    FOREIGN KEY (id_empresa) REFERENCES empresa(id_empresa)
    ON DELETE RESTRICT ON UPDATE CASCADE,

  CONSTRAINT ck_proveedores_softdelete
    CHECK (
      (borrado = 0 AND fecha_borrado IS NULL) OR
      (borrado = 1 AND fecha_borrado IS NOT NULL)
    )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =========================
-- PRODUCTO (soft delete)
-- =========================
CREATE TABLE producto (
  id_producto INT AUTO_INCREMENT PRIMARY KEY,
  id_empresa INT NOT NULL,
  nombre_producto VARCHAR(45) NOT NULL,

  borrado TINYINT NOT NULL DEFAULT 0,
  fecha_borrado DATETIME NULL,

  UNIQUE KEY uq_producto_empresa_id (id_empresa, id_producto),
  KEY idx_producto_empresa_borrado (id_empresa, borrado),

  CONSTRAINT fk_producto_empresa
    FOREIGN KEY (id_empresa) REFERENCES empresa(id_empresa)
    ON DELETE RESTRICT ON UPDATE CASCADE,

  CONSTRAINT ck_producto_softdelete
    CHECK (
      (borrado = 0 AND fecha_borrado IS NULL) OR
      (borrado = 1 AND fecha_borrado IS NOT NULL)
    )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =========================
-- PRODUCTO <-> PROVEEDOR (soft delete) + FKs compuestas
-- =========================
CREATE TABLE producto_proveedor (
  id INT AUTO_INCREMENT PRIMARY KEY,
  id_empresa INT NOT NULL,
  id_producto INT NOT NULL,
  id_proveedor INT NOT NULL,

  borrado TINYINT NOT NULL DEFAULT 0,
  fecha_borrado DATETIME NULL,

  id_producto_activo INT
    GENERATED ALWAYS AS (CASE WHEN borrado = 0 THEN id_producto ELSE NULL END) STORED,
  id_proveedor_activo INT
    GENERATED ALWAYS AS (CASE WHEN borrado = 0 THEN id_proveedor ELSE NULL END) STORED,

  UNIQUE KEY uq_pp_activo (id_empresa, id_producto_activo, id_proveedor_activo),

  KEY idx_pp_empresa_producto (id_empresa, id_producto),
  KEY idx_pp_empresa_proveedor (id_empresa, id_proveedor),
  KEY idx_pp_empresa_borrado (id_empresa, borrado),

  CONSTRAINT fk_pp_producto
    FOREIGN KEY (id_empresa, id_producto)
    REFERENCES producto(id_empresa, id_producto)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_pp_proveedor
    FOREIGN KEY (id_empresa, id_proveedor)
    REFERENCES proveedores(id_empresa, id_proveedor)
    ON DELETE RESTRICT ON UPDATE CASCADE,

  CONSTRAINT ck_pp_softdelete
    CHECK (
      (borrado = 0 AND fecha_borrado IS NULL) OR
      (borrado = 1 AND fecha_borrado IS NOT NULL)
    )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =========================
-- INVENTARIO (soft delete) + FKs compuestas
-- =========================
CREATE TABLE inventario (
  id_inventario INT AUTO_INCREMENT PRIMARY KEY,
  id_empresa INT NOT NULL,
  id_bodega INT NOT NULL,
  id_producto INT NOT NULL,
  stock INT UNSIGNED NOT NULL DEFAULT 0,

  borrado TINYINT NOT NULL DEFAULT 0,
  fecha_borrado DATETIME NULL,

  id_bodega_activo INT
    GENERATED ALWAYS AS (CASE WHEN borrado = 0 THEN id_bodega ELSE NULL END) STORED,
  id_producto_activo INT
    GENERATED ALWAYS AS (CASE WHEN borrado = 0 THEN id_producto ELSE NULL END) STORED,

  UNIQUE KEY uq_inv_activo (id_empresa, id_bodega_activo, id_producto_activo),

  KEY idx_inv_empresa_borrado (id_empresa, borrado),
  KEY idx_inv_empresa_bodega (id_empresa, id_bodega),
  KEY idx_inv_empresa_producto (id_empresa, id_producto),

  CONSTRAINT fk_inv_bodega
    FOREIGN KEY (id_empresa, id_bodega)
    REFERENCES bodega(id_empresa, id_bodega)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_inv_producto
    FOREIGN KEY (id_empresa, id_producto)
    REFERENCES producto(id_empresa, id_producto)
    ON DELETE RESTRICT ON UPDATE CASCADE,

  CONSTRAINT ck_inv_softdelete
    CHECK (
      (borrado = 0 AND fecha_borrado IS NULL) OR
      (borrado = 1 AND fecha_borrado IS NOT NULL)
    )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =========================
-- FLOTA / VEHICULO (soft delete) + FKs compuestas
-- =========================
CREATE TABLE flota (
  id_flota INT AUTO_INCREMENT PRIMARY KEY,
  id_empresa INT NOT NULL,
  nombre_flota VARCHAR(45) NOT NULL,
  id_bodega INT NOT NULL,

  borrado TINYINT NOT NULL DEFAULT 0,
  fecha_borrado DATETIME NULL,

  UNIQUE KEY uq_flota_empresa_id (id_empresa, id_flota),

  KEY idx_flota_empresa_borrado (id_empresa, borrado),
  KEY idx_flota_empresa_bodega (id_empresa, id_bodega),

  CONSTRAINT fk_flota_bodega
    FOREIGN KEY (id_empresa, id_bodega)
    REFERENCES bodega(id_empresa, id_bodega)
    ON DELETE RESTRICT ON UPDATE CASCADE,

  CONSTRAINT ck_flota_softdelete
    CHECK (
      (borrado = 0 AND fecha_borrado IS NULL) OR
      (borrado = 1 AND fecha_borrado IS NOT NULL)
    )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE vehiculo (
  id_vehiculo INT AUTO_INCREMENT PRIMARY KEY,
  id_empresa INT NOT NULL,
  id_flota INT NOT NULL,

  marca VARCHAR(45) NOT NULL,
  modelo VARCHAR(45) NOT NULL,
  anio SMALLINT NOT NULL,

  fecha_ingreso DATE NOT NULL,
  fecha_salida DATE NULL,

  patente VARCHAR(10) NOT NULL,

  borrado TINYINT NOT NULL DEFAULT 0,
  fecha_borrado DATETIME NULL,

  patente_activo VARCHAR(10)
    GENERATED ALWAYS AS (CASE WHEN borrado = 0 THEN patente ELSE NULL END) STORED,

  UNIQUE KEY uq_vehiculo_empresa_patente_activo (id_empresa, patente_activo),

  KEY idx_vehiculo_empresa_borrado (id_empresa, borrado),
  KEY idx_vehiculo_empresa_flota (id_empresa, id_flota),

  CONSTRAINT fk_vehiculo_flota
    FOREIGN KEY (id_empresa, id_flota)
    REFERENCES flota(id_empresa, id_flota)
    ON DELETE RESTRICT ON UPDATE CASCADE,

  CONSTRAINT ck_vehiculo_anio
    CHECK (anio BETWEEN 1900 AND 2100),
  CONSTRAINT ck_vehiculo_fechas
    CHECK (fecha_salida IS NULL OR fecha_salida >= fecha_ingreso),
  CONSTRAINT ck_vehiculo_softdelete
    CHECK (
      (borrado = 0 AND fecha_borrado IS NULL) OR
      (borrado = 1 AND fecha_borrado IS NOT NULL)
    )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;