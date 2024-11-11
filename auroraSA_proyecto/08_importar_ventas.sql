
IF EXISTS (SELECT * FROM sys.databases WHERE name = 'Com2900G19')
	USE Com2900G19
ELSE
	RAISERROR('Este script est� dise�ado para que se ejecute despues del script de la creacion de tablas y esquemas.',20,1);
GO

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
GO

CREATE OR ALTER PROCEDURE Factura.importarFacturas (@rutaArch NVARCHAR(MAX))
AS
BEGIN
    DECLARE @SqlDinamico NVARCHAR(MAX);
    
    CREATE TABLE #aux (
        idFactura NVARCHAR(MAX),
        tipoFactura NVARCHAR(MAX),
        ciudad NVARCHAR(MAX),
        tipoCliente NVARCHAR(MAX),
        genero NVARCHAR(MAX),
        producto NVARCHAR(MAX),
        preciounitario NVARCHAR(MAX),
        cantidad NVARCHAR(MAX),
        fecha NVARCHAR(MAX),
        hora NVARCHAR(MAX),
        medioDePago NVARCHAR(MAX),
        empleado NVARCHAR(MAX),
        idDePago NVARCHAR(MAX)
    );
    
    SET @SqlDinamico = N'BULK INSERT #aux
        FROM ''' + @rutaArch + '''
        WITH (
		 DATAFILETYPE = ''widechar'', 
            FIELDTERMINATOR = '';'', 
            CODEPAGE = ''65001'', 
            FIRSTROW = 2
        );';
    EXEC sp_executesql @SqlDinamico;
	
    UPDATE #aux 
		SET producto = REPLACE(producto, 'á', 'a');		
    UPDATE #aux 
		SET producto = REPLACE(producto, 'é', 'e');
    UPDATE #aux 
		SET producto = REPLACE(producto, 'í', 'i');
    UPDATE #aux 
		SET producto = REPLACE(producto, 'ó', 'o');
    UPDATE #aux 
		SET producto = REPLACE(REPLACE(producto, 'Ãº', 'u'),'ú','u');
    UPDATE #aux 
		SET producto = REPLACE(REPLACE(producto, 'ñ', '�'),'単','�');
	UPDATE #aux
		SET idDePago = SUBSTRING(idDePago,2,LEN(idDePago))
		WHERE CHARINDEX('-',idDePago,1) = 0;

	UPDATE #aux
		SET ciudad = 'San Justo'
		WHERE ciudad LIKE 'Yangon'
	UPDATE #aux
		SET ciudad = 'Ramos Mejia'
		WHERE ciudad LIKE 'Naypyitaw'
	UPDATE #aux
		SET ciudad = 'Lomas del Mirador'
		WHERE ciudad LIKE 'Mandalay';

	--SELECT * FROM #aux;
	WITH ProductosInexistentesCTE AS
	(
		SELECT * FROM #aux a 
			WHERE NOT EXISTS (
								SELECT 1 FROM Producto.Producto p
									WHERE p.descripcionProducto = a.producto COLLATE Modern_Spanish_CI_AI
							)
	)
	DELETE FROM ProductosInexistentesCTE;
	
	WITH FacturaCTE AS 
	(
		SELECT idFactura AS id,medioDePago,producto,ciudad FROM #aux
	),
	SucursalCTE AS
	(
		SELECT id,medioDePago,producto,d.idSucursal 
			FROM FacturaCTE f JOIN Direccion.verDireccionesDeSucursales d
				ON f.ciudad LIKE d.localidad COLLATE Modern_Spanish_CI_AI
	)
	, NombreProductoCTE (idFactura,medioDePago,idProducto,idSucursal) AS
	(
		SELECT f.id,f.medioDePago,p.idProducto,f.idSucursal 
			FROM SucursalCTE f JOIN Producto.Producto p
				ON f.producto LIKE p.descripcionProducto COLLATE Modern_Spanish_CI_AI
	), NombreMedioDePagoCTE AS
	(
		SELECT p.idFactura,p.idProducto,m.idMedioDePago,p.idSucursal
			FROM NombreProductoCTE p JOIN Factura.MedioDePago m
				ON p.medioDePago LIKE m.nombreMedioDePago COLLATE Modern_Spanish_CI_AI
	),FacturaAInsertarCTE AS
	(
		SELECT  tipoFactura,tipoCliente,genero,CAST(cantidad as smallint) as cantidad,CONVERT(smalldatetime,fecha) + CONVERT(smalldatetime,hora) AS Fecha,n.idProducto,n.idMedioDePago,empleado,idSucursal,idDePago
			FROM NombreMedioDePagoCTE n JOIN (
												SELECT idFactura,tipoFactura,
														tipoCliente,genero,cantidad,fecha,hora,empleado,idDePago FROM #aux
											) AS a
				ON n.idFactura LIKE a.idFactura
	)
	INSERT INTO Factura.Factura (tipoFactura,tipoCliente,genero,cantidad,fechaHora,idProducto,idMedioDepago,legajo,idSucursal,identificadorDePago)
		SELECT * FROM FacturaAInsertarCTE

    DROP TABLE #aux;
END;
GO