
IF EXISTS (SELECT * FROM sys.databases WHERE name = 'Com2900G19')
	USE Com2900G19
ELSE
	RAISERROR('Este script está diseñado para que se ejecute despues del script de la creacion de tablas y esquemas.',20,1);
GO
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
-------------------------------------------------------------------------------------------------------------------
/*
Mensual: ingresando un mes y año determinado mostrar el total facturado por días de
la semana, incluyendo sábado y domingo.
Trimestral: mostrar el total facturado por turnos de trabajo por mes.
Por rango de fechas: ingresando un rango de fechas a demanda, debe poder mostrar
la cantidad de productos vendidos en ese rango, ordenado de mayor a menor.
Por rango de fechas: ingresando un rango de fechas a demanda, debe poder mostrar
la cantidad de productos vendidos en ese rango por sucursal, ordenado de mayor a
menor.
Mostrar los 5 productos más vendidos en un mes, por semana
Mostrar los 5 productos menos vendidos en el mes.
Mostrar total acumulado de ventas (o sea tambien mostrar el detalle) para una fecha
y sucursal particulares
*/

/*
Mensual: ingresando un mes y año determinado mostrar el total facturado por días de
la semana, incluyendo sábado y domingo.
*/
--		DROP PROCEDURE Factura.exportarResumenMensual
--		EXEC Factura.exportarResumenMensual 3,2019
CREATE OR ALTER PROCEDURE Factura.exportarResumenMensual (@mes TINYINT, @anio SMALLINT)
AS BEGIN
	WITH VentasXDiaCTE AS
	(
		SELECT DATENAME(dw,fechaHora) AS Dia,f.cantidad * p.precioReferencia AS Venta
			FROM Factura.Factura f JOIN Producto.Producto p
				ON f.idProducto = p.idProducto
			WHERE MONTH(fechaHora) = @mes AND YEAR(fechaHora) = @anio
	), ResumenDiarioDelMesCTE AS
	(
		SELECT DISTINCT Dia,SUM(Venta) OVER(PARTITION BY Dia) AS Total FROM VentasXDiaCTE
	)
	SELECT * FROM ResumenDiarioDelMesCTE
	FOR XML RAW('Dia'), ROOT('ResumenMensual'), ELEMENTS XSINIL;
END
GO
--SELECT GETDATE()
--SELECT DATEPART(dw,GETDATE())
--SELECT DATENAME(dw,GETDATE())
/*
Trimestral: mostrar el total facturado por turnos de trabajo por mes.

	Trimestre:
		->1: Enero,Febrero,Marzo
		->2: Abril,Mayo,Junio
		->3: Julio,Agosto,Septiembre
		->4: Octubre,Noviembre,Diciembre

	Trimestre:
		->4: 10,11,12
		->3:  7, 8, 9
		->2:  4, 5, 6
		->1:  1, 2, 3
*/
--SELECT * FROM Sucursal.verTurnosDeEmpleados
--		DROP PROCEDURE Factura.exportarResumenTrimestral
--		EXEC Factura.exportarResumenTrimestral 1,2019
CREATE OR ALTER PROCEDURE Factura.exportarResumenTrimestral (@trimestre TINYINT, @anio SMALLINT)
AS BEGIN
	IF(@trimestre > 4 OR @anio < 0)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado exportarResumenTrimestral.',16,15);
		RETURN;
	END
	DECLARE @primerMes  TINYINT = 1,
			@segundoMes TINYINT = 2,
			@tercerMes  TINYINT = 3;

	IF (@trimestre > 1)
	BEGIN
		SET @primerMes = @primerMes + (@trimestre-1) * 3;
		SET @segundoMes = @segundoMes + (@trimestre-1) * 3;
		SET @tercerMes = @tercerMes + (@trimestre-1) * 3;
	END;
	--SELECT @primerMes,@segundoMes,@tercerMes;
	WITH ProductosVendidosXMes (legajo,Monto,Mes) AS
	(
		SELECT f.legajo,f.cantidad * p.precioReferencia,DATENAME(MONTH,fechaHora) FROM Factura.Factura f JOIN Producto.Producto p ON f.idProducto = p.idProducto
		WHERE YEAR(fechaHora) = @anio AND (MONTH(fechaHora) BETWEEN @primerMes AND @tercerMes)
	),MontoTotalXTurno AS
	(
		SELECT Mes,nombreTurno,SUM(Monto) OVER (PARTITION BY Mes, nombreTurno) AS MontoTotal
			FROM ProductosVendidosXMes p JOIN Sucursal.verTurnosDeEmpleados t
				ON p.legajo = t.legajo
	)
	SELECT DISTINCT * 
		FROM MontoTotalXTurno
		FOR XML RAW('VentaMensualXTurno'),ROOT('Trimestre'),ELEMENTS

END
GO
EXEC Factura.exportarResumenTrimestral 1,2019
GO
/*
Por rango de fechas: ingresando un rango de fechas a demanda, debe poder mostrar
la cantidad de productos vendidos en ese rango por sucursal, ordenado de mayor a
menor.
*/
--		Factura.exportarResumenRangoFechas
--		EXEC Factura.exportarResumenRangoFechas @fecha1='2019-1-15',@fecha2='2019-2-24'
CREATE OR ALTER PROCEDURE Factura.exportarResumenRangoFechas (@fecha1 DATE,@fecha2 DATE)
AS BEGIN
	DECLARE @fechaAux DATE;

	IF(@fecha1 IS NULL OR @fecha2 IS NULL)
	BEGIN
		RAISERROR('Error en el procedimiento almacenado exportarResumenRangoFechas.',16,16);
		RETURN;
	END
	IF(@fecha1 > @fecha2)
	BEGIN
		SET @fechaAux = @fecha1;
		SET @fecha1 = @fecha2;
		SET @fecha2 = @fechaAux;
	END;

	WITH ProductosVendidosEnRango AS
	(
		SELECT DISTINCT idSucursal,SUM(cantidad) OVER(PARTITION BY idSucursal) AS CantVentas 
			FROM Factura.Factura
			WHERE fechaHora BETWEEN @fecha1 AND @fecha2
	)
	SELECT * FROM ProductosVendidosEnRango ORDER BY idSucursal DESC
	FOR XML RAW('CantidadDeVentasPorSucursal'),ROOT('MejoresVentas')
END
GO
--Mostrar los 5 productos más vendidos en un mes, por semana

--		DROP PROCEDURE Factura.mostrarTop5ProductosMasVendidosXSemana
--		EXEC Factura.mostrarTop5ProductosMasVendidosXSemana @mes=3,@anio=2019
CREATE OR ALTER Procedure Factura.mostrarTop5ProductosMasVendidosXSemana (@mes TINYINT,@anio SMALLINT)
AS BEGIN
	WITH VentaDeProductosXSemana (producto,montoDeVenta,semana) AS
	(
		SELECT p.descripcionProducto,f.cantidad * p.precioReferencia ,DATEPART(ISO_WEEK,fechaHora)
			FROM Factura.Factura f JOIN Producto.Producto p
				ON  f.idProducto = p.idProducto
			WHERE YEAR(fechaHora) = @anio AND MONTH(fechaHora) = @mes
	),VentaTotalDeProductosXSemana (Semana,Producto,MontoTotal) AS
	(
		SELECT semana,producto,SUM(montoDeVenta) OVER (PARTITION BY semana,producto ORDER BY semana) 
			FROM VentaDeProductosXSemana
	),TopVentasXSemana (semana,producto,montoTotal,TopN) AS
	(
		SELECT semana,producto,montoTotal,DENSE_RANK() OVER(PARTITION BY semana ORDER BY montoTotal DESC)
			FROM VentaTotalDeProductosXSemana
	),TopCincoVentasXSemana (Producto,Total,Semana) AS
	(
		SELECT producto,montoTotal,semana FROM TopVentasXSemana WHERE TopN < 5
	)
	SELECT Semana,Producto,Total FROM TopCincoVentasXSemana

END
GO
--Mostrar los 5 productos menos vendidos en el mes.
--		DROP PROCEDURE Factura.mostrarTop5ProductosMenosVendidosDelMes
--		EXEC Factura.mostrarTop5ProductosMenosVendidosDelMes @mes=2,@anio=2019
CREATE OR ALTER PROCEDURE Factura.mostrarTop5ProductosMenosVendidosDelMes (@mes TINYINT, @anio SMALLINT)
AS BEGIN
	WITH FacturaProductoVenta (producto,monto) AS
	(
	SELECT p.descripcionProducto,f.cantidad*p.precioReferencia
		FROM Factura.Factura f JOIN Producto.Producto p
			ON  f.idProducto = p.idProducto
		WHERE YEAR(fechaHora) = @anio AND MONTH(fechaHora) = @mes
	), MontoTotalXProducto (Producto,Monto) AS
	(
		SELECT DISTINCT producto,SUM(monto) OVER(PARTITION BY producto)
			FROM FacturaProductoVenta
	)
	SELECT TOP(5) * FROM MontoTotalXProducto ORDER BY Monto ASC
END
GO
/*
Mostrar total acumulado de ventas (o sea tambien mostrar el detalle) para una fecha
y sucursal particulares
	SELECT * FROM Factura.Factura;
	SELECT * FROM Factura.verFacturaDetallada;
*/
--		EXEC Factura.exportarResumenRangoFechas @fecha1='2019-1-15',@fecha2='2019-2-24'
--		DROP PROCEDURE Factura.mostrarFacturaDetalladaXSucursalFecha
--		EXEC Factura.mostrarFacturaDetalladaXSucursalFecha @fecha='2019-1-15',@idSucursal=1;
CREATE OR ALTER PROCEDURE Factura.mostrarFacturaDetalladaXSucursalFecha (@fecha DATE, @idSucursal INT)
AS BEGIN
	WITH SucursalCiudad AS
	(
		SELECT s.idSucursal,d.localidad 
			FROM Sucursal.Sucursal s JOIN Direccion.Direccion d
				ON s.idDireccion = d.idDireccion
	),FacturaIds AS
	(
		SELECT f.idFactura,f.idMedioDepago,f.idProducto,s.localidad 
			FROM SucursalCiudad s JOIN Factura.Factura f
				ON s.idSucursal = f.idSucursal
			WHERE s.idSucursal = @idSucursal AND CAST(f.fechaHora as DATE) = @fecha
	),MedioDePagoIds AS
	(
		SELECT f.idFactura,f.idProducto,f.localidad,m.nombreMedioDePago 
			FROM FacturaIds f JOIN Factura.MedioDePago m
				ON f.idMedioDepago = m.idMedioDePago
	),ProductoIds AS
	(
		SELECT m.idFactura,m.localidad,m.nombreMedioDePago,p.descripcionProducto,
				p.idTipoDeProducto,p.precioUnitario
			FROM MedioDePagoIds m JOIN Producto.Producto p
				ON m.idProducto = p.idProducto
	),TipoDeProductoIds AS
	(
		SELECT idFactura,localidad,nombreMedioDePago,descripcionProducto,precioUnitario,nombreTipoDeProducto 
			FROM ProductoIds p JOIN Producto.TipoDeProducto t
				ON p.idTipoDeProducto = t.idTipoDeProducto
	),FacturaDetallada ([ID Factura],[Tipo de Factura],Ciudad,[Tipo De Cliente],Genero,Producto,[Categoría],
						[Monto Acumulado],Fecha,[Medio De Pago],Empleado,[Identificador de pago]) AS
	(
		SELECT f.idFactura, f.tipoFactura,t.localidad,f.tipoCliente,f.genero,t.descripcionProducto,
				t.nombreTipoDeProducto,t.precioUnitario*f.cantidad,CAST(f.fechaHora AS DATE),
				t.nombreMedioDePago,f.legajo,f.identificadorDePago
			FROM TipoDeProductoIds t JOIN Factura.Factura f
				ON t.idFactura = f.idFactura
	)
	SELECT * FROM FacturaDetallada
END
GO
--		DROP VIEW Factura.verFacturaDetallada
--		SELECT * FROM Factura.Factura;
--		SELECT * FROM Factura.verFacturaDetallada
CREATE OR ALTER VIEW Factura.verFacturaDetallada AS
	WITH SucursalCiudad AS
	(
		SELECT s.idSucursal,d.localidad 
			FROM Sucursal.Sucursal s JOIN Direccion.Direccion d
				ON s.idDireccion = d.idDireccion
	),FacturaIds AS
	(
		SELECT f.idFactura,f.idMedioDepago,f.idProducto,s.localidad 
			FROM SucursalCiudad s JOIN Factura.Factura f
				ON s.idSucursal = f.idSucursal
	),MedioDePagoIds AS
	(
		SELECT f.idFactura,f.idProducto,f.localidad,m.nombreMedioDePago 
			FROM FacturaIds f JOIN Factura.MedioDePago m
				ON f.idMedioDepago = m.idMedioDePago
	),ProductoIds AS
	(
		SELECT m.idFactura,m.localidad,m.nombreMedioDePago,p.descripcionProducto,
				p.idTipoDeProducto,p.precioUnitario,p.precioReferencia,p.unidadReferencia
			FROM MedioDePagoIds m JOIN Producto.Producto p
				ON m.idProducto = p.idProducto
	),TipoDeProductoIds AS
	(
		SELECT idFactura,localidad,nombreMedioDePago,descripcionProducto,precioUnitario,precioReferencia,
				unidadReferencia,nombreTipoDeProducto 
			FROM ProductoIds p JOIN Producto.TipoDeProducto t
				ON p.idTipoDeProducto = t.idTipoDeProducto
	),FacturaDetallada ([ID Factura],[Tipo de Factura],Ciudad,[Tipo De Cliente],Genero,Producto,[Categoría],
						[Precio Unitario],Cantidad,Fecha,Hora,[Medio De Pago],Empleado,[Identificador de pago]) AS
	(
		SELECT f.idFactura, f.tipoFactura,t.localidad,f.tipoCliente,f.genero,t.descripcionProducto,
				t.nombreTipoDeProducto,t.precioUnitario,f.cantidad,CAST(f.fechaHora AS DATE),
				CAST(f.fechaHora AS TIME(0)),t.nombreMedioDePago,f.legajo,f.identificadorDePago
			FROM TipoDeProductoIds t JOIN Factura.Factura f
				ON t.idFactura = f.idFactura
	)
	SELECT * FROM FacturaDetallada
GO
