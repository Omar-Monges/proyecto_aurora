USE Com2900G19;
GO
--		USE MASTER
--		DROP DATABASE Com2900G19
CREATE OR ALTER PROCEDURE Venta.ArchComplementario_importarMedioDePago (@ruta NVARCHAR(MAX))
AS BEGIN
	CREATE TABLE #MedioDePagoTemp
	(
		nombreMDP VARCHAR(MAX),
		descripcion VARCHAR(MAX)
	)
	DECLARE @SqlDinamico NVARCHAR(MAX);

	SET @SqlDinamico = 'INSERT INTO #MedioDePagoTemp ';

	SET @SqlDinamico = @SqlDinamico + ' SELECT F2,F3
										FROM OPENROWSET(''Microsoft.ACE.OLEDB.16.0'', 
														''Excel 12.0; Database='+ @ruta +'; HDR=YES'', 
														''SELECT * FROM [medios de pago$]'')'

	EXECUTE sp_executesql @SqlDinamico;

	INSERT INTO Venta.MedioDePago (nombreMedioDePago,descripcion)
		SELECT t.* FROM #MedioDePagoTemp t
			WHERE NOT EXISTS (SELECT 1 FROM Venta.MedioDePago
								WHERE nombreMDP LIKE nombreMedioDePago COLLATE Modern_Spanish_CI_AI
							)
	DROP TABLE #MedioDePagoTemp
END;
exec Venta.ArchComplementario_importarMedioDePago 'C:\Users\joela\Downloads\TP_integrador_Archivos\Informacion_complementaria.xlsx'
--		SELECT * from Venta.MedioDePago
GO
--Importar categorias de los productos
--		DROP PROCEDURE Venta.ImportarClasificacionProducto
--		SELECT * FROM Producto.Clasificacion
CREATE OR ALTER PROCEDURE Venta.ImportarClasificacionProducto (@ruta NVARCHAR(MAX))
AS BEGIN
	CREATE TABLE #ClasificacionAux
	(
		lineaDeProductoAux VARCHAR(MAX),
		clasificacion VARCHAR(MAX)
	)
	DECLARE @SqlDinamico NVARCHAR(MAX)
	SET @SqlDinamico = 'INSERT INTO #ClasificacionAux';

	SET @SqlDinamico =		@SqlDinamico	+ ' SELECT *
										FROM OPENROWSET(''Microsoft.ACE.OLEDB.16.0'', 
														''Excel 12.0; Database='+ @ruta +'; HDR=YES'', 
														''SELECT * FROM [Clasificacion productos$]'')'
	EXECUTE sp_executesql @SqlDinamico;
	INSERT INTO Producto.Clasificacion (lineaDeProducto,nombreClasificacion)
		SELECT * FROM #ClasificacionAux
			WHERE NOT EXISTS (
								SELECT 2 FROM Producto.Clasificacion WHERE clasificacion LIKE nombreClasificacion COLLATE Modern_Spanish_CI_AI
							)
	DROP TABLE #ClasificacionAux

END
exec Venta.ImportarClasificacionProducto 'C:\Users\joela\Downloads\TP_integrador_Archivos\Informacion_complementaria.xlsx'
--		SELECT * FROM Producto.Clasificacion
GO
--Importar Sucursales
--		DROP PROCEDURE Venta.ArchComplementario_importarSucursal
--		SELECT * FROM Sucursal.Sucursal
CREATE OR ALTER PROCEDURE Venta.ArchComplementario_importarSucursal (@ruta NVARCHAR(MAX))
AS BEGIN
	CREATE TABLE #SucursalTemp
	(
		Ciudad VARCHAR(MAX),
		ReemplazarPor VARCHAR(MAX),
		Direccion VARCHAR(MAX),
		Horario VARCHAR(MAX),
		Telefono VARCHAR(MAX)
	)
	DECLARE @SqlDinamico NVARCHAR(MAX);

	SET @SqlDinamico = 'INSERT INTO #SucursalTemp ';
	SET @SqlDinamico = @SqlDinamico + ' SELECT *
										FROM OPENROWSET(''Microsoft.ACE.OLEDB.16.0'', 
														''Excel 12.0; Database='+ @ruta +'; HDR=YES'', 
														''SELECT * FROM [sucursal$]'')'

	EXECUTE sp_executesql @SqlDinamico;

	UPDATE #SucursalTemp
		SET Ciudad = ReemplazarPor
	
	INSERT INTO Sucursal.Sucursal (telefono,direccion,localidad,horario,sucursalActiva,cuit)
		SELECT Telefono,Direccion,Ciudad,Horario,1,'20-22222222-3'
			FROM #SucursalTemp t 
			WHERE NOT EXISTS (SELECT 1 FROM Sucursal.Sucursal s WHERE s.localidad LIKE t.Ciudad COLLATE Modern_Spanish_CI_AI)

	DROP TABLE #SucursalTemp
END;
GO
exec Venta.ArchComplementario_importarSucursal 'C:\Users\joela\Downloads\TP_integrador_Archivos\Informacion_complementaria.xlsx'
--		SELECT * FROM Sucursal.Sucursal
GO
---------------------------------------ImportarEmpleado------------------------
--https://learn.microsoft.com/en-us/sql/relational-databases/in-memory-oltp/implementing-update-with-from-or-subqueries?view=sql-server-ver16
--		DROP PROCEDURE Venta.ArchComplementario_importarEmpleado
CREATE OR ALTER PROCEDURE Venta.ArchComplementario_importarEmpleado (@ruta NVARCHAR(MAX))
AS BEGIN
	DECLARE @tabulador CHAR = CHAR(9);
	DECLARE @espacio CHAR = CHAR(10);

	create table #aux
	(
		legajo VARCHAR(max),
		nombre VARCHAR(max),
		apellido VARCHAR(max),
		dni VARCHAR(max),
		direccion VARCHAR(max),
		emailPersonal VARCHAR(max),
		emailEmpresarial VARCHAR(max),
		cuil VARCHAR(max),
		cargo VARCHAR(max),
		sucursal VARCHAR(max),
		turno VARCHAR(max)
	)
	
	DECLARE @SqlDinamico NVARCHAR(MAX);

	SET @SqlDinamico = 'INSERT #aux';
	SET @SqlDinamico = @SqlDinamico + ' SELECT [Legajo/ID],Nombre,Apellido,CAST(DNI AS INT),Direccion,[email personal],[email empresa],CUIL,Cargo,Sucursal,Turno
										FROM OPENROWSET(''Microsoft.ACE.OLEDB.16.0'', 
														''Excel 12.0; Database='+ @ruta +'; HDR=YES'', 
														''SELECT * FROM [Empleados$]'')'
	EXECUTE sp_executesql @SqlDinamico;
	--Eliminamos las filas nulas
	DELETE FROM #aux WHERE legajo IS NULL
	--Eliminamos las tabulaciones
	UPDATE #aux
		SET emailPersonal = REPLACE(emailPersonal,@tabulador,''),
			emailEmpresarial = REPLACE(emailEmpresarial,@tabulador,'');
	--Eliminamos los espacios
	UPDATE #aux
		SET emailPersonal = REPLACE(emailPersonal,@espacio,''),
			emailEmpresarial = REPLACE(emailEmpresarial,@espacio,'');
	--CUIL nulos ----> PREGUNTAR!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	UPDATE #aux
		SET cuil = '12-12345678-9'--PREGUNTAR!!!!!!!!!!!!!!!!!!!!!!!!
		WHERE cuil IS NULL
	--Agregamos los cargos en la tabla Cargo
	INSERT INTO Sucursal.Cargo (nombreCargo)
		SELECT DISTINCT a.cargo FROM #aux a
			WHERE NOT EXISTS (
								SELECT 1 FROM Sucursal.Cargo c WHERE a.cargo NOT LIKE c.nombreCargo COLLATE Modern_Spanish_CI_AI
							)
	--Linkeamos los cargos con sus respectivos IDs
	UPDATE #aux
		SET cargo = idCargo
		FROM Sucursal.Cargo c JOIN #aux a ON c.nombreCargo LIKE a.cargo COLLATE Modern_Spanish_CI_AI
	--Ahora linkeamos las sucursales con sus IDs
	UPDATE #aux
		SET sucursal = idSucursal
		FROM Sucursal.Sucursal s JOIN #aux a ON s.localidad LIKE a.sucursal COLLATE Modern_Spanish_CI_AI

	INSERT INTO Empleado.Empleado (legajo,dni,cuil,nombre,apellido,emailPersonal,emailEmpresarial,direccion,turno,empleadoActivo,idSucursal,idCargo)
		SELECT legajo,dni,cuil,nombre,apellido,emailPersonal,emailEmpresarial,direccion,turno,1,sucursal,cargo FROM #aux a
			WHERE NOT EXISTS (SELECT 1 FROM Empleado.Empleado e WHERE e.legajo LIKE CAST(a.legajo AS int))
	--SELECT * FROM #aux
	DROP TABLE #aux
END;
GO
exec Venta.ArchComplementario_importarEmpleado 'C:\Users\joela\Downloads\TP_integrador_Archivos\Informacion_complementaria.xlsx'
/*		
		SELECT * FROM Empleado.Empleado
		SELECT * FROM Sucursal.Cargo
*/
GO
/*
DECLARE @rutaArchivo NVARCHAR(MAX) = 'C:\Datos\archivo.csv'; -- Ruta del archivo CSV
DECLARE @tablaDestino NVARCHAR(128) = 'MiTablaTemporal';    -- Nombre de la tabla destino
DECLARE @sql NVARCHAR(MAX);

SET @sql = '
BULK INSERT ' + QUOTENAME(@tablaDestino) + '
FROM ''' + @rutaArchivo + '''
WITH (
    FIELDTERMINATOR = '','', -- Delimitador de campo
    ROWTERMINATOR = ''\n'',  -- Delimitador de fila
    FIELDQUOTE = '''''''     -- Especifica que las comillas simples encapsulan texto
);';

-- Ejecutar el SQL dinámico
EXEC sp_executesql @sql;

*/
------------------------Importar Catalogo ------------------------------------------- <------		ACAAAAAAAAAAAAAAAAA
--		DROP PROCEDURE Producto.importarCatalogoCSV 
--		SELECT * FROM Producto.Producto
--		SELECT * FROM Producto.Clasificacion
CREATE OR ALTER PROCEDURE Producto.importarCatalogoCSV (@rutaArchivo NVARCHAR(MAX))
AS BEGIN
	DECLARE @valorDelDolar DECIMAL(6,2);
	DECLARE @idClasificacion VARCHAR(35),
			@fila INT;
	DECLARE @nombreProducto VARCHAR(100);
	DECLARE @precioUnitario DECIMAL(10,2),
			@precioRef DECIMAL(10,2);
	DECLARE @unidadRef VARCHAR(10);
	DECLARE @campoAParsear VARCHAR(MAX);

	CREATE TABLE #aux
	(
		id VARCHAR(MAX),
		categoria VARCHAR(MAX),
		campo VARCHAR(MAX)
	)
	CREATE TABLE #ProductoAux
	(
		fila INT,
		clasificacion VARCHAR(35),
		nombre VARCHAR(100),
		precioUnitario DECIMAL(10,2),
		precioRef DECIMAL(10,2),
		unidadRef VARCHAR(10),
	)
	
	DECLARE @SqlDinamico NVARCHAR(MAX);
	SET @SqlDinamico = 'BULK INSERT #aux
					FROM '''+ @rutaArchivo +'''
					WITH
					(
						FIELDTERMINATOR = '','',
						ROWTERMINATOR = ''0x0A'',
						CODEPAGE=''ACP'',
						FIRSTROW = 2
					)';
	EXEC sp_executesql @SqlDinamico;

	--SELECT * FROM #aux
	
	--Primero parseamos los productos con comillas
	DECLARE cursorProductosConComillas CURSOR FOR
		SELECT id,categoria,campo FROM #aux WHERE CHARINDEX('"',campo,1) = 1

	OPEN cursorProductosConComillas

	FETCH NEXT FROM cursorProductosConComillas
		INTO @fila,@idClasificacion,@campoAParsear
	WHILE (@@FETCH_STATUS = 0)
	BEGIN
		--Obtenemos el nombre del producto
		SET @nombreProducto = SUBSTRING(@campoAParsear,2,CHARINDEX('"',@campoAParsear,2) - 2);
		-- 1.79,2.98,kg,2020-07-21 12:06:00
		--SET @campoAParsear = SUBSTRING(@campoAParsear,CHARINDEX('"',@campoAParsear,2) + 1, LEN(@campoAParsear));
		SET @campoAParsear = SUBSTRING(@campoAParsear,CHARINDEX('"',@campoAParsear,2) + 2, LEN(@campoAParsear));

		SET @precioUnitario = SUBSTRING(@campoAParsear,1,CHARINDEX(',',@campoAParsear,1) - 1);
		---- 2.98,kg,2020-07-21 12:06:00
		SET @campoAParsear = SUBSTRING(@campoAParsear,CHARINDEX(',',@campoAParsear,1) + 1, LEN(@campoAParsear));

		SET @precioRef = SUBSTRING(@campoAParsear,1,CHARINDEX(',',@campoAParsear,1) - 1);

		SET @campoAParsear = SUBSTRING(@campoAParsear,CHARINDEX(',',@campoAParsear,1) + 1, LEN(@campoAParsear));
		
		SET @unidadRef = SUBSTRING(@campoAParsear,1,CHARINDEX(',',@campoAParsear,1) - 1);

		INSERT INTO #ProductoAux VALUES (@fila,@idClasificacion,@nombreProducto,@precioUnitario,@precioRef,@unidadRef);
		
		FETCH NEXT FROM cursorProductosConComillas
			INTO @fila,@idClasificacion,@campoAParsear
	END
	CLOSE cursorProductosConComillas
	DEALLOCATE cursorProductosConComillas

	--Ahora parseamos los productos sin comillas
	DECLARE cursorProdSinComillas CURSOR FOR
		SELECT id,categoria,campo FROM #aux WHERE CHARINDEX('"',campo,1) = 0
	OPEN cursorProdSinComillas
	FETCH NEXT FROM cursorProdSinComillas
		INTO @fila,@idClasificacion,@campoAParsear
	WHILE (@@FETCH_STATUS = 0)
	BEGIN
		--Obtenemos el nombre del producto
		SET @nombreProducto = SUBSTRING(@campoAParsear,1,CHARINDEX(',',@campoAParsear,1) - 1);
		SET @campoAParsear =SUBSTRING(@campoAParsear,CHARINDEX(',',@campoAParsear,1) + 1, LEN(@campoAParsear));

		SET @precioUnitario = SUBSTRING(@campoAParsear,1,CHARINDEX(',',@campoAParsear,1) - 1);
		---- 2.98,kg,2020-07-21 12:06:00
		SET @campoAParsear = SUBSTRING(@campoAParsear,CHARINDEX(',',@campoAParsear,1) + 1, LEN(@campoAParsear));

		SET @precioRef = SUBSTRING(@campoAParsear,1,CHARINDEX(',',@campoAParsear,1) - 1);

		SET @campoAParsear = SUBSTRING(@campoAParsear,CHARINDEX(',',@campoAParsear,1) + 1, LEN(@campoAParsear));
		
		SET @unidadRef = SUBSTRING(@campoAParsear,1,CHARINDEX(',',@campoAParsear,1) - 1);

		INSERT INTO #ProductoAux VALUES (@fila,@idClasificacion,@nombreProducto,@precioUnitario,@precioRef,@unidadRef);
		
		FETCH NEXT FROM cursorProdSinComillas
			INTO @fila,@idClasificacion,@campoAParsear
	END
	CLOSE cursorProdSinComillas;
	DEALLOCATE cursorProdSinComillas;


	/*
		CREATE TABLE #ProductoAux
	(
		fila INT,
		clasificacion INT,
		nombre VARCHAR(100),
		precioUnitario DECIMAL(10,2),
		precioRef DECIMAL(10,2),
		unidadRef VARCHAR(10),
	)
	*/
	--1.20 16.00

	WITH ProductosRepetidosCTE AS
	(
	SELECT ROW_NUMBER() OVER (PARTITION BY nombre ORDER BY fila DESC) AS repetidos FROM #ProductoAux
	)
	DELETE FROM ProductosRepetidosCTE WHERE repetidos > 1;
			
	UPDATE #ProductoAux
		SET clasificacion = c.idClasificacion
		FROM #ProductoAux p JOIN Producto.Clasificacion c ON clasificacion LIKE nombreClasificacion COLLATE Modern_Spanish_CI_AI
	
	--Arreglamos las "á"
	UPDATE #ProductoAux
		SET nombre = REPLACE(nombre,'Ã¡','á');
	--Arreglamos las "é"
	UPDATE #ProductoAux--Pepino holandÃ©s
		SET nombre = REPLACE(nombre,'Ã©','é');
	--Arreglamos las "ó"
	UPDATE #ProductoAux
		SET nombre = REPLACE(nombre,'Ã³','ó');	
	--Arreglamos las "ú"
	UPDATE #ProductoAux--Filete de atÃºn
		SET nombre = REPLACE(nombre,'Ãº','ú');
	--Arreglamos las "í"
	UPDATE #ProductoAux--Ñ
		SET nombre = REPLACE(nombre,'Ã','í');
	--Arreglamos las ñ
	UPDATE #ProductoAux--Ã‘oras Hacendado
		SET nombre = REPLACE(nombre,'Ã‘','ñ');

	SELECT * FROM #ProductoAux
	--SELECT * FROM #aux
	DROP TABLE #ProductoAux
	DROP TABLE #aux
END;
GO 
exec Producto.importarCatalogoCSV 'C:\Users\joela\Downloads\TP_integrador_Archivos\Productos\catalogo.csv'
GO
SELECT * FROM Producto.Clasificacion
--23,fruta,Naranjas,3.79,1.26,kg,2020-07-21 12:06:00



DECLARE @campoAParsear VARCHAR(MAX) = '"Pimientos tricolor rojo, amarillo y verde",1.79,2.98,kg,2020-07-21 12:06:00'
print SUBSTRING(@campoAParsear,2,CHARINDEX('"',@campoAParsear,2) - 2);
SET @campoAParsear = SUBSTRING(@campoAParsear,CHARINDEX('"',@campoAParsear,2)+2, LEN(@campoAParsear));
print @campoAParsear
print SUBSTRING(@campoAParsear,1,CHARINDEX(',',@campoAParsear,1) - 1)

/*
		SET @nombreProducto = SUBSTRING(@campoAParsear,2,CHARINDEX('"',@campoAParsear,2) - 2);
		-- 1.79,2.98,kg,2020-07-21 12:06:00
		--SET @campoAParsear = SUBSTRING(@campoAParsear,CHARINDEX('"',@campoAParsear,2) + 1, LEN(@campoAParsear));
		SET @campoAParsear = SUBSTRING(@campoAParsear,CHARINDEX(',',@campoAParsear,1) + 1, LEN(@campoAParsear));

		SET @precioUnitario = SUBSTRING(@campoAParsear,1,CHARINDEX(',',@campoAParsear,1) - 1);
		---- 2.98,kg,2020-07-21 12:06:00
		SET @campoAParsear = SUBSTRING(@campoAParsear,CHARINDEX(',',@campoAParsear,1) + 1, LEN(@campoAParsear));

		SET @precioRef = SUBSTRING(@campoAParsear,1,CHARINDEX(',',@campoAParsear,1) - 1);

		SET @campoAParsear = SUBSTRING(@campoAParsear,CHARINDEX(',',@campoAParsear,1) + 1, LEN(@campoAParsear));
		
		SET @unidadRef = SUBSTRING(@campoAParsear,1,CHARINDEX(',',@campoAParsear,1) - 1);
*/


DECLARE @x VARCHAR(MAX) = 'Naranjas,3.79,1.26,kg,2020-07-21 12:06:00'
SELECT REVERSE(@x),
SUBSTRING(REVERSE(@x),CHARINDEX(',',REVERSE(@x),1) + 1,LEN(@x)),
SUBSTRING(SUBSTRING(REVERSE(@x),CHARINDEX(',',REVERSE(@x),1) + 1,LEN(@x)),1,CHARINDEX(',',SUBSTRING(REVERSE(@x),CHARINDEX(',',REVERSE(@x),1) - 1,LEN(@x)),1))

SUBSTRING(SUBSTRING(REVERSE(@x),CHARINDEX(',',REVERSE(@x),1) + 1,LEN(@x)),CHARINDEX(',',SUBSTRING(REVERSE(@x),CHARINDEX(',',REVERSE(@x),1) + 1,LEN(@x)),1) + 1,LEN(@x))


SUBSTRING(SUBSTRING(REVERSE(@x),CHARINDEX(',',REVERSE(@x),1) + 1,LEN(@x)),CHARINDEX(',',SUBSTRING(REVERSE(@x),CHARINDEX(',',REVERSE(@x),1) + 1,LEN(@x)),1) + 1,LEN(@x))

SUBSTRING(REVERSE(@x),CHARINDEX(',',REVERSE(@x),1) + 1,LEN(@x)),

  SUBSTRING(REVERSE(@x),CHARINDEX(',',REVERSE(@x),1) + 1,LEN(@x))

--SUBSTRING(@campo,2,CHARINDEX('"',@campo,2) - 2)
DECLARE @var VARCHAR(MAX) = '"Jorge"XD'
print SUBSTRING(@var,CHARINDEX('"',@var,2) + 1,LEN(@var))
print SUBSTRING(@var,2,CHARINDEX('"',@var,2) - 2)
print SUBSTRING(@var,2,LEN(@var))
print CHARINDEX('"',@var,1)

--id,category,name,price,reference_price,reference_unit,date		


GO
--		SELECT * FROM Producto.Clasificacion
--Importar Accesorios Electronicos
--		DROP PROCEDURE Producto.importarAccesoriosElectronicos
--		SELECT * FROM Producto.Producto
CREATE OR ALTER PROCEDURE Producto.importarAccesoriosElectronicos (@ruta NVARCHAR(MAX))
AS BEGIN
	DECLARE @dolar DECIMAL(6,2);
	CREATE TABLE #ProductoAux
	(
		producto VARCHAR(MAX),
		precio VARCHAR(MAX),
		idClasificacion VARCHAR(MAX)
	)
	DECLARE @SqlDinamico NVARCHAR(MAX);

	SET @SqlDinamico = 'INSERT INTO #ProductoAux (producto,precio)';

	SET @SqlDinamico = @SqlDinamico + ' SELECT *
										FROM OPENROWSET(''Microsoft.ACE.OLEDB.16.0'', 
														''Excel 12.0; Database='+ @ruta +'; HDR=YES'', 
														''SELECT * FROM [Sheet1$]'')'

	EXECUTE sp_executesql @SqlDinamico;


	IF NOT EXISTS(SELECT 1 FROM Producto.Clasificacion WHERE nombreClasificacion LIKE 'Electronico/a')
	BEGIN
		INSERT INTO Producto.Clasificacion (nombreClasificacion,lineaDeProducto) VALUES ('Electronico/a','Tecnologia')
	END

	UPDATE #ProductoAux
		SET idClasificacion = c.idClasificacion
		FROM Producto.Clasificacion c WHERE c.nombreClasificacion LIKE 'Electronico/a'

	 EXEC Producto.pasajeDolarAPesos @dolar OUTPUT;

	INSERT INTO Producto.Producto (idClasificacion,descripcionProducto,precioUnitario,precioReferencia,unidadReferencia,productoActivo)
		SELECT idClasificacion,producto,precio*@dolar,precio*@dolar,'ud',1 FROM #ProductoAux

	--SELECT * FROM #ProductoAux
	DROP TABLE #ProductoAux
END;
exec Producto.importarAccesoriosElectronicos 'C:\Users\joela\Downloads\TP_integrador_Archivos\Productos\Electronic accessories.xlsx'
/*
		SELECT * FROM Producto.Clasificacion
		SELECT * FROM Producto.Producto
*/

GO
--Importar productos importados
--		DROP PROCEDURE Producto.importarProductosImportados
CREATE OR ALTER PROCEDURE Producto.importarProductosImportados (@ruta NVARCHAR(MAX))
AS BEGIN
	DECLARE @dolar DECIMAL(6,2);
	CREATE TABLE #ProductoAux
	(
		producto VARCHAR(MAX),
		precio VARCHAR(MAX),
		categoria VARCHAR(MAX)
	)
	DECLARE @SqlDinamico NVARCHAR(MAX);

	SET @SqlDinamico = 'INSERT INTO #ProductoAux';

	SET @SqlDinamico = @SqlDinamico + ' SELECT NombreProducto,PrecioUnidad,[Categoría]
										FROM OPENROWSET(''Microsoft.ACE.OLEDB.16.0'', 
														''Excel 12.0; Database='+ @ruta +'; HDR=YES'', 
														''SELECT * FROM [Listado de Productos$]'')'

	EXECUTE sp_executesql @SqlDinamico;
	--Agregamos las categorias de Importado
	INSERT INTO Producto.Clasificacion (nombreClasificacion,lineaDeProducto)
		SELECT pa.categoria,'Importado' FROM #ProductoAux pa 
		WHERE NOT EXISTS (
							SELECT 1 FROM Producto.Clasificacion c 
								WHERE c.nombreClasificacion LIKE pa.categoria COLLATE Modern_Spanish_CI_AI
						)
	--Linkeamos las categorias con sus IDs
	UPDATE #ProductoAux
		SET categoria = c.idClasificacion
		FROM #ProductoAux a JOIN Producto.Clasificacion c 
			ON a.categoria LIKE c.nombreClasificacion COLLATE Modern_Spanish_CI_AI
	--Obtenemos el valor del dolar
	EXEC Producto.pasajeDolarAPesos @dolar OUTPUT;

	INSERT INTO Producto.Producto (idClasificacion,descripcionProducto,precioUnitario,precioReferencia,unidadReferencia,productoActivo)
		SELECT categoria,producto,precio * @dolar,precio * @dolar,'ud',1 
			FROM #ProductoAux pa
			WHERE NOT EXISTS(
							 SELECT 1 FROM Producto.Producto p 
								WHERE p.descripcionProducto LIKE pa.producto COLLATE Modern_Spanish_CI_AI
							)
	--SELECT * FROM #ProductoAux
	DROP TABLE #ProductoAux
END;
GO
exec Producto.importarProductosImportados 'C:\Users\joela\Downloads\TP_integrador_Archivos\Productos\Productos_importados.xlsx'
/*
	SELECT * FROM Producto.Clasificacion
	SELECT * FROM Producto.Producto
*/