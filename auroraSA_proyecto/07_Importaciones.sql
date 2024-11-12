USE Com2900G19;
GO
--		USER MASTER
--		DROP DATABASE Com2900G19

CREATE OR ALTER PROCEDURE Factura.ArchComplementario_importarMedioDePago (@ruta NVARCHAR(MAX))
AS BEGIN
	
	DECLARE @SqlDinamico NVARCHAR(MAX);

	SET @SqlDinamico = 'INSERT Factura.MedioDePago (nombreMedioDePago,descripcion) ';

	SET @SqlDinamico = @SqlDinamico + ' SELECT F2,F3
										FROM OPENROWSET(''Microsoft.ACE.OLEDB.16.0'', 
														''Excel 12.0; Database='+ @ruta +'; HDR=YES'', 
														''SELECT * FROM [medios de pago$]'')'

	EXECUTE sp_executesql @SqlDinamico;
END;

exec Factura.ArchComplementario_importarMedioDePago 'C:\Users\soyOmar\Documents\bbddAplicada\tp\TP_integrador_Archivos\Informacion_complementaria.xlsx'

SELECT * from Factura.MedioDePago
DROP PROCEDURE Factura.ArchComplementario_importarMedioDePago
DELETE FROM Factura.MedioDePago

---------------------------------------ImportarEmpleado------------------------
--		DROP PROCEDURE Factura.ArchComplementario_importarEmpleado
CREATE OR ALTER PROCEDURE Factura.ArchComplementario_importarEmpleado (@ruta NVARCHAR(MAX))
AS BEGIN
	DECLARE @tabulador CHAR = CHAR(9);
	DECLARE @espacio CHAR = CHAR(10);

	create table #aux
	(
		fila int identity(1,1),
		legajo varchar(max),
		nombre varchar(max),
		apellido varchar(max),
		dni varchar(max),
		sexo varchar(max),
		direccion varchar(max),
		emailPersonal varchar(max),
		emailEmpresarial varchar(max),
		cuil varchar(max),
		cargo varchar(max),
		sucursal varchar(max),
		turno varchar(max)
	)

	create table #direccionAux
	(
		calle varchar(max),
		numeroDeCalle varchar(max),
		codigoPostal varchar(max),
		localidad varchar(max),
		provincia varchar(max)
	)

	DECLARE @direccionAParsear VARCHAR(MAX),
			@calle VARCHAR(MAX),
			@numeroDeCalle VARCHAR(MAX),
			@codigoPostal VARCHAR(MAX),
			@localidad VARCHAR(MAX),
			@provincia VARCHAR(MAX);
	
	DECLARE @SqlDinamico NVARCHAR(MAX);

	SET @SqlDinamico = 'INSERT #aux ';

	SET @SqlDinamico = @SqlDinamico + ' SELECT *
										FROM OPENROWSET(''Microsoft.ACE.OLEDB.16.0'', 
														''Excel 12.0; Database='+ @ruta +'; HDR=YES'', 
														''SELECT * FROM [Empleados$]'')'
	EXECUTE sp_executesql @SqlDinamico;

	DELETE FROM #aux
	WHERE legajo IS NULL

	--SELECT * FROM #aux

	UPDATE #aux
		SET cuil = Empleado.calcularCuil (dni,sexo)
		WHERE cuil IS NULL;

	--DELETE FROM Sucursal.Turno; --Esto borrarlo, es solo pa' q funcione xd
	--SELECT * FROM #aux
	--Agregamos los turnos
	INSERT INTO Sucursal.Turno
		SELECT DISTINCT turno
			FROM #aux a 
			WHERE NOT EXISTS(Select 1 FROM Sucursal.Turno t 
								WHERE t.nombreTurno <> a.turno COLLATE Modern_Spanish_CI_AI);
	UPDATE #aux
		SET turno = t.idTurno
		FROM #aux a JOIN Sucursal.Turno t
			ON a.turno = t.nombreTurno COLLATE Modern_Spanish_CI_AI;
	--Agregamos los cargos
	INSERT INTO Sucursal.Cargo
		SELECT DISTINCT cargo
			FROM #aux a
			WHERE NOT EXISTS(SELECT 1 from Sucursal.Cargo c
								WHERE c.nombreCargo <> a.cargo COLLATE Modern_Spanish_CI_AI);
	UPDATE #aux
		SET cargo = c.idCargo
		FROM #aux a JOIN Sucursal.Cargo c
			ON a.cargo = c.nombreCargo COLLATE Modern_Spanish_CI_AI;
	
	UPDATE #aux
		SET sucursal = s.idSucursal
		FROM (SELECT idSucursal,d.localidad 
				FROM Sucursal.Sucursal s JOIN Direccion.Direccion d 
					ON s.idDireccion = d.idDireccion
			) AS s JOIN #aux a ON s.localidad LIKE a.sucursal COLLATE Modern_Spanish_CI_AI;
	--Arreglamos los espacios en blanco
	UPDATE #aux
		SET emailPersonal = REPLACE(emailPersonal,@tabulador,'_'),
			emailEmpresarial = REPLACE(emailEmpresarial,@tabulador,'_')
	UPDATE #aux
		SET emailPersonal = REPLACE(emailPersonal,@espacio,'_'),
			emailEmpresarial = REPLACE(emailEmpresarial,@espacio,'_')
	--SELECT * FROM Sucursal.Turno
	--SELECT * FROM Sucursal.Cargo

	DECLARE @cursorFila INT = 1,
			@ultFila INT = (SELECT ROW_NUMBER() OVER(ORDER BY legajo) AS filas FROM #aux ORDER BY filas DESC)

	WHILE (@cursorFila <= @ultFila)
	BEGIN
		SET @direccionAParsear = (SELECT * FROM #aux WHERE )
		--Aca lo dejo 7/11 10.38 xd
		SET @cursorFila = @cursorFila + 1;
	END

	SELECT * FROM #aux
	DROP TABLE #aux
END;
GO;

------------------------Importar Catalogo -------------------------------------------
--		DROP PROCEDURE Producto.importarCatalogoCSV 
CREATE OR ALTER PROCEDURE Producto.importarCatalogoCSV (@rutaArchivo NVARCHAR(MAX))
AS BEGIN
	DECLARE @i INT = 1,
			@ultFila INT;
	DECLARE @valorDelDolar DECIMAL(6,2);
	DECLARE @SqlDinamico NVARCHAR(MAX),
			@categoria NVARCHAR(MAX),
			@nombreProducto NVARCHAR(MAX),
			@precio NVARCHAR(MAX),
			@precioReferencia NVARCHAR(MAX),
			@unidadReferencia NVARCHAR(MAX),
			@parteUno NVARCHAR(MAX),
			@parteDos NVARCHAR(MAX),
			@parteTres NVARCHAR(MAX);
	DECLARE @precioDecimalUni DECIMAL(15,2),
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

	update #Catalogo
		SET Nombre = REPLACE(Nombre,'ú','�')
		WHERE Nombre LIKE '%ú%';

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
			WHERE filas = @i;
		SET @precioDecimalUni = @precioDecimalUni * @valorDelDolar;
		SET @precioDecimalRef = @precioDecimalRef * @valorDelDolar;

		EXEC Producto.agregarProductoConNombreTipoProd @categoria,@nombreProducto,@precioDecimalUni,@precioDecimalRef,@unidadReferencia;

		SET @i = @i + 1;
	END

	DROP TABLE #campoSinComillas;
	DROP TABLE #campoConComillas;
	DROP TABLE #aux;
	DROP TABLE #Catalogo;
END;
GO