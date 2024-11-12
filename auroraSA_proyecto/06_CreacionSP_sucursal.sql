
IF EXISTS (SELECT * FROM sys.databases WHERE name = 'Com2900G19')
	USE Com2900G19
ELSE
	RAISERROR('Este script está diseñado para que se ejecute despues del script de la creacion de tablas y esquemas.',20,1);
GO
--  USE master
--DROP DATABASE G2900G19
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
CREATE OR ALTER PROCEDURE Sucursal.agregarSucursal (@telefono CHAR(9),@horario VARCHAR(50),
													@calle VARCHAR(25),@numeroDeCalle SMALLINT,@codPostal VARCHAR(10),
													@localidad VARCHAR(50),@provincia VARCHAR(45))
AS BEGIN
	DECLARE @altaSucursal BIT = 1;
	IF(@horario IS NULL OR LEN(LTRIM(@horario)) = 0)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarSucursal. El horario es inválido.',16,2);
		RETURN;
	END

	IF(@calle IS NULL OR LEN(LTRIM(@calle)) = 0)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarSucursal. La calle es inválida.',16,2);
		RETURN;
	END

	IF(LEN(LTRIM(@codPostal)) = 0)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarSucursal. El código postal es inválido.',16,2);
		RETURN;
	END

	IF(@localidad IS NULL OR LEN(LTRIM(@localidad)) = 0)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarSucursal. La localidad es inválida.',16,2);
		RETURN;
	END

	IF(@provincia IS NULL OR LEN(LTRIM(@provincia)) = 0)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarSucursal. La provincia es inválida.',16,2);
		RETURN;
	END

	IF(@codPostal IS NULL)
	BEGIN
		EXEC Direccion.calcularCodigoPostal @codPostal OUTPUT;
	END
	LTRIM(RTRIM())
	DECLARE @direccion varchar(100);
	SET @direccion = LTRIM(RTRIM(@calle)) + ', ' + LTRIM(RTRIM(@numeroDeCalle ))+ ', ' + LTRIM(RTRIM(@provincia));
	INSERT INTO Sucursal.Sucursal (telefono,horario,codPostal,sucursalActiva,direccion,localidad,provincia)
			VALUES (@telefono,@horario,@codPostal, @altaSucursal, @direccion,@localidad,@provincia);
END
GO
--	Procedimiento almacenado que permite modificar una sucursal.
--	DROP PROCEDURE Sucursal.modificarSucursal
CREATE OR ALTER PROCEDURE Sucursal.modificarSucursal (@idSucursal INT,@telefono VARCHAR(9) = NULL,
													@horario VARCHAR(255) = NULL,@calle VARCHAR(255) = NULL,
													@numeroDeCalle SMALLINT = NULL,@codPostal VARCHAR(255) = NULL,
													@localidad VARCHAR(255) = NULL,@provincia VARCHAR(255) = NULL)
AS BEGIN
	DECLARE @direccion VARCHAR(100) = NULL;
	DECLARE @calle  

	IF(LEN(LTRIM(@horario)) = 0)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado modificarSucursal. El horario es inválido.',16,10);
		RETURN;
	END

	IF(LEN(LTRIM(@calle)) = 0)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado modificarSucursal. La calle es inválida.',16,10);
		RETURN;
	END

	IF(LEN(LTRIM(@codPostal)) = 0)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado modificarSucursal. El código postal es inválido.',16,10);
		RETURN;
	END

	IF(LEN(LTRIM(@localidad)) = 0)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado modificarSucursal. La localidad es inválida.',16,10);
		RETURN;
	END

	IF(LEN(LTRIM(@provincia)) = 0)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado modificarSucursal. La provincia es inválida.',16,10);
		RETURN;
	END

	SET @direccion = @calle + ', ' + @numeroDeCalle;

	UPDATE Sucursal.Sucursal
		SET telefono = COALESCE(@telefono,telefono),
			horario = COALESCE(@horario,horario),
			direccion = COALESCE(@direccion, direccion),
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
CREATE OR ALTER PROCEDURE Sucursal.agregarCargo (@nombreCargo VARCHAR(255))
AS BEGIN
	IF EXISTS (SELECT 1 FROM Sucursal.Cargo 
						WHERE nombreCargo = @nombreCargo)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarCargo. el cargo ya se encuentra ingresado',16,3);
		RETURN;
	END

	IF(@nombreCargo IS NULL OR LEN(LTRIM(RTRIM(@nombreCargo))) = 0)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarCargo. El nombre del cargo es inválido.',16,3);
		RETURN;
	END

	INSERT Sucursal.Cargo (nombreCargo) VALUES (@nombreCargo);
END
GO
--	Procedimiento almacenado que permite modificar un cargo
--	DROP PROCEDURE Sucursal.modificarCargo
CREATE OR ALTER PROCEDURE Sucursal.modificarCargo (@idCargo INT,@nombreCargo VARCHAR(255))
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
	SELECT e.legajo,e.cuil,e.apellido,e.nombre,c.nombreCargo 
		FROM Empleado.Empleado e JOIN Sucursal.Cargo c
		ON e.idCargo = c.idCargo;
GO
--	Vista que permite ver los turnos que tiene cada empleado.
--	DROP VIEW Sucursal.verTurnosDeEmpleados
--	SELECT * FROM Sucursal.verTurnosDeEmpleados
CREATE OR ALTER VIEW Sucursal.verTurnosDeEmpleados AS
	SELECT e.legajo,e.cuil,e.apellido,e.nombre,e.turno 
			FROM Empleado.Empleado e
GO