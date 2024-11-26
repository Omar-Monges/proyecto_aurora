------------------------------------------------Creacion DB------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'Com2900G19')
	CREATE DATABASE Com2900G19 COLLATE Modern_Spanish_CI_AS;
	
	EXEC sp_configure 'show advanced options', 1;
	RECONFIGURE;

	EXEC sp_configure 'Ole Automation Procedures', 1;
	RECONFIGURE;

	EXECUTE sp_configure 'Ad Hoc Distributed Queries', 1;
	RECONFIGURE;
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
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = 'Venta')
	EXEC('CREATE SCHEMA Venta');
GO
--Esquema Producto
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = 'Producto')
	EXEC('CREATE SCHEMA Producto');
--Esquema Importación
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = 'Importacion')
	EXEC('CREATE SCHEMA Importacion');
GO
--Esquema Seguridad
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = 'Seguridad')
	EXEC('CREATE SCHEMA Seguridad');
GO
------------------------------------------------Tablas------------------------------------------------
--Esquema Sucursal:
--		Tabla Sucursal
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Sucursal')
BEGIN
	CREATE TABLE Sucursal.Sucursal
	(
		idSucursal INT IDENTITY(1,1),
		telefono VARCHAR(9) NOT NULL,
		direccion VARCHAR(100),
		localidad VARCHAR(30),
		horario VARCHAR(100) NOT NULL,
		sucursalActiva BIT NOT NULL,
		cuit CHAR(13) NOT NULL,
		CONSTRAINT PK_Sucursal PRIMARY KEY(idSucursal),
		CONSTRAINT CK_Sucursal_Telefono CHECK(telefono LIKE '[0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]'),
		CONSTRAINT CK_Sucursal_Cuit CHECK(cuit LIKE '[0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]-[0-9]')
	)
END;
GO
--		Tabla Cargo de los Empleados
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Cargo')
BEGIN
	CREATE TABLE Sucursal.Cargo
	(
		idCargo INT IDENTITY(1,1),
		nombreCargo VARCHAR(30) NOT NULL,
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
		idEmpleado INT IDENTITY(1,1),
		legajo INT,
		dni CHAR(8) NOT NULL,
		cuil CHAR(13) NOT NULL,
		nombre VARCHAR(30) NOT NULL,
		apellido VARCHAR(30) NOT NULL,
		emailPersonal VARCHAR(60) NULL,
		emailEmpresarial VARCHAR(60) NOT NULL,
		direccion VARCHAR(100) NOT NULL,
		turno VARCHAR(20) NOT NULL,
		empleadoActivo BIT NOT NULL,
		idSucursal INT,
		idCargo INT,
		CONSTRAINT PK_Empleado_ID PRIMARY KEY(idEmpleado),
		CONSTRAINT FK_Empleado_Sucursal FOREIGN KEY(idSucursal) REFERENCES Sucursal.Sucursal(idSucursal),
		CONSTRAINT FK_Empleado_Cargo FOREIGN KEY(idCargo) REFERENCES Sucursal.Cargo(idCargo),
		CONSTRAINT CK_Empleado_DNI CHECK(dni LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'),
		CONSTRAINT CK_Empleado_CUIL CHECK(cuil LIKE '[0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]-[0-9]'),
		CONSTRAINT CK_Empleado_EmailPersonal CHECK(emailPersonal like '%_@__%.__%'),
		CONSTRAINT CK_Empleado_EmailEmpresarial CHECK(emailEmpresarial LIKE '%_@superA.com')
	)
END;
GO
--Esquema Producto:
--		Tabla Linea de Producto
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Clasificacion')
BEGIN
	CREATE TABLE Producto.Clasificacion
	(
		idClasificacion INT IDENTITY(1,1),
		nombreClasificacion VARCHAR(40) NOT NULL,
		lineaDeProducto VARCHAR(15) NOT NULL,
		CONSTRAINT PK_TipoDeProducto PRIMARY KEY(idClasificacion)
	)
END;
GO
--		Tabla Producto
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Producto')
BEGIN
	CREATE TABLE Producto.Producto
	(
		idProducto INT IDENTITY(1,1),
		idClasificacion INT,
		descripcionProducto VARCHAR(100) NOT NULL,
		precioUnitario DECIMAL(10,2)  NOT NULL,
		precioReferencia DECIMAL(10,2)  NULL,
		unidadReferencia VARCHAR(10) NULL,
		productoActivo bit,
		CONSTRAINT PK_Producto PRIMARY KEY(idProducto),
		CONSTRAINT FK_Producto_TipoDeProducto FOREIGN KEY(idClasificacion) REFERENCES Producto.Clasificacion(idClasificacion),
		CONSTRAINT CK_Producto_PrecioUnitario CHECK(precioUnitario >= 0),
		CONSTRAINT CK_Producto_PrecioReferencia CHECK(precioReferencia >= 0),
		CONSTRAINT CK_Producto_Referencia CHECK((precioReferencia IS NOT NULL AND unidadReferencia IS NOT NULL) OR 
												(precioReferencia IS NULL AND unidadReferencia IS NULL))
	)
END;
GO
--Esquema Venta:
--		Tabla Medio De Pago de la Venta
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'MedioDePago')
BEGIN
	CREATE TABLE Venta.MedioDePago
	(
		idMedioDePago INT IDENTITY(1,1),
		nombreMedioDePago VARCHAR(12) NOT NULL,
		descripcion VARCHAR(25) NOT NULL,
		CONSTRAINT PK_MedioDePago PRIMARY KEY(idMedioDePago)
	);
END;
GO
--		Tabla venta
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Venta')
BEGIN
	CREATE TABLE Venta.Venta
	(
		idVenta INT IDENTITY(1,1),
		idEmpleado INT,
		idSucursal INT,
		fechaHoraVenta SMALLDATETIME,
		cuilCliente CHAR(13),
		tipoCliente CHAR(6),
		estadoVenta VARCHAR(10),
		CONSTRAINT PK_Venta PRIMARY KEY(idVenta),
		CONSTRAINT FK_Venta_Empleado FOREIGN KEY(idEmpleado) REFERENCES Empleado.Empleado(idEmpleado),
		CONSTRAINT FK_Venta_Sucursal FOREIGN KEY(idSucursal) REFERENCES Sucursal.Sucursal(idSucursal)
	)
END;
GO
--		Tabla Factura
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Factura')
BEGIN
	CREATE TABLE Venta.Factura
	(
		idFactura INT IDENTITY(1,1),
		idVenta INT,
		tipoFactura CHAR,
		cuit CHAR(23),
		--idTipoCliente SMALLINT NOT NULL,
		fechaHora SMALLDATETIME,
		idMedioDepago INT,
		identificadorDePago VARCHAR(23),
		estadoDeFactura VARCHAR(10),
		totalConIva DECIMAL(11,2),
		totalSinIva DECIMAL(11,2),
		iva DECIMAL(3,2) DEFAULT 1.21,
		CONSTRAINT PK_Factura PRIMARY KEY(idFactura),
		CONSTRAINT FK_Factura_Venta FOREIGN KEY(idVenta) REFERENCES Venta.Venta(idVenta),
		CONSTRAINT FK_Factura_MedioDePago FOREIGN KEY(idMedioDePago) REFERENCES Venta.MedioDePago(idMedioDePago),
		--CONSTRAINT FK_Factura_tipoCliente FOREIGN KEY(idTipoCliente) REFERENCES Factura.TipoCliente(idTipoCliente),
		CONSTRAINT CK_Factura_TipoFactura CHECK(tipoFactura IN ('A', 'B', 'C')),
		--CORRECCION=> CONSTRAINT CK_Factura_Genero CHECK(genero IN('Male', 'Female')),
		
--		CONSTRAINT CK_Factura_IdentificadorDepago CHECK() <-- ¿Solo aceptan 3 tipos de pago? Efectivo,tarjeta y ewallet
	)
END;
GO
--		Tabla Detalle Venta
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'DetalleVenta')
BEGIN
	CREATE TABLE Venta.DetalleVenta
	(
		idDetalleVenta INT IDENTITY(1,1),
		idVenta INT,
		idProducto INT,
		precioUnitario DECIMAL(10,2),
		cantidad SMALLINT NOT NULL,
		subTotal DECIMAL(11,2),
		CONSTRAINT PK_DetalleVenta PRIMARY KEY(idDetalleVenta, idVenta),
		CONSTRAINT FK_DetalleVenta_Venta FOREIGN KEY(idVenta) REFERENCES Venta.Venta(idVenta),
		CONSTRAINT FK_DetalleVenta_Producto FOREIGN KEY(idProducto) REFERENCES Producto.Producto(idProducto)
	)
END;
GO
-- Table Nota de Credito
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'NotaDeCredito')
BEGIN
	CREATE TABLE Venta.NotaDeCredito
	(
		idNotaDeCredito INT IDENTITY(1,1),
		idFactura INT,
		idEmpleadoSupervisor INT,
		razon VARCHAR(50),
		fechaDeCreacion SMALLDATETIME NOT NULL,
		montoTotalDeCredito DECIMAL(10,2),
		CONSTRAINT PK_NotaDeCredito PRIMARY KEY(idNotaDeCredito),
		CONSTRAINT FK_NotaDeCredito_idFactura FOREIGN KEY(idFactura) REFERENCES Venta.Factura(idFactura),
		CONSTRAINT FK_NotaDeCredito_idEmpleadoSupervisor FOREIGN KEY(idEmpleadoSupervisor) REFERENCES Empleado.Empleado(idEmpleado),
		CONSTRAINT CK_NotaDeCredito_Monto CHECK(montoTotalDeCredito > 0)
	)
END
GO