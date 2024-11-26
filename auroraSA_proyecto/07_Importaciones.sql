USE Com2900G19;
GO
--		USE MASTER
--		DROP DATABASE Com2900G19

--Importamos los medios de pago
--		DROP PROCEDURE Importacion.ArchComplementario_importarMedioMedioDePago
--		SELECT * FROM Venta.MedioDePago
CREATE OR ALTER PROCEDURE Importacion.ArchComplementario_importarMedioDePago (@ruta NVARCHAR(MAX))
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

	INSERT INTO Venta.MedioDePago (nombreMedioDePago,descripcion, medioDePagoActivo)
		SELECT t.*, 1 FROM #MedioDePagoTemp t
			WHERE NOT EXISTS (SELECT 1 FROM Venta.MedioDePago
								WHERE nombreMDP LIKE nombreMedioDePago COLLATE Modern_Spanish_CI_AI
							)
	DROP TABLE #MedioDePagoTemp
END;
GO
--Importar categorias de los productos
--		DROP PROCEDURE Venta.ImportarClasificacionProducto
--		SELECT * FROM Producto.Clasificacion
CREATE OR ALTER PROCEDURE Importacion.ImportarClasificacionProducto (@ruta NVARCHAR(MAX))
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
GO
--Importar Sucursales
--		DROP PROCEDURE Venta.ArchComplementario_importarSucursal
--		SELECT * FROM Sucursal.Sucursal
CREATE OR ALTER PROCEDURE Importacion.ArchComplementario_importarSucursal (@ruta NVARCHAR(MAX))
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
---------------------------------------ImportarEmpleado------------------------
--https://learn.microsoft.com/en-us/sql/relational-databases/in-memory-oltp/implementing-update-with-from-or-subqueries?view=sql-server-ver16
--		DROP PROCEDURE Importacion.ArchComplementario_importarEmpleado
CREATE OR ALTER PROCEDURE Importacion.ArchComplementario_importarEmpleado (@ruta NVARCHAR(MAX))
AS BEGIN
	DECLARE @tabulador CHAR = CHAR(9);--ASCII del tab
	DECLARE @espacio CHAR = CHAR(10);--ASCII del espacio
	DECLARE @genero CHAR;
	DECLARE @DNI CHAR(8);
	DECLARE @nombre VARCHAR(30);
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
	UPDATE #aux
		SET nombre = REPLACE(nombre,@tabulador,' ');
	--Eliminamos los espacios
	UPDATE #aux
		SET emailPersonal = REPLACE(emailPersonal,@espacio,''),
			emailEmpresarial = REPLACE(emailEmpresarial,@espacio,'');
	--Obtenemos el CUIL
	UPDATE #aux
		SET cuil = '20-22222222-3'
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
END
GO
------------------------Importar Catalogo -------------------------------------------
--		DROP PROCEDURE Importacion.importarCatalogoCSV 
--		SELECT * FROM Producto.Producto
--		SELECT * FROM Producto.Clasificacion
--		https://www.experts-exchange.com/questions/29057655/Import-CSV-file-into-SQL-Server.html
CREATE OR ALTER PROCEDURE Importacion.importarCatalogoCSV (@rutaArchivo NVARCHAR(MAX))
AS BEGIN
	DECLARE @valorDelDolar DECIMAL(6,2);

	CREATE TABLE #ProductoAux
	(
		fila INT,
		clasificacion VARCHAR(40),
		nombre VARCHAR(100),
		precioUnitario DECIMAL(10,2),
		precioRef DECIMAL(10,2),
		unidadRef VARCHAR(10),
		fecha DATETIME
	)--id,category,name,price,reference_price,reference_unit,date
	DECLARE @SqlDinamico NVARCHAR(MAX)

	SET @SqlDinamico = 'INSERT #ProductoAux';
	SET @SqlDinamico = @SqlDinamico + ' SELECT *
										FROM OPENROWSET(''Microsoft.ACE.OLEDB.16.0'', 
											''Text; Database='+ @rutaArchivo +'; HDR=YES'', 
											''SELECT * FROM [catalogo.csv]'');';
	EXEC sp_executesql @SqlDinamico;

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
	--Arreglamos las Ñ
	UPDATE #ProductoAux--Ã‘oras Hacendado
		SET nombre = REPLACE(nombre,'Ã‘','Ñ');
	UPDATE #ProductoAux--Filetes de vacuno 1ÂªB aí±ojo
		SET nombre = REPLACE(nombre,'Ã±','ñ');
	--Arreglamos las "í"
	UPDATE #ProductoAux
		SET nombre = REPLACE(nombre,'Ã','í');

	EXEC Producto.pasajeDolarAPesos @valorDelDolar OUTPUT;
		
	INSERT INTO Producto.Producto (idClasificacion,descripcionProducto,precioUnitario,precioReferencia,unidadReferencia,productoActivo)
		SELECT clasificacion,nombre,(precioUnitario/100) * @valorDelDolar,(precioRef/100) * @valorDelDolar,unidadRef,1 FROM #ProductoAux
			WHERE NOT EXISTS (SELECT 1 FROM Producto.Producto WHERE descripcionProducto LIKE nombre COLLATE Modern_Spanish_CI_AI)
			
	--SELECT * FROM #ProductoAux --ORDER BY precioUnitario DESC
	DROP TABLE #ProductoAux
END;
GO 
--Importar Accesorios Electronicos
--		DROP PROCEDURE Importacion.importarAccesoriosElectronicos
--		SELECT * FROM Producto.Producto
CREATE OR ALTER PROCEDURE Importacion.importarAccesoriosElectronicos (@ruta NVARCHAR(MAX))
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
		SELECT idClasificacion,producto,precio*@dolar,precio*@dolar,'ud',1 FROM #ProductoAux pa
		WHERE NOT EXISTS(
							SELECT 1 FROM Producto.Producto p  WHERE p.descripcionProducto LIKE pa.producto COLLATE Modern_Spanish_CI_AI
						)

	--SELECT * FROM #ProductoAux
	DROP TABLE #ProductoAux
END;
GO
--Importar productos importados
--		DROP PROCEDURE Importacion.importarProductosImportados
CREATE OR ALTER PROCEDURE Importacion.importarProductosImportados (@ruta NVARCHAR(MAX))
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
GO
CREATE OR ALTER PROCEDURE Importacion.importar_Ventas (@rutaArchivo NVARCHAR(MAX))
AS BEGIN
	DECLARE @valorDolar DECIMAL(6,2),
			@iva DECIMAL(3,2) = 1.21;
	CREATE TABLE #aux
	(
		id VARCHAR(MAX),
		tipoFactura VARCHAR(MAX),
		ciudad VARCHAR(MAX),
		tipoCliente VARCHAR(MAX),
		Genero VARCHAR(MAX),
		Producto VARCHAR(MAX),
		Precio VARCHAR(MAX),
		Cantidad VARCHAR(MAX),
		Fecha VARCHAR(MAX),
		Hora VARCHAR(MAX),
		MedioDePago VARCHAR(MAX),
		Empleado VARCHAR(MAX),
		IdentificadorDePago VARCHAR(MAX)
	);
	DECLARE @SqlDinamico NVARCHAR(MAX);
	SET @SqlDinamico = 'BULK INSERT #aux
					FROM '''+ @rutaArchivo +'''
					WITH
					(
						FIRSTROW = 2,
						FIELDTERMINATOR = '';'',
						ROWTERMINATOR = ''\n'',
						CODEPAGE=''65001''
					)';
	EXEC sp_executesql @SqlDinamico;

	--Fixeamos las tildes
	UPDATE #aux--PlÃ¡tano macho
		SET Producto = REPLACE(Producto,'Ã¡','á');	
	UPDATE #aux--TÃ© matcha en polvo Hacendado
		SET Producto = REPLACE(Producto,'Ã©','é');
	UPDATE #aux--TÃ³nica zero calorÃ­as Schweppes
		SET Producto = REPLACE(Producto,'Ã³','ó');
	UPDATE #aux
		SET Producto = REPLACE(Producto,'Ãº','ú');
	UPDATE #aux--NÃ©ctar guayaba Hacendado sin azÃºcares aÃ±adidos
		SET Producto = REPLACE(Producto,'Ã±','ñ');
	UPDATE #aux
		SET Producto = REPLACE(Producto,'Ã‘','Ñ');
	UPDATE #aux
		SET Producto = REPLACE(Producto,'Ã','í');
	
	DELETE FROM #aux WHERE NOT EXISTS ( SELECT 1 FROM Producto.Producto WHERE descripcionProducto LIKE Producto COLLATE Modern_SPanish_CI_AI)

	UPDATE #aux
		SET ciudad = 'San Justo'
		WHERE ciudad LIKE 'Yangon'
	UPDATE #aux
		SET ciudad = 'Ramos Mejia'
		WHERE ciudad LIKE 'Naypyitaw'
	UPDATE #aux
		SET ciudad = 'Lomas del Mirador'
		WHERE ciudad LIKE 'Mandalay'

	UPDATE #aux
		SET MedioDePago = m.idMedioDePago
		FROM Venta.MedioDePago m JOIN #aux a ON m.nombreMedioDePago LIKE a.MedioDePago COLLATE Modern_Spanish_CI_AI

	UPDATE #aux
		SET Empleado = e.idEmpleado
		FROM #aux a JOIN Empleado.Empleado e ON CAST(a.Empleado as int) = e.legajo;
		
	UPDATE #aux
		SET ciudad = s.idSucursal
		FROM #aux a JOIN Sucursal.Sucursal s ON a.ciudad LIKE s.localidad COLLATE Modern_Spanish_CI_AI

	INSERT INTO Venta.Venta (idEmpleado,idSucursal,fechaHoraVenta,tipoCliente,estadoVenta)
		SELECT Empleado,ciudad,cast(Fecha as datetime) + cast(Hora as datetime),tipoCliente,'Pagado' 
		FROM #aux a WHERE NOT EXISTS (
										SELECT 1 FROM Venta.Venta v WHERE v.idEmpleado = a.Empleado AND v.idSucursal = a.ciudad AND 
											v.fechaHoraVenta = CAST(Fecha as smalldatetime) + CAST(Hora as smalldatetime)
									)
		
	UPDATE #aux
		SET Producto = p.idProducto
		FROM #aux a JOIN Producto.Producto p ON a.Producto LIKE p.descripcionProducto COLLATE Modern_Spanish_CI_AI
		Select * FROM Venta.Venta

	EXEC Producto.pasajeDolarAPesos @valorDolar OUTPUT;

	INSERT INTO Venta.DetalleVenta (idVenta,idProducto,precioUnitario,cantidad,subtotal)
		SELECT v.idVenta,a.Producto,a.Precio,a.Cantidad,(a.Precio * @valorDolar) * a.Cantidad 
		FROM #aux a JOIN Venta.Venta v 
			ON v.idEmpleado = a.Empleado AND v.idSucursal = a.ciudad AND v.fechaHoraVenta = CAST(Fecha as smalldatetime) + CAST(Hora as smalldatetime)
		WHERE NOT EXISTS(SELECT 1 FROM Venta.DetalleVenta dv WHERE dv.idVenta = v.idVenta AND dv.idProducto = a.Producto)
	
	INSERT INTO Venta.Factura (idVenta,tipoFactura,fechaHora,idMedioDepago,identificadorDePago,estadoDeFactura,totalConIva,totalSinIva,cuit)
		SELECT v.idVenta,a.tipoFactura,v.fechaHoraVenta,a.MedioDePago,a.IdentificadorDePago,'Pagado',@iva* (a.Cantidad * (a.Precio * @valorDolar)),a.Cantidad * (a.Precio * @valorDolar),s.cuit 
		FROM #aux a JOIN Venta.Venta v 
			ON v.idEmpleado = a.Empleado AND v.idSucursal = a.ciudad AND v.fechaHoraVenta = CAST(Fecha as smalldatetime) + CAST(Hora as smalldatetime)
			JOIN Sucursal.Sucursal s ON v.idSucursal = s.idSucursal
		WHERE NOT EXISTS(
			SELECT 1 FROM Venta.Factura f WHERE f.idVenta = v.idVenta
		)
		
	DROP TABLE #aux
END
GO

/*

SELECT * FROM Empleado.Empleado

SELECT * FROM Producto.Producto

SELECT * FROM Producto.Clasificacion

SELECT * FROM Venta.Venta

SELECT * FROM Venta.DetalleVenta

SELECT * FROM Venta.Factura

SELECT * FROM Venta.MedioDePago
*/

/*
SELECT * FROM Empleado.Empleado
exec Importacion.ArchComplementario_importarSucursal 'C:\Users\joela\Downloads\TP_integrador_Archivos\Informacion_complementaria.xlsx'
exec Importacion.ArchComplementario_importarMedioDePago 'C:\Users\joela\Downloads\TP_integrador_Archivos\Informacion_complementaria.xlsx'
exec Importacion.ArchComplementario_importarEmpleado 'C:\Users\joela\Downloads\TP_integrador_Archivos\Informacion_complementaria.xlsx'
exec Importacion.ImportarClasificacionProducto 'C:\Users\joela\Downloads\TP_integrador_Archivos\Informacion_complementaria.xlsx'
exec Importacion.importarCatalogoCSV 'C:\Users\joela\Downloads\TP_integrador_Archivos\Productos\'
exec Importacion.importarAccesoriosElectronicos 'C:\Users\joela\Downloads\TP_integrador_Archivos\Productos\Electronic accessories.xlsx'
exec Importacion.importarProductosImportados 'C:\Users\joela\Downloads\TP_integrador_Archivos\Productos\Productos_importados.xlsx'
exec Importacion.importar_Ventas 'C:\Users\joela\Downloads\TP_integrador_Archivos\Ventas_registradas.csv'
*/