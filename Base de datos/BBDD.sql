-- MySQL Workbench Forward Engineering

SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

-- -----------------------------------------------------
-- Schema Distribution
-- -----------------------------------------------------
DROP SCHEMA IF EXISTS `Distribution` ;

-- -----------------------------------------------------
-- Schema Distribution
-- -----------------------------------------------------
CREATE SCHEMA IF NOT EXISTS `Distribution` DEFAULT CHARACTER SET utf8 ;
USE `Distribution` ;

-- -----------------------------------------------------
-- Table `Distribution`.`Region`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `Distribution`.`Region` ;

CREATE TABLE IF NOT EXISTS `Distribution`.`Region` (
  `id_Region` INT NOT NULL AUTO_INCREMENT,
  `Nombre_region` VARCHAR(45) NULL,
  PRIMARY KEY (`id_Region`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `Distribution`.`Comunas`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `Distribution`.`Comunas` ;

CREATE TABLE IF NOT EXISTS `Distribution`.`Comunas` (
  `id_comuna` INT NOT NULL AUTO_INCREMENT,
  `id_region` INT NOT NULL,
  `Nombre_comuna` VARCHAR(45) NULL,
  PRIMARY KEY (`id_comuna`),
  CONSTRAINT `fk_comunas_id_region`
    FOREIGN KEY (`id_region`)
    REFERENCES `Distribution`.`Region` (`id_Region`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;

CREATE INDEX `id_region_idx` ON `Distribution`.`Comunas` (`id_region` ASC) INVISIBLE;


-- -----------------------------------------------------
-- Table `Distribution`.`Ciudad`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `Distribution`.`Ciudad` ;

CREATE TABLE IF NOT EXISTS `Distribution`.`Ciudad` (
  `id_Ciudad` INT NOT NULL AUTO_INCREMENT,
  `id_comuna` INT NOT NULL,
  `nombre_ciudad` VARCHAR(45) NULL,
  PRIMARY KEY (`id_Ciudad`),
  CONSTRAINT `fk_comuna_id_comuna`
    FOREIGN KEY (`id_comuna`)
    REFERENCES `Distribution`.`Comunas` (`id_comuna`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `Distribution`.`Empresa`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `Distribution`.`Empresa` ;

CREATE TABLE IF NOT EXISTS `Distribution`.`Empresa` (
  `id_empresa` INT NOT NULL AUTO_INCREMENT,
  `nombre_empresa` VARCHAR(50) NULL,
  `Rut_empresa` INT NOT NULL,
  `calle_empresa` VARCHAR(50) NULL,
  `numero_calle_empresa` INT NULL,
  `id_region` INT NOT NULL,
  `id_comuna` INT NOT NULL,
  `id_ciudad` INT NOT NULL,
  PRIMARY KEY (`id_empresa`),
  CONSTRAINT `fk_empresa_id_comuna`
    FOREIGN KEY (`id_comuna`)
    REFERENCES `Distribution`.`Comunas` (`id_comuna`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_empresa_id_ciudad`
    FOREIGN KEY (`id_ciudad`)
    REFERENCES `Distribution`.`Ciudad` (`id_Ciudad`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_empresa_id_region`
    FOREIGN KEY (`id_region`)
    REFERENCES `Distribution`.`Region` (`id_Region`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;

CREATE UNIQUE INDEX `Rut_empresa_UNIQUE` ON `Distribution`.`Empresa` (`Rut_empresa` ASC) VISIBLE;

CREATE INDEX `id_comuna_idx` ON `Distribution`.`Empresa` (`id_comuna` ASC) VISIBLE;

CREATE INDEX `id_ciudad_idx` ON `Distribution`.`Empresa` (`id_ciudad` ASC) VISIBLE;

CREATE INDEX `id_region_idx` ON `Distribution`.`Empresa` (`id_region` ASC) VISIBLE;


-- -----------------------------------------------------
-- Table `Distribution`.`Usuarios`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `Distribution`.`Usuarios` ;

CREATE TABLE IF NOT EXISTS `Distribution`.`Usuarios` (
  `id_Usuarios` INT NOT NULL AUTO_INCREMENT,
  `Nombres` VARCHAR(45) NULL,
  `Apellido_paterno` VARCHAR(45) NULL,
  `Apellido_materno` VARCHAR(45) NULL,
  `celular` VARCHAR(20) NULL,
  PRIMARY KEY (`id_Usuarios`))
ENGINE = InnoDB;

CREATE UNIQUE INDEX `celular_UNIQUE` ON `Distribution`.`Usuarios` (`celular` ASC) VISIBLE;


-- -----------------------------------------------------
-- Table `Distribution`.`Login`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `Distribution`.`Login` ;

CREATE TABLE IF NOT EXISTS `Distribution`.`Login` (
  `id_login` INT NOT NULL AUTO_INCREMENT,
  `email` VARCHAR(256) NOT NULL,
  `password` VARCHAR(255) NOT NULL,
  `id_Usuarios` INT NOT NULL,
  `verificado` TINYINT NOT NULL DEFAULT 1,
  `fecha_creacion` DATETIME NOT NULL,
  `fecha_modificacion` DATETIME NOT NULL,
  PRIMARY KEY (`id_login`),
  CONSTRAINT `fk_login_id_Usuarios`
    FOREIGN KEY (`id_Usuarios`)
    REFERENCES `Distribution`.`Usuarios` (`id_Usuarios`)
    ON DELETE CASCADE
    ON UPDATE NO ACTION)
ENGINE = InnoDB;

CREATE INDEX `id_Usuarios_idx` ON `Distribution`.`Login` (`id_Usuarios` ASC) VISIBLE;

CREATE UNIQUE INDEX `email_UNIQUE` ON `Distribution`.`Login` (`email` ASC) VISIBLE;


-- -----------------------------------------------------
-- Table `Distribution`.`Empleados`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `Distribution`.`Empleados` ;

CREATE TABLE IF NOT EXISTS `Distribution`.`Empleados` (
  `id_Empleados` INT NOT NULL AUTO_INCREMENT,
  `id_Usuarios` INT NOT NULL,
  `id_empresa` INT NULL,
  `cargo` VARCHAR(100) NULL,
  `borrado` TINYINT NULL DEFAULT 0,
  `fecha_borrado` DATE NULL DEFAULT NULL,
  `borrado_por` INT NULL,
  PRIMARY KEY (`id_Empleados`),
  CONSTRAINT `fk_empleados_id_usuarios`
    FOREIGN KEY (`borrado_por`)
    REFERENCES `Distribution`.`Usuarios` (`id_Usuarios`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_empleados_id_empresa`
    FOREIGN KEY (`id_empresa`)
    REFERENCES `Distribution`.`Empresa` (`id_empresa`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;

CREATE INDEX `id_usuarios_idx` ON `Distribution`.`Empleados` (`borrado_por` ASC) VISIBLE;

CREATE INDEX `id_empresa_idx` ON `Distribution`.`Empleados` (`id_empresa` ASC) VISIBLE;


-- -----------------------------------------------------
-- Table `Distribution`.`lista_giros`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `Distribution`.`lista_giros` ;

CREATE TABLE IF NOT EXISTS `Distribution`.`lista_giros` (
  `id_giros` INT NOT NULL AUTO_INCREMENT,
  `nombre_giro` VARCHAR(256) NULL,
  `codigo_giro` INT NULL,
  PRIMARY KEY (`id_giros`))
ENGINE = InnoDB;

CREATE UNIQUE INDEX `codigo_giro_UNIQUE` ON `Distribution`.`lista_giros` (`codigo_giro` ASC) VISIBLE;


-- -----------------------------------------------------
-- Table `Distribution`.`Giros_empresa`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `Distribution`.`Giros_empresa` ;

CREATE TABLE IF NOT EXISTS `Distribution`.`Giros_empresa` (
  `id_Giros_empresa` INT NOT NULL AUTO_INCREMENT,
  `id_giro` INT NULL,
  `id_empresa` INT NULL,
  PRIMARY KEY (`id_Giros_empresa`),
  CONSTRAINT `fk_giro_empresa_id_giro`
    FOREIGN KEY (`id_giro`)
    REFERENCES `Distribution`.`lista_giros` (`id_giros`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_giro_empresa_id_empresa`
    FOREIGN KEY (`id_empresa`)
    REFERENCES `Distribution`.`Empresa` (`id_empresa`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;

CREATE INDEX `id_giro_idx` ON `Distribution`.`Giros_empresa` (`id_giro` ASC) VISIBLE;

CREATE INDEX `id_empresa_idx` ON `Distribution`.`Giros_empresa` (`id_empresa` ASC) VISIBLE;


-- -----------------------------------------------------
-- Table `Distribution`.`Clientes`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `Distribution`.`Clientes` ;

CREATE TABLE IF NOT EXISTS `Distribution`.`Clientes` (
  `id_Clientes` INT NOT NULL AUTO_INCREMENT,
  `id_empresa` INT NULL,
  `Nombre_cliente` VARCHAR(100) NULL,
  `Rut_cliente` INT NULL,
  `Giro_cliente` INT NULL,
  `Calle_cliente` VARCHAR(50) NULL,
  `Numero_calle_cliente` INT NULL,
  `Region_cliente` INT NOT NULL,
  `comuna_cliente` INT NOT NULL,
  `Ciudad_cliente` INT NOT NULL,
  PRIMARY KEY (`id_Clientes`),
  CONSTRAINT `fk_clientes_id_empresa`
    FOREIGN KEY (`id_empresa`)
    REFERENCES `Distribution`.`Empresa` (`id_empresa`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_clientes_comuna_cliente`
    FOREIGN KEY (`comuna_cliente`)
    REFERENCES `Distribution`.`Comunas` (`id_comuna`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_clientes_Ciudad_cliente`
    FOREIGN KEY (`Ciudad_cliente`)
    REFERENCES `Distribution`.`Ciudad` (`id_Ciudad`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_clientes_region_cliente`
    FOREIGN KEY (`Region_cliente`)
    REFERENCES `Distribution`.`Region` (`id_Region`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;

CREATE INDEX `id_empresa_idx` ON `Distribution`.`Clientes` (`id_empresa` ASC) VISIBLE;

CREATE INDEX `comuna_cliente_idx` ON `Distribution`.`Clientes` (`comuna_cliente` ASC) VISIBLE;

CREATE INDEX `Ciudad_cliente_idx` ON `Distribution`.`Clientes` (`Ciudad_cliente` ASC) VISIBLE;

CREATE INDEX `region_cliente_idx` ON `Distribution`.`Clientes` (`Region_cliente` ASC) VISIBLE;


-- -----------------------------------------------------
-- Table `Distribution`.`Bodega`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `Distribution`.`Bodega` ;

CREATE TABLE IF NOT EXISTS `Distribution`.`Bodega` (
  `id_Bodega` INT NOT NULL AUTO_INCREMENT,
  `id_empresa` INT NOT NULL,
  `id_Region` INT NOT NULL,
  `id_comuna` INT NOT NULL,
  `id_ciudad` INT NOT NULL,
  `nombre_bodega` VARCHAR(45) NOT NULL,
  `Calle_bodega` VARCHAR(45) NOT NULL,
  `numero_calle_bodega` INT NULL,
  PRIMARY KEY (`id_Bodega`),
  CONSTRAINT `fk_bodega_id_empresa`
    FOREIGN KEY (`id_empresa`)
    REFERENCES `Distribution`.`Empresa` (`id_empresa`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_bodega_id_region`
    FOREIGN KEY (`id_Region`)
    REFERENCES `Distribution`.`Region` (`id_Region`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_bodega_id_comuna`
    FOREIGN KEY (`id_comuna`)
    REFERENCES `Distribution`.`Comunas` (`id_comuna`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_bodega_id_ciudad`
    FOREIGN KEY (`id_ciudad`)
    REFERENCES `Distribution`.`Ciudad` (`id_Ciudad`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;

CREATE INDEX `id_empresa_idx` ON `Distribution`.`Bodega` (`id_empresa` ASC) VISIBLE;

CREATE INDEX `id_region_idx` ON `Distribution`.`Bodega` (`id_Region` ASC) VISIBLE;

CREATE INDEX `id_comuna_idx` ON `Distribution`.`Bodega` (`id_comuna` ASC) VISIBLE;

CREATE INDEX `id_ciudad_idx` ON `Distribution`.`Bodega` (`id_ciudad` ASC) VISIBLE;


-- -----------------------------------------------------
-- Table `Distribution`.`Proveedores`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `Distribution`.`Proveedores` ;

CREATE TABLE IF NOT EXISTS `Distribution`.`Proveedores` (
  `id_Proveedores` INT NOT NULL AUTO_INCREMENT,
  `id_empresa` INT NOT NULL,
  `rut_proveedor` INT NOT NULL,
  `nombre_proveedor` VARCHAR(45) NULL,
  `nombre_vendedor` VARCHAR(45) NULL,
  `celular_vendedor` INT NULL,
  `email_vendedor` VARCHAR(256) NULL,
  PRIMARY KEY (`id_Proveedores`),
  CONSTRAINT `fk_proveedores_id_empresa`
    FOREIGN KEY (`id_empresa`)
    REFERENCES `Distribution`.`Empresa` (`id_empresa`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;

CREATE UNIQUE INDEX `rut_proveedor_UNIQUE` ON `Distribution`.`Proveedores` (`rut_proveedor` ASC) VISIBLE;

CREATE INDEX `id_empresa_idx` ON `Distribution`.`Proveedores` (`id_empresa` ASC) VISIBLE;


-- -----------------------------------------------------
-- Table `Distribution`.`producto`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `Distribution`.`producto` ;

CREATE TABLE IF NOT EXISTS `Distribution`.`producto` (
  `id_producto` INT NOT NULL,
  `id_proveedor` INT NOT NULL,
  `id_empresa` INT NOT NULL,
  `nombre_producto` VARCHAR(45) NULL,
  PRIMARY KEY (`id_producto`),
  CONSTRAINT `fk_producto_id_proveedor`
    FOREIGN KEY (`id_proveedor`)
    REFERENCES `Distribution`.`Proveedores` (`id_Proveedores`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_producto_id_empresa`
    FOREIGN KEY (`id_empresa`)
    REFERENCES `Distribution`.`Empresa` (`id_empresa`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;

CREATE INDEX `id_proveedor_idx` ON `Distribution`.`producto` (`id_proveedor` ASC) VISIBLE;

CREATE INDEX `id_empresa_idx` ON `Distribution`.`producto` (`id_empresa` ASC) VISIBLE;


-- -----------------------------------------------------
-- Table `Distribution`.`inventario`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `Distribution`.`inventario` ;

CREATE TABLE IF NOT EXISTS `Distribution`.`inventario` (
  `id_nventario` INT NOT NULL,
  `id_bodega` INT NOT NULL,
  `id_producto` INT NOT NULL,
  `stock_producto` INT NOT NULL,
  PRIMARY KEY (`id_nventario`),
  CONSTRAINT `fk_inventario_id_bodega`
    FOREIGN KEY (`id_bodega`)
    REFERENCES `Distribution`.`Bodega` (`id_Bodega`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_inventario_id_producto`
    FOREIGN KEY (`id_producto`)
    REFERENCES `Distribution`.`producto` (`id_producto`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;

CREATE INDEX `id_bodega_idx` ON `Distribution`.`inventario` (`id_bodega` ASC) VISIBLE;

CREATE INDEX `id_producto_idx` ON `Distribution`.`inventario` (`id_producto` ASC) VISIBLE;


-- -----------------------------------------------------
-- Table `Distribution`.`flota`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `Distribution`.`flota` ;

CREATE TABLE IF NOT EXISTS `Distribution`.`flota` (
  `id_flota` INT NOT NULL,
  `nombre_flota` VARCHAR(45) NOT NULL,
  `id_bodega` INT NOT NULL,
  PRIMARY KEY (`id_flota`),
  CONSTRAINT `fk_bodega_id_bodega`
    FOREIGN KEY (`id_bodega`)
    REFERENCES `Distribution`.`Bodega` (`id_Bodega`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;

CREATE INDEX `fk_bodega_id_bodega_idx` ON `Distribution`.`flota` (`id_bodega` ASC) VISIBLE;


-- -----------------------------------------------------
-- Table `Distribution`.`vehiculo`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `Distribution`.`vehiculo` ;

CREATE TABLE IF NOT EXISTS `Distribution`.`vehiculo` (
  `id_vehiculo` INT NOT NULL AUTO_INCREMENT,
  `id_flota` INT NOT NULL,
  `marca_vehiculo` VARCHAR(45) NULL,
  `modelo_vehiculo` VARCHAR(45) NULL,
  `anio_vehiculo` INT NULL,
  `fecha_ingreso` DATE NOT NULL,
  `fecha_salida` DATE NULL,
  `patente_vehiculo` VARCHAR(45) NOT NULL,
  PRIMARY KEY (`id_vehiculo`),
  CONSTRAINT `fk_vehiculo_id_flota`
    FOREIGN KEY (`id_flota`)
    REFERENCES `Distribution`.`flota` (`id_flota`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;

CREATE UNIQUE INDEX `patente_vehiculo_UNIQUE` ON `Distribution`.`vehiculo` (`patente_vehiculo` ASC) VISIBLE;

CREATE INDEX `fk_vehiculo_id_flota_idx` ON `Distribution`.`vehiculo` (`id_flota` ASC) VISIBLE;


SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;
