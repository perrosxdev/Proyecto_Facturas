Table region {
  id_region int [pk]
  nombre_region varchar
}

Table comuna {
  id_comuna int [pk]
  id_region int
  nombre_comuna varchar
  Note: 'Cada comuna pertenece a una única región. FK simple: id_region a region.'
}

Table ciudad {
  id_ciudad int [pk]
  id_comuna int
  nombre_ciudad varchar
  Note: 'Cada ciudad pertenece a una única comuna. FK simple: id_comuna a comuna.'
}

Table empresa {
  id_empresa int [pk]
  nombre_empresa varchar
  rut_empresa varchar
  calle varchar
  numero int
  id_ciudad int
  borrado tinyint
  fecha_borrado datetime
  Note: 'Pertenece a una ciudad. Tiene soft delete. rut_empresa solo índice, no unique.'
}

Table usuarios {
  id_usuario int [pk]
  nombres varchar
  apellido_paterno varchar
  apellido_materno varchar
  celular varchar
  borrado tinyint
  fecha_borrado datetime
  Note: 'Soft delete por borrado y fecha_borrado. Celular activo debe ser único.'
}

Table empleados {
  id_empleado int [pk]
  id_usuario int
  id_empresa int
  cargo varchar
  borrado tinyint
  fecha_borrado datetime
  borrado_por int
  Note: 'Empleo pertenece a usuario y empresa. Solo 1 empleo activo por usuario, validación por app no representada.'
}

Table roles {
  id_rol int [pk]
  nombre_rol varchar
  Note: 'Nombre de rol es único.'
}

Table login {
  id_login int [pk]
  email varchar
  password varchar
  id_usuario int
  id_rol int
  verificado tinyint
  fecha_creacion datetime
  fecha_modificacion datetime
  borrado tinyint
  fecha_borrado datetime
  Note: '1 login por usuario (unicidad no dibujada). Email activo único. Soft delete.'
}

Table lista_giros {
  id_giro int [pk]
  nombre_giro varchar
  codigo_giro int
  Note: 'Código es único.'
}

Table giros_empresa {
  id int [pk]
  id_giro int
  id_empresa int
  Note: 'Combinación id_giro e id_empresa es única, restricción no visualizada.'
}

Table clientes {
  id_cliente int [pk]
  id_empresa int
  nombre_cliente varchar
  rut_cliente varchar
  id_giro int
  calle varchar
  numero int
  id_ciudad int
  borrado tinyint
  fecha_borrado datetime
  Note: 'Soft delete. Unicidad compuesta por empresa y rut_cliente_activo solo activos.'
}

Table bodega {
  id_bodega int [pk]
  id_empresa int
  nombre_bodega varchar
  calle varchar
  numero int
  id_ciudad int
  borrado tinyint
  fecha_borrado datetime
  Note: 'Soft delete. Unique compuesto por (id_empresa, id_bodega); usada por FK compuesta en varias tablas.'
}

Table proveedores {
  id_proveedor int [pk]
  id_empresa int
  rut_proveedor varchar
  nombre_proveedor varchar
  nombre_vendedor varchar
  telefono_vendedor varchar
  telefono_fijo varchar
  email_vendedor varchar
  borrado tinyint
  fecha_borrado datetime
  Note: 'Soft delete. Unicidad compuesta por (id_empresa, id_proveedor) y (id_empresa, rut_proveedor_activo).'
}

Table producto {
  id_producto int [pk]
  id_empresa int
  nombre_producto varchar
  borrado tinyint
  fecha_borrado datetime
  Note: 'Soft delete. Unique compuesto por (id_empresa, id_producto). FK compuesta usada en inventario.'
}

Table producto_proveedor {
  id int [pk]
  id_empresa int
  id_producto int
  id_proveedor int
  borrado tinyint
  fecha_borrado datetime
  Note: 'Soft delete y FK compuesta a producto y proveedor, ver modelo lógico.'
}

Table inventario {
  id_inventario int [pk]
  id_empresa int
  id_bodega int
  id_producto int
  stock int
  borrado tinyint
  fecha_borrado datetime
  Note: 'Soft delete. Unique compuesto y FK compuesta a bodega y producto.'
}

Table flota {
  id_flota int [pk]
  id_empresa int
  nombre_flota varchar
  id_bodega int
  borrado tinyint
  fecha_borrado datetime
  Note: 'Soft delete y FK compuesta a bodega, unicidad compuesta.'
}

Table vehiculo {
  id_vehiculo int [pk]
  id_empresa int
  id_flota int
  marca varchar
  modelo varchar
  anio smallint
  fecha_ingreso date
  fecha_salida date
  patente varchar
  borrado tinyint
  fecha_borrado datetime
  Note: 'Soft delete. FK compuesta a flota y unicidad por patente_activo en empresa.'
}

Ref: comuna.id_region > region.id_region
Ref: ciudad.id_comuna > comuna.id_comuna
Ref: empresa.id_ciudad > ciudad.id_ciudad
Ref: empleados.id_usuario > usuarios.id_usuario
Ref: empleados.id_empresa > empresa.id_empresa
Ref: empleados.borrado_por > usuarios.id_usuario
Ref: login.id_usuario > usuarios.id_usuario
Ref: login.id_rol > roles.id_rol
Ref: giros_empresa.id_giro > lista_giros.id_giro
Ref: giros_empresa.id_empresa > empresa.id_empresa
Ref: clientes.id_empresa > empresa.id_empresa
Ref: clientes.id_giro > lista_giros.id_giro
Ref: clientes.id_ciudad > ciudad.id_ciudad
Ref: bodega.id_empresa > empresa.id_empresa
Ref: bodega.id_ciudad > ciudad.id_ciudad
Ref: proveedores.id_empresa > empresa.id_empresa
Ref: producto.id_empresa > empresa.id_empresa
Ref: producto_proveedor.id_producto > producto.id_producto
Ref: producto_proveedor.id_proveedor > proveedores.id_proveedor
Ref: inventario.id_producto > producto.id_producto
Ref: inventario.id_bodega > bodega.id_bodega
Ref: flota.id_bodega > bodega.id_bodega
Ref: vehiculo.id_flota > flota.id_flota