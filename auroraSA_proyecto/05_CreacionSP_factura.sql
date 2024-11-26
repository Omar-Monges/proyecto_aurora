USE Com2900G19
GO
/*
	Solo una linea de caja :(
	Estados de una factura:
	-Pendiente(sin productos)
	-En proceso(con productos, pero aún no cerrados)
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
								@legajo INT	= NULL,
								@idSucursal INT	= NULL,
								@idVentaRecien INT OUTPUT
								)
AS BEGIN
	IF @legajo IS NULL OR NOT EXISTS(SELECT 1 FROM Empleado.Empleado WHERE legajo = @legajo)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado crearVenta. Empleado no valido',16,14);
		RETURN;
	END
	IF @idSucursal IS NULL OR NOT EXISTS(SELECT 1 FROM Sucursal.Sucursal WHERE idSucursal = @idSucursal AND sucursalActiva = 1)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado crearVenta. Sucursal no valido',16,14);
		RETURN;
	END
	DECLARE @fechaHora SMALLDATETIME = GETDATE()
	
	INSERT Venta.Venta(legajo, idSucursal, fechaHoraVenta, estadoVenta)
	SELECT @legajo, @idSucursal, @fechaHora, 'Pendiente'
	-- obtenemos el idVenta para crear la factura
	SET @idVentaRecien = SCOPE_IDENTITY()
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
		RAISERROR ('Error en el procedimiento almacenado agregarProductos. Venta no valida.',16,12);
		RETURN;
	END
	IF(@idProducto IS NULL) OR NOT EXISTS(SELECT 1 FROM Producto.Producto WHERE idProducto = @idProducto AND productoActivo = 1)
	BEGIN
		RAISERROR ('Error en el procedimiento almacenado agregarProductos. Producto no encontrada.',16,12);
		RETURN;
	END
	
	IF(@cantidad IS NULL AND @cantidad > 0)
	BEGIN
		RAISERROR ('Error en el procedimiento almacenado agregarProductos. Cantidad invalida',16,12);
		RETURN;
	END
	IF EXISTS(SELECT 1 FROM Venta.DetalleVenta WHERE idVenta = @idVenta AND idProducto = @idProducto)
	BEGIN
		RAISERROR ('Error en el procedimiento almacenado agregarProductos. Producto ya ingresado',16,12);
		RETURN;
	END
	--Verificamos el estado de la venta
	SET @estado = (SELECT estadoVenta FROM Venta.Venta WHERE idVenta = @idVenta)
	IF @estado IN ('Pagado', 'Cancelado')
	BEGIN
		RAISERROR ('Error en el procedimiento almacenado agregarProductos. La Venta ingresada ya no se puede modificar',16,12);
		RETURN;
	END
	
	SET @precioUnitario = (SELECT precioUnitario FROM Producto.Producto WHERE idProducto = @idProducto)
	SET @subTotal = @cantidad * @precioUnitario
	--Inseramos el producto a detalleVenta
	INSERT Venta.DetalleVenta(idVenta, idProducto, cantidad, precioUnitario, subTotal)
		SELECT @idVenta, @idProducto, @cantidad, @precioUnitario, @subTotal
	-- Actualizamos el estado de venta
	UPDATE Venta.Venta
		SET estadoVenta = 'En proceso'
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
	--Chequeamos el estado de la venta
	DECLARE @estado VARCHAR(10) = (SELECT estadoVenta FROM Venta.Venta WHERE idVenta = @idVenta)
	--NO MODIFICAMOS VENTAS YA CERRADAS O SEA 'Pagado' o 'cancelado'
	IF @estado IN ('Pagado', 'Cancelado')
	BEGIN
		RAISERROR ('Error en el procedimiento almacenado eliminarProducto. La venta ingresada ya no se puede modificar',16,12);
		RETURN;
	END
	-- Eliminamos el producto
	DELETE FROM Venta.DetalleVenta
		WHERE idVenta = @idVenta AND idProducto = @idProducto
	IF NOT EXISTS(SELECT 1 FROM Venta.DetalleVenta WHERE idVenta = @idVenta)
	BEGIN
		-- Despues de elminar producto no hay al menos un producto en detalle con ese id = cambio de estado
		UPDATE Venta.Venta
			SET estadoVenta = 'Pendiente'
		WHERE idVenta = @idVenta
	END
END
GO
-----------------------Para modificar cantidad mas que nada--------------------------
CREATE OR ALTER PROCEDURE Venta.modificarCantDelProducto(
				@idVenta INT = NULL, @idProducto INT = NULL, @cantidad INT = NULL)
AS BEGIN
	DECLARE @estado VARCHAR(10)
	IF(@idVenta IS NULL)
	BEGIN
		RAISERROR ('Error en el procedimiento almacenado agregarProductos. Venta no valida.',16,12);
		RETURN;
	END
	--Verificamos el estado de la venta
	SET @estado = (SELECT estadoVenta FROM Venta.Venta WHERE idVenta = @idVenta)
	IF @estado IN ('Pagado', 'Cancelado')
	BEGIN
		RAISERROR ('Error en el procedimiento almacenado agregarProductos. La venta ingresada ya no se puede modificar',16,12);
		RETURN;
	END
	IF @estado = 'Pendiente'
	BEGIN
		RAISERROR ('Error en el procedimiento almacenado agregarProductos. La venta ingresada no tiene productos',16,12);
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
	--Actualizamos el producto en detalleVenta
	UPDATE Venta.DetalleVenta
		SET cantidad = @cantidad,
			subTotal = @cantidad * precioUnitario
	WHERE idVenta = @idVenta AND idProducto = @idProducto
END
GO
--------------Cerrar Venta-----------------------------

CREATE OR ALTER PROCEDURE Venta.cerrarVenta(
								@idVenta INT				= NULL,
								@dni CHAR(8)				= NULL,
								@genero CHAR				= NULL,
								@tipoCliente CHAR(6)		= NULL,
								@medioDePago VARCHAR(12)	= NULL,
								@comprobante VARCHAR(23)	= NULL,
								@tipoFactura CHAR(1)		= NULL,
								@nuevoEstado VARCHAR(10)	= NULL
)
AS BEGIN
	DECLARE @estado VARCHAR(10),
			@idMedioDePago INT,
			@cuilCliente CHAR(13),
			@fechaVenta SMALLDATETIME,
			@total DECIMAL(11,2),
			@cuit CHAR(13),
			@idSucursal INT
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
	IF @dni IS NULL OR LEN(RTRIM(@dni)) <> 8
	BEGIN
		RAISERROR('Error en el procedimiento almacenado cerrarVenta. DNI no valido',16,14);
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
	SELECT @estado = estadoVenta, @fechaVenta = fechaHoraVenta, @idSucursal = idSucursal FROM Venta.Venta WHERE idVenta = @idVenta
	IF @estado <> 'En proceso'
	BEGIN
		RAISERROR ('Error en el procedimiento almacenado cerrarVenta. El estado de la Venta no valido.',16,12);
		RETURN;
	END
	IF @medioDePago IS NULL
	BEGIN
		RAISERROR ('Error en el procedimiento almacenado cerrarVenta. medio de pago no valido.',16,12);
		RETURN;
	END
	SELECT @idMedioDePago = idMedioDePago
	FROM Venta.MedioDePago
	WHERE nombreMedioDePago LIKE @medioDePago AND medioDePagoActivo = 1
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
	SET @cuilCliente = Empleado.calcularCUIL(@dni, @genero)
	SET @total = (SELECT SUM(subTotal) FROM Venta.DetalleVenta WHERE idVenta = @idVenta)
	SET @cuit = (SELECT cuit FROM Sucursal.Sucursal WHERE idSucursal = @idSucursal)
	-- Creacion de la factura
	IF @nuevoEstado LIKE 'Pagado'
	BEGIN
		UPDATE Venta.Venta
			SET cuilCliente = @cuilCliente,
				tipoCliente = @tipoCliente,
				estadoVenta = @nuevoEstado
		WHERE idVenta = @idVenta
		INSERT INTO Venta.Factura(
					idVenta, tipoFactura, cuit,
					fechaHora, idMedioDepago,
					identificadorDePago, estadoDeFactura,
					totalSinIva, totalConIva)
		SELECT @idVenta, @tipoFactura, @cuit,
				@fechaVenta, @idMedioDePago,
				@comprobante, 'Pagado',
				@total, @total * 1.21
	END
	ELSE
	BEGIN
		UPDATE Venta.Venta
			SET estadoVenta = @nuevoEstado
		WHERE idVenta = @idVenta
		INSERT INTO Venta.Factura(
					idVenta, fechaHora,estadoDeFactura, cuit,
					totalSinIva, totalConIva)
		SELECT @idVenta, @fechaVenta, 'Cancelado', @cuit,
				@total, @total * 1.21
	END
END
GO
--------------Cancelar Venta de forma logica
CREATE OR ALTER PROCEDURE Venta.cancelarVenta(@idVenta INT = NULL)
AS BEGIN
	DECLARE @estado VARCHAR(10),
			@total DECIMAL(11,2),
			@fechaVenta SMALLDATETIME,
			@cuit CHAR(13)
	IF(@idVenta IS NULL)
	BEGIN
		RAISERROR ('Error en el procedimiento almacenado cancelarVenta. idVenta no valido.',16,12);
		RETURN;
	END
	SELECT @estado = v.estadoVenta, @fechaVenta = v.fechaHoraVenta, @cuit = s.cuit
		FROM Venta.Venta v
		JOIN Sucursal.Sucursal s ON s.idSucursal = v.idSucursal WHERE idVenta = @idVenta
	IF @estado IS NULL
	BEGIN
		RAISERROR ('Error en el procedimiento almacenado cancelarVenta. La venta no encontrada.',16,12);
		RETURN;
	END
	IF @estado IN ('Pagado', 'Cancelado')
	BEGIN
		RAISERROR ('Error en el procedimiento almacenado cancelarVenta. La venta no puede ser modificada.',16,12);
		RETURN;
	END
	SET @total = (SELECT SUM(subTotal) FROM Venta.DetalleVenta WHERE idVenta = @idVenta)
	-- cancelar solo si esta pendiente o en proceso
	-- Cancelamos la Factura
	UPDATE Venta.Venta
		SET estadoVenta = 'Cancelado'
	WHERE idVenta = @idVenta
	INSERT INTO Venta.Factura(
					idVenta, fechaHora,estadoDeFactura,
					totalSinIva, totalConIva, cuit)
		SELECT @idVenta, @fechaVenta, 'Cancelado',
				@total, @total * 1.21, @cuit
END
GO

--------------Crear nota de Credito SOLO SUPERVISORES----------------------

CREATE OR ALTER PROCEDURE Venta.crearNotaDeCredito(
			@idFactura INT		= NULL,
			@idSupervisor INT	= NULL,
			@laRazon VARCHAR(50)= NULL,
			@idNDC INT OUTPUT)
AS BEGIN
	/*
		1. idVenta exista y estado sea pagado x
		1.1 Chequeamos que esa factura no tenga ya un NDC x
		2. Chequeamos el monto de credito no supere el total de la factua pagada x
		3. Agregamos quien dio el credito x
		4. generamos la nota de credito x
	*/
	DECLARE @estado VARCHAR(10)
	IF(@idFactura IS NULL)
	BEGIN
		RAISERROR ('Error en el procedimiento almacenado crearNotaDeCredito. Factura no encontrada.',16,12);
		RETURN;
	END
	-- Solo dar nota de credito a facturas pagadas y el monto no supere el total pagado
	SELECT @estado = estadoDeFactura FROM Venta.Factura WHERE idFactura = @idFactura
	IF @estado IS NULL 
	BEGIN
		RAISERROR ('Error en el procedimiento almacenado crearNotaDeCredito. La factura no existe.',16,12);
		RETURN;
	END
	IF @estado <> 'Pagado'
	BEGIN
		RAISERROR ('Error en el procedimiento almacenado crearNotaDeCredito. No se puede emitir nota de credito a Factura no pagada.',16,12);
		RETURN;
	END
	-- Chequeamos que no hay nota de credito para esa factura
	IF (SELECT COUNT(idNotaDeCredito) FROM Venta.NotaDeCredito WHERE idFactura = @idFactura) > 0
	BEGIN
		RAISERROR ('Error en el procedimiento almacenado crearNotaDeCredito. La factura ya tiene una NOTA DE CREDITO.',16,12);
		RETURN;
	END
	IF @idSupervisor IS NULL OR NOT EXISTS(SELECT 1 FROM Empleado.Empleado WHERE legajo = @idSupervisor AND empleadoActivo = 1)
	BEGIN
		RAISERROR ('Error en el procedimiento almacenado crearNotaDeCredito. Supervisor no Valido.',16,12);
		RETURN;
	END
	
	IF @laRazon IS NULL OR LEN(RTRIM(@laRazon)) < 5
	BEGIN
		RAISERROR ('Error en el procedimiento almacenado crearNotaDeCredito. La razon es invalida.',16,12);
		RETURN;
	END
	/*
	-- Creamos una tabla temporal para la nota de credito
	CREATE TABLE #tmpNDC(
		idFactura INT,
		legajoSupervisor INT,
		laRazon VARCHAR(50)
		)
	CREATE TABLE #detalleNDC(
		idProductoNDC INT,
		cantidadNDC INT,
		precioUnitarioNDC DECIMAL(11,2),
		subTotalNDC DECIMAL(11,2)
	)
	INSERT INTO #tmpNDC(legajoSupervisor, idFactura, laRazon)
		SELECT @idSupervisor, @idFactura, @laRazon
	*/
	INSERT INTO Venta.NotaDeCredito(idFactura, fechaDeCreacion, legajoSupervisor, razon, activo)
	SELECT @idFactura, GETDATE(), @idSupervisor, @laRazon, 'p'
	SET @idNDC = SCOPE_IDENTITY()
END
GO
CREATE OR ALTER PROCEDURE Venta.agregarProductoNDC(
			@idNotaDeCredito INT	= NULL,
			@idProducto INT			= NULL,
			@cantidad INT			= NULL)
AS BEGIN
	DECLARE @cantDetalleVenta INT,
			@cantidadNDCacumulada INT,
			@precioUnitarioProducto DECIMAL(11,2),
			@idFactura INT
	IF @idProducto IS NULL OR @cantidad IS NULL
	BEGIN
		RAISERROR ('Error en el procedimiento almacenado agregarProductoNDC. Parametro/s no valido/s.',16,12);
		RETURN;
	END
	IF	@cantidad < 1
	BEGIN
		RAISERROR ('Error en el procedimiento almacenado agregarProductoNDC. Cantidad en menor a cero.',16,12);
		RETURN;
	END
	SET @idFactura = (SELECT idFactura FROM Venta.NotaDeCredito WHERE idNotaDeCredito = @idNotaDeCredito AND activo = 'p')
	SET @cantidadNDCacumulada = (SELECT cantidad FROM Venta.DetalleNotaDeCredito WHERE idProducto = @idProducto)
	IF @cantidadNDCacumulada IS NULL
		SET @cantidadNDCacumulada = @cantidad
	ELSE
		SET @cantidadNDCacumulada = @cantidadNDCacumulada + @cantidad
	SELECT @cantDetalleVenta = dv.cantidad, @precioUnitarioProducto = dv.precioUnitario
		FROM Venta.DetalleVenta dv
		JOIN Venta.Venta v ON v.idVenta = dv.idVenta
		JOIN Venta.Factura f ON f.idVenta = v.idVenta
	WHERE f.idFactura = @idFactura AND dv.idProducto = @idProducto
	IF @cantDetalleVenta IS NULL OR @precioUnitarioProducto IS NULL
	BEGIN
		RAISERROR ('Error en el procedimiento almacenado agregarProductoNDC. Producto no esta en la Factura.',16,12);
		RETURN;
	END
	IF @cantDetalleVenta <= @cantidadNDCacumulada
	BEGIN
		RAISERROR ('Error en el procedimiento almacenado agregarProductoNDC. La cantidad excede a lo Factura.',16,12);
		RETURN;
	END
	--INSERT INTO #detalleNDC(idProductoNDC, cantidadNDC, precioUnitarioNDC, subTotalNDC)
	--SELECT @idProducto, @cantidadNDCacumulada, @precioUnitarioProducto, @cantidadNDCacumulada * @precioUnitarioProducto
	IF EXISTS(SELECT 1 FROM Venta.DetalleNotaDeCredito WHERE idProducto = @idProducto AND idNotaDeCredito = @idNotaDeCredito)
	BEGIN
		UPDATE Venta.DetalleNotaDeCredito 
			SET cantidad = @cantidadNDCacumulada,
				subtotal = @precioUnitarioProducto * @cantidadNDCacumulada
		WHERE idProducto = @idProducto AND idNotaDeCredito = @idNotaDeCredito
	END
	ELSE
	BEGIN
		INSERT INTO Venta.DetalleNotaDeCredito(idNotaDeCredito, idProducto, cantidad, subtotal)
		SELECT @idNotaDeCredito, @idProducto, @cantidadNDCacumulada, @cantidadNDCacumulada * @precioUnitarioProducto
	END
END
GO
CREATE OR ALTER PROCEDURE Venta.cerrarNotaDeCredito(@idNotaDeCredito INT = NULL)
AS BEGIN
	--IF NOT EXISTS(SELECT 1 FROM tempdb.sys.tables WHERE name LIKE '#tmpNDC%' OR name LIKE '#detalleNDC%')
	--BEGIN
	--	RAISERROR ('Error en el procedimiento almacenado cerrarNotaDeCredito. No se creo la nota de credito.',16,12);
	--	RETURN;
	--END
	IF @idNotaDeCredito IS NULL
	BEGIN
		RAISERROR ('Error en el procedimiento almacenado cerrarNotaDeCredito. ID nota de credito invalido.',16,12);
		RETURN;
	END
	IF NOT EXISTS(SELECT 2 FROM Venta.NotaDeCredito WHERE idNotaDeCredito = @idNotaDeCredito AND activo = 'p')
	BEGIN
		RAISERROR ('Error en el procedimiento almacenado cerrarNotaDeCredito. Nota de credito ya emitida.',16,12);
		RETURN;
	END
	DECLARE @totalNotaDeCredito DECIMAL(11,2), @iva DECIMAL(3,2)
	SET @iva = (SELECT V.iva FROM Venta.Factura V JOIN Venta.NotaDeCredito T ON T.idFactura = V.idFactura)
	SET @totalNotaDeCredito = (SELECT SUM(subtotal) FROM Venta.DetalleNotaDeCredito WHERE idNotaDeCredito = @idNotaDeCredito) * @iva
	UPDATE Venta.NotaDeCredito
		SET montoTotalDeCredito = @totalNotaDeCredito,
			activo = 'a'
	WHERE idNotaDeCredito = @idNotaDeCredito

	--- enfoque con tabla temporal fallido
	--INSERT INTO Venta.NotaDeCredito(idFactura, idEmpleadoSupervisor, fechaDeCreacion, montoTotalDeCredito, razon)
	--SELECT idFactura, legajoSupervisor, GETDATE(), @totalNotaDeCredito, laRazon
	--	FROM #tmpNDC
	--SET @idNDC = SCOPE_IDENTITY()
	--INSERT INTO Venta.DetalleNotaDeCredito(idNotaDeCredito, idProducto, cantidad, subtotal)
	--SELECT @idNDC, idProductoNDC, cantidadNDC, subTotalNDC
	--	FROM #detalleNDC
	---- LIBERAMOS LAS TABLAS TEMPORALES
	--DROP TABLE #tmpNDC
	--DROP TABLE #detalleNDC
END
GO

-- idFatura, idSucursal, tipoFactura, legajo, fechahora, nombreProducto, cantProd, precioU, subTotal, precio, precioIVA
CREATE OR ALTER VIEW Venta.verFacturasDetalladas AS
	SELECT	f.idFactura,
			v.idSucursal,
			f.cuit,
			f.tipoFactura,
			v.legajo,
			f.fechaHora,
			p.descripcionProducto,
			dv.cantidad,
			dv.precioUnitario,
			dv.subTotal,
			f.totalSinIva,
			f.totalConIva
		FROM Venta.Factura f 
			JOIN Venta.DetalleVenta dv ON f.idVenta = dv.idVenta
			JOIN Producto.Producto p ON p.idProducto = dv.idProducto
			JOIN Venta.Venta v ON v.idVenta = f.idVenta


---------cancelar facturas pendientes o en proceso SOLO SUPERVISORE-------------
-- En este enfoque donde no se crean facturas hasta cerrar ventas no necesitamos cancelar la ventas pendientes\en proceso
