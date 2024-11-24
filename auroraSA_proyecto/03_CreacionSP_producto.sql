
IF EXISTS (SELECT * FROM sys.databases WHERE name = 'Com2900G19')
	USE Com2900G19
ELSE
	RAISERROR('Este script está diseñado para que se ejecute despues del script de la creacion de tablas y esquemas.',20,1);
GO
--  USE master
--DROP DATABASE G2900G19
/*
	
--Esquema Producto
	Tabla Producto
		agregarProducto
		modificarProducto
		eliminarProducto

		pasajeDolarAPesos

		verProductos ->muestra a los productos con sus categorias
	Tabla TipoDeProducto
		agregarTipoDeProducto
		modificarTipoDeProducto
		eliminarTipoDeProducto
*/

------------------------------------------------Producto------------------------------------------------
--Tabla Producto
--Procedimiento almacenado que permite agregar un producto
--DROP PROCEDURE Sucursal.
CREATE OR ALTER PROCEDURE Producto.agregarProducto (@idTipoDeProducto INT,@descripcionProducto VARCHAR(255),
													@precioUnitario DECIMAL(10,2),@precioReferencia DECIMAL(10,2) = NULL,
													@unidadReferencia VARCHAR(255) = NULL)
AS BEGIN
	IF EXISTS (SELECT 5 FROM Producto.Producto WHERE descripcionProducto = @descripcionProducto)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarProducto. El producto ya existe.',16,5);
		RETURN;
	END

	IF (LEN(LTRIM(@descripcionProducto)) = 0)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarProducto. La descripción del producto es incorrecta',16,5);
		RETURN;
	END

	IF(LEN(LTRIM(@unidadReferencia)) = 0)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarProducto. El precio o unidad de referencia son incorrectos.',16,5);
		RETURN;
	END

	IF(@precioReferencia IS NULL AND @unidadReferencia IS NULL)
	BEGIN
		SET @precioReferencia = @precioUnitario;
		SET @unidadReferencia = 'unidad';
	END

	BEGIN TRY
		INSERT INTO Producto.Producto (idTipoDeProducto,descripcionProducto,precioUnitario,precioReferencia,unidadReferencia)
			VALUES (@idTipoDeProducto,@descripcionProducto,@precioUnitario,@precioReferencia,@unidadReferencia);
	END TRY
	BEGIN CATCH
		RAISERROR ('Error en el procedimiento almacenado agregarproducto. Los datos del producto son incorrectos.',16,5);
	END CATCH
END
GO
CREATE OR ALTER PROCEDURE Producto.agregarProductoConNombreTipoProd (@nombreTipoDeProducto VARCHAR(255),@descripcionProducto VARCHAR(255),
													@precioUnitario DECIMAL(10,2),@precioReferencia DECIMAL(10,2) = NULL,
													@unidadReferencia VARCHAR(255) = NULL)
AS BEGIN
	DECLARE @idTipoProducto INT;
	IF EXISTS (SELECT 5 FROM Producto.Producto WHERE descripcionProducto = @descripcionProducto)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarProducto. El producto ya existe.',16,5);
		RETURN;
	END

	IF (LEN(LTRIM(@descripcionProducto)) = 0)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarProducto. La descripción del producto es incorrecta',16,5);
		RETURN;
	END

	IF(LEN(LTRIM(@unidadReferencia)) = 0)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarProducto. El precio o unidad de referencia son incorrectos.',16,5);
		RETURN;
	END

	IF(@precioReferencia IS NULL AND @unidadReferencia IS NULL)
	BEGIN
		SET @precioReferencia = @precioUnitario;
		SET @unidadReferencia = 'ud';
	END

	SET @idTipoProducto = (SELECT idTipoDeProducto FROM Producto.TipoDeProducto WHERE nombreTipoDeProducto LIKE @nombreTipoDeProducto);

	IF @idTipoProducto IS NULL
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarProducto XD',16,5);
		RETURN;
	END

	BEGIN TRY
		INSERT INTO Producto.Producto (idTipoDeProducto,descripcionProducto,precioUnitario,precioReferencia,unidadReferencia)
			VALUES (@idTipoProducto,@descripcionProducto,@precioUnitario,@precioReferencia,@unidadReferencia);
	END TRY
	BEGIN CATCH
		RAISERROR ('Error en el procedimiento almacenado agregarproducto. Los datos del producto son incorrectos.',16,5);
	END CATCH
END
GO
--Procedimiento almacenado que permite modificar producto
--DROP PROCEDURE Producto.modificarProducto
CREATE OR ALTER PROCEDURE Producto.modificarProducto (@idProducto INT, @idTipoDeProducto INT = NULL,
													@descripcionProducto VARCHAR(255) = NULL,
													@precioUnitario DECIMAL(10,2) = NULL,
													@precioReferencia DECIMAL(10,2) = NULL,
													@unidadReferencia DECIMAL(10,2) = NULL)
AS BEGIN
	IF (@idTipoDeProducto IS NOT NULL AND 
		NOT EXISTS (SELECT 5 FROM Producto.TipoDeProducto WHERE idTipoDeProducto = @idTipoDeProducto))
		RETURN;
	IF(LEN(LTRIM(@descripcionProducto)) = 0)
	BEGIn
		RAISERROR ('Error en el procedimiento almacenado modificarProducto. El formato de la descripción del producto es inválido.',16,12);
		RETURN;
	END
	IF(LEN(LTRIM(@unidadReferencia)) = 0)
	BEGIn
		RAISERROR ('Error en el procedimiento almacenado modificarProducto. El formato de la unidadReferencia es inválido.',16,12);
		RETURN;
	END

	BEGIN TRY
		UPDATE Producto.Producto
			SET idTipoDeProducto = COALESCE(@idTipoDeProducto,idTipoDeProducto),
				descripcionProducto = COALESCE(@descripcionProducto,descripcionProducto),
				precioUnitario = COALESCE(@precioUnitario,precioUnitario),
				precioReferencia = COALESCE(@precioReferencia,precioReferencia),
				unidadReferencia = COALESCE(@unidadReferencia,unidadReferencia)
			WHERE idProducto = @idProducto;
	END TRY
	BEGIN CATCH
		RAISERROR ('Error en el procedimiento almacenado modificarProducto. Los datos que se desean cambiar son inválidos.',16,12);
	END CATCH
END
GO
--Procedimiento almacenado que permite eliminar producto
--DROP PROCEDURE Producto.eliminarProducto
CREATE OR ALTER PROCEDURE Producto.eliminarProducto (@idProducto INT)
AS BEGIN
	UPDATE Factura.DetalleFactura
		SET idProducto = NULL
		WHERE idProducto = @idProducto

	DELETE FROM Producto.Producto
		WHERE idProducto = @idProducto;
END
GO
--	Vista para ver los productos junto a su categoría
--	DROP VIEW Producto.VerListadoDeProductos
--	SELECT * FROM Producto.VerListadoDeProductos
CREATE OR ALTER VIEW Producto.verListadoDeProductos AS
	SELECT idProducto,precioUnitario,precioReferencia,unidadReferencia,t.nombreTipoDeProducto
		FROM Producto.Producto p JOIN Producto.TipoDeProducto t ON p.idTipoDeProducto = t.idTipoDeProducto;
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

	SET NOCOUNT ON;
	EXEC sp_configure 'show advanced options', 1;
	RECONFIGURE;
	EXEC sp_configure 'Ole Automation Procedures', 1;
	RECONFIGURE;

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
	EXEC sp_configure 'Ole Automation Procedures', 0;
	RECONFIGURE;
	EXEC sp_configure 'show advanced options', 0;
	RECONFIGURE;
	SET NOCOUNT OFF;
END
GO
--Tabla Tipo  de Producto
--	Procedimiento almacenado para agregar una categoría de los productos
--	DROP PROCEDURE Producto.AgregarTipoDeProducto;
CREATE OR ALTER PROCEDURE Producto.agregarTipoDeProducto (@nombreTipoDeProducto VARCHAR(255))
AS BEGIN
	IF EXISTS (SELECT 1 FROM Producto.TipoDeProducto 
				WHERE nombreTipoDeProducto LIKE @nombreTipoDeProducto)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado "AgregarTipoDeProducto". La categoría ya se encuentra ingresada.',16,1);
		RETURN;
	END

	IF(LEN(LTRIM(@nombreTipoDeProducto)) = 0)
	BEGIN
		RAISERROR('ERror en el procedimiento almacenado agregarTipoDeProducto. La categoría es inválida.',16,6);
		RETURN;
	END

	INSERT INTO Producto.TipoDeProducto(nombreTipoDeProducto) VALUES (@nombreTipoDeProducto);
END
GO
--	Procedimiento almacenado para modificar el nombre de la categoría
--	DROP PROCEDURE Producto.modificarTipoDeProducto
CREATE OR ALTER PROCEDURE Producto.modificarTipoDeProducto (@idTipoDeProducto INT,@nombreTipoDeProducto VARCHAR(255))
AS BEGIN
	IF (LEN(LTRIM(@nombreTipoDeProducto)) = 0)
		RETURN;
	UPDATE Producto.TipoDeProducto 
		SET nombreTipoDeProducto = COALESCE(@nombreTipoDeProducto,nombreTipoDeProducto) 
		WHERE idTipoDeProducto = @idTipoDeProducto;
END
GO
--	Procedimienot almacenado para eliminar un tipo de categoría de los productos.
--	DROP PROCEDURE Producto.eliminarTipoDeProducto
CREATE OR ALTER PROCEDURE Producto.eliminarTipoDeProducto (@idTipoDeProducto INT)
AS BEGIN
	UPDATE Producto.Producto
		SET idTipoDeProducto = NULL
		WHERE idTipoDeProducto = @idTipoDeProducto

	DELETE FROM Producto.TipoDeProducto
		WHERE idTipoDeProducto = @idTipoDeProducto;
END;
GO