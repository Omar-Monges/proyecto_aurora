
IF EXISTS (SELECT * FROM sys.databases WHERE name = 'Com2900G19')
	USE Com2900G19
ELSE
	RAISERROR('Este script está diseñado para que se ejecute despues del script de la creacion de tablas y esquemas.',20,1);
GO

--EXECUTE sp_configure 'show advanced options', 1;
--GO

--RECONFIGURE;
--GO

--EXECUTE sp_configure 'Ad Hoc Distributed Queries', 1;
--GO

--RECONFIGURE;
--GO

------------------Importacion de productos---------------------------------------

---- catalogos csv
CREATE OR ALTER PROCEDURE Producto.importarCatalogoCSV (@rutaArchivo NVARCHAR(MAX))
AS BEGIN
	--DECLARE @RUTA nvarchar(max) = 'C:\Users\soyOmar\Documents\bbddAplicada\tp\TP_integrador_Archivos\Productos\catalogo.csv'
	DECLARE @i INT = 1,
			@ultFila INT,
			@idCategoria INT,
			@valorDelDolar DECIMAL(6,2),
			@SqlDinamico NVARCHAR(MAX),
			@categoria NVARCHAR(MAX),
			@nombreProducto NVARCHAR(MAX),
			@precio NVARCHAR(MAX),
			@precioReferencia NVARCHAR(MAX),
			@unidadReferencia NVARCHAR(MAX),
			@parteUno NVARCHAR(MAX),
			@parteDos NVARCHAR(MAX),
			@parteTres NVARCHAR(MAX),
			@precioDecimalUni DECIMAL(15,2),
			@precioDecimalRef DECIMAL(15,2);

	CREATE TABLE #Catalogo
	(
		id INT identity(1,1),
		Categoria VARCHAR(255),
		Nombre VARCHAR(255),
		Precio DECIMAL(10,2),
		PrecioReferencia DECIMAL(10,2),
		UnidadReferencia VARCHAR(255)
	);
	CREATE TABLE #aux
	(
		campo VARCHAR(MAX) COLLATE Modern_Spanish_CI_AS
	)
	CREATE TABLE #campoConComillas
	(
		fila INT IDENTITY(1,1),
		parteUno VARCHAR(MAX),
		parteDos VARCHAR(MAX),
		parteTres VARCHAR(MAX)
	)
	CREATE TABLE #campoSinComillas
	(
		fila INT IDENTITY(1,1),
		campo VARCHAR(MAX)
	)

	SET @SqlDinamico = 'BULK INSERT #aux
					FROM '''+ @rutaArchivo +'''
					WITH
					(
						FIELDTERMINATOR = '','',
						ROWTERMINATOR = ''0x0A'',
						CODEPAGE=''65001'',
						FIRSTROW = 2
					);';
	EXEC sp_executesql @SqlDinamico;

	INSERT #campoConComillas (parteDos,parteUno,parteTres)
			SELECT SUBSTRING(campo, CHARINDEX('"',campo,1) + 1, CHARINDEX('"',SUBSTRING(campo,CHARINDEX('"',campo,1) + 1,LEN(campo)),1) - 1) AS parteDos,
					LEFT(campo,CHARINDEX(SUBSTRING(campo, CHARINDEX('"',campo,1) + 1, CHARINDEX('"',SUBSTRING(campo,CHARINDEX('"',campo,1) + 1,LEN(campo)),1) - 1),campo,1) - 3) AS parteUno,
					SUBSTRING(campo, CHARINDEX('",',campo,1) + 2,LEN(campo))  AS parteTres
				FROM #aux
				WHERE CHARINDEX('"',campo,1) > 0;

	SET @ultFila = (SELECT TOP(1) fila FROM #campoConComillas ORDER BY fila DESC);
	

	WHILE (@i <= @ultFila)
	BEGIN
		SELECT @parteUno = parteUno, @parteDos = parteDos, @parteTres = parteTres 
			FROM #campoConComillas WHERE fila = @i;

		SET @categoria = SUBSTRING(@parteUno,CHARINDEX(',',@parteUno,1) + 1,LEN(@parteUno));
		SET @nombreProducto = @parteDos;

		SET @precio = SUBSTRING(@parteTres,1,CHARINDEX(',',@parteTres,1) - 1);

		SET @parteTres = SUBSTRING(@parteTres,CHARINDEX(',',@parteTres,1) + 1,LEN(@parteTres));

		SET @precioReferencia = SUBSTRING(@parteTres,1,CHARINDEX(',',@parteTres,1) - 1);

		SET @parteTres = SUBSTRING(@parteTres,CHARINDEX(',',@parteTres,1) + 1,LEN(@parteTres));

		SET @unidadReferencia = SUBSTRING(@parteTres,1,CHARINDEX(',',@parteTres,1) - 1);

		INSERT INTO #Catalogo (Categoria,Nombre,Precio,PrecioReferencia,UnidadReferencia)
			VALUES(LTRIM(RTRIM(@categoria)),LTRIM(RTRIM(@nombreProducto)),CAST(@precio AS decimal(10,2)),CAST(@precioReferencia AS decimal(10,2)),@unidadReferencia);

		SET @i = @i + 1;
	END

	INSERT INTO #campoSinComillas (campo)
		SELECT campo FROM #aux WHERE CHARINDEX('"',campo,1) = 0;

	SET @i = 1;
	SET @ultFila = (SELECT TOP(1) fila FROM #campoSinComillas ORDER BY fila DESC)
	DECLARE @campoParsear VARCHAR(MAX);
	WHILE (@i <= @ultFila)
	BEGIN
		SET @campoParsear = (SELECT campo FROM #campoSinComillas WHERE fila = @i);
		--Categoria
		SET @campoParsear = SUBSTRING(@campoParsear,CHARINDEX(',',@campoParsear,1) + 1, LEN(@campoParsear));
		SET @categoria = SUBSTRING(@campoParsear,1,CHARINDEX(',',@campoParsear,1) - 1);
		--Producto
		SET @campoParsear = SUBSTRING(@campoParsear,CHARINDEX(',',@campoParsear,1) + 1, LEN(@campoParsear));
		SET @nombreProducto = SUBSTRING(@campoParsear,1,CHARINDEX(',',@campoParsear,1) - 1);
		--Precio
		SET @campoParsear = SUBSTRING(@campoParsear,CHARINDEX(',',@campoParsear,1) + 1, LEN(@campoParsear));
		SET @precio = SUBSTRING(@campoParsear,1,CHARINDEX(',',@campoParsear,1) - 1);
		--Precio Referencia
		SET @campoParsear = SUBSTRING(@campoParsear,CHARINDEX(',',@campoParsear,1) + 1, LEN(@campoParsear));
		SET @precioReferencia = SUBSTRING(@campoParsear,1,CHARINDEX(',',@campoParsear,1) - 1);
		--Unidad Referencia
		SET @campoParsear = SUBSTRING(@campoParsear,CHARINDEX(',',@campoParsear,1) + 1, LEN(@campoParsear));
		SET @unidadReferencia = SUBSTRING(@campoParsear,1,CHARINDEX(',',@campoParsear,1) - 1);

		INSERT INTO #Catalogo (Categoria,Nombre,Precio,PrecioReferencia,UnidadReferencia)
			VALUES (LTRIM(RTRIM(@categoria)),LTRIM(RTRIM(@nombreProducto)),CAST(@precio AS decimal(10,2)),CAST(@precioReferencia AS decimal(10,2)),@unidadReferencia);

		SET @i = @i + 1;
	END;

	WITH RepetidosCTE AS
	(
		SELECT *, ROW_NUMBER() OVER(PARTITION BY Nombre ORDER BY id DESC) AS repetidos FROM #Catalogo
	)
	DELETE FROM RepetidosCTE WHERE repetidos > 1

	EXEC Producto.pasajeDolarAPesos @valorDelDolar OUTPUT;

	UPDATE #Catalogo
		SET Nombre = REPLACE(Nombre,'Ãº','ú')
		WHERE Nombre LIKE '%Ãº%';

	INSERT INTO Producto.TipoDeProducto (nombreTipoDeProducto)
		SELECT DISTINCT Categoria FROM #Catalogo;
	
	SET @i = 1;
	SET @ultFila = (SELECT TOP(1) filas FROM (SELECT ROW_NUMBER() OVER (ORDER BY id) AS filas FROM #Catalogo) AS T ORDER BY filas DESC);
	WHILE (@i <= @ultFila)
	BEGIN
		SELECT @categoria = Categoria,@nombreProducto = Nombre, @precioDecimalUni = Precio, @precioDecimalRef = PrecioReferencia, @unidadReferencia = UnidadReferencia 
			FROM 
				(
					SELECT Categoria,Nombre,Precio,PrecioReferencia,UnidadReferencia,ROW_NUMBER() OVER (ORDER BY id) AS filas FROM #Catalogo
				) AS T 
			WHERE filas = @i
		SET @precioDecimalUni = @precioDecimalUni * @valorDelDolar
		SET @precioDecimalRef = @precioDecimalRef * @valorDelDolar
		-- y este procedimiento
		-- insertar las variables a las tabla producto
		SET @idCategoria = (SELECT idTipoDeProducto FROM Producto.TipoDeProducto WHERE nombreTipoDeProducto LIKE @categoria)
		INSERT INTO Producto.Producto(idTipoDeProducto, descripcionProducto, precioUnitario, precioReferencia, unidadReferencia)
			VALUES (@idCategoria, @nombreProducto, @precioDecimalUni, @precioDecimalRef, @unidadReferencia)
		--EXEC Producto.agregarProductoConNombreTipoProd @categoria,@nombreProducto,@precioDecimalUni,@precioDecimalRef,@unidadReferencia;

		SET @i = @i + 1;
	END
	DROP TABLE #campoSinComillas;
	DROP TABLE #campoConComillas;
	DROP TABLE #aux;
	DROP TABLE #Catalogo;
END;
GO
--------electronicos xlsx
CREATE OR ALTER PROCEDURE Producto.importarProductosElectronicosXLSX (@ruta NVARCHAR(MAX))
AS BEGIN
	DECLARE @idTipoDeProducto INT;
	DECLARE @SqlDinamico NVARCHAR(MAX);
	DECLARE @DolarEnPesos DECIMAL(6,2);

	CREATE TABLE #aux
	(
		nombre VARCHAR(MAX),
		precio DECIMAL(10,2)
	)

	SET @SqlDinamico = 'INSERT #aux';

	SET @SqlDinamico = @SqlDinamico + ' SELECT *
										FROM OPENROWSET(''Microsoft.ACE.OLEDB.16.0'', 
														''Excel 12.0; Database='+ @ruta +'; HDR=YES'', 
														''SELECT * FROM [sheet1$]'')';
	EXECUTE sp_executesql @SqlDinamico;
	EXEC Producto.pasajeDolarAPesos @DolarEnPesos OUTPUT;

	EXEC Producto.agregarTipoDeProducto 'Electronica';
	
	SET @idTipoDeProducto = (SELECT TOP(1) idTipoDeProducto FROM Producto.TipoDeProducto 
								ORDER BY idTipoDeProducto DESC);

	INSERT INTO Producto.Producto (descripcionProducto,idTipoDeProducto,precioUnitario,precioReferencia,unidadReferencia)
		SELECT nombre, @idTipoDeProducto, precio * @DolarEnPesos, precio  * @DolarEnPesos, 'ud' FROM #aux

	DROP TABLE #aux;
END;
GO
CREATE OR ALTER PROCEDURE Producto.importarProductosImportadosXLSX (@rutaArch VARCHAR(MAX))
AS BEGIN
	
	DECLARE @SqlDinamico NVARCHAR(MAX);

	DECLARE @DolarEnPesos DECIMAL(6,2);

	CREATE TABLE #aux
	(
		nombre VARCHAR(MAX),
		categoria varchar(max),
		precio DECIMAL(10,2),
		precioRef DECIMAL(10,2),
		unidadRef VARCHAR(MAX)
	)

	SET @SqlDinamico = 'INSERT #aux (nombre,categoria,precio)';
	SET @SqlDinamico = @SqlDinamico + ' SELECT NombreProducto,[Categoría],PrecioUnidad
										FROM OPENROWSET(''Microsoft.ACE.OLEDB.16.0'', 
														''Excel 12.0; Database='+ @rutaArch +'; HDR=YES'', 
														''SELECT * FROM [Listado de Productos$]'')';
	EXECUTE sp_executesql @SqlDinamico;

	INSERT INTO Producto.TipoDeProducto (nombreTipoDeProducto)
		SELECT DISTINCT categoria FROM #aux

	UPDATE #aux
		SET precioRef = precio,
			unidadRef = 'ud'

	EXEC Producto.pasajeDolarAPesos @DolarEnPesos OUTPUT;

	INSERT INTO Producto.Producto (descripcionProducto,precioUnitario,precioReferencia,unidadReferencia,idTipoDeProducto)
		SELECT nombre,precio * @DolarEnPesos,precioRef  * @DolarEnPesos,unidadRef, t.idTipoDeProducto
			FROM #aux a JOIN Producto.TipoDeProducto t
				ON a.categoria like t.nombreTipoDeProducto COLLATE Modern_Spanish_CI_AS;

	DROP TABLE #aux;
END
GO