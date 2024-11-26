CREATE TABLE tablita
(
	cod int identity(1,1),
	nombre varchar(100),
	dni VARCHAR(100)
)
GO

INSERT INTO tablita(nombre,dni) VALUES  ('AAA','111'),
									    ('BBB','222'),
										('CCC','333'),
										('DDD','444')
GO


SELECT * FROM tablita


    CREATE MASTER KEY ENCRYPTION BY
		PASSWORD = 'JorgitoContrasenia'
GO
 
CREATE CERTIFICATE NombreDelCertificado
   WITH SUBJECT = 'Certificado Para Ejemplo';
GO
 
CREATE SYMMETRIC KEY SSN_Clave_Simétrica_01
    WITH ALGORITHM = AES_256
    ENCRYPTION BY CERTIFICATE NombreDelCertificado;
GO

-- Primero abre la clave simétrica.
OPEN SYMMETRIC KEY SSN_Clave_Simétrica_01
   DECRYPTION BY CERTIFICATE NombreDelCertificado;
 
--Luego introduce los datos
UPDATE BDEjemplos.Ejemplo
SET ColumnaDatosEncriptados = EncryptByKey(Key_GUID('SSN_Clave_Simétrica_01'), 'Una cadena cualquiera');
GO




GO
DROP TABLE tablita