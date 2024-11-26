use master
GO
--		SELECT CURRENT_USER QuienSoyChe

--Creamos el login para el supervisor y el noSupervisor
--		DROP LOGIN Supervisor
--		DROP LOGIN NoSupervisor
CREATE LOGIN Gerente
	WITH PASSWORD = '¡SuperContraseniaUltraSecret@123!',CHECK_POLICY = ON, DEFAULT_DATABASE = [Com2900G19]
GO
CREATE LOGIN Supervisor 
	WITH PASSWORD = '¡SuperContraseniaUltraSecret@123!',CHECK_POLICY = ON, DEFAULT_DATABASE = [Com2900G19]
GO
CREATE LOGIN Cajero
	WITH PASSWORD = '¡B@seDeD@tosAplic@d@s2024!',CHECK_POLICY = ON, DEFAULT_DATABASE = [Com2900G19]
GO

--Creamos los users para cada login
use Com2900G19
GO
CREATE USER GerenteUsuario FOR LOGIN Gerente
GO
CREATE USER SupervisorUsuario FOR LOGIN Supervisor
GO
CREATE USER CajeroUsuario FOR LOGIN Cajero
GO

--Creamos el Rol para los cargos
CREATE ROLE RolGerente --AUTHORIZATION SupervisorUsuario
GO
ALTER ROLE RolGerente ADD MEMBER GerenteUsuario
GO
CREATE ROLE RolSupervisor --AUTHORIZATION SupervisorUsuario
GO
ALTER ROLE RolSupervisor ADD MEMBER SupervisorUsuario
GO
CREATE ROLE RolCajero --AUTHORIZATION NoSupervisorUsuario
GO
ALTER ROLE RolCajero ADD MEMBER CajeroUsuario
GO

--	EXEC Seguridad.restringirAccesosARoles
CREATE OR ALTER PROCEDURE Seguridad.restringirAccesosARoles
AS BEGIN
	GRANT EXEC ON SCHEMA::Empleado to RolGerente;
	GRANT EXEC ON SCHEMA::Producto to RolGerente;
	GRANT SELECT ON SCHEMA::Direccion to RolGerente;

	GRANT SELECT ON SCHEMA::Empleado to RolGerente;
	DENY SELECT ON Empleado.Empleado to RolGerente;
	
	GRANT EXEC ON SCHEMA::Venta to RolSupervisor;
	GRANT SELECT ON Venta.NotaDeCredito TO PUBLIC;
	--Aseguramos que los empleados no supervisores puedan acceder a emitir una nota de credito
	GRANT EXEC ON SCHEMA::Venta to RolCajero
	DENY EXEC ON Venta.crearNotaDeCredito TO RolCajero
END
GO
/*
PROCEDURE Venta.crearNotaDeCredito(
									@idFactura INT = NULL, @idSupervisor INT = NULL,
									@montoDeCredito DECIMAL(11,2) = NULL, @laRazon VARCHAR(50) = NULL
									)
*/
SELECT * FROM Venta.Factura
SELECT CURRENT_USER QuienSoyChe

EXECUTE AS USER = 'GerenteUsuario'
SELECT * FROM Empleado.verDatosDeEmpleados
SELECT * FROM Producto.Producto
EXEC Empleado.eliminarEmpleado 18
--Probamos si el supervisor puede acceder al procedimiento almacenado Venta.CrearNotaDeCredito y hacer un select de Venta.NotaDeCredito
EXECUTE AS USER = 'SupervisorUsuario'
EXEC Venta.crearNotaDeCredito @idFactura=7,@idSupervisor=13,@montoDeCredito=150,@laRazon = 'Devolucion'
SELECT * FROM Venta.Notadecredito
GO
--Probamos si el NO supervisor puede acceder al procedimiento almacenado Venta.CrearNotaDeCredito y hacer un select de Venta.NotaDeCredito
use Com2900G19
EXECUTE AS USER = 'CajeroUsuario'
EXEC Venta.crearNotaDeCredito @idFactura=6,@idSupervisor=13,@montoDeCredito=150,@laRazon = 'Devolucion'
SELECT * FROM Venta.Notadecredito

/*
DROP ROLE RolCajero;
DROP ROLE RolSupervisor;
DROP ROLE RolGerente
GO
DROP USER SupervisorUsuario;
DROP USER CajeroUsuario;
DROP USER GerenteUsuario;
GO
DROP LOGIN Supervisor;
DROP LOGIN Cajero;
DROP LOGIN Gerente;
*/