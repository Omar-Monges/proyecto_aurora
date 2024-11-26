USE Com2900G19
GO
--		DROP PROCEDURE Seguridad.crearMasterKey
CREATE or ALTER PROCEDURE Seguridad.crearMasterKey (@contrasenia Nvarchar(max))
AS BEGIN
	DECLARE @SqlDinamico NVARCHAR(MAX);

	SET @SqlDinamico = N'CREATE MASTER KEY ENCRYPTION BY
						PASSWORD = '''+	@contrasenia +''''

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

exec Empleado.agregarEmpleado @dni='42781944',@nombre='XD',@apellido='Guatelli',@sexo='F',
								@emailPersonal='renata@yahoo.com',@emailEmpresa='guatelli@superA.com',
								@idSucursal=1,@turno='Jornada Completa',@cargo='Supervisor',@direccion='EstoEsUnaCalle 123'

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
