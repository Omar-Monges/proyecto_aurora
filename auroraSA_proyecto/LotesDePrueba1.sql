USE Com2900G19
GO
-- use master
/*
SELECT * FROM Empleado.Empleado
SELECT * FROM Direccion.Direccion
SELECT * FROM Sucursal.Sucursal
SELECT * FROM Sucursal.Cargo
SELECT * FROM Sucursal.Turno
*/
------------------------------------------------Esquema Dirección------------------------------------------------
/*
Se probará con el procedure Empleado.agregarEmpleado
Formato:
	EXEC Empleado.agregarEmpleado DNI,Nombre,Apellido,Sexo,EmailPersonal,EmailEmpresarial,IDSucursal,IDTurno,IDCargo,
									NombreCalle,NumeroDeCalle,CodigoPostal,Localidad,Provincia,Piso,NumeroDeDepartamento

*/
--->1) Agregamos una calle nula: 
	EXEC Empleado.agregarEmpleado '12345678','Ezequiel','Calaz','M','topicos@hotmail.com','deProgramacion@superA.com',1,2,1,'av. sim 11'			--<--- Salida esperada: Error
--->2) Agregamos una calle vacía:		<--- Salida esperada: Error
	EXEC Empleado.agregarEmpleado '12345678','Ezequiel','Calaz','M','topicos@hotmail.com','deProgramacion@superA.com',18,2,1,
								'              ','3140','1333','Rosario','Santa Fé', NULL, NULL		--<--- Salida esperada: Error
--->3) Agregamos un numero de calle vacío:	<--- Salida esperada: Error
	EXEC Empleado.agregarEmpleado '12345678','Ezequiel','Calaz','M','topicos@hotmail.com','deProgramacion@superA.com',18,2,1,
								'nombreDeCalleXD','3140','1333','Rosario','Santa Fé', NULL, NULL	--<--- Salida esperada: Error
--->4) Agregamos un numero de calle negativo:		<--- Salida esperada: Error
	EXEC Empleado.agregarEmpleado '12345678','Ezequiel','Calaz','M','topicos@hotmail.com','deProgramacion@superA.com',18,2,1,
								'San Martin','-314','1333','Rosario','Santa Fé', NULL, NULL		--<--- Salida esperada: Error
--->5) Agregamoso un codigo postal NULO
	EXEC Empleado.agregarEmpleado '12345678','Ezequiel','Calaz','M','topicos@hotmail.com','deProgramacion@superA.com',18,2,1,
								'San Martin','3140',NULL,'Rosario','Santa Fé', NULL, NULL		--<--- Salida esperada: Error
--->6) Agregamos un código postal vacío
	EXEC Empleado.agregarEmpleado '12345678','Ezequiel','Calaz','M','topicos@hotmail.com','deProgramacion@superA.com',18,2,1,
								'San Martin','3140','       ','Rosario','Santa Fé', NULL, NULL		--<--- Salida esperada: Error
--->7) Agregamos una localidad NULA (Es lo mismo con Provincia):
	EXEC Empleado.agregarEmpleado '12345678','Ezequiel','Calaz','M','topicos@hotmail.com','deProgramacion@superA.com',18,2,1,
								'San Martin','3140','1333',NULL,'Santa Fé', NULL, NULL		--<--- Salida esperada: Error
--->8) Agregamos una localidad vacía (es lo mismo  con Provincia):
	EXEC Empleado.agregarEmpleado '12345678','Ezequiel','Calaz','M','topicos@hotmail.com','deProgramacion@superA.com',18,2,1,
								'San Martin','3140','1333','      ','Santa Fé', NULL, NULL		--<--- Salida esperada: Error

--->9) Agregamos un departamento pero un piso NULO (es lo mismo al revés): 
EXEC Empleado.agregarEmpleado '12345678','Ezequiel','Calaz','M','topicos@hotmail.com','deProgramacion@superA.com',18,2,1,
								'San Martin','3140','1333','Rosario','Santa Fé', NULL, 5		--<--- Salida esperada: Error

GO
------------------------------------------------Esquema Sucursal------------------------------------------------

--Prueba de Cargo:
SELECT * FROM Sucursal.Cargo
-->1) Agregamos un cargo NULO
	EXEC Sucursal.agregarCargo NULL						--- Salida esperada: ERROR
-->2) Agregamos un cargo vacío
	EXEC Sucursal.agregarCargo '     '					--- Salida esperada: ERROR
-->2) Agregamos un cargo X:
	EXEC Sucursal.agregarCargo 'El de informática'		--- Salida esperada: Todo ok
-->3) Agregamos un cargo que ya existe (el del item 2):
	EXEC Sucursal.agregarCargo 'eL DE InFORmáTica'		--- Salida esperada: 'El turno ya ha ingresado'
	EXEC Sucursal.agregarCargo 'cajero'

/*
	(
										@telefono CHAR(9)	= NULL, @horario VARCHAR(50)	= NULL,
										@dire VARCHAR(100)	= NULL, @localidad VARCHAR(50)	= NULL,
										@cuit char(13)		= NULL
													)
*/
--Prueba de Sucursal:
SELECT * FROM Sucursal.Cargo
-->1) Agregamos un telefono NULO:
	EXEC Sucursal.agregarSucursal NULL,'L-V 8-21','EstoEsUnaCalle','Morón', '123456789abcd'						--- Salida esperada: ERROR
-->2) Agregamos un telefono que no respete el formato:
	EXEC Sucursal.agregarSucursal '5555$5555','L-V 8-21','EstoEsUnaCalle','Morón', '123456789abcd'				--- Salida esperada: ERROR
-->3) Agregamos un horario NULO:
	EXEC Sucursal.agregarSucursal '1234-5678',NULL,'EstoEsUnaCalle','Morón', '123456789abcd'		--- Salida esperada: ERROR
-->4) Agregamos un horario vacío:
	EXEC Sucursal.agregarSucursal '1234-5678','     ','EstoEsUnaCalle','Morón',	'123456789abcd'	--- Salida esperada: ERROR
-->5) Agregamos una sucursal:
	EXEC Sucursal.agregarSucursal '1234-5678','L-V 8-21','EstoEsUnaCalle 11','Morón','123556789abcd'	--- Salida esperada: Todo_ok
	EXEC Sucursal.agregarSucursal '8765-4321','M-S 10-22','EstoEsUnaAvenida 221','Palermo','20-11111111-2'		--- Salida esperada: Todo_ok
SELECT * FROM Sucursal.verDatosDeSucursales
GO
------------------------------------------------Esquema Empleado------------------------------------------------

SELECT * FROM Empleado.Empleado
SELECT * FROM Sucursal.Sucursal
SELECT * FROM Sucursal.Cargo
-->1) Agregamos un DNI NULL:
	EXEC Empleado.agregarEmpleado NULL,'Ezequiel',
									'Calaz','M',
									'topicos@hotmail.com','deProgramacion@superA.com',
									18,2,
									1,'San Martin 3140, Santa Fé, Rosario'

-->2) Agregamos un DNI vacío
	EXEC Empleado.agregarEmpleado '     ','Ezequiel',
							'Calaz','M',
							'topicos@hotmail.com','deProgramacion@superA.com',
							18,2,
							1,'San Martin, 314,Santa Fé, Rosario'
-->3) Agregamos un nombre NULL (es lo mismo con apellido):
	EXEC Empleado.agregarEmpleado '42781944',NULL,
							'Calaz','M',
							'topicos@hotmail.com','deProgramacion@superA.com',
							18,2,
							1,'San Martin, 314,Santa Fé, Rosario'
-->4) Agregamos un nombre vacío (es lo mismo con apellido:
	EXEC Empleado.agregarEmpleado '42781944','           ',
							'Calaz','M',
							'topicos@hotmail.com','deProgramacion@superA.com',
							18,2,
							1,'San Martin, 314,Santa Fé, Rosario'
-->5) Agregamos un sexo que no esté dentro de los parámetros
	EXEC Empleado.agregarEmpleado '42781944','Ezequiel',
							'Calaz','y',
							'topicos@hotmail.com','deProgramacion@superA.com',
							18,2,
							1,'San Martin, 314,Santa Fé, Rosario'
-->6) Agregamos un email que no cumpla con el formato:
	EXEC Empleado.agregarEmpleado '42781944','Ezequiel',
							'Calaz','y',
							'ttopicos$hotmail:com','deProgramacion@superA.com',
							18,2,
							1,'San Martin, 314,Santa Fé, Rosario'
-->7) Agregamos dos empleados:
	EXEC Empleado.agregarEmpleado '42781944','Ezequiel',
							'Calaz','M',
							'topicos@hotmail.com','deProgramacion@superA.com',
							1,'turno tarde',
							'El de informática','San Martin, 314,Santa Fé, Rosario'
	EXEC Empleado.agregarEmpleado '42781924','Harol',
							'Calaz','M',
							'topicos@hotmail.com','deProgramacion@superA.com',
							1,'jornada Completa',
							'cajero','San Martin, 314,Santa Fé, Rosario'
/*
CREATE OR ALTER PROCEDURE Empleado.agregarEmpleado (
								@dni VARCHAR(8)				= NULL, @nombre VARCHAR(50)			= NULL,
								@apellido VARCHAR(50)		= NULL, @sexo CHAR					= NULL,
								@emailPersonal VARCHAR(100)	= NULL, @emailEmpresa VARCHAR(100)	= NULL,
								@idSucursal INT				= NULL, @turno VARCHAR(20)			= NULL,
								@cargo VARCHAR(30)			= NULL, @direccion VARCHAR(100)		= NULL
													)
*/
SELECT * FROM Empleado.verDatosDeEmpleados
EXEC Empleado.agregarEmpleado '42781924','Juan',
							'Calaz','M',
							'topicos@hotmail.com','gramacion@superA.com',
							1,'jornada Completa',
							'cajero','San Martin, 314,Santa Fé, Rosario'
SELECT *
	from Empleado.Empleado e
	JOIN Sucursal.Cargo c on c.idCargo = e.idCargo
	WHERE e.empleadoActivo = 1

SELECT * FROM Empleado.verDatosPersonalesDeEmpleados
SELECT * FROM Sucursal.verTurnosDeEmpleados
SELECT * FROM Sucursal.verCargoDeEmpleados
SELECT * FROM Sucursal.verEmpleadosDeCadaSucursal
SELECT * FROM Sucursal.Cargo

EXEC Empleado.modificarEmpleado 1, NULL, 'Juan'
EXEC Empleado.modificarEmpleado 1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'otra Calle 11'
exec Empleado.eliminarEmpleado 1
SELECT * FROM Empleado.Empleado

EXEC Sucursal.eliminarCargo 1
--Archivo Informacion_Complementaria.xlsx

--Agregamos Sucursales
--SELECT * FROM Sucursal.Sucursal
--SELECT * FROM Direccion.Direccion
EXEC Sucursal.agregarSucursal '5555-5551','L a V 8a.m.-9p.m. S y D 9a.m-8p.m.','Av. Brig. Gral. Juan Manuel de Rosas',
								3634,'B1754','San Justo','Buenos Aires';
EXEC Sucursal.agregarSucursal '5555-5552','L a V 8a.m.-9p.m. S y D 9a.m-8p.m.','Av. de Mayo 791',
								791,'B1704','Ramos Mejía','Buenos Aires';
EXEC Sucursal.agregarSucursal '5555-5553','L a V 8a.m.-9p.m. S y D 9a.m-8p.m.','Pres. Juan Domingo Perón',
								763,'B1753AWO','Lomas del Mirador','Buenos Aires';
GO
--Agregamos Medios de pagos
--Agregamos Turnos
EXEC Sucursal.agregarTurno 'Turno Mañana';
EXEC Sucursal.agregarTurno 'Turno Tarde';
EXEC Sucursal.agregarTurno 'Jornada Completa';
GO
--Agregamos Cargos
EXEC Sucursal.agregarCargo 'Cajero';
EXEC Sucursal.agregarCargo 'Supervisor';
EXEC Sucursal.agregarCargo 'Gerente de sucursal';
GO
--Agregamos Empleados
/*
SELECT * FROM Sucursal.Cargo
SELECT * FROM Sucursal.Sucursal
SELECT * FROM Sucursal.Turno
SELECT * FROM Direccion.Direccion
SELECT * FROM Empleado.Empleado
*/
EXEC Empleado.agregarEmpleado '36383025','Romina Alejandra','Alias','F','Romina Alejandra_ALIAS@gmail.com','Romina Alejandra.ALIAS@superA.com',2,1,1,'Bernando de Irigoyen',2647,NULL,'San Isidro','Buenos Aires',NULL,NULL;
EXEC Empleado.agregarEmpleado '31816587','Romina Soledad','Rodriguez','F','Romina Soledad_RODRIGUEZ@gmail.com','Romina Alejandra.ALIAS@superA.com',2,2,1,'Av. Vergara',1910,NULL,'Hurlingham','Buenos Aires',NULL,NULL;
EXEC Empleado.agregarEmpleado '30103258','Sergio Elio','Rodriguez','M','Sergio Elio_RODRIGUEZ@gmail.com','Sergio Elio.RODRIGUEZ@superA.com',3,1,1,'Av. Belgrano',422,NULL,'Avellaneda','Buenos Aires',NULL,NULL;
EXEC Empleado.agregarEmpleado '41408274','Christian Joel','Rojas','M','Christian Joel_ROJAS@gmail.com','Christian Joel.ROJAS@superA.com',3,2,1,'Calle 7',767,'-','La Plata','Buenos Aires',NULL,NULL;
EXEC Empleado.agregarEmpleado '30417854','María Roberta de los Angeles','Rolon Gamarra','F','María Roberta de los Angeles_ROLON GAMARRA@gmail.com','María Roberta de los Angeles.ROLON GAMARRA@superA.com',1,1,1,'Av Arturo Illia',3770,NULL,'Malvinas Argentinas','Buenos Aires',NULL,NULL;
EXEC Empleado.agregarEmpleado '29943254','Rolando','Lopez','M','Rolando_LOPEZ@gmail.com','@Rolando.LOPEZ@superA.com',1,2,1,'Av. Rivadavia',6538,NULL,'Ciudad Autónoma de Buenos Aires','Ciudad Autónoma de Buenos Aires',NULL,NULL;
EXEC Empleado.agregarEmpleado '37633159','Francisco Emmanuel','Lucena','M','Francisco Emmanuel_LUCENA@gmail.com','Francisco Emmanuel.LUCENA@superA.com',2,1,2,'Av. Don Bosco',2680,NULL,'San Justo','Buenos Aires',NULL,NULL;
EXEC Empleado.agregarEmpleado '30338745','Eduardo Matias','Luna','M','Eduardo Matias _LUNA @gmail.com','Eduardo Matias .LUNA @superA.com',3,1,2,'Av. Santa Fe',1954,NULL,'Ciudad Autónoma de Buenos Aires','Ciudad Autónoma de Buenos Aires',NULL,NULL;
EXEC Empleado.agregarEmpleado '34605254','Mauro Alberto','Luna','M','Mauro Alberto_LUNA@gmail.com','Mauro Alberto.LUNA@superA.com',1,1,2,'Av. San Martín',420,NULL,'San Martín','Buenos Aires',NULL,NULL;
EXEC Empleado.agregarEmpleado '36508254','Emilce','Maidana','F','Emilce_MAIDANA@gmail.com','Emilce.MAIDANA@superA.com',2,2,2,'Independencia',3067,NULL,'Carapachay','Buenos Aires',NULL,NULL;
EXEC Empleado.agregarEmpleado '34636354','Noelia Gisela Fabiola','Maidana','F','NOELIA GISELA FABIOLA_MAIDANA@gmail.com','NOELIA GISELA FABIOLA.MAIDANA@superA.com',3,2,2,'Bernando de Irigoyen',2647,NULL,'San Isidro','Buenos Aires',NULL,NULL;
EXEC Empleado.agregarEmpleado '33127114','Fernanda Gisela Evangelina','Maizares','F','Fernanda Gisela Evangelina_MAIZARES@gmail.com','Fernanda Gisela Evangelina.MAIZARES@superA.com',1,2,2,'Av. Rivadavia',2243,NULL,'Ciudad Autónoma de Buenos Aires','Ciudad Autónoma de Buenos Aires',NULL,NULL;
EXEC Empleado.agregarEmpleado '39231254','Oscar Martín','Ortiz','M','Oscar Martín_ORTIZ@gmail.com','Oscar Martín.ORTIZ@superA.com',2,3,3,'Juramento',2971,NULL,'Ciudad Autónoma de Buenos Aires','Ciudad Autónoma de Buenos Aires',NULL,NULL;
EXEC Empleado.agregarEmpleado '30766254','Débora','Pachtman','F','Débora_PACHTMAN@gmail.com','Débora.PACHTMAN@superA.com',3,3,3,'Av. Presidente Hipólito Yrigoyen',299,NULL,'Provincia de Buenos Aires','Buenos Aires',NULL,NULL;
EXEC Empleado.agregarEmpleado '38974125','Romina Natalia','Padilla','F','Romina Natalia_PADILLA@gmail.com','Romina Natalia.PADILLA@superA.com',1,3,3,'Lacroze',5910,NULL,'Chilavert','Buenos Aires',NULL,NULL;
GO
