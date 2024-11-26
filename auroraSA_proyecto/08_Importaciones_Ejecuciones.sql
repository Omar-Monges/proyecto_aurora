USE Com2900G19
GO

SELECT * FROM Empleado.Empleado

SELECT * FROM Producto.Producto

SELECT * FROM Producto.Clasificacion

SELECT * FROM Venta.Venta

SELECT * FROM Venta.DetalleVenta

SELECT * FROM Venta.Factura

SELECT * FROM Venta.MedioDePago

SELECT * FROM Empleado.Empleado


--Importamos sucursales
exec Importacion.ArchComplementario_importarSucursal 'C:\Users\joela\Downloads\TP_integrador_Archivos\Informacion_complementaria.xlsx'
GO
--Importamos medios de pagos
exec Importacion.ArchComplementario_importarMedioDePago 'C:\Users\joela\Downloads\TP_integrador_Archivos\Informacion_complementaria.xlsx'
GO
--Importamos empleados
exec Importacion.ArchComplementario_importarEmpleado 'C:\Users\joela\Downloads\TP_integrador_Archivos\Informacion_complementaria.xlsx'
GO
--Importamos la categoría de los producto
exec Importacion.ImportarClasificacionProducto 'C:\Users\joela\Downloads\TP_integrador_Archivos\Informacion_complementaria.xlsx'
GO
--Importamos el  archivo catalogo.csv
exec Importacion.importarCatalogoCSV 'C:\Users\joela\Downloads\TP_integrador_Archivos\Productos\'
GO
--Importamos el archivo de productos electronicos
exec Importacion.importarAccesoriosElectronicos 'C:\Users\joela\Downloads\TP_integrador_Archivos\Productos\Electronic accessories.xlsx'
GO
--Importamos productos importados
exec Importacion.importarProductosImportados 'C:\Users\joela\Downloads\TP_integrador_Archivos\Productos\Productos_importados.xlsx'
GO
--Importamos archivo de ventas realizadas
exec Importacion.importar_Ventas 'C:\Users\joela\Downloads\TP_integrador_Archivos\Ventas_registradas.csv'
GO