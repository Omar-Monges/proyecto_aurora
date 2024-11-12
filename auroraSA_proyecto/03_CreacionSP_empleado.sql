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

--Esquema Factura
*/
USE Com2900G19

--  USE master
--DROP DATABASE G2900G19

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
													@provincia VARCHAR(255))
AS BEGIN
	DECLARE @cuil VARCHAR(13);
	DECLARE @altaEmpleado bit = 1;

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

	IF (@calle IS NULL OR LEN(LTRIM(@calle)) = 0 OR @localidad IS NULL OR LEN(LTRIM(@localidad)) = 0 OR 
		LEN(LTRIM(@codPostal)) = 0 OR @provincia IS NULL OR LEN(LTRIM(@provincia)) = 0)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarEmpleado. El formato de la direccion es inválida.',16,1);
		RETURN;
	END;

	IF(@codPostal IS NULL)
		EXEC Direccion.obtenerCodigoPostal @localidad, @codPostal OUTPUT;

	IF @codPostal IS NULL
		SET @codPostal = COALESCE(@codPostal,'-');
	SET @cuil = Empleado.calcularCUIL(@dni,@sexo);
	SET @emailEmpresa = REPLACE(@emailEmpresa,' ','');
	SET @emailPersonal = REPLACE(@emailPersonal,' ','');
	INSERT INTO Empleado.Empleado(dni,nombre,apellido,emailPersonal,emailEmpresarial,idSucursal,turno,idCargo,cuil, empleadoActivo) 
				VALUES(@dni,@nombre,@apellido,@emailPersonal,@emailEmpresa,@idSucursal,@idTurno,@idCargo,@cuil, @altaEmpleado);

END;
GO
---Modificar Empleado
--DROP PROCEDURE Empleado.modificarEmpleado
CREATE OR ALTER PROCEDURE Empleado.modificarEmpleado(@legajo INT, @nombre VARCHAR(255), @apellido VARCHAR(255) = NULL,
													@emailPersonal VARCHAR(60)=NULL, @emailEmpresarial VARCHAR(60)=NULL, @turno char(20)=NULL,
													@idCargo INT = NULL, @direccion varchar(100), @codPostal varchar(10) = NULL, @localidad VARCHAR(50) = NULL,
													@provincia VARCHAR(50) = NULL)
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
	IF (LEN(LTRIM(@turno)) = 0)
	BEGIN
		RAISERROR ('Error en el procedimiento almacenado modificarEmpleado. Los datos del empleados son inválidos.',16,9);
		RETURN;
	END
	IF (LEN(LTRIM(@localidad)) = 0)
	BEGIN
		RAISERROR ('Error en el procedimiento almacenado modificarEmpleado. Los datos del empleados son inválidos.',16,9);
		RETURN;
	END
	IF(LEN(LTRIM(@provincia))  = 0)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado modificarEmpleado. El formato de la provincia es inválido',16,9);
		RETURN;
	END
	IF (LEN(LTRIM(@direccion)) = 0)
	BEGIN
		RAISERROR ('Error en el procedimiento almacenado modificarEmpleado. Los datos del empleados son inválidos.',16,9);
		RETURN;
	END
	IF NOT EXISTS (SELECT 9 FROM Sucursal.Cargo WHERE idCargo = @idCargo)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado modificarEmpleado. El cargo no existe',16,9);
		RETURN;
	END
	IF (@emailEmpresarial NOT LIKE '%_@__%.__%')
	BEGIN
		RAISERROR('Error en el procedimiento almacenado modificarEmpleado. El cargo no existe',16,9);
		RETURN;
	END
	IF (@emailPersonal NOT LIKE '%_@__%.__%')
	BEGIN
		RAISERROR('Error en el procedimiento almacenado modificarEmpleado. El cargo no existe',16,9);
		RETURN;
	END

	UPDATE Empleado.Empleado
			SET nombre = COALESCE(@nombre,nombre),
				apellido = COALESCE(@apellido,apellido),
				emailPersonal = COALESCE(@emailPersonal,emailPersonal),
				emailEmpresarial = COALESCE(@emailEmpresarial,emailEmpresarial),
				turno = COALESCE(@turno,turno),
				idCargo = COALESCE(@idCargo,idCargo),
				direccion = COALESCE(@direccion,direccion),
				localidad = COALESCE(@localidad,localidad),
				provincia = COALESCE(@provincia,provincia),
				codPostal = COALESCE(@codPostal,codPostal)
	WHERE legajo = @legajo;
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
			direccion, codPostal, localidad, provincia
	FROM Empleado.Empleado
GO