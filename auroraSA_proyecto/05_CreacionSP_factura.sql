
IF EXISTS (SELECT * FROM sys.databases WHERE name = 'Com2900G19')
	USE Com2900G19
ELSE
	RAISERROR('Este script est� dise�ado para que se ejecute despues del script de la creacion de tablas y esquemas.',20,1);
GO
/*
	Solo una linea de caja :(
	Estados de una factura:
	-Pendiente(sin productos)
	-En proceso(con productos, pero a�n no cerrados)
	-Pagado(Con el metodo y comprobante)
	-Cancelado (hay que ver)
		Planteo:
		1.Creamos la Venta con la de facturacion con estado: pendiente(sin productos)
		2.Cargamos los productos en detalle de venta cambiamos el estado: En proceso(con producto)
		3.Cerramos la venta calculando y actualizando la factura con los total de iva etc

		OPCION A
		1. Creamos la tabla en memoria/temporal para productos
		1.2 Si llama al proced
		2. llamamos al procedimiento para agregar productos a la tabla
		3. Cerramos la factura volcando la data en la base

		OPCION B
		1. crearFactura -> datos para la factura 
		2. agregarProducto -> pasamos el idFactura -> obtener la ultima idFactura // muchos productos
		3. sacarProducto 
		4. modificarProducto
		5. eliminarFactura -> Si se cancela la compra
*/
	
--Esquema Venta
CREATE OR ALTER PROCEDURE Venta.crearVenta(
								@idEmpleado INT	= NULL, @idSucursal INT	= NULL,
								@dni CHAR(8)	= NULL,@genero CHAR		= NULL,
								@tipoCliente CHAR(6) = NULL, @idVentaRecien INT OUTPUT
								)
AS BEGIN
	IF @idEmpleado IS NULL OR NOT EXISTS(SELECT 1 FROM Empleado.Empleado WHERE idEmpleado = @idEmpleado)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado crearVenta. Empleado no valido',16,14);
		RETURN;
	END
	IF @idSucursal IS NULL OR NOT EXISTS(SELECT 1 FROM Sucursal.Sucursal WHERE idSucursal = @idSucursal)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado crearVenta. Sucursal no valido',16,14);
		RETURN;
	END
	IF @dni IS NULL OR LEN(RTRIM(@dni)) <> 8
	BEGIN
		RAISERROR('Error en el procedimiento almacenado crearVenta. DNI no valido',16,14);
		RETURN;
	END
	IF @genero IS NULL OR UPPER(@genero) NOT IN ('M','F')
	BEGIN
		RAISERROR('Error en el procedimiento almacenado crearVenta. Genero no valido para calcular el cuil',16,14);
		RETURN;
	END
	IF @tipoCliente IS NULL OR LEN(RTRIM(@tipoCliente)) <> 6
	BEGIN
		RAISERROR('Error en el procedimiento almacenado crearVenta. tipoCliente no valido',16,14);
		RETURN;
	END
	DECLARE @cuilCliente CHAR(13),
		@fechaHora SMALLDATETIME = GETDATE()

	SET @cuilCliente = Empleado.calcularCUIL(@dni, @genero)

	INSERT Venta.Venta(cuilCliente, idEmpleado, idSucursal, fechaHoraVenta, tipoCliente)
	SELECT @cuilCliente, @idEmpleado, @idSucursal, @fechaHora, @tipoCliente
	-- obtenemos el idVenta para crear la factura
	SET @idVentaRecien = SCOPE_IDENTITY()
	-- creamos la factura
	--EXEC Venta.crearFactura @idVentaRecien, @fechaHora, 'Pendiente'
	
	INSERT INTO Venta.Factura(idVenta, fechaHora,estadoDeFactura, totalConIva, totalSinIva, cuit)
	SELECT @idVentaRecien,@fechaHora,'Pendiente', 0, 0, cuit
	FROM Sucursal.Sucursal WHERE idSucursal = @idSucursal
END
GO
CREATE OR ALTER PROCEDURE Venta.agregarProducto(
					@idVenta INT = NULL, @idProducto INT = NULL, @cantidad INT = NULL
								)
AS BEGIN
	DECLARE @precioUnitario DECIMAL(10,2),
		@subTotal DECIMAL(10,2) = 0,
		@estado VARCHAR(10)
	IF(@idVenta IS NULL)
	BEGIN
		RAISERROR ('Error en el procedimiento almacenado agregarProductos. Factura no valida.',16,12);
		RETURN;
	END
	IF(@idProducto IS NULL) OR NOT EXISTS(SELECT 1 FROM Producto.Producto WHERE idProducto = @idProducto)
	BEGIN
		RAISERROR ('Error en el procedimiento almacenado agregarProductos. Producto no encontrada.',16,12);
		RETURN;
	END
	
	IF(@cantidad IS NULL AND @cantidad > 0)
	BEGIN
		RAISERROR ('Error en el procedimiento almacenado agregarProductos. Cantidad invalida',16,12);
		RETURN;
	END
	IF EXISTS(SELECT 1 FROM Venta.DetalleVenta WHERE idProducto = @idProducto)
	BEGIN
		RAISERROR ('Error en el procedimiento almacenado agregarProductos. Producto ya ingresado',16,12);
		RETURN;
	END
	--Verificamos el estado de la factura-venta
	SET @estado = (SELECT estadoDeFactura FROM Venta.Factura WHERE idVenta = @idVenta)
	IF @estado IN ('Pagado', 'Cancelado')
	BEGIN
		RAISERROR ('Error en el procedimiento almacenado agregarProductos. La Factura ingresada ya no se puede modificar',16,12);
		RETURN;
	END
	
	SET @precioUnitario = (SELECT precioUnitario FROM Producto.Producto WHERE idProducto = @idProducto)
	SET @subTotal = @cantidad * @precioUnitario
	--Inseramos el producto a detalleVenta
	INSERT Venta.DetalleVenta(idVenta, idProducto, cantidad, precioUnitario, subTotal)
		SELECT @idVenta, @idProducto, @cantidad, @precioUnitario, @subTotal
	--Actualizamos los totales
	UPDATE Venta.Factura
		SET totalSinIva = totalSinIva + @subTotal,
			--totalConIva = totalConIva + @subTotal * iva, -- Lo hacemos al cerrar la venta
			estadoDeFactura = REPLACE(estadoDeFactura, 'Pendiente', 'En proceso')
	WHERE idVenta = @idVenta
END
GO
-----------------------Para eliminar un producto--------------------------
CREATE OR ALTER PROCEDURE Venta.eliminarProducto(@idVenta INT = NULL, @idProducto INT = NULL)
AS BEGIN
	IF(@idVenta IS NULL)
	BEGIN
		RAISERROR ('Error en el procedimiento almacenado eliminarProducto. Factura no encontrada.',16,12);
		RETURN;
	END
	IF(@idProducto IS NULL) OR NOT EXISTS(SELECT 1 FROM Venta.DetalleVenta WHERE idVenta = @idVenta AND idProducto = @idProducto)
	BEGIN
		RAISERROR ('Error en el procedimiento almacenado eliminarProducto. Producto no encontrada.',16,12);
		RETURN;
	END
	--Chequeamos el estado de la factura-venta
	DECLARE @estado VARCHAR(10) = (SELECT estadoDeFactura FROM Venta.Factura WHERE idVenta = @idVenta)
	--NO MODIFICAMOS FACTURAS YA CERRADAS O SEA 'Pagado' o 'cancelado'
	IF @estado IN ('Pagado', 'Cancelado')
	BEGIN
		RAISERROR ('Error en el procedimiento almacenado eliminarProducto. La Factura ingresada ya no se puede modificar',16,12);
		RETURN;
	END
	DECLARE @subTotalAnt DECIMAL(11,2)
	-- Recuperamos la cantidad y el precio unitario para actualizar el total sin iva
	SELECT @subTotalAnt = subTotal
		FROM Venta.DetalleVenta WHERE idVenta = @idVenta AND idProducto = @idProducto
	-- Eliminamos el producto
	DELETE FROM Venta.DetalleVenta
		WHERE idVenta = @idVenta AND idProducto = @idProducto

	--SI eliminamos detalle de un solo producto
	--(ingresamos un producto y luego lo sacamos quedaria sin productos la venta)
	--lo ponemos en Pendiente

	IF EXISTS(SELECT 1 FROM Venta.DetalleVenta WHERE idVenta = @idVenta)
	-- Actualizamos el total
	BEGIN
		UPDATE Venta.Factura
			SET totalSinIva = totalSinIva - @subTotalAnt
		WHERE idVenta = @idVenta
	END
	ELSE
	BEGIN
		UPDATE Venta.Factura
			SET totalSinIva = totalSinIva - @subTotalAnt,
				estadoDeFactura = 'Pendiente'
		WHERE idVenta = @idVenta
	END
END
GO
-----------------------Para modificar cantidad mas que nada--------------------------
CREATE OR ALTER PROCEDURE Venta.modificarCantDelProducto(
				@idVenta INT = NULL, @idProducto INT = NULL, @cantidad INT = NULL)
AS BEGIN
	DECLARE @precioUnitario DECIMAL(11,2),
		@subTotalAnt DECIMAL(11,2),
		@estado VARCHAR(10)
	IF(@idVenta IS NULL)
	BEGIN
		RAISERROR ('Error en el procedimiento almacenado agregarProductos. Factura no valida.',16,12);
		RETURN;
	END
	--Verificamos el estado de la factura-venta
	SET @estado = (SELECT estadoDeFactura FROM Venta.Factura WHERE idVenta = @idVenta)
	IF @estado IN ('Pagado', 'Cancelado')
	BEGIN
		RAISERROR ('Error en el procedimiento almacenado agregarProductos. La Factura ingresada ya no se puede modificar',16,12);
		RETURN;
	END
	IF @estado = 'Pendiente'
	BEGIN
		RAISERROR ('Error en el procedimiento almacenado agregarProductos. La Factura ingresada no tiene productos',16,12);
		RETURN;
	END
	IF(@idProducto IS NULL)
	BEGIN
		RAISERROR ('Error en el procedimiento almacenado agregarProductos. idProducto no valido.',16,12);
		RETURN;
	END
	IF(@cantidad IS NULL AND @cantidad > 0)
	BEGIN
		RAISERROR ('Error en el procedimiento almacenado agregarProductos. Cantidad invalida llama a Eliminar producto',16,12);
		RETURN;
	END
	IF NOT EXISTS(SELECT 1 FROM Venta.DetalleVenta WHERE idVenta = @idVenta AND idProducto = @idProducto)
	BEGIN
		RAISERROR ('Error en el procedimiento almacenado agregarProductos. Producto no esta en detalle Venta',16,12);
		RETURN;
	END
	SELECT @precioUnitario = precioUnitario, @subTotalAnt = subTotal
	FROM Venta.DetalleVenta 
	WHERE idVenta = @idVenta AND idProducto = @idProducto
	--Actualizamos el producto en detalleVenta
	UPDATE Venta.DetalleVenta
		SET cantidad = @cantidad,
			precioUnitario = @precioUnitario,
			subTotal = @cantidad * @precioUnitario
	WHERE idVenta = @idVenta AND idProducto = @idProducto
	--Actualizamos los totales
	UPDATE Venta.Factura
		SET totalSinIva = (totalSinIva - @subTotalAnt) + (@cantidad * @precioUnitario)
	WHERE idVenta = @idVenta
END
GO

--------------Cerrar Venta-----------------------------

CREATE OR ALTER PROCEDURE Venta.cerrarVenta(
		@idVenta INT = NULL, @medioDePago VARCHAR(12) = NULL,
		@comprobante VARCHAR(23) = NULL, @tipoFactura CHAR(1) = NULL,
		@nuevoEstado VARCHAR(10) = NULL, @idNotaDeCredito INT = NULL
)
AS BEGIN
	DECLARE @estado VARCHAR(10), @idMedioDePago INT
	IF @idVenta IS NULL
	BEGIN
		RAISERROR ('Error en el procedimiento almacenado cerrarVenta. idVenta no valido.',16,12);
		RETURN;
	END
	IF @nuevoEstado IS NULL OR LEN(RTRIM(@nuevoEstado)) = 0
	BEGIN
		RAISERROR ('Error en el procedimiento almacenado cerrarVenta. El nuevo estado no es valido.',16,12);
		RETURN;
	END
	IF @tipoFactura IS NULL OR NOT @tipoFactura IN ('A','B','C')
	BEGIN
		RAISERROR ('Error en el procedimiento almacenado cerrarVenta. Tipo de factura no valido.',16,12);
		RETURN;
	END

	SET @estado = (SELECT estadoDeFactura FROM Venta.Factura WHERE idVenta = @idVenta)
	IF @estado <> 'En proceso'
	BEGIN
		RAISERROR ('Error en el procedimiento almacenado cerrarVenta. El estado de la factura no valido.',16,12);
		RETURN;
	END
	IF @medioDePago IS NULL
	BEGIN
		RAISERROR ('Error en el procedimiento almacenado cerrarVenta. medio de pago no valido.',16,12);
		RETURN;
	END
	SELECT @idMedioDePago = idMedioDePago
	FROM Venta.MedioDePago
	WHERE nombreMedioDePago LIKE @medioDePago
	IF @idMedioDePago IS NULL
	BEGIN
		RAISERROR ('Error en el procedimiento almacenado cerrarVenta. medio de pago no disponible.',16,12);
		RETURN;
	END
	IF LEN(RTRIM(@comprobante)) = 0
	BEGIN
		RAISERROR ('Error en el procedimiento almacenado cerrarVenta. Comprobante de pago no valido.',16,12);
		RETURN;
	END
	IF @nuevoEstado LIKE 'Pagado'
	BEGIN
		UPDATE Venta.Factura
			SET tipoFactura = @tipoFactura,
				idMedioDepago = @idMedioDePago,
				identificadorDePago = @comprobante,
				estadoDeFactura = @nuevoEstado,
				totalConIva = totalSinIva * iva
		WHERE idVenta = @idVenta
	END
	ELSE
	BEGIN
		UPDATE Venta.Factura
			SET tipoFactura = @tipoFactura,
				idMedioDepago = @idMedioDePago,
				identificadorDePago = @comprobante,
				estadoDeFactura = 'Cancelado',
				totalConIva = totalSinIva * iva
		WHERE idVenta = @idVenta
	END
END
GO
--------------Eliminar factura de forma logica

CREATE OR ALTER PROCEDURE Venta.cancelarFactura(@idVenta INT = NULL)
AS BEGIN
	DECLARE @estado VARCHAR(10)
	IF(@idVenta IS NULL)
	BEGIN
		RAISERROR ('Error en el procedimiento almacenado cancelarFactura. idVenta no valido.',16,12);
		RETURN;
	END
	SET @estado = (SELECT estadoDeFactura FROM Venta.Factura WHERE idVenta = @idVenta)
	IF @estado IS NULL
	BEGIN
		RAISERROR ('Error en el procedimiento almacenado cancelarFactura. La factura no encontrada.',16,12);
		RETURN;
	END
	IF @estado IN ('Pagado', 'Cancelado')
	BEGIN
		RAISERROR ('Error en el procedimiento almacenado cancelarFactura. La factura no puede ser modificada.',16,12);
		RETURN;
	END
	-- cancelar solo si esta pendiente o en proceso
	-- Cancelamos la Factura
	UPDATE Venta.Factura
		SET estadoDeFactura = 'Cancelado'
	WHERE idVenta = @idVenta
END
GO

--------------Crear nota de Credito SOLO SUPERVISORES----------------------

CREATE OR ALTER PROCEDURE Venta.crearNotaDeCredito(
			@idVenta INT = NULL, @idSupervisor INT = NULL,
			@montoDeCredito DECIMAL(11,2) = NULL, @laRazon VARCHAR(50) = NULL)
AS BEGIN
	/*
		1. idVenta exista y estado sea pagado
		2. Chequeamos el monto de credito no supere el total de la factua pagada
		3. Agregamos quien dio el credito
		4. generamos la nota de credito
	*/
	DECLARE @estado VARCHAR(10), @montoFactura DECIMAL(11,2)
	IF(@idVenta IS NULL)
	BEGIN
		RAISERROR ('Error en el procedimiento almacenado crearNotaDeCredito. Factura no encontrada.',16,12);
		RETURN;
	END
	IF @idSupervisor IS NULL OR EXISTS(SELECT 1 FROM Empleado.Empleado WHERE idEmpleado = @idSupervisor AND empleadoActivo = 1)
	BEGIN
		RAISERROR ('Error en el procedimiento almacenado crearNotaDeCredito. Supervisor no Valido.',16,12);
		RETURN;
	END
	-- Solo dar nota de credito a facturas pagadas y el monto no supere el total pagado
	SELECT @estado = estadoDeFactura, @montoFactura = totalConIva FROM Venta.Factura WHERE idVenta = @idVenta
	IF @estado <> 'Pagado'
	BEGIN
		RAISERROR ('Error en el procedimiento almacenado crearNotaDeCredito. No se puede emitir nota de credito a Factura no pagada.',16,12);
		RETURN;
	END
	IF @montoDeCredito > @montoFactura
	BEGIN
		RAISERROR ('Error en el procedimiento almacenado crearNotaDeCredito. No se puede emitir el monto de credito, supera a la monto de la Factura pagada.',16,12);
		RETURN;
	END
	-- Creamos la nota de credito
	-- Siempre se mantiene igual?
	-- Cuando se usa? este credito?
END
GO
---------cancelar facturas pendientes o en proceso SOLO SUPERVISORE-------------