USE Com2900G19
GO
--  use master
-- drop database Com2900G19
------------------------------------------------Esquema Dirección------------------------------------------------
--Ver los domicilios de todos los empleados.
--DROP VIEW Direccion.verDomiciliosDeEmpleados
--		SELECT * FROM Direccion.verDomiciliosDeEmpleados
CREATE OR ALTER VIEW Direccion.verDomiciliosDeEmpleados AS
	SELECT legajo, nombre, apellido, direccion, localidad, codPostal FROM Empleado.Empleado;
GO
--Ver las direcciones de todas las sucursales
--DROP VIEW Direccion.verDireccionesDeSucursales
--		SELECT *  FROM Direccion.verDireccionesDeSucursales
CREATE OR ALTER VIEW Direccion.verDireccionesDeSucursales AS
	select idSucursal, telefono, localidad, codPostal, direccion, horario from Sucursal.Sucursal
GO
--Obtener un codigo Postal mediante una API
--https://api.zippopotam.us/ar/buenos%20aires/laferrere
--https://www.geonames.org/postalcode-search.html?q=san+isidro&country=AR
--DROP CREATE OR ALTER PROCEDURE Direccion.obtenerCodigoPostal
--DECLARE @codPostal VARCHAR(10);EXEC Direccion.obtenerCodigoPostal 'Laferrere',@codPostal OUTPUT; print @codPostal
CREATE OR ALTER PROCEDURE Direccion.obtenerCodigoPostal (@ciudad VARCHAR(50),@codigoPostal varchar(10) OUTPUT)
AS BEGIN
	SET @ciudad = REPLACE(@ciudad,' ','%20');
	
	SET @ciudad = REPLACE(@ciudad,'á','a');
	SET @ciudad = REPLACE(@ciudad,'é','e');
	SET @ciudad = REPLACE(@ciudad,'í','i');
	SET @ciudad = REPLACE(@ciudad,'ó','o');
	SET @ciudad = REPLACE(@ciudad,'ú','u');
	
	DECLARE @url NVARCHAR(336) = 'https://api.zippopotam.us/ar/buenos%20aires/'+ @ciudad;

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
	SELECT @codigoPostal = codPostal FROM OPENJSON(@datos)
	WITH
	(
			lugares NVARCHAR(MAX) '$.places' AS JSON)
			cross apply openjson(lugares) with (
			codPostal Nvarchar(MAX) '$."post code"')
END
GO