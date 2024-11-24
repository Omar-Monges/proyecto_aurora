USE Com2900G19
GO
--		user master
--		drop database Com2900G19

--		DROP PROCEDURE Empleado.ArchComplementario_importarEmpleado
CREATE OR ALTER PROCEDURE Empleado.ArchComplementario_importarEmpleado (@ruta NVARCHAR(MAX))
AS BEGIN
	DECLARE @tabulador CHAR = CHAR(9);
	DECLARE @espacio CHAR = CHAR(10);

	create table #aux
	(
		fila int identity(1,1),
		legajo varchar(max),
		nombre varchar(max),
		apellido varchar(max),
		dni varchar(max),
		sexo varchar(max),
		direccion varchar(max),
		emailPersonal varchar(max),
		emailEmpresarial varchar(max),
		cuil varchar(max),
		cargo varchar(max),
		sucursal varchar(max),
		turno varchar(max)
	)

	create table #direccionAux
	(
		calle varchar(max),
		numeroDeCalle varchar(max),
		codigoPostal varchar(max),
		localidad varchar(max),
		provincia varchar(max)
	)

	DECLARE @direccionAParsear VARCHAR(MAX),
			@calle VARCHAR(MAX),
			@numeroDeCalle VARCHAR(MAX),
			@codigoPostal VARCHAR(MAX),
			@localidad VARCHAR(MAX),
			@provincia VARCHAR(MAX);
	
	DECLARE @SqlDinamico NVARCHAR(MAX);

	SET @SqlDinamico = 'INSERT #aux ';

	SET @SqlDinamico = @SqlDinamico + ' SELECT *
										FROM OPENROWSET(''Microsoft.ACE.OLEDB.16.0'', 
														''Excel 12.0; Database='+ @ruta +'; HDR=YES'', 
														''SELECT * FROM [Empleados$]'')'
	EXECUTE sp_executesql @SqlDinamico;

	DELETE FROM #aux
	WHERE legajo IS NULL

	--SELECT * FROM #aux

	UPDATE #aux
		SET cuil = Empleado.calcularCuil (dni,sexo)
		WHERE cuil IS NULL;

	--DELETE FROM Sucursal.Turno; --Esto borrarlo, es solo pa' q funcione xd
	--SELECT * FROM #aux
	--Agregamos los turnos
	/*
	INSERT INTO Sucursal.Turno
		SELECT DISTINCT turno
			FROM #aux a 
			WHERE NOT EXISTS(Select 1 FROM Sucursal.Turno t 
								WHERE t.nombreTurno <> a.turno COLLATE Modern_Spanish_CI_AI);
	*/
	UPDATE #aux
		SET turno = t.idTurno
		FROM #aux a JOIN Sucursal.Turno t
			ON a.turno = t.nombreTurno COLLATE Modern_Spanish_CI_AI;
	--Agregamos los cargos
	INSERT INTO Sucursal.Cargo
		SELECT DISTINCT cargo
			FROM #aux a
			WHERE NOT EXISTS(SELECT 1 from Sucursal.Cargo c
								WHERE c.nombreCargo <> a.cargo COLLATE Modern_Spanish_CI_AI);
	UPDATE #aux
		SET cargo = c.idCargo
		FROM #aux a JOIN Sucursal.Cargo c
			ON a.cargo = c.nombreCargo COLLATE Modern_Spanish_CI_AI;
	
	UPDATE #aux
		SET sucursal = s.idSucursal
		FROM (SELECT idSucursal,d.localidad 
				FROM Sucursal.Sucursal s JOIN Direccion.Direccion d 
					ON s.idDireccion = d.idDireccion
			) AS s JOIN #aux a ON s.localidad LIKE a.sucursal COLLATE Modern_Spanish_CI_AI;
	--Arreglamos los espacios en blanco
	UPDATE #aux
		SET emailPersonal = REPLACE(emailPersonal,@tabulador,'_'),
			emailEmpresarial = REPLACE(emailEmpresarial,@tabulador,'_')
	UPDATE #aux
		SET emailPersonal = REPLACE(emailPersonal,@espacio,'_'),
			emailEmpresarial = REPLACE(emailEmpresarial,@espacio,'_')
	--SELECT * FROM Sucursal.Turno
	--SELECT * FROM Sucursal.Cargo

	DECLARE @cursorFila INT = 1,
			@ultFila INT = (SELECT ROW_NUMBER() OVER(ORDER BY legajo) AS filas FROM #aux ORDER BY filas DESC)

	WHILE (@cursorFila <= @ultFila)
	BEGIN
		SET @direccionAParsear = (SELECT * FROM #aux WHERE )
		--Aca lo dejo 7/11 10.38 xd
		SET @cursorFila = @cursorFila + 1;
	END

	SELECT * FROM #aux
	DROP TABLE #aux
END;
GO
EXEC Empleado.ArchComplementario_importarEmpleado 'C:\Users\joela\Downloads\TP_integrador_Archivos\TP_integrador_Archivos\Newfolder\Informacion_complementaria.xlsx'
GO
