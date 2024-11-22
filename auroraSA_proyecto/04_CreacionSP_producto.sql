USE Com2900G19
GO
--		USE master
--		DROP DATABASE G2900G19
/*
	
--Esquema Producto
	Tabla Producto
		agregarProducto
		modificarProducto
		eliminarProducto

		pasajeDolarAPesos

		verProductos ->muestra a los productos con sus categorias
	Tabla clasificacion
		agregarClasificacion
		modificarClasificacion
		eliminarClasificacion
*/

------------------------------------------------Producto------------------------------------------------
--Tabla Producto
--Procedimiento almacenado que permite agregar un producto
--DROP PROCEDURE Sucursal.
CREATE OR ALTER PROCEDURE Producto.agregarProducto (
							@clasificacion VARCHAR(35)		= NULL,@descripcionProducto VARCHAR(100)= NULL,
							@precioUnitario DECIMAL(10,2)	= NULL,@precioReferencia DECIMAL(10,2)	= NULL,
							@unidadReferencia VARCHAR(10)	= NULL
													)
AS BEGIN
	DECLARE @altaProducto BIT = 1,
		@idProducto INT,
		@idClasificacion INT

	IF (@descripcionProducto IS NULL OR LEN(LTRIM(@descripcionProducto)) = 0)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarProducto. La descripci�n del producto es incorrecta',16,5);
		RETURN;
	END
	IF (@clasificacion IS NULL OR LEN(LTRIM(@clasificacion)) = 0)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarProducto. La clasificacion del producto es incorrecta',16,5);
		RETURN;
	END

	IF(@unidadReferencia IS NULL OR LEN(LTRIM(@unidadReferencia)) = 0)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarProducto. El precio o unidad de referencia son incorrectos.',16,5);
		RETURN;
	END
	IF(@precioReferencia IS NULL AND @unidadReferencia IS NULL)
	BEGIN
		SET @precioReferencia = @precioUnitario;
	END
	
	IF(@unidadReferencia IS NULL)
	BEGIN
		SET @unidadReferencia = 'u';
	END
	SET @idProducto = (SELECT idProducto FROM Producto.Producto WHERE descripcionProducto = LTRIM(@descripcionProducto))
	IF @idProducto IS NOT NULL
	BEGIN
		-- Prouducto ya existe lo damos de alta
		UPDATE Producto.Producto
			SET productoActivo = @altaProducto,
				precioUnitario = COALESCE(@precioUnitario, precioUnitario),
				precioReferencia = COALESCE(@precioReferencia, precioReferencia),
				unidadReferencia = COALESCE(@unidadReferencia, unidadReferencia)
			WHERE idProducto = @idProducto
	END
	SET @clasificacion = REPLACE(@clasificacion, ' ', '_')
	SET @idClasificacion = (SELECT idClasificacion FROM Producto.Clasificacion WHERE nombreClasificacion = @clasificacion)
	IF @idClasificacion IS NULL
	BEGIN
		--Clasificacion no existe / llamamos a una primitiva? / hacemos insercion directa?
		RAISERROR('Error en el procedimiento almacenado agregarProducto. La clasificacion no existe.',16,5);
		RETURN;
	END
	INSERT INTO Producto.Producto (idClasificacion,descripcionProducto,precioUnitario,precioReferencia,unidadReferencia)
		VALUES (@idClasificacion,@descripcionProducto,@precioUnitario,@precioReferencia,@unidadReferencia);

END
GO
--Procedimiento almacenado que permite modificar producto
--DROP PROCEDURE Producto.modificarProducto
CREATE OR ALTER PROCEDURE Producto.modificarProducto (
						@idProducto INT						= NULL,@idClasificacion INT				= NULL,
						@descripcionProducto VARCHAR(100)	= NULL,@precioUnitario DECIMAL(10,2)	= NULL,
						@precioReferencia DECIMAL(10,2)		= NULL,@unidadReferencia VARCHAR(10)	= NULL
												)
AS BEGIN
	IF @idProducto IS NULL
	BEGIN
		RAISERROR ('Error en el procedimiento almacenado modificarProducto. El ID del producto es inv�lido.',16,12);
		RETURN;
	END
	IF (@idClasificacion IS NOT NULL AND 
		NOT EXISTS (SELECT 5 FROM Producto.Clasificacion WHERE idClasificacion = @idClasificacion))
		RETURN;
	IF(@descripcionProducto IS NULL OR LEN(LTRIM(@descripcionProducto)) = 0)
	BEGIN
		RAISERROR ('Error en el procedimiento almacenado modificarProducto. El formato de la descripci�n del producto es inv�lido.',16,12);
		RETURN;
	END
	IF @precioUnitario IS NULL
	BEGIN
		RAISERROR ('Error en el procedimiento almacenado modificarProducto. El precio unitario es inv�lido.',16,12);
		RETURN;
	END
	IF @precioReferencia IS NULL
	BEGIN
		RAISERROR ('Error en el procedimiento almacenado modificarProducto. El precio referencial es inv�lido.',16,12);
		RETURN;
	END
	IF(@unidadReferencia IS NULL OR LEN(LTRIM(@unidadReferencia)) = 0)
	BEGIN
		RAISERROR ('Error en el procedimiento almacenado modificarProducto. El formato de la unidadReferencia es inv�lido.',16,12);
		RETURN;
	END

	UPDATE Producto.Producto
		SET idClasificacion = COALESCE(@idClasificacion,idClasificacion),
			descripcionProducto = COALESCE(@descripcionProducto,descripcionProducto),
			precioUnitario = COALESCE(@precioUnitario,precioUnitario),
			precioReferencia = COALESCE(@precioReferencia,precioReferencia),
			unidadReferencia = COALESCE(@unidadReferencia,unidadReferencia)
		WHERE idProducto = @idProducto;

END
GO
--Procedimiento almacenado que permite eliminar producto
--DROP PROCEDURE Producto.eliminarProducto
CREATE OR ALTER PROCEDURE Producto.eliminarProducto (@idProducto INT = NULL)
AS BEGIN
	DECLARE @bajaProducto BIT = 0
	IF @idProducto IS NULL
	BEGIN
		RAISERROR ('Error en el procedimiento almacenado modificarProducto. El ID del producto es inv�lido.',16,12);
		RETURN;
	END
	--UPDATE Factura.DetalleFactura
	--	SET idProducto = NULL
	--	WHERE idProducto = @idProducto

	--DELETE FROM Producto.Producto
	--	WHERE idProducto = @idProducto;
	UPDATE Producto.Producto
		SET productoActivo = @bajaProducto
	WHERE idProducto = @idProducto
END
GO
--	Vista para ver los productos junto a su categor�a
--	DROP VIEW Producto.VerListadoDeProductos
--	SELECT * FROM Producto.VerListadoDeProductos
CREATE OR ALTER VIEW Producto.verListadoDeProductos AS
	SELECT idProducto,precioUnitario,precioReferencia,unidadReferencia,t.nombreClasificacion, t.lineaDeProducto
		FROM Producto.Producto p INNER JOIN Producto.Clasificacion t ON p.idClasificacion = t.idClasificacion;
GO
--	Chequear en https://dolarito.ar
--	Devuelve el valor del dolar en pesos
--	DROP PROCEDURE Producto.PasajeDolarAPesos
--	DECLARE @dolar DECIMAL(6,2); EXEC Producto.pasajeDolarAPesos @dolar OUTPUT; PRINT @dolar
CREATE OR ALTER PROCEDURE Producto.pasajeDolarAPesos(@dolarPesificado DECIMAL(6,2) OUTPUT)
AS
BEGIN
	DECLARE @valorDolar DECIMAL(6,2);
	DECLARE @url NVARCHAR(336) = 'https://dolarapi.com/v1/dolares/oficial';

	DECLARE @Object INT;
	DECLARE @json TABLE(DATA NVARCHAR(MAX));
	DECLARE @respuesta NVARCHAR(MAX);

	EXEC sp_OACreate 'MSXML2.XMLHTTP', @Object OUT;
	EXEC sp_OAMethod @Object, 'OPEN', NULL, 'GET', @url, 'FALSE';
	EXEC sp_OAMethod @Object, 'SEND';
	EXEC sp_OAMethod @Object, 'RESPONSETEXT', @respuesta OUTPUT, @json OUTPUT;

	INSERT INTO @json 
		EXEC sp_OAGetProperty @Object, 'RESPONSETEXT';

	DECLARE @datos NVARCHAR(MAX) = (SELECT DATA FROM @json)
	SELECT @dolarPesificado=venta FROM OPENJSON(@datos)
	WITH
	(
			moneda VARCHAR(15) '$.moneda',
			casa VARCHAR(15) '$.casa',
			nombre VARCHAR(15) '$.nombre',
			compra DECIMAL(6, 2) '$.compra',
			venta DECIMAL(6, 2) '$.venta',
			fechaActualizacion DATETIME2 '$.fechaActualizacion'
	);
END
GO
--Tabla Tipo  de Producto
--	Procedimiento almacenado para agregar una categor�a de los productos
--	DROP PROCEDURE Producto.AgregarTipoDeProducto;
CREATE OR ALTER PROCEDURE Producto.agregarClasificacion (@nombreClasificacion VARCHAR(35) = NULL, @linea VARCHAR(15) = NULL)
AS BEGIN

	IF(@nombreClasificacion IS NULL OR LEN(LTRIM(@nombreClasificacion)) = 0)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarTipoDeProducto. El nombre de la clasificacion es inv�lida.',16,6);
		RETURN;
	END
	IF EXISTS (SELECT 1 FROM Producto.Clasificacion 
				WHERE nombreClasificacion LIKE @nombreClasificacion)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado "AgregarTipoDeProducto". La Clasificacion ya se encuentra ingresada.',16,1);
		RETURN;
	END
	
	IF(@linea IS NULL OR LEN(LTRIM(@linea)) = 0)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarTipoDeProducto. La linea de producto es inv�lida.',16,6);
		RETURN;
	END
	SET @nombreClasificacion = REPLACE(@nombreClasificacion, ' ', '_')
	INSERT INTO Producto.Clasificacion(nombreClasificacion, lineaDeProducto)
		VALUES (@nombreClasificacion, @linea);
END
GO
--	Procedimiento almacenado para modificar el nombre de la categor�a
--	DROP PROCEDURE Producto.modificarTipoDeProducto
CREATE OR ALTER PROCEDURE Producto.modificarClasificacion (@idClasificacion INT = NULL,@nombreClasificacion VARCHAR(35) = NULL, @linea VARCHAR(15) = NULL)
AS BEGIN
	IF @idClasificacion IS NULL
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarTipoDeProducto. El ID de clasificacion es inv�lida.',16,6);
		RETURN;
	END
	IF(@nombreClasificacion IS NULL OR LEN(LTRIM(@nombreClasificacion)) = 0)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarTipoDeProducto. El nombre de la clasificacion es inv�lida.',16,6);
		RETURN;
	END
	IF(@linea IS NULL OR LEN(LTRIM(@linea)) = 0)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarTipoDeProducto. La linea de producto es inv�lida.',16,6);
		RETURN;
	END
	SET @nombreClasificacion = REPLACE(@nombreClasificacion, ' ', '_')
	UPDATE Producto.Clasificacion 
		SET nombreClasificacion = COALESCE(@nombreClasificacion,nombreClasificacion),
			lineaDeProducto = COALESCE(@linea,lineaDeProducto)
		WHERE idClasificacion = @idClasificacion;
END
GO
--	Procedimienot almacenado para eliminar un tipo de categor�a de los productos.
--	DROP PROCEDURE Producto.eliminarTipoDeProducto
CREATE OR ALTER PROCEDURE Producto.eliminarTipoDeProducto (@idClasificacion INT = NULL)
AS BEGIN
	IF @idClasificacion IS NULL
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarTipoDeProducto. La linea de producto es inv�lida.',16,6);
		RETURN;
	END
	UPDATE Producto.Producto
		SET idClasificacion = NULL
		WHERE idClasificacion = @idClasificacion

	DELETE FROM Producto.Clasificacion
		WHERE idClasificacion = @idClasificacion;
END;
GO