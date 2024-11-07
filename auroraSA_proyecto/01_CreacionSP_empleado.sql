/*
--Lista Codigo de errores:
	1 -> agregarEmpleado
	2 -> agregarSucursal
	3 -> agregarCargo
	4 -> agregarTurno
	5 -> agregarProducto
	6 -> agregarTipoDeProducto
*/
/*
--Esquema Dirección
	verDireccionesDeEmpleados ->vemos las direcciones de los empleados
	verDireccionesDeSucursales -> vemos las direcciones de las sucursales
	
--Esquema Empleado
	calcularCUIL -> devuelve el CUIL de un empleado

	agregarEmpleado
	modificarEmpleado
	eliminarEmpleado

	verDatosEmpleados -> vemos los datos de los empleados junto a su turno,cargo y sucursal en la que trabaja.
	verDatosPersonalesDeEmpleados -> vemos los datos personales

--Esquema Sucursal
	Tabla Sucursal	
		agregarSucursal
		modificarSucursal
		eliminarSucursal

		verSucursales
		verEmpleadosDeSucursales
	Tabla Cargo
		agregarCargo X
		modificarCargo X 
		eliminarCargo X

		verCargosDeEmpleados
	Tabla Turno
		agregarTurno
		modificarTurno
		eliminarTurno

		verTurnosDeEmpleados
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

--Esquema Factura
*/
IF EXISTS (SELECT * FROM sys.databases WHERE name = 'Com2900G19')
	USE Com2900G19
ELSE
	RAISERROR('Este script está diseñado para que se ejecute despues del script de la creacion de tablas y esquemas.',20,1);
GO
--  USE master
--DROP DATABASE G2900G19
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
	SELECT @codigoPostal = codPostal FROM OPENJSON(@datos)
	WITH
	(
			lugares NVARCHAR(MAX) '$.places' AS JSON)
			cross apply openjson(lugares) with (
			codPostal Nvarchar(MAX) '$."post code"')

	EXEC sp_configure 'Ole Automation Procedures', 0;
	RECONFIGURE;
	EXEC sp_configure 'show advanced options', 0;
	RECONFIGURE;
	SET NOCOUNT OFF;
END
GO
------------------------------------------------Esquema Empleado------------------------------------------------
--Calcula el cuil de un empleado mediante un DNI y el Sexo:
--	DROP FUNCTION Empleado.calcularCUIL		<--- ¡Primero borrar el procedure agregarEmpleado!
--	DROP PROCEDURE Empleado.agregarEmpleado
--	PRINT Empleado.calcularCUIL('42781944','M')		<--- Salida esperada: 20-42781944-3
CREATE OR ALTER FUNCTION Empleado.calcularCUIL (@dni VARCHAR(8), @sexo CHAR)
RETURNS VARCHAR(13)
AS BEGIN
	DECLARE @aux VARCHAR(10) = '5432765432',
			@dniAux VARCHAR(10);
	DECLARE @digInt TINYINT,
			@cursorIndice TINYINT = 1,
			@resto TINYINT;
	DECLARE @sumador SMALLINT = 0;
	DECLARE @prefijo VARCHAR(2);

	IF (@sexo = 'F')
		SET @prefijo = '27';
	ELSE
		SET @prefijo = '20';
	SET @dniAux = @prefijo + @DNI;
	WHILE (@cursorIndice <= LEN(@dniAux))
	BEGIN
		SET @digInt = CAST(SUBSTRING(@dniAux,@cursorIndice,1) AS TINYINT);
		SET @sumador = @sumador + (@digInt * CAST(SUBSTRING(@aux,@cursorIndice,1) AS TINYINT));
		SET @cursorIndice = @cursorIndice + 1;
	END;
	SET @resto = @sumador % 11;
	IF (@resto = 0)
		RETURN @prefijo + '-' + @dni+'-0';
	IF(@resto = 1)
	BEGIN
		IF (@sexo = 'M')
			RETURN '23-' + @dni + '-9';
		RETURN '23-' + @dni + '-4';
	END
	RETURN @prefijo + '-' + @dni + '-' + CAST((11-@resto) AS CHAR);
END
GO
--Agregar un Empleado
--Drop Empleado.agregarEmpleado
CREATE OR ALTER PROCEDURE Empleado.agregarEmpleado (@dni VARCHAR(8), @nombre VARCHAR(50), @apellido VARCHAR(50),
													@sexo CHAR, @emailPersonal VARCHAR(100)=NULL, @emailEmpresa VARCHAR(100),
													@idSucursal INT, @idTurno INT,@idCargo INT, @calle VARCHAR(255),
													@numCalle SMALLINT, @codPostal VARCHAR(255), @localidad VARCHAR(255),
													@provincia VARCHAR(255), @piso TINYINT = NULL, @numDepto TINYINT = NULL)
AS BEGIN
	--DECLARE @idDireccion INT;
	DECLARE @cuil VARCHAR(13);
	DECLARE @altaEmpleado bit = 1;

	IF (LEN(LTRIM(@nombre)) = 0)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarEmpleado. El formato del Nombre es inválido.',16,1);
		RETURN;
	END;

	IF (LEN(LTRIM(@apellido)) = 0)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarEmpleado. El formato del Apellido es inválido.',16,1);
		RETURN;
	END;

	IF ((LEN(LTRIM(@calle)) = 0 OR LEN(LTRIM(@localidad)) = 0 OR LEN(LTRIM(@codPostal)) = 0 OR LEN(LTRIM(@provincia)) = 0))
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarEmpleado. El formato de la direccion es inválida.',16,1);
		RETURN;
	END;
	
/*
		legajo INT IDENTITY(257020,1),
		dni char(8) NOT NULL,
		cuil char(13) NOT NULL,
		nombre VARCHAR(50) NOT NULL,
		apellido VARCHAR(50) NOT NULL,
		emailPersonal VARCHAR(60) NULL,
		emailEmpresarial VARCHAR(60) NOT NULL,
		localidad varchar(50),
		codPostal varchar(10),
		direccion varchar(100),
		turno char(3),
		empleadoActivo bit,
		idSucursal INT,
		idCargo INT,
*/
	IF(@codPostal IS NULL)
		EXEC Direccion.obtenerCodigoPostal @localidad, @codPostal OUTPUT;
	BEGIN TRY
		SET TRANSACTION ISOLATION LEVEL READ COMMITTED;--Nivel de aislamiento default.
		BEGIN TRANSACTION
		/*
		INSERT INTO Direccion.Direccion(calle,numeroDeCalle,codigoPostal,piso,departamento,localidad,provincia) 
					VALUES(@calle,@numCalle,COALESCE(@codPostal,'-'),@piso,@numDepto,@localidad,@provincia);
		*/

		--SET @idDireccion = (SELECT TOP(1) idDireccion FROM Direccion.Direccion ORDER BY idDireccion DESC);
		SET @cuil = Empleado.calcularCUIL(@dni,@sexo);
		SET @emailEmpresa = REPLACE(@emailEmpresa,' ','');
		SET @emailPersonal = REPLACE(@emailPersonal,' ','');
		INSERT INTO Empleado.Empleado(dni,nombre,apellido,emailPersonal,emailEmpresarial,idSucursal,turno,idCargo,cuil, empleadoActivo) 
					VALUES(@dni,@nombre,@apellido,@emailPersonal,@emailEmpresa,@idSucursal,@idTurno,@idCargo,@cuil, @altaEmpleado);
		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		RAISERROR('Error en el procedimiento almacenado agregarEmpleado. Los datos del empleado son inválidos.',16,1);
	END CATCH
END;
GO
---Modificar Empleado
--DROP PROCEDURE Empleado.modificarEmpleado
CREATE OR ALTER PROCEDURE Empleado.modificarEmpleado(@legajo INT, @nombre VARCHAR(255), @apellido VARCHAR(255) = NULL,
													@emailPersonal VARCHAR(60)=NULL, @emailEmpresarial VARCHAR(60)=NULL, @turno char(3)=NULL,
													@idCargo INT=NULL, @direccion varchar(100), @codPostal SMALLINT = NULL, @localidad VARCHAR(50) = NULL)
AS BEGIN

	IF (LEN(LTRIM(@nombre)) = 0)
	BEGIN
		RAISERROR ('Error en el procedimiento almacenado modificarEmpleado. Los datos del empleados son inválidos.',16,9);
		RETURN
	END
	IF (LEN(LTRIM(@apellido)) = 0)
	BEGIN
		RAISERROR ('Error en el procedimiento almacenado modificarEmpleado. El apellido del empleados son inválidos.',16,9);
		RETURN
	END
	IF (LEN(LTRIM(@turno)) > 3)
	BEGIN
		RAISERROR ('Error en el procedimiento almacenado modificarEmpleado. Los datos del empleados son inválidos.',16,9);
		RETURN;
	END
	IF (LEN(LTRIM(@localidad)) = 0)
	BEGIN
		RAISERROR ('Error en el procedimiento almacenado modificarEmpleado. Los datos del empleados son inválidos.',16,9);
		RETURN;
	END
	IF (LEN(LTRIM(@direccion)) = 0)
	BEGIN
		RAISERROR ('Error en el procedimiento almacenado modificarEmpleado. Los datos del empleados son inválidos.',16,9);
		RETURN;
	END
	
	BEGIN TRY
		SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
		BEGIN TRANSACTION
			UPDATE Empleado.Empleado
					SET nombre = COALESCE(@nombre,nombre),
						apellido = COALESCE(@apellido,apellido),
						emailPersonal = COALESCE(@emailPersonal,emailPersonal),
						emailEmpresarial = COALESCE(@emailEmpresarial,emailEmpresarial),
						turno = COALESCE(@turno,turno),
						idCargo = COALESCE(@idCargo,idCargo),
						direccion = COALESCE(@direccion,direccion)
			WHERE legajo = @legajo;
		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		RAISERROR ('Error en el procedimiento almacenado modificarEmpleado. Los datos del empleados son inválidos.',16,9);
	END CATCH
END
GO
--Eliminar Empleado
--DROP PROCEDURE Empleado.eliminarEmpleado
CREATE OR ALTER PROCEDURE Empleado.eliminarEmpleado(@legajo INT)
AS BEGIN
	

	--SET @idDireccion = (SELECT idDireccion FROM Empleado.Empleado WHERE legajo = @legajo)
	/*
	UPDATE Factura.Factura
		SET legajo = NULL
		WHERE legajo = @legajo
	DELETE FROM Empleado.Empleado
		WHERE legajo = @legajo;
	*/
	UPDATE Empleado.Empleado
		SET empleadoActivo = 0
		WHERE legajo = @legajo

END
GO
--Ver toda la tabla de empleados junto a su turno,cargo y sucursal en la que trabaja.
--DROP VIEW Empleado.verEmpleados
--		SELECT * FROM Empleado.verDatosDeEmpleados
CREATE OR ALTER VIEW Empleado.verDatosDeEmpleados AS
	/*
	WITH EmpleadoCTE AS
	(
		SELECT legajo,idTurno,idCargo,idSucursal,idDireccion 
			FROM Empleado.Empleado
	),CargoCTE (legajo,idDireccion,idSucursal,idTurno,cargo) AS
	(
		SELECT e.legajo,e.idDireccion,e.idSucursal,e.idTurno,c.nombreCargo 
			FROM EmpleadoCTE e JOIN Sucursal.Cargo c ON e.idCargo = c.idCargo
	),TurnoCTE (legajo,idDireccion,idSucursal,turno,cargo) AS
	(
		SELECT c.legajo,c.idDireccion,c.idSucursal,c.cargo,t.nombreTurno 
			FROM CargoCTE c JOIN Sucursal.Turno t ON c.idTurno = t.idTurno
	),SucursalCTE (legajo,cargo,turno,idDireccion,sucursal) AS
	(
		SELECT t.legajo,t.cargo,t.turno,t.idDireccion,sucursalDireccion.localidad
			FROM TurnoCTE t JOIN (SELECT s.idSucursal,d.localidad 
									FROM Sucursal.Sucursal s JOIN Direccion.Direccion d
										ON s.idDireccion = d.idDireccion
									) AS sucursalDireccion
				ON t.idSucursal = sucursalDireccion.idSucursal
	),DomicilioCTE AS
	(
		SELECT s.legajo,s.cargo,s.turno,s.sucursal,d.calle,d.numeroDeCalle,d.codigoPostal,
				d.piso,d.departamento,d.localidad,d.provincia
			FROM SucursalCTE s JOIN Direccion.Direccion d 
				ON s.idDireccion = d.idDireccion
	)
	SELECT e.legajo,e.cuil,e.apellido,e.nombre,e.emailEmpresarial,d.calle,d.numeroDeCalle,
			d.piso,d.departamento,d.localidad,d.turno,d.cargo,d.sucursal
		FROM DomicilioCTE d JOIN Empleado.Empleado e 
			ON d.legajo = e.legajo
	*/
	SELECT legajo, cuil, apellido, nombre, emailEmpresarial, e.direccion, e.localidad, turno,
			e.idSucursal, c.nombreCargo
	from Empleado.Empleado e
	INNER JOIN Sucursal.Cargo c on c.idCargo = e.idCargo
GO
--Ver los datos personales de los empleados
--DROP VIEW Empleado.verDatosPersonalesDeEmpleados
--		SELECT * FROM Empleado.verDatosPersonalesDeEmpleados
CREATE OR ALTER VIEW Empleado.verDatosPersonalesDeEmpleados AS
	SELECT legajo, apellido, nombre, cuil, emailEmpresarial, emailPersonal,
			direccion, codPostal, localidad
	FROM Empleado.Empleado
GO