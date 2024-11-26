use Com2900G19
go
--		use master
--		drop database Com2900G19

/*
Mensual: ingresando un mes y año determinado mostrar el total facturado por días de
la semana, incluyendo sábado y domingo.
*/
--		DROP PROCEDURE Venta.ReporteMensualDeUnAnio
--		DECLARE @mes TINYINT = 1, @anio SMALLINT = 2019;EXEC Venta.ReporteMensualDeUnAnio @mes,@anio
CREATE OR ALTER PROCEDURE venta.ReporteMensualDeUnAnio (@mes TINYINT, @anio SMALLINT)
AS BEGIN
	WITH VentasXDiaCTE (Dia,MontoFacturado)AS
	(
		SELECT DISTINCT DATENAME(dw,fechaHora),SUM(totalConIva) OVER(PARTITION BY DATENAME(dw,fechaHora)) FROM Venta.Factura
			WHERE MONTH(fechaHora) = @mes AND YEAR(fechaHora) = @anio
	)
	SELECT * FROM VentasXDiaCTE
	FOR XML RAW('Resumen_Diario'),ROOT('ReporteMensual'),ELEMENTS XSINIL;
END
GO
/*
	Trimestral: mostrar el total facturado por turnos de trabajo por mes.
*/
CREATE OR ALTER PROCEDURE Venta.reporteXTurnos
AS BEGIN
	WITH VentaXTurnoEmpl AS
	(
		SELECT v.idVenta,e.turno FROM Venta.Venta v JOIN Empleado.Empleado e ON v.legajo = e.legajo
	),FacturaXTurnoEmpl (Turno,Mes,TotalFacturado)AS
	(
		SELECT DISTINCT v.turno,DATENAME(MONTH,f.fechaHora),SUM(f.totalConIva) OVER(PARTITION BY v.turno,MONTH(f.fechaHora)) 
			FROM VentaXTurnoEmpl v JOIN Venta.Factura f ON v.idVenta = f.idVenta
	)
	SELECT * FROM FacturaXTurnoEmpl
	FOR XML RAW('VentasXTurno'),ROOT('Total_Facturado_por_Turno_de_trabajo'),ELEMENTS XSINIL
	
END
GO
/*
Por rango de fechas: ingresando un rango de fechas a demanda, debe poder mostrar
la cantidad de productos vendidos en ese rango por sucursal, ordenado de mayor a
menor.
*/
--EXEC Venta.reporteXRangoDeFecha '2019-01-5','2019-02-16'
CREATE OR ALTER PROCEDURE Venta.reporteXRangoDeFecha(@fecha1 DATE,@fecha2 DATE)
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
			FROM Venta.Venta v JOIN Venta.DetalleVenta dv ON v.idVenta = dv.idVenta
			WHERE fechaHoraVenta BETWEEN @fecha1 AND @fecha2
	)
	SELECT * FROM ProductosVendidosEnRango ORDER BY CantVentas DESC
	FOR XML RAW('CantidadDeVentasPorSucursal'),ROOT('MejoresVentas')
END
GO
/*
Mostrar los 5 productos más vendidos en un mes, por semana
*/
--EXEC Venta.reporteCincoProductosMasVendidosXSemana 1
CREATE OR ALTER PROCEDURE Venta.reporteCincoProductosMasVendidosXSemana (@mes TINYINT)
AS BEGIN
	WITH cantProdVendidosXSemana AS
	(
		SELECT DISTINCT descripcionProducto,DATEPART(ISO_WEEK,fechaHoraVenta) AS semana,
				SUM(cantidad) OVER(PARTITION BY DATEPART(ISO_WEEK,fechaHoraVenta),p.idProducto) as cantTotal
			FROM Venta.DetalleVenta dv 
				JOIN Venta.Venta v ON dv.idVenta = v.idVenta
				JOIN Producto.Producto p ON dv.idProducto = p.idProducto
			WHERE MONTH(fechaHoraVenta) = 1
	),topProd (semana,nombreProducto,cantVendidas,topN) AS
	(
		SELECT semana,descripcionProducto,cantTotal,ROW_NUMBER() OVER(PARTITION BY semana ORDER BY semana,cantTotal DESC) AS topN FROM cantProdVendidosXSemana 
	)
	SELECT semana,topN,nombreProducto,cantVendidas FROM topProd WHERE topN <= 5
	FOR XML RAW('SemanaXProductos'),ROOT('TOP_Productos'),ELEMENTS XSINIL
END
GO
/*
Mostrar los 5 productos menos vendidos en el mes.
*/
--		DROP PROCEDURE Venta.reporteCincoProductosMenosVendidosXMes
--		EXEC Venta.reporteCincoProductosMenosVendidosXMes 1
CREATE OR ALTER PROCEDURE Venta.reporteCincoProductosMenosVendidosXMes (@mes TINYINT)
AS BEGIN
	WITH cantProdVendidosXMes AS
	(
		SELECT DISTINCT MONTH(fechaHoraVenta) AS mes,p.descripcionProducto,SUM(cantidad) OVER(PARTITION BY MONTH(fechaHoraVenta),p.idProducto) AS cant
			FROM Venta.Venta v JOIN Venta.DetalleVenta dv ON v.idVenta = dv.idVenta
				JOIN Producto.Producto p ON p.idProducto = dv.idProducto
			WHERE MONTH(fechaHoraVenta) = 1
	),topProd AS
	(
		SELECT *,ROW_NUMBER() OVER(ORDER BY mes,cant) as topN FROM cantProdVendidosXMes 
	)
	SELECT * FROM topProd WHERE topN <= 5
	FOR XML RAW('MesXProductos'),ROOT('TOP_Productos'),ELEMENTS XSINIL
END
GO
/*
Mostrar total acumulado de ventas (o sea tambien mostrar el detalle) para una fecha
y sucursal particulares
*/
--		DROP PROCEDURE Venta.reporteAcumuladoDeVentasXFechaSucursal
--		EXEC Venta.reporteAcumuladoDeVentasXFechaSucursal 2,'2019-03-05'
CREATE OR ALTER PROCEDURE Venta.reporteAcumuladoDeVentasXFechaSucursal (@idSucursal INT,@fecha date)
AS BEGIN
	SELECT idSucursal,CAST(fechaHoraVenta as DATE) AS fecha,f.idVenta,idDetalleVenta,SUM(totalConIva) OVER() as totalAcumulado
		FROM Venta.Venta v 
			JOIN Venta.DetalleVenta dv ON v.idVenta = dv.idVenta
			JOIN Venta.Factura f ON f.idVenta =  dv.idVenta
		WHERE idSucursal = @idSucursal AND CAST(fechaHoraVenta as DATE) = @fecha
	FOR XML RAW('TotalAcumulado'),ROOT('ResumenVentasEnSucursal')
END