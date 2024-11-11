
IF EXISTS (SELECT * FROM sys.databases WHERE name = 'Com2900G19')
	USE Com2900G19
ELSE
	RAISERROR('Este script está diseñado para que se ejecute despues del script de la creacion de tablas y esquemas.',20,1);
GO
/*
	
--Esquema Factura
	Tabla Factura
		agregarFactura
		modificarFactura				falta hacer
		eliminarFactura					falta hacer
										falta hacer
		pasajeDolarAPesos -->sera?		falta hacer
										falta hacer
	Tabla DetalleFactura				falta hacer
		agregarProducto					falta hacer
		modificarProducto				falta hacer
		eliminarProducto				falta hacer
*/
------------------------------------------------Factura------------------------------------------------
--		DROP PROCEDURE Factura.agregarFactura
CREATE OR ALTER PROCEDURE Factura.crearFactura(@tipoFactura CHAR	= NULL, @tipoCliente VARCHAR(10)= NULL,
												@genero CHAR(1)		= NULL,@fechaHora SMALLDATETIME	= NULL,
												@idMedioDePago INT	= NULL, @legajo INT				= NULL,
												@idSucursal INT		= NULL, @medioDePago VARCHAR(12)= NULL)
AS BEGIN
	DECLARE @idtipoCliente INT
	--DECLARE @comprobanteDePago VARCHAR(23)
	IF(@tipoFactura IS NULL AND @tipoFactura NOT IN ('A', 'B','C'))
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarFactura. Tipo de factura no valido',16,14);
		RETURN;
	END
	IF(@tipoCliente IS NULL OR @genero IS NULL)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarFactura. TipoCliente o genero no valido',16,14);
		RETURN;
	END
	IF(@legajo IS NULL) OR NOT EXISTS(SELECT 1 FROM Empleado.Empleado WHERE legajo = @legajo)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarFactura. Empleado no valido',16,14);
		RETURN;
	END
	IF(@idSucursal IS NULL) OR NOT EXISTS(SELECT 1 FROM Sucursal.Sucursal WHERE idSucursal = @idSucursal)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarFactura. Sucursal no valido',16,14);
		RETURN;
	END
	IF(@medioDePago IS NULL)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarFactura. Medio de pago no valido',16,14);
		RETURN;
	END
	SET @fechaHora = GETDATE()
	SET @idtipoCliente = (SELECT idTipoCliente FROM Factura.TipoCliente WHERE tipoCliente = @tipoCliente AND genero = @genero)
	SET @idMedioDePago = (SELECT idMedioDePago FROM Factura.MedioDePago WHERE nombreMedioDePago = @medioDePago)
	IF (@idtipoCliente IS NULL)
	BEGIN
		-- creamos un nuevo tipo de cliente
		INSERT INTO Factura.TipoCliente (tipoCliente, genero)
			VALUES (@tipoCliente, @genero)
		SET @idtipoCliente = (SELECT idTipoCliente FROM Factura.TipoCliente WHERE tipoCliente = @tipoCliente AND genero = @genero)
	END
	IF (@idMedioDePago IS NULL)
	BEGIN
		-- creamos un nuevo medio de pago
		INSERT INTO Factura.MedioDePago(nombreMedioDePago)
			VALUES (@medioDePago)
		SET @idMedioDePago = (SELECT idMedioDePago FROM Factura.MedioDePago WHERE nombreMedioDePago = @medioDePago)
	END
	-- Creamos la factura
	INSERT INTO Factura.Factura (tipoFactura, idTipoCliente, idSucursal, idMedioDepago, fechaHora, legajo, identificadorDePago)
		VALUES (@tipoFactura, @idtipoCliente, @idSucursal, @idMedioDePago, @fechaHora, @legajo, '--')

END

GO
/*
		OPCION A
		1. Creamos la tabla en memoria para productos
		1.2 Si llama al proced
		2. llamamos al procedimiento para agregar productos a la tabla
		3. Cerramos la factura volcando la data en la base

		OPCION B
		1. crearFactura -> datos para la factura 
		2. agregarProducto -> pasamos el idFactura -> funcion obtener la ultima idFactura // muchos productos
		3. sacarProducto 
		4. modificarProducto
		5. eliminarFactura -> Si se cancela la compra
	*/

/*
CREATE OR ALTER FUNCTION Factura.obtenerUltimoId()
RETURNS INT
BEGIN
	DECLARE @id INT;
	SET @id = (SELECT MAX(idFactura) from Factura.Factura);
	IF(@id IS NULL)
		RETURN NULL
	RETURN @id;
END
*/
CREATE OR ALTER PROCEDURE Factura.agregarProducto(@idProducto INT = NULL, @cantidad INT = NULL)
AS BEGIN
	DECLARE @idFactura INT;
	DECLARE @precioUnitario DECIMAL(10,2);
	SET @idFactura = (SELECT MAX(idFactura) from Factura.Factura) -- Solo para probar
	IF(@idFactura IS NULL)
	BEGIN
		RAISERROR ('Error en el procedimiento almacenado agregarProducots. Factura no encontrada.',16,12);
		RETURN;
	END
	IF(@idProducto IS NULL) OR NOT EXISTS(SELECT 1 FROM Producto.Producto WHERE idProducto = @idProducto)
	BEGIN
		RAISERROR ('Error en el procedimiento almacenado agregarProducots. Producto no encontrada.',16,12);
		RETURN;
	END
	
	IF(@cantidad IS NULL AND @cantidad > 0)
	BEGIN
		RAISERROR ('Error en el procedimiento almacenado agregarProducots. Cantidad invalida',16,12);
		RETURN;
	END
	IF EXISTS(SELECT 1 FROM Factura.DetalleFactura WHERE idProducto = @idProducto)
	BEGIN
		RAISERROR ('Error en el procedimiento almacenado agregarProducots. Producto ya ingresado',16,12);
		RETURN;
	END
	SET @precioUnitario = (SELECT precioUnitario FROM Producto.Producto WHERE idProducto = @idProducto)
	INSERT INTO Factura.DetalleFactura(idFactura, idProducto, precioUnitario, cantidad)
		VALUES (@idFactura, @idProducto, @precioUnitario, @cantidad)
	
END
GO
-----------------------Para modificar cantidad mas que nada--------------------------
CREATE OR ALTER PROCEDURE Factura.modificarProducto(@idProducto INT = NULL, @cantidad INT = NULL)
AS BEGIN
	DECLARE @idFactura INT;
	SET @idFactura = (SELECT MAX(idFactura) from Factura.Factura) -- Solo para probar
	IF(@idFactura IS NULL)
	BEGIN
		RAISERROR ('Error en el procedimiento almacenado agregarProducots. Factura no encontrada.',16,12);
		RETURN;
	END
	IF(@idProducto IS NULL) OR NOT EXISTS(SELECT 1 FROM Factura.DetalleFactura WHERE idProducto = @idProducto)
	BEGIN
		RAISERROR ('Error en el procedimiento almacenado agregarProducots. Producto no encontrada en la factura.',16,12);
		RETURN;
	END
	
	IF(@cantidad IS NULL AND @cantidad > 0)
	BEGIN
		RAISERROR ('Error en el procedimiento almacenado agregarProducots. Cantidad invalida',16,12);
		RETURN;
	END
	UPDATE Factura.DetalleFactura
		SET cantidad = @cantidad
	WHERE idFactura = @idFactura AND idProducto = @idProducto
END
GO
-----------------------Para eliminar un producto--------------------------
CREATE OR ALTER PROCEDURE Factura.eliminarProducto(@idProducto INT = NULL)
AS BEGIN
	DECLARE @idFactura INT;
	SET @idFactura = (SELECT MAX(idFactura) from Factura.Factura) -- Solo para probar
	IF(@idFactura IS NULL)
	BEGIN
		RAISERROR ('Error en el procedimiento almacenado agregarProducots. Factura no encontrada.',16,12);
		RETURN;
	END
	IF(@idProducto IS NULL) OR NOT EXISTS(SELECT 1 FROM Factura.DetalleFactura WHERE idProducto = @idProducto)
	BEGIN
		RAISERROR ('Error en el procedimiento almacenado agregarProducots. Producto no encontrada.',16,12);
		RETURN;
	END
	-- Eliminamos el producto
	DELETE FROM Factura.DetalleFactura
		WHERE idProducto = @idProducto
END

--------------Eliminar factura de forma logica o no?