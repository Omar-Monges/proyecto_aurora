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

--Esquema Factura
*/
USE Com2900G19
GO

--  USE master
--DROP DATABASE G2900G19

------------------------------------------------Esquema Empleado------------------------------------------------
--Calcula el cuil de un empleado mediante un DNI y el Sexo:
--	DROP FUNCTION Empleado.calcularCUIL		<--- ¡Primero borrar el procedure agregarEmpleado!
--	DROP PROCEDURE Empleado.agregarEmpleado
--	PRINT Empleado.calcularCUIL('42781944','M')		<--- Salida esperada: 20-42781944-3
-- PRINT Empleado.calcularCUIL('93113720', 'F')
-- PRINT Empleado.calcularCUIL('36508254','F')
CREATE OR ALTER FUNCTION Empleado.calcularCUIL (@dni CHAR(8), @sexo CHAR)
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
--Obtener el genero de un empleado.
--		DROP PROCEDURE Empleado.obtenerGenero
--		DECLARE @genero CHAR;DECLARE @nombre VARCHAR(30) = 'Micaela';EXEC Empleado.ObtenerGenero @nombre,@genero OUTPUT;print @genero
/*

	DECLARE @genero CHAR;DECLARE @nombre VARCHAR(30) = 'Joel',@dni CHAR(8)='42781944';EXEC Empleado.ObtenerGenero @nombre,@genero OUTPUT;SELECT Empleado.calcularCuil(@dni,@genero)

*/


CREATE OR ALTER PROCEDURE Empleado.obtenerGenero (@nombre VARCHAR(30), @genero CHAR OUTPUT)
AS
BEGIN
	DECLARE @generoAux VARCHAR(10);
	DECLARE @url NVARCHAR(336);
	
	IF(@nombre IS NULL)
		RETURN;

	SET @nombre = REPLACE(@nombre,' ','%20');
	SET @nombre = REPLACE(@nombre,'á','a');
	SET @nombre = REPLACE(@nombre,'é','e');
	SET @nombre = REPLACE(@nombre,'í','i');
	SET @nombre = REPLACE(@nombre,'ó','o');
	SET @nombre = REPLACE(@nombre,'ú','u');

	SET @url = 'https://api.genderize.io?name=' + @nombre;

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
	SELECT @generoAux = gender FROM OPENJSON(@datos)
	WITH
	(
			[count] INT '$.count',
			[name] VARCHAR(30) '$.name',
			gender VARCHAR(6) '$.gender',
			probability DECIMAL(3, 2) '$.probability'
	);

	IF (@generoAux LIKE 'female')
		SET @genero = 'F';
	ELSE
		SET @genero = 'M';
END
GO
--Agregar un Empleado
--Drop Empleado.agregarEmpleado
CREATE OR ALTER PROCEDURE Empleado.agregarEmpleado (
								@dni VARCHAR(8)				= NULL, @nombre VARCHAR(50)			= NULL,
								@apellido VARCHAR(50)		= NULL, @sexo CHAR					= NULL,
								@emailPersonal VARCHAR(100)	= NULL, @emailEmpresa VARCHAR(100)	= NULL,
								@idSucursal INT				= NULL, @turno VARCHAR(20)			= NULL,
								@cargo VARCHAR(30)			= NULL, @direccion VARCHAR(100)		= NULL
													)
AS BEGIN
	DECLARE @cuil VARCHAR(13), @altaEmpleado BIT = 1, @idCargo INT
	IF(@dni IS NULL OR @dni NOT LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]')
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarEmpleado. EL formato del DNI es inválido.',16,1);
		RETURN;
	END
	IF (@nombre IS NULL OR LEN(LTRIM(@nombre)) = 0)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarEmpleado. El formato del Nombre es inválido.',16,1);
		RETURN;
	END;

	IF (@apellido IS NULL OR LEN(LTRIM(@apellido)) = 0)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarEmpleado. El formato del Apellido es inválido.',16,1);
		RETURN;
	END;
	IF (@direccion IS NULL OR LEN(LTRIM(@direccion)) = 0)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarEmpleado. El formato de la direccion es inválido.',16,1);
		RETURN;
	END
	IF (@emailPersonal IS NULL OR LEN(LTRIM(@emailPersonal)) = 0 OR @emailPersonal NOT LIKE '%_@__%.__%')
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarEmpleado. El email personal es inválido.',16,1);
		RETURN;
	END
	IF (@emailEmpresa IS NULL OR LEN(LTRIM(@emailEmpresa)) = 0 OR @emailEmpresa NOT LIKE '%_@superA.com')
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarEmpleado. El email de empresa es inválido.',16,1);
		RETURN;
	END
	IF (@idSucursal IS NULL OR NOT EXISTS(SELECT 1 FROM Sucursal.Sucursal WHERE idSucursal = @idSucursal))
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarEmpleado. La sucursal es inválido.',16,1);
		RETURN;
	END
	IF (@turno IS NULL OR LEN(LTRIM(@turno)) = 0)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarEmpleado. El turno es inválido.',16,1);
		RETURN;
	END
	IF (@cargo IS NULL OR LEN(LTRIM(@direccion)) = 0)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarEmpleado. El cargo es inválido.',16,1);
		RETURN;
	END
	IF NOT EXISTS(SELECT 1 FROM Sucursal.Cargo WHERE nombreCargo LIKE @cargo)
	BEGIN
		--El cargo no existe lo damos de alta?
		RAISERROR('Error en el procedimiento almacenado agregarEmpleado. El cargo es inválido.',16,1);
		RETURN;
	END
	SET @idCargo = (SELECT idCargo FROM Sucursal.Cargo WHERE nombreCargo = @cargo)
	SET @cuil = Empleado.calcularCUIL(@dni,@sexo);

	SET @emailEmpresa = REPLACE(@emailEmpresa,' ','');
	SET @emailPersonal = REPLACE(@emailPersonal,' ','');
	IF EXISTS(SELECT 1 FROM Empleado.Empleado WHERE dni = @dni AND cuil = @cuil AND empleadoActivo = 0)
	BEGIN
		-- El empleado existe y lo damos de alta
		--DECLARE @id INT = (SELECT idEmpleado FROM Empleado.Empleado WHERE dni = @dni AND cuil = @cuil)
		UPDATE Empleado.Empleado
			SET empleadoActivo = @altaEmpleado,
				nombre = @nombre,
				apellido = @apellido,
				emailPersonal = @emailPersonal,
				emailEmpresarial = @emailEmpresa,
				direccion = @direccion,
				idSucursal = @idSucursal,
				turno = @turno,
				idCargo = @idCargo
		WHERE dni = @dni AND cuil = @cuil
		RETURN
	END
	INSERT INTO Empleado.Empleado(dni,nombre,apellido,emailPersonal,emailEmpresarial,direccion,idSucursal,turno,idCargo,cuil, empleadoActivo) 
							VALUES(@dni,@nombre,@apellido,@emailPersonal,@emailEmpresa,@direccion,@idSucursal,@turno,@idCargo,@cuil, @altaEmpleado);

END;
GO
---Modificar Empleado
--DROP PROCEDURE Empleado.modificarEmpleado
CREATE OR ALTER PROCEDURE Empleado.modificarEmpleado(
									@idEmpleado INT				= NULL, @legajo INT						= NULL,
									@nombre VARCHAR(255)		= NULL, @apellido VARCHAR(255)			= NULL,
									@emailPersonal VARCHAR(60)	= NULL, @emailEmpresa VARCHAR(60)		= NULL,
									@turno CHAR(20)				= NULL, @idCargo INT					= NULL,
									@direccion VARCHAR(100)		= NULL, @dni VARCHAR(8)					= NULL,
									@idSucursal INT				= NULL
													)
AS BEGIN
	IF(@dni IS NOT NULL AND @dni NOT LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]')
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarEmpleado. EL formato del DNI es inválido.',16,1);
		RETURN;
	END
	IF (@nombre IS NOT NULL AND LEN(LTRIM(@nombre)) = 0)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarEmpleado. El formato del Nombre es inválido.',16,1);
		RETURN;
	END;

	IF (@apellido IS NOT NULL AND LEN(LTRIM(@apellido)) = 0)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarEmpleado. El formato del Apellido es inválido.',16,1);
		RETURN;
	END;
	IF (@direccion IS NOT NULL AND LEN(LTRIM(@direccion)) = 0)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarEmpleado. El formato de la direccion es inválido.',16,1);
		RETURN;
	END
	IF (@emailPersonal IS NOT NULL AND LEN(LTRIM(@emailPersonal)) = 0)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarEmpleado. El email personal es inválido.',16,1);
		RETURN;
	END
	IF (@emailEmpresa IS NOT NULL AND LEN(LTRIM(@emailEmpresa)) = 0)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarEmpleado. El email de empresa es inválido.',16,1);
		RETURN;
	END
	IF (@idSucursal IS NOT NULL AND NOT EXISTS(SELECT 1 FROM Sucursal.Sucursal WHERE idSucursal = @idSucursal))
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarEmpleado. La sucursal es inválido.',16,1);
		RETURN;
	END
	IF (@turno IS NOT NULL AND LEN(LTRIM(@turno)) = 0)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarEmpleado. El turno es inválido.',16,1);
		RETURN;
	END

	UPDATE Empleado.Empleado
			SET nombre = COALESCE(@nombre,nombre),
				apellido = COALESCE(@apellido,apellido),
				emailPersonal = COALESCE(@emailPersonal,emailPersonal),
				emailEmpresarial = COALESCE(@emailEmpresa,emailEmpresarial),
				turno = COALESCE(@turno,turno),
				idCargo = COALESCE(@idCargo,idCargo),
				direccion = COALESCE(@direccion,direccion)
	WHERE legajo = @legajo OR idEmpleado = @idEmpleado;
END
GO
--Eliminar Empleado
--DROP PROCEDURE Empleado.eliminarEmpleado
CREATE OR ALTER PROCEDURE Empleado.eliminarEmpleado(@idEmpleado INT)
AS BEGIN
	UPDATE Empleado.Empleado
		SET empleadoActivo = 0
		WHERE idEmpleado = @idEmpleado
END
GO
--DROP PROCEDURE Empleado.eliminarEmpleadoConLegajo
CREATE OR ALTER PROCEDURE Empleado.eliminarEmpleadoConLegajo(@legajo INT)
AS BEGIN
	UPDATE Empleado.Empleado
		SET empleadoActivo = 0
		WHERE legajo = @legajo
END
GO
--Ver toda la tabla de empleados junto a su turno,cargo y sucursal en la que trabaja.
--DROP VIEW Empleado.verEmpleados
--		SELECT * FROM Empleado.verDatosDeEmpleados
CREATE OR ALTER VIEW Empleado.verDatosDeEmpleados AS
	SELECT idEmpleado, legajo, cuil, apellido, nombre, emailEmpresarial, e.direccion, turno,
			e.idSucursal, c.nombreCargo
	from Empleado.Empleado e
	INNER JOIN Sucursal.Cargo c on c.idCargo = e.idCargo
	WHERE e.empleadoActivo = 1
GO
--Ver los datos personales de los empleados
--DROP VIEW Empleado.verDatosPersonalesDeEmpleados
--		SELECT * FROM Empleado.verDatosPersonalesDeEmpleados
CREATE OR ALTER VIEW Empleado.verDatosPersonalesDeEmpleados AS
	SELECT idEmpleado, legajo, apellido, nombre, cuil, emailEmpresarial, emailPersonal, direccion
	FROM Empleado.Empleado
GO