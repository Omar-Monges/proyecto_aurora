------------------------------------------------Creacion DB------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'Com2900G19')
	CREATE DATABASE Com2900G19 COLLATE Modern_Spanish_CI_AS;
-- USE master;
--IF EXISTS (SELECT * FROM sys.databases WHERE name = 'Com2900G19') DROP DATABASE Com2900G19;
GO
USE Com2900G19;
GO
------------------------------------------------Esquemas------------------------------------------------
--Esquema Direccion
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = 'Direccion')
	EXEC('CREATE SCHEMA Direccion');
GO
--Esquema Sucursal
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = 'Sucursal')
	EXEC('CREATE SCHEMA Sucursal');
GO
--Esquema Empleado
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = 'Empleado')
	EXEC('CREATE SCHEMA Empleado');
GO
--Esquema Factura
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = 'Factura')
	EXEC('CREATE SCHEMA Factura');
GO
--Esquema Producto
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = 'Producto')
	EXEC('CREATE SCHEMA Producto');
GO
------------------------------------------------Tablas------------------------------------------------
---Esquema Direccion:
--		Tabla Direccion:
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Direccion')
BEGIN
	CREATE TABLE Direccion.Direccion
	(
		idDireccion INT IDENTITY(1,1),
		calle VARCHAR(255)NOT NULL,
		numeroDeCalle SMALLINT NOT NULL,--short en C
		piso TINYINT NULL, --unsigned char en C
		departamento TINYINT NULL,
		codigoPostal VARCHAR(10) NOT NULL,
		localidad VARCHAR(50) NOT NULL,
		provincia VARCHAR(50) NOT NULL,
		CONSTRAINT PK_Direccion PRIMARY KEY(IDDireccion),
		CONSTRAINT CK_Direccion_NumeroDeCalle CHECK(numeroDeCalle >= 0),
		CONSTRAINT CK_Empleado_Edificio CHECK((piso IS NULL AND departamento IS NULL) OR 
											(piso IS NOT NULL AND departamento IS NOT NULL))
	)--CK = Check
END;
GO
--Esquema Sucursal:
--		Tabla Sucursal
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Sucursal')
BEGIN
	CREATE TABLE Sucursal.Sucursal
	(
		idSucursal INT IDENTITY(1,1),
		telefono VARCHAR(9) NOT NULL,
		idDireccion INT,
		horario VARCHAR(100) NOT NULL,
		CONSTRAINT PK_Sucursal PRIMARY KEY(idSucursal),
		CONSTRAINT FK_Sucursal_Direccion FOREIGN KEY(IDDireccion) REFERENCES Direccion.Direccion(idDireccion),
		CONSTRAINT CK_Sucursal_Telefono CHECK(telefono LIKE '[0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]')
	)
END;
GO
--		Tabla Turnos de los Empleados
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Turno')
BEGIN
	CREATE TABLE Sucursal.Turno
	(
		idTurno INT IDENTITY(1,1),
		nombreTurno VARCHAR(50) NOT NULL,
		CONSTRAINT PK_Turno PRIMARY KEY(idTurno)
	)
END;
GO
--		Tabla Cargo de los Empleados
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Cargo')
BEGIN
	CREATE TABLE Sucursal.Cargo
	(
		idCargo INT IDENTITY(1,1),
		nombreCargo VARCHAR(50) NOT NULL,
		CONSTRAINT PK_Cargo PRIMARY KEY(idCargo)
	)
END;
GO
--Esquema Empleado:
--		Tabla Empleado
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Empleado')
BEGIN
	CREATE TABLE Empleado.Empleado
	(
		legajo INT IDENTITY(257020,1),
		dni VARCHAR(8) NOT NULL,
		cuil VARCHAR(13) NOT NULL,
		nombre VARCHAR(50) NOT NULL,
		apellido VARCHAR(50) NOT NULL,
		emailPersonal VARCHAR(100) NULL,
		emailEmpresarial VARCHAR(100) NOT NULL,
		idDireccion INT,
		idSucursal INT,
		idTurno INT,
		idCargo INT,
		CONSTRAINT PK_Legajo PRIMARY KEY(legajo),
		CONSTRAINT FK_Empleado_Direccion FOREIGN KEY(idDireccion) REFERENCES Direccion.Direccion(idDireccion),
		CONSTRAINT FK_Empleado_Sucursal FOREIGN KEY(idSucursal) REFERENCES Sucursal.Sucursal(idSucursal),
		CONSTRAINT FK_Empleado_Turno FOREIGN KEY(idTurno) REFERENCES Sucursal.Turno(idTurno),
		CONSTRAINT FK_Empleado_Cargo FOREIGN KEY(idCargo) REFERENCES Sucursal.Cargo(idCargo),
		CONSTRAINT CK_Empleado_DNI CHECK(dni LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'),
		CONSTRAINT CK_Empleado_CUIL CHECK(cuil LIKE '[0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]-[0-9]'),
		CONSTRAINT CK_Empleado_EmailPersonal CHECK(emailPersonal like '%@%.com'),
		CONSTRAINT CK_Empleado_EmailEmpresarial CHECK(emailEmpresarial LIKE '%@superA.com')
	)
END;
GO
--Esquema Producto:
--		Tabla Linea de Producto
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'TipoDeProducto')
BEGIN
	CREATE TABLE Producto.TipoDeProducto
	(
		idTipoDeProducto INT IDENTITY(1,1),
		nombreTipoDeProducto VARCHAR(50) NOT NULL,
		CONSTRAINT PK_TipoDeProducto PRIMARY KEY(idTipoDeProducto)
	)
END;
GO
--		Tabla Producto
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Producto')
BEGIN
	CREATE TABLE Producto.Producto
	(
		idProducto INT IDENTITY(1,1),
		idTipoDeProducto INT,
		descripcionProducto VARCHAR(150) NOT NULL,
		precioUnitario DECIMAL(15,2)  NOT NULL,
		precioReferencia DECIMAL(15,2)  NULL,
		unidadReferencia VARCHAR(10) NULL,
		CONSTRAINT PK_Producto PRIMARY KEY(idProducto),
		CONSTRAINT FK_Producto_TipoDeProducto FOREIGN KEY(idTipoDeProducto) REFERENCES Producto.TipoDeProducto(idTipoDeProducto),
		CONSTRAINT CK_Producto_PrecioUnitario CHECK(precioUnitario >= 0),
		CONSTRAINT CK_Producto_PrecioReferencia CHECK(precioReferencia >= 0),
		CONSTRAINT CK_Producto_Referencia CHECK((precioReferencia IS NOT NULL AND unidadReferencia IS NOT NULL) OR 
												(precioReferencia IS NULL AND unidadReferencia IS NULL))
	)
END;
GO
--Esquema Factura:
--		Tabla Medio De Pago de la Factura
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'MedioDePago')
BEGIN
	CREATE TABLE Factura.MedioDePago
	(
		idMedioDePago INT IDENTITY(1,1),
		nombreMedioDePago VARCHAR(50) NOT NULL,
		descripcion VARCHAR(50) NULL,
		CONSTRAINT PK_MedioDePago PRIMARY KEY(idMedioDePago)
	);
END;
GO
--		Tabla Factura
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Factura')
BEGIN
	CREATE TABLE Factura.Factura
	(
		idFactura INT IDENTITY(1,1),
		tipoFactura CHAR NOT NULL,
		tipoCliente VARCHAR(10) NOT NULL,
		genero VARCHAR(10) NOT NULL,
		cantidad SMALLINT NOT NULL,
		fechaHora SMALLDATETIME NOT NULL,
		idProducto INT,
		idMedioDepago INT,
		legajo INT,
		idSucursal INT,
		identificadorDePago VARCHAR(23) NOT NULL,
		CONSTRAINT PK_Factura PRIMARY KEY(idFactura),
		CONSTRAINT FK_Factura_MedioDePago FOREIGN KEY(idMedioDePago) REFERENCES Factura.MedioDePago(idMedioDePago),
		CONSTRAINT FK_Factura_LegajoEmpleado FOREIGN KEY(legajo) REFERENCES Empleado.Empleado(legajo),
		CONSTRAINT FK_Factura_Sucursal FOREIGN KEY(idSucursal) REFERENCES Sucursal.Sucursal(idSucursal),
		CONSTRAINT CK_Factura_TipoFactura CHECK(tipoFactura IN ('A', 'B', 'C')),
		CONSTRAINT CK_Factura_TipoCliente CHECK(tipoCliente IN('Normal', 'Member')), 
		CONSTRAINT CK_Factura_Genero CHECK(genero IN('Male', 'Female')),
		CONSTRAINT FK_Factura_Producto FOREIGN KEY(idProducto) REFERENCES Producto.Producto(idProducto),
		CONSTRAINT CK_Factura_CantidadProductos CHECK(cantidad > 0)
--		CONSTRAINT CK_Factura_IdentificadorDepago CHECK() <-- ¿Solo aceptan 3 tipos de pago? Efectivo,tarjeta y ewallet
	)
END;
GO