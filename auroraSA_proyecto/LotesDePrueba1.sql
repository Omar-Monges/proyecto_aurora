USE Com2900G19
GO
-- use master

------------------------------------------------Esquema Sucursal------------------------------------------------
--Prueba de Cargo:
SELECT * FROM Sucursal.Cargo
-->1) Agregamos un cargo NULO
	EXEC Sucursal.agregarCargo @nombreCargo=NULL						--- Salida esperada: ERROR
-->2) Agregamos un cargo vac�o
	EXEC Sucursal.agregarCargo @nombreCargo='     '					--- Salida esperada: ERROR
-->2) Agregamos un cargo X:
	EXEC Sucursal.agregarCargo @nombreCargo='El de inform�tica'		--- Salida esperada: Todo ok
-->3) Agregamos un cargo que ya existe (el del item 2):
	EXEC Sucursal.agregarCargo @nombreCargo='eL DE InFORm�Tica'		--- Salida esperada: 'El turno ya ha ingresado'
	EXEC Sucursal.agregarCargo @nombreCargo='Guardia de seguridad'

--Modificamos el nombre del cargo
--1) El nuevo nombre ya se encuentra en otro id
EXEC Sucursal.modificarCargo @idCargo=1,@nombreCargo='Guardia de seguridad'
EXEC Sucursal.modificarCargo @idCargo=1,@nombreCargo='GuardIa De sEgurIdaD'
--2) Todo_Ok:
EXEC Sucursal.modificarCargo @idCargo=1,@nombreCargo='El de informatica'

/*
	Sucursal.agregarSucursal (
							@telefono CHAR(9)	= NULL, @horario VARCHAR(50)	= NULL,
							@dire VARCHAR(100)	= NULL, @localidad VARCHAR(50)	= NULL,
							@cuit char(13)		= NULL
							)
*/
--	EXEC Sucursal.agregarSucursal @telefono='1234-1234',@horario='Lunes a viernes 9:00-21.30',@dire='',@localidad='',@cuit=''

--Prueba de Sucursal:
SELECT * FROM Sucursal.Sucursal
-->1) Agregamos un telefono NULO:	<--- Salida esperada: ERROR
	EXEC Sucursal.agregarSucursal @telefono=NULL,@horario='Lunes a viernes 9:00-21.30',@dire='',@localidad='',@cuit=''						
-->2) Agregamos un telefono que no respete el formato:		<--- Salida esperada: ERROR
	EXEC Sucursal.agregarSucursal @telefono='1234@1234',@horario='Lunes a viernes 9:00-21.30',@dire='',@localidad='',@cuit=''				
-->3) Agregamos un horario NULO:		<--- Salida esperada: ERROR
	EXEC Sucursal.agregarSucursal @telefono='1234-1234',@horario=NULL,@dire='',@localidad='',@cuit=''		
-->4) Agregamos un horario vac�o (Idem con direccion y localidad):		<--- Salida esperada: ERROR
	EXEC Sucursal.agregarSucursal @telefono='1234-1234',@horario='    ',@dire='',@localidad='',@cuit=''
-->5) Agregamos una sucursal:			<--- Salida esperada: ERROR
	EXEC Sucursal.agregarSucursal @telefono='1234-1234',@horario='Lunes a viernes 9:00-21.30',@dire='Rio Cuarto 3140',@localidad='Laferrere',@cuit='20@12341234@-2'	
-->6)Todo_Ok:	
	EXEC Sucursal.agregarSucursal @telefono='1234-1234',@horario='Lunes a viernes 9:00-21.30',@dire='Rio cuarto 3140',@localidad='Laferrere',@cuit='20-12341234-5'	
	EXEC Sucursal.agregarSucursal @telefono='4321-4321',@horario='Sabado a Domingo 9:00-21.30',@dire='Avenida 123',@localidad='Palermo',@cuit=NULL

SELECT * FROM Sucursal.verDatosDeSucursales
GO

EXEC Sucursal.modificarSucursal @idSucursal=2,@horario='Todos los dias 24/7'
SELECT * FROM Sucursal.Sucursal
Exec Sucursal.darDebajaSucursal 2

------------------------------------------------Esquema Empleado------------------------------------------------
/*
Se probar� con el procedure Empleado.agregarEmpleado
Formato:
CREATE OR ALTER PROCEDURE Empleado.agregarEmpleado (
								@legajo INT,
								@dni VARCHAR(8)				= NULL, @nombre VARCHAR(50)			= NULL,
								@apellido VARCHAR(50)		= NULL, @sexo CHAR					= NULL,
								@emailPersonal VARCHAR(100)	= NULL, @emailEmpresa VARCHAR(100)	= NULL,
								@idSucursal INT				= NULL, @turno VARCHAR(20)			= NULL,
								@cargo VARCHAR(30)			= NULL, @direccion VARCHAR(100)		= NULL
													)

*/

EXEC Empleado.agregarEmpleado @legajo,@dni,@nombre,@apellido,@sexo,@emailPersonal,@emailEmpresa,@idSucursal,@turno,@cargo,@direccion


--->1) Agregamos un legajo incorrecto: <--- Salida esperada: Error
	EXEC Empleado.agregarEmpleado @legajo=-15,@dni='12345678',@nombre='Ezequiel',@apellido='Calaz',@sexo='M',@emailPersonal='topicos@yahoo.com',
					@emailEmpresa='deprogramacion@superA.com',@idSucursal=1,@turno='TM',@cargo=1,@direccion='EstoesUnaCalle 123'
--->2) Agregamos un formato de dni incorrecto:		<--- Salida esperada: Error
	EXEC Empleado.agregarEmpleado @legajo=15,@dni='ABCDEFGH',@nombre='Ezequiel',@apellido='Calaz',@sexo='M',@emailPersonal='topicos@yahoo.com',
					@emailEmpresa='deprogramacion@superA.com',@idSucursal=1,@turno='TM',@cargo=1,@direccion='EstoesUnaCalle 123'
--->3) Agregamos un nombre invlaido (Idem con apellido):	<--- Salida esperada: Error
	EXEC Empleado.agregarEmpleado @legajo=15,@dni='12345678',@nombre='   ',@apellido='Calaz',@sexo='M',@emailPersonal='topicos@yahoo.com',
					@emailEmpresa='deprogramacion@superA.com',@idSucursal=1,@turno='TM',@cargo=1,@direccion='EstoesUnaCalle 123'
--->4) Agregamos un sexo invalido:		<--- Salida esperada: Error
	EXEC Empleado.agregarEmpleado @legajo=15,@dni='12345678',@nombre='Ezequiel',@apellido='Calaz',@sexo='W',@emailPersonal='topicos@yahoo.com',
					@emailEmpresa='deprogramacion@superA.com',@idSucursal=1,@turno='TM',@cargo=1,@direccion='EstoesUnaCalle 123'
--->5) Agregamoso un email erroneo (Idem con email empresarial)		<--- Salida esperada: Error
	EXEC Empleado.agregarEmpleado @legajo=15,@dni='12345678',@nombre='Ezequiel',@apellido='Calaz',@sexo='F',@emailPersonal='topicos!yahoo,com',
					@emailEmpresa='deprogramacion@superA.com',@idSucursal=1,@turno='TM',@cargo=1,@direccion='EstoesUnaCalle 123'
--->6) Agregamos un idSucursal erroneo		<--- Salida esperada: Error
	EXEC Empleado.agregarEmpleado @legajo=15,@dni='12345678',@nombre='Ezequiel',@apellido='Calaz',@sexo='F',@emailPersonal='topicos@yahoo.com',
					@emailEmpresa='deprogramacion@superA.com',@idSucursal=-1,@turno='TM',@cargo=1,@direccion='EstoesUnaCalle 123'
--->7) Agregamos un turno inv�lido:		<--- Salida esperada: Error
	EXEC Empleado.agregarEmpleado @legajo=15,@dni='12345678',@nombre='Ezequiel',@apellido='Calaz',@sexo='M',@emailPersonal='topicos@yahoo.com',
					@emailEmpresa='deprogramacion@superA.com',@idSucursal=1,@turno='    ',@cargo=1,@direccion='EstoesUnaCalle 123'	
--->8) Agregamos un cargo inv�lido:		<--- Salida esperada: Error
	EXEC Empleado.agregarEmpleado @legajo=15,@dni='12345678',@nombre='Ezequiel',@apellido='Calaz',@sexo='M',@emailPersonal='topicos@yahoo.com',
					@emailEmpresa='deprogramacion@superA.com',@idSucursal=1,@turno='TM',@cargo=-1,@direccion='EstoesUnaCalle 123'
--->9) Agregamos una direcci�n vac�a:	<--- Salida esperada: Error
	EXEC Empleado.agregarEmpleado @legajo=15,@dni='12345678',@nombre='Ezequiel',@apellido='Calaz',@sexo='M',@emailPersonal='topicos@yahoo.com',
					@emailEmpresa='deprogramacion@superA.com',@idSucursal=1,@turno='TM',@cargo=-1,@direccion='    '
---->10)Todo_Ok:
	EXEC Empleado.agregarEmpleado @legajo=15,@dni='12345678',@nombre='Ezequiel',@apellido='Calaz',@sexo='M',@emailPersonal='topicos@yahoo.com',
					@emailEmpresa='deprogramacion@superA.com',@idSucursal=1,@turno='TM',@cargo=1,@direccion='EstoesUnaCalle 123'
GO

SELECT * FROM Empleado.Empleado
Select * FROM Sucursal.Cargo

EXEC Empleado.darDeBajaEmpleado 15

GO
----Esquema productos
Use Com2900G19
--Tabla Categoria
SELECT * FROM Producto.Clasificacion
--1) Nombre vac�o (idem con linea):
	EXEC Producto.agregarClasificacion @nombreClasificacion='  ', @linea='LineaNueva'
--2) Nombre NULL (idem con linea):
	EXEC Producto.agregarClasificacion @nombreClasificacion='CategoriaNueva', @linea='   '
--3) Todo_Ok:
	EXEC Producto.agregarClasificacion @nombreClasificacion='CategoriaNueva', @linea='LineaNueva'	

--Tabla Producto
SELECT * FROM Producto.Producto
EXEC Producto.agregarProducto @clasificacion = 'categoriaNueva',@descripcionProducto='Calculadora Cassio con WIFI',
							@precioUnitario = 1050.09,@precioReferencia=1626.16,@unidadReferencia='ud'
--1) clasificaci�n NULL
	EXEC Producto.agregarProducto @clasificacion = '',@descripcionProducto='Calculadora Cassio con WIFI',
		@precioUnitario = 1050.09,@precioReferencia=1626.16,@unidadReferencia='ud'
--2) Clasificaci�n vac�a
	EXEC Producto.agregarProducto @clasificacion = '     ',@descripcionProducto='Calculadora Cassio con WIFI',
		@precioUnitario = 1050.09,@precioReferencia=1626.16,@unidadReferencia='ud'
--3)Nombre producto
	EXEC Producto.agregarProducto @clasificacion = 'categoriaNueva',@descripcionProducto='    ',
		@precioUnitario = 1050.09,@precioReferencia=1626.16,@unidadReferencia='ud'
--4)Precio Unitario Negativo
	EXEC Producto.agregarProducto @clasificacion = 'categoriaNueva',@descripcionProducto='Calculadora Cassio con WIFI',
		@precioUnitario = -1050.09,@precioReferencia=1626.16,@unidadReferencia='ud'
--5)Precio referencia negativo
	EXEC Producto.agregarProducto @clasificacion = 'categoriaNueva',@descripcionProducto='Calculadora Cassio con WIFI',
		@precioUnitario = 1050.09,@precioReferencia=-1626.16,@unidadReferencia='ud'
--6)unidad referencia incorrecto
	EXEC Producto.agregarProducto @clasificacion = 'categoriaNueva',@descripcionProducto='Calculadora Cassio con WIFI',
		@precioUnitario = 1050.09,@precioReferencia=1626.16,@unidadReferencia='    '
--7)Todo_Ok:
	EXEC Producto.agregarProducto @clasificacion = 'categoriaNueva',@descripcionProducto='Calculadora Cassio con WIFI',
		@precioUnitario = 1050.09,@precioReferencia=1626.16,@unidadReferencia='ud'

