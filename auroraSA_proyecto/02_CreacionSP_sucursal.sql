
IF EXISTS (SELECT * FROM sys.databases WHERE name = 'Com2900G19')
	USE Com2900G19
ELSE
	RAISERROR('Este script está diseñado para que se ejecute despues del script de la creacion de tablas y esquemas.',20,1);
GO
/*
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
*/

------------------------------------------------Esquema Sucursal------------------------------------------------
--Tabla Sucursal
--	Procedimiento almacenado que permite agregar una sucursal.
--	DROP PROCEDURE Sucursal.agregarSucursal
CREATE OR ALTER PROCEDURE Sucursal.agregarSucursal (
										@telefono CHAR(9)	= NULL, @horario VARCHAR(50)	= NULL,
										@dire VARCHAR(100)	= NULL, @localidad VARCHAR(50)	= NULL,
										@cuit char(13)		= NULL
													)
AS BEGIN
	DECLARE @altaSucursal BIT = 1;
	IF @telefono IS NULL OR @telefono NOT LIKE '[0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]'
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarSucursal. El telefono es inválido.',16,2);
		RETURN;
	END
	IF(@horario IS NULL OR LEN(LTRIM(@horario)) = 0)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarSucursal. El horario es inválido.',16,2);
		RETURN;
	END

	IF(@dire IS NULL OR LEN(LTRIM(@dire)) = 0)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarSucursal. La direccion es inválida.',16,2);
		RETURN;
	END

	IF(@localidad IS NULL OR LEN(LTRIM(@localidad)) = 0)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarSucursal. La localidad es inválida.',16,2);
		RETURN;
	END
	IF @cuit IS NOT NULL OR @cuit NOT LIKE '[0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]-[0-9]'
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarSucursal. El cuit es inválida.',16,2);
		RETURN;
	END

	IF (@cuit IS NULL)
		SET @cuit = '20-22222222-3'

	INSERT INTO Sucursal.Sucursal (telefono,horario,sucursalActiva,direccion,localidad,cuit)
			VALUES (@telefono,@horario,@altaSucursal,@dire,@localidad,@cuit);
END
GO
--	Procedimiento almacenado que permite modificar una sucursal.
--	DROP PROCEDURE Sucursal.modificarSucursal
CREATE OR ALTER PROCEDURE Sucursal.modificarSucursal (
									@idSucursal INT			= NULL,@telefono VARCHAR(9)	= NULL,
									@horario VARCHAR(100)	= NULL,@dire VARCHAR(100)	= NULL,
									@localidad VARCHAR(30)	= NULL,@cuit CHAR(13) = NULL
												)
AS BEGIN
	DECLARE @direccion VARCHAR(100) = NULL;
	
	IF(@dire IS NOT NULL AND LEN(LTRIM(@dire)) = 0)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado modificarSucursal. La direccion es inválido.',16,10);
		RETURN;
	END
	IF(@horario IS NOT NULL AND LEN(LTRIM(@horario)) = 0)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado modificarSucursal. El horario es inválido.',16,10);
		RETURN;
	END
	IF(@localidad IS NOT NULL AND LEN(LTRIM(@localidad)) = 0)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado modificarSucursal. La localidad es inválida.',16,10);
		RETURN;
	END


	UPDATE Sucursal.Sucursal
		SET telefono = COALESCE(@telefono,telefono),
			horario = COALESCE(@horario,horario),
			direccion = COALESCE(@dire, direccion),
			localidad = COALESCE(@localidad, localidad)
		WHERE idSucursal = @idSucursal;

END;
GO
--	Procedimiento almacenado que permite eliminar una sucursal.
--	DROP PROCEDURE Sucursal.eliminarSucursal
CREATE OR ALTER PROCEDURE Sucursal.eliminarSucursal (@idSucursal INT)
AS BEGIN
	UPDATE Sucursal.Sucursal
		SET sucursalActiva = 0
		WHERE idSucursal = @idSucursal;
END
GO
--	Vista que permite ver la información de cada sucursal.
--	DROP VIEW Sucursal.verDatosDeSucursales
--	SELECT * FROM Sucursal.verDatosDeSucursales
CREATE OR ALTER VIEW Sucursal.verDatosDeSucursales AS
	SELECT s.idSucursal,s.horario,s.telefono,s.direccion,s.localidad
		FROM Sucursal.Sucursal s
GO 
--	Vista que permite ver a los empleados de cada sucursal
--	DROP VIEW Sucursal.verEmpleadosDeCadaSucursal
--	SELECT * FROM Sucursal.verEmpleadosDeCadaSucursal
CREATE OR ALTER VIEW Sucursal.verEmpleadosDeCadaSucursal AS
	SELECT s.idSucursal,e.legajo,e.cuil,e.apellido,e.nombre 
		FROM Sucursal.Sucursal s JOIN Empleado.Empleado e
		ON s.idSucursal = e.idSucursal;
GO
--Tabla Cargo
--	Procedimiento almacenado que permite agregar un cargo
--	DROP PROCEDURE Sucursal.agregarCargo
CREATE OR ALTER PROCEDURE Sucursal.agregarCargo (@nombreCargo VARCHAR(30))
AS BEGIN

	IF(@nombreCargo IS NULL OR LEN(LTRIM(RTRIM(@nombreCargo))) = 0)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarCargo. El nombre del cargo es inválido.',16,3);
		RETURN;
	END
	IF EXISTS (SELECT 1 FROM Sucursal.Cargo 
						WHERE nombreCargo = @nombreCargo)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarCargo. el cargo ya se encuentra ingresado',16,3);
		RETURN;
	END

	INSERT Sucursal.Cargo (nombreCargo) VALUES (@nombreCargo);
END
GO
--	Procedimiento almacenado que permite modificar un cargo
--	DROP PROCEDURE Sucursal.modificarCargo
CREATE OR ALTER PROCEDURE Sucursal.modificarCargo (@idCargo INT,@nombreCargo VARCHAR(30))
AS BEGIN
	IF (@nombreCargo IS NULL OR LEN(LTRIM(RTRIM(@nombreCargo))) = 0)
	BEGIN
		RAISERROR ('Error en el procedimiento almacenado modificarCargo.',16,11);
		RETURN;
	END
	UPDATE Sucursal.Cargo
		SET nombreCargo = COALESCE(@nombreCargo,nombreCargo)
		WHERE idCargo = @idCargo;
END
GO
--	Procedimiento almacenado que permite eliminar un cargo
--	DROP PROCEDURE Sucursal.eliminarCargo
CREATE OR ALTER PROCEDURE Sucursal.eliminarCargo (@idCargo INT)
AS BEGIN
	UPDATE Empleado.Empleado
		SET idCargo = NULL
		WHERE idCargo = @idCargo;

	DELETE FROM Sucursal.Cargo
		WHERE idCargo = @idCargo;
END
GO
--	Vista que permite ver el cargo que tiene cada empleado
--	DROP VIEW Sucursal.verCargoDeEmpleados
--	SELECT * FROM Sucursal.verCargoDeEmpleados
CREATE OR ALTER VIEW Sucursal.verCargoDeEmpleados AS
	SELECT e.idEmpleado, e.legajo,e.cuil,e.apellido,e.nombre,c.nombreCargo 
		FROM Empleado.Empleado e JOIN Sucursal.Cargo c
		ON e.idCargo = c.idCargo;
GO
--	Vista que permite ver los turnos que tiene cada empleado.
--	DROP VIEW Sucursal.verTurnosDeEmpleados
--	SELECT * FROM Sucursal.verTurnosDeEmpleados
CREATE OR ALTER VIEW Sucursal.verTurnosDeEmpleados AS
	SELECT e.idEmpleado, e.legajo,e.cuil,e.apellido,e.nombre,e.turno 
			FROM Empleado.Empleado e
GO