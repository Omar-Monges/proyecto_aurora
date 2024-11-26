USE Com2900G19
GO
--		DROP PROCEDURE Seguridad.crearMasterKey
CREATE or ALTER PROCEDURE Seguridad.crearMasterKey (@contrasenia Nvarchar(max))
AS BEGIN
	DECLARE @SqlDinamico NVARCHAR(MAX);

	SET @SqlDinamico = N'CREATE MASTER KEY ENCRYPTION BY
						PASSWORD = '''+	@contrasenia +''''
	/*
	CREATE MASTER KEY ENCRYPTION BY
		PASSWORD = 'PepitoContrasenia'
	*/
	EXEC sp_executesql @SqlDinamico;
END
GO

--		DROP PROCEDURE Seguridad.crearCertificado
CREATE or ALTER PROCEDURE Seguridad.crearCertificado
AS BEGIN
	CREATE CERTIFICATE certificadoEmpleadoEncriptacion
		WITH SUBJECT = 'Certificado para encriptados los datos de la tabla empleado';
END
GO

--		DROP Seguridad.crearClaveSimetrica
CREATE or ALTER PROCEDURE Seguridad.crearClaveSimetrica
AS BEGIN
	CREATE SYMMETRIC KEY ClaveSimetrica
		WITH ALGORITHM = AES_256
		ENCRYPTION BY CERTIFICATE certificadoEmpleadoEncriptacion;
END
GO
--		DROP Seguridad.configurarTablaEmpleadoParaEncriptado
CREATE OR ALTER PROCEDURE Seguridad.configurarTablaEmpleadoParaEncriptado
AS BEGIN
	ALTER TABLE Empleado.Empleado
		DROP CONSTRAINT CK_Empleado_DNI;
	ALTER TABLE Empleado.Empleado
		DROP CONSTRAINT CK_Empleado_CUIL;
	ALTER TABLE Empleado.Empleado
		DROP CONSTRAINT CK_Empleado_EmailPersonal;

	ALTER TABLE Empleado.Empleado
		ALTER COLUMN dni NVARCHAR(256);
	ALTER TABLE Empleado.Empleado
		ALTER COLUMN cuil NVARCHAR(256);
	ALTER TABLE Empleado.Empleado
		ALTER COLUMN emailPersonal NVARCHAR(256);
	ALTER TABLE Empleado.Empleado
		ALTER COLUMN direccion NVARCHAR(256)
END
GO
SELECT COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Empleado' 
AND COLUMN_NAME = 'datosEncriptados'
AND TABLE_SCHEMA = 'Empleado';
GO
--		DROP PROCEDURE Seguridad.encriptarTablaEmpleado
CREATE or ALTER PROCEDURE Seguridad.encriptarTablaEmpleado
AS BEGIN
	OPEN SYMMETRIC KEY ClaveSimetrica
	   DECRYPTION BY CERTIFICATE certificadoEmpleadoEncriptacion;

	UPDATE Empleado.Empleado
		SET dni = EncryptByKey(Key_GUID('ClaveSimetrica'), dni),
			cuil = EncryptByKey(Key_GUID('ClaveSimetrica'), cuil),
			emailPersonal = EncryptByKey(Key_GUID('ClaveSimetrica'), emailPersonal),
			direccion = EncryptByKey(Key_GUID('ClaveSimetrica'), direccion);

	CLOSE SYMMETRIC KEY ClaveSimetrica
END
GO
SELECT CONVERT(VARBINARY,cuil) FROM Empleado.Empleado

UPDATE Empleado.Empleado
	SET cuil = CONVERT(VARBINARY,cuil)

SELECT CONVERT(NVARCHAR(256),DECRYPTBYKEY(cuil)) FROM Empleado.Empleado

UPDATE Empleado.Empleado
	SET dni = CONVERT(NVARCHAR(256),DECRYPTBYKEY(dni))

ALTER TABLE EMpleado.Empleado
	ALTER column cuil NVARCHAR(256)

SELECT * FROM Empleado.Empleado
--		EXEC Seguridad.encriptarTablaEmpleado
--		DROP PROCEDURE Seguridad.desencriptarTablaEmpleado
CREATE OR ALTER PROCEDURE Seguridad.desencriptarTablaEmpleado
AS BEGIN
	OPEN SYMMETRIC KEY ClaveSimetrica
		DECRYPTION BY CERTIFICATE certificadoEmpleadoEncriptacion;

	UPDATE Empleado.Empleado
		SET dni = CONVERT(NVARCHAR(256),DECRYPTBYKEY(dni)),
			cuil = CONVERT(nvarchar(256),DECRYPTBYKEY(cuil)),
			emailPersonal = CONVERT(NVARCHAR(256),DECRYPTBYKEY(emailPersonal)),
			direccion = CONVERT(NVARCHAR(256),DECRYPTBYKEY(direccion));


	ALTER TABLE Empleado.Empleado
			ALTER COLUMN dni CHAR(8) NOT NULL;
	ALTER TABLE Empleado.Empleado
			ALTER COLUMN cuil CHAR(13) NOT NULL;
	ALTER TABLE Empleado.Empleado
			ALTER COLUMN emailPersonal VARCHAR(60) NULL;
	ALTER TABLE Empleado.Empleado
			ALTER COLUMN direccion VARCHAR(100) NOT NULL;
		
	ALTER TABLE Empleado.Empleado
			ADD CONSTRAINT CK_Empleado_DNI CHECK(dni LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]');
	ALTER TABLE Empleado.Empleado
			ADD CONSTRAINT CK_Empleado_CUIL CHECK(cuil LIKE '[0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]-[0-9]')
	ALTER TABLE Empleado.Empleado
			ADD CONSTRAINT CK_Empleado_EmailPersonal CHECK(emailPersonal like '%_@__%.__%')

	CLOSE SYMMETRIC KEY ClaveSimetrica
END
GO
EXEC Seguridad.desencriptarTablaEmpleado
SELECT dni,CONVERT(VARBINARY,dni) FROM Empleado.Empleado


SELECT * FROM Empleado.Empleado

--		DROP CERTIFICATE certificadoEmpleadoEncriptacion
--		DROP SYMMETRIC KEY ClaveSimetrica
SELECT 
    d.name AS Default_Constraint_Name,
    c.name AS Column_Name,
    t.name AS Table_Name
FROM 
    sys.default_constraints d
    INNER JOIN sys.columns c ON d.parent_object_id = c.object_id AND d.parent_column_id = c.column_id
    INNER JOIN sys.tables t ON t.object_id = c.object_id
WHERE 
    c.name = 'datosEncriptados' 

/*
		dni CHAR(8) NOT NULL,
		cuil CHAR(13) NOT NULL,
		nombre VARCHAR(30) NOT NULL,
		apellido VARCHAR(30) NOT NULL,
		emailPersonal VARCHAR(60) NULL,
		emailEmpresarial VARCHAR(60) NOT NULL,
		direccion VARCHAR(100) NOT NULL,*/


	OPEN SYMMETRIC KEY ClaveSimetrica
	   DECRYPTION BY CERTIFICATE certificadoEmpleadoEncriptacion;
--SELECT DECRYPTBYKEY(campo1) FROM Empleado.Empleado

--DECLARE @var VARBINARY(256)=(SELECT TOP(1) EncryptByKey(Key_GUID('ClaveSimetrica'),campo1) FROM Empleado.Empleado)
--select CONVERT(VARCHAR(256),DECRYPTBYKEY(@var))

--	CLOSE SYMMETRIC KEY ClaveSimetrica

--	UPDATE Empleado.Empleado
--		set campo1 =  EncryptByKey(Key_GUID('ClaveSimetrica'),CONVERT(varbinary,campo1))
--	UPDATE Empleado.Empleado
--		set campo1 =  CONVERT(NVARCHAR(256),DECRYPTBYKEY(campo1))

--		select  * from Empleado.Empleado

update Empleado.Empleado
	set dni='12345678',
		cuil='20-12345678-3'

	OPEN SYMMETRIC KEY ClaveSimetrica
	   DECRYPTION BY CERTIFICATE certificadoEmpleadoEncriptacion;
SELECT LEN(CONVERT(NVARCHAR(256),DECRYPTBYKEY(dni))) FROM Empleado.Empleado

SELECT * FROM Empleado.Empleado

	OPEN SYMMETRIC KEY ClaveSimetrica
	   DECRYPTION BY CERTIFICATE certificadoEmpleadoEncriptacion;
	CLOSE SYMMETRIC KEY ClaveSimetrica

exec Empleado.agregarEmpleado @dni='42781944',@nombre='XD',@apellido='Guatelli',@sexo='F',
								@emailPersonal='renata@yahoo.com',@emailEmpresa='guatelli@superA.com',
								@idSucursal=1,@turno='Jornada Completa',@cargo='Supervisor',@direccion='EstoEsUnaCalle 123'

INSERT INTO Empleado.Empleado(dni,nombre,apellido,cuil,emailEmpresarial,emailPersonal,idSucursal,turno,idCargo,direccion,empleadoActivo)
	SELECT EncryptByKey(Key_GUID('ClaveSimetrica'), '42781944'),'pepe','ramirez','20-42781944-3','jorge@superA.com','pepe@yahoo.com',1,'TM',2,'EstoEsUnaAvenida 123',1
	

		UPDATE Empleado.Empleado
		SET dni = EncryptByKey(Key_GUID('ClaveSimetrica'), dni),
			cuil = EncryptByKey(Key_GUID('ClaveSimetrica'), cuil),
			emailPersonal = EncryptByKey(Key_GUID('ClaveSimetrica'), emailPersonal),
			direccion = EncryptByKey(Key_GUID('ClaveSimetrica'), direccion);
	


SELECT * FROM Empleado.Empleado


EXEC Seguridad.crearMasterKey 'ContraseniaIndescifrable'
GO
EXEC Seguridad.crearCertificado
GO
EXEC Seguridad.crearClaveSimetrica
GO
EXEC Seguridad.configurarTablaEmpleadoParaEncriptado
GO
EXEC Seguridad.encriptarTablaEmpleado
GO
EXEC Seguridad.desencriptarTablaEmpleado
GO

-- CTRL+K -> CTRL+C
-- CTRL+K -> CTRL+U

---- Primero abre la clave simétrica.
 
-- alter table tablita
--	alter column nombre2 varbinary(256)
-- alter table tablita
--	alter column nombre nvarchar(256)
----Luego introduce los datos
--UPDATE tablita
--	SET nombre = EncryptByKey(Key_GUID('SSN_Clave_Simétrica_01'),CONVERT(varbinary, nombre) ),
--		dni = EncryptByKey(Key_GUID('SSN_Clave_Simétrica_01'),CONVERT(varbinary, dni) );
--GO

--alter table tablita
--	alter column dni nvarchar(256)
--update tablita 
--	set nombre = NULL 
--UPDATE tablita
--SET nombre = CONVERT(VARCHAR(255), DECRYPTBYKEY(nombre2))
--GO

--SELECT * FROM tablita

--CLOSE SYMMETRIC KEY ClaveSimetrica

--SELECT nombre2, 
--       CONVERT(VARCHAR(255), DECRYPTBYKEY(nombre2)) AS nombre_desencriptado
--FROM tablita;



--GO
--DROP TABLE tablita

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