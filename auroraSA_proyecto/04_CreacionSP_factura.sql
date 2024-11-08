
IF EXISTS (SELECT * FROM sys.databases WHERE name = 'Com2900G19')
	USE Com2900G19
ELSE
	RAISERROR('Este script está diseñado para que se ejecute despues del script de la creacion de tablas y esquemas.',20,1);
GO
/*
	
--Esquema Factura
	Tabla Factura
		agregarFactura
		modificarFactura				falta hacer
		eliminarFactura					falta hacer
										falta hacer
		pasajeDolarAPesos -->sera?		falta hacer
										falta hacer
	Tabla DetalleFactura				falta hacer
		agregarProducto					falta hacer
		modificarProducto				falta hacer
		eliminarProducto				falta hacer
*/
------------------------------------------------Factura------------------------------------------------
--		DROP PROCEDURE Factura.agregarFactura
CREATE OR ALTER PROCEDURE Factura.agregarFactura(@tipoFactura CHAR, @tipoCliente VARCHAR(10), @genero VARCHAR(10),
												@fechaHora SMALLDATETIME, @idMedioDePago INT, @legajo INT,
												@idSucursal INT, @idDePago INT,@idProducto INT,@cantidad SMALLINT)
AS BEGIN
	IF(LEN(LTRIM(@tipoCliente)) = 0 OR LEN(LTRIM(@genero)) = 0)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado agregarFactura.',16,14);
		RETURN;
	END

	INSERT INTO Factura.Factura (tipoFactura,tipoCliente,genero,fechaHora,idMedioDepago,legajo,idSucursal,identificadorDePago,idProducto,cantidad)
		VALUES (@tipoFactura,@tipoCLiente,@genero,@fechaHora,@idMedioDePago,@legajo,@idSucursal,@idDePago,@idProducto,@cantidad);

END
GO