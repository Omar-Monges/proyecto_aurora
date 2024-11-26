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
		DROP CONSTRAINT CK_Empleado_EmailEmpresarial;

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

--		DROP PROCEDURE Seguridad.encriptarTablaEmpleado
CREATE or ALTER PROCEDURE Seguridad.encriptarTablaEmpleado
AS BEGIN
	OPEN SYMMETRIC KEY ClaveSimetrica
	   DECRYPTION BY CERTIFICATE certificadoEmpleadoEncriptacion;

	UPDATE Empleado.Empleado
		SET dni = EncryptByKey(Key_GUID('ClaveSimetrica'), dni),
			cuil = EncryptByKey(Key_GUID('ClaveSimetrica'), cuil),
			emailPersonal = EncryptByKey(Key_GUID('ClaveSimetrica'), emailPersonal),
			direccion = EncryptByKey(Key_GUID('ClaveSimetrica'), direccion)
	CLOSE SYMMETRIC KEY ClaveSimetrica
END
GO

--		DROP PROCEDURE Seguridad.desencriptarTablaEmpleado
CREATE OR ALTER PROCEDURE Seguridad.desencriptarTablaEmpleado
AS BEGIN
	OPEN SYMMETRIC KEY ClaveSimetrica
		DECRYPTION BY CERTIFICATE certificadoEmpleadoEncriptacion;

	UPDATE Empleado.Empleado
		SET dni = CONVERT(NVARCHAR(256),DECRYPTBYKEY(dni)),
			cuil = CONVERT(NVARCHAR(256),DECRYPTBYKEY(cuil)),
			emailPersonal = CONVERT(NVARCHAR(256),DECRYPTBYKEY(emailPersonal)),
			direccion = CONVERT(NVARCHAR(256),DECRYPTBYKEY(direccion))

	SELECT * FROM Empleado.Empleado

	CLOSE SYMMETRIC KEY ClaveSimetrica

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
END

--		DROP CERTIFICATE certificadoEmpleadoEncriptacion
--		DROP SYMMETRIC KEY ClaveSimetrica


/*
		dni CHAR(8) NOT NULL,
		cuil CHAR(13) NOT NULL,
		nombre VARCHAR(30) NOT NULL,
		apellido VARCHAR(30) NOT NULL,
		emailPersonal VARCHAR(60) NULL,
		emailEmpresarial VARCHAR(60) NOT NULL,
		direccion VARCHAR(100) NOT NULL,*/


--	OPEN SYMMETRIC KEY ClaveSimetrica
--	   DECRYPTION BY CERTIFICATE certificadoEmpleadoEncriptacion;
--SELECT DECRYPTBYKEY(campo1) FROM Empleado.Empleado

--DECLARE @var VARBINARY(256)=(SELECT TOP(1) EncryptByKey(Key_GUID('ClaveSimetrica'),campo1) FROM Empleado.Empleado)
--select CONVERT(VARCHAR(256),DECRYPTBYKEY(@var))

--	CLOSE SYMMETRIC KEY ClaveSimetrica

--	UPDATE Empleado.Empleado
--		set campo1 =  EncryptByKey(Key_GUID('ClaveSimetrica'),CONVERT(varbinary,campo1))
--	UPDATE Empleado.Empleado
--		set campo1 =  CONVERT(NVARCHAR(256),DECRYPTBYKEY(campo1))

--		select  * from Empleado.Empleado


SELECT * FROM Empleado.Empleado

	OPEN SYMMETRIC KEY ClaveSimetrica
	   DECRYPTION BY CERTIFICATE certificadoEmpleadoEncriptacion;
	CLOSE SYMMETRIC KEY ClaveSimetrica

exec Empleado.agregarEmpleado @dni='42781944',@nombre='XD',@apellido='Guatelli',@sexo='F',
								@emailPersonal='renata@yahoo.com',@emailEmpresa='guatelli@superA.com',
								@idSucursal=1,@turno='Jornada Completa',@cargo='Supervisor',@direccion='EstoEsUnaCalle 123'

INSERT INTO Empleado.Empleado(dni,nombre,apellido,cuil,emailEmpresarial,emailPersonal,idSucursal,turno,idCargo,direccion,empleadoActivo)
	SELECT '42781944','pepe','ramirez','20-42781944-3','jorge@superA.com','pepe@yahoo.com',1,'TM',2,'EstoEsUnaAvenida 123',1

SELECT * FROM Empleado.Empleado

EXEC Seguridad.crearMasterKey 'ContraseniaIndescifrable'
GO
EXEC Seguridad.crearCertificado
GO
EXEC Seguridad.crearClaveSimetrica
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