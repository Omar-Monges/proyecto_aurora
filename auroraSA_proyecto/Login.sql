use master
GO
--Creamos el login para el supervisor y el noSupervisor
--		DROP LOGIN Supervisor
CREATE LOGIN Supervisor 
	WITH PASSWORD = '¡SuperContraseniaUltraSecret@123!',CHECK_POLICY = ON, DEFAULT_DATABASE = [Com2900G19]
GO
CREATE LOGIN NoSupervisor
	WITH PASSWORD = '¡B@seDeD@tosAplic@d@s2024!',CHECK_POLICY = ON, DEFAULT_DATABASE = [Com2900G19]
GO

--Creamos los users para cada login
use Com2900G19
CREATE USER SupervisorUsuario FOR LOGIN Supervisor
GO
CREATE USER NoSupervisorUsuario FOR LOGIN NoSupervisor
GO

--Creamos el Rol para el supervisor
CREATE ROLE RolSupervisor --AUTHORIZATION SupervisorUsuario
GO
ALTER ROLE RolSupervisor ADD MEMBER SupervisorUsuario
GO
CREATE ROLE RolNoSupervisor --AUTHORIZATION NoSupervisorUsuario
GO
ALTER ROLE RolNoSupervisor ADD MEMBER NoSupervisorUsuario
GO

--	EXEC Seguridad.restringirAccesosARoles
CREATE OR ALTER PROCEDURE Seguridad.restringirAccesosARoles
AS BEGIN
	GRANT EXEC ON Venta.crearNotaDeCredito TO RolSupervisor;
	GRANT SELECT ON Venta.NotaDeCredito TO PUBLIC;
	--Aseguramos que los empleados no supervisores puedan acceder a emitir una nota de credito
	REVOKE EXEC ON Venta.crearNotaDeCredito TO RolNoSupervisor
END
GO

/*
PROCEDURE Venta.crearNotaDeCredito(
									@idFactura INT = NULL, @idSupervisor INT = NULL,
									@montoDeCredito DECIMAL(11,2) = NULL, @laRazon VARCHAR(50) = NULL
									)
*/

SELECT CURRENT_USER QuienSoyChe
--Probamos si el supervisor puede acceder al procedimiento almacenado Venta.CrearNotaDeCredito y hacer un select de Venta.NotaDeCredito
EXECUTE AS USER = 'SupervisorUsuario'
EXEC Venta.crearNotaDeCredito @idFactura=1,@idSupervisor=13,@montoDeCredito=150,@laRazon = 'Devolucion'
SELECT * FROM Venta.Notadecredito
GO
--Probamos si el NO supervisor puede acceder al procedimiento almacenado Venta.CrearNotaDeCredito y hacer un select de Venta.NotaDeCredito
use Com2900G19
EXECUTE AS USER = 'NoSupervisorUsuario'
EXEC Venta.crearNotaDeCredito @idFactura=2,@idSupervisor=13,@montoDeCredito=150,@laRazon = 'Devolucion'
SELECT * FROM Venta.Notadecredito
GO
/*
DROP ROLE RolNoSupervisor;
DROP ROLE RolSupervisor;
GO
DROP USER SupervisorUsuario;
DROP USER NoSupervisorUsuario;
GO
DROP LOGIN Supervisor;
DROP LOGIN NoSupervisor;
*/