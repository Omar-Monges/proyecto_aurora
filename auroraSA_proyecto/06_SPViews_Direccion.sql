USE Com2900G19
GO
--  use master
-- drop database Com2900G19
------------------------------------------------Esquema Dirección------------------------------------------------
--Ver los domicilios de todos los empleados.
--DROP VIEW Direccion.verDomiciliosDeEmpleados
--		SELECT * FROM Direccion.verDomiciliosDeEmpleados
CREATE OR ALTER VIEW Direccion.verDomiciliosDeEmpleados AS
	SELECT idEmpleado, legajo, nombre, apellido, direccion FROM Empleado.Empleado;
GO
--Ver las direcciones de todas las sucursales
--DROP VIEW Direccion.verDireccionesDeSucursales
--		SELECT *  FROM Direccion.verDireccionesDeSucursales
CREATE OR ALTER VIEW Direccion.verDireccionesDeSucursales AS
	select idSucursal, telefono, localidad, direccion, horario from Sucursal.Sucursal
GO