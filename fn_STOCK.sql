/****** Object:  UserDefinedFunction [dbo].[fn_STOCK]    Script Date: 05/12/2017 9:11:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER FUNCTION [dbo].[fn_STOCK]
(
    @IdArticulo int
)
RETURNS @output TABLE(IdArticulo int,Lote varchar(50),Pieza varchar(50),Ubicacion int, Almacen int,
			Stock_Inicial decimal(18,2),
			Albaranes_Compra decimal(18,2),
			Albaranes_Venta decimal(18,2) ,
			Facturas_Venta decimal(18,2) ,
			Pedidos_Compra_Pendientes decimal(18,2) ,
			Pedidos_Venta_Pendientes decimal(18,2) ,
			Produccion_Pendiente decimal(18,2) ,
			Movtos_Almacen_Origen decimal(18,2) ,
			Movtos_Almacen_Destino decimal(18,2) ,
			Transformaciones_Origen decimal(18,2) ,
			Transformaciones_Destino decimal(18,2) ,
			Produccion_Entradas decimal(18,2) ,
			Produccion_Consumo decimal(18,2) ,
			Historico decimal(18,2) ,
			Stock decimal(18,2),Disponible decimal(18,2))
BEGIN



--------------------------------------------------------------------------------------------------------------------------------------
-- Se crea una tabla para obtener la fecha de la última regularización (entre stock y stock_dia) de cada artículo, lote, etc...
--------------------------------------------------------------------------------------------------------------------------------------
DECLARE @TEMP TABLE
(
  IdArticulo_temp int, 
  Lote_temp varchar(50),
  Pieza_temp varchar(50),
  Ubicacion_temp int,
  Almacen_temp int,
  FechaMax_temp datetime
)

declare @Usar_LOTES int
declare @Usar_UBICACION int
set @Usar_LOTES= (select top 1 coalesce(usar_lotes,0) from CONFIGURACION_ALMACEN)
set @Usar_UBICACION= (select top 1 coalesce(USARLOCALIZACION,0) from CONFIGURACION_ALMACEN)



INSERT INTO @TEMP (IdArticulo_temp, Lote_temp, Pieza_temp, Ubicacion_temp,Almacen_temp,FechaMax_temp)
	(
	SELECT IdArticulo,Lote,Pieza,Ubicacion,Almacen,max(coalesce(MaxFecha,0)) as MaxFecha
	from 
		(
			SELECT IdArticulo,Lote,Pieza,Ubicacion,Almacen,Fecha_Stock_Inicial as MaxFecha
			FROM STOCK 
			where IdArticulo = @IdArticulo and Stock_Inicial <> 0
			GROUP BY IdArticulo,Lote,Pieza,Ubicacion,Almacen,Fecha_Stock_Inicial
		Union
			SELECT IdArticulo,
						CASE WHEN @Usar_LOTES = 0
							THEN ''
							ELSE coalesce(Lote,'')
						END AS Lote,
					Pieza,
						CASE WHEN @Usar_UBICACION = 0
							THEN -1
							ELSE coalesce(Ubicacion,'')
						END as Ubicacion,
					Almacen,
					FechaHora as MaxFecha
			FROM STOCK_DIA 
			where IdArticulo = @IdArticulo and Stock_Inicial <> 0
			GROUP BY IdArticulo,
					--Lote,
						CASE WHEN @Usar_LOTES = 0
							THEN ''
							ELSE coalesce(lote,'')
						END,
					Pieza,
					Ubicacion,
						CASE WHEN @Usar_UBICACION = 0
							THEN -1
							ELSE coalesce(Ubicacion,'')
						END,

					Almacen,
					FechaHora
		) temp2
	group by IdArticulo,Lote,Pieza,Ubicacion,Almacen
	) 
--------------------------------------------------------------------------------------------------------------------------------------









--------------------------------------------------------------------------------------------------------------------------------------
-- Se crea una tabla con todos los movimientos de STOCK + STOCK_DIA de cada artículo
--------------------------------------------------------------------------------------------------------------------------------------
DECLARE @TEMP_STOCK TABLE
(
  IdArticulo_temp_st int, 
  Lote_temp_st varchar(50),
  Pieza_temp_st varchar(50),
  Ubicacion_temp_st int,
  Almacen_temp_st int,
  Fecha_temp_st datetime,

	Stock_Inicial_temp_st decimal(18,2),
	Albaranes_Compra_temp_st decimal(18,2),
	Albaranes_Venta_temp_st decimal(18,2) ,
	Facturas_Venta_temp_st decimal(18,2) ,
	Pedidos_Compra_Pendientes_temp_st decimal(18,2) ,
	Pedidos_Venta_Pendientes_temp_st decimal(18,2) ,
	Produccion_Pendiente_temp_st decimal(18,2) ,
	Movtos_Almacen_Origen_temp_st decimal(18,2) ,
	Movtos_Almacen_Destino_temp_st decimal(18,2) ,
	Transformaciones_Origen_temp_st decimal(18,2) ,
	Transformaciones_Destino_temp_st decimal(18,2) ,
	Produccion_Entradas_temp_st decimal(18,2) ,
	Produccion_Consumo_temp_st decimal(18,2) ,
	Historico_temp_st decimal(18,2),
	FechaStockMax_temp_st datetime
)

INSERT INTO @TEMP_STOCK (IdArticulo_temp_st, Lote_temp_st, Pieza_temp_st, Ubicacion_temp_st,Almacen_temp_st,Fecha_temp_st,
						Stock_Inicial_temp_st,
						Albaranes_Compra_temp_st,
						Albaranes_Venta_temp_st,
						Facturas_Venta_temp_st,
						Pedidos_Compra_Pendientes_temp_st,
						Pedidos_Venta_Pendientes_temp_st,
						Produccion_Pendiente_temp_st,
						Movtos_Almacen_Origen_temp_st,
						Movtos_Almacen_Destino_temp_st,
						Transformaciones_Origen_temp_st,
						Transformaciones_Destino_temp_st,
						Produccion_Entradas_temp_st,
						Produccion_Consumo_temp_st,
						Historico_temp_st,
						FechaStockMax_temp_st)



/*
DECLARE @TEMP TABLE
(
  IdArticulo_temp int, 
  Lote_temp varchar(50),
  Pieza_temp varchar(50),
  Ubicacion_temp int,
  Almacen_temp int,
  FechaMax_temp datetime


*/

	SELECT temp2.*,
		(select coalesce(FechaMax_temp,0) from @TEMP where IdArticulo_temp = temp2.idArticulo and Lote_temp= temp2.Lote and Pieza_temp=temp2.Pieza and Ubicacion_temp=temp2.ubicacion and Almacen_temp=temp2.Almacen) as MaxFecha 
	from 
		(select * from STOCK where IdArticulo = @IdArticulo
		union
		select * from stock_dia where IdArticulo = @IdArticulo) temp2
	left outer join @TEMP tt on tt.IdArticulo_temp = IdArticulo 
							and tt.Lote_temp = 	Lote 
							and tt.Pieza_temp = Pieza 
							and tt.Ubicacion_temp = Ubicacion 
							and tt.Almacen_temp = Almacen


if (select top 1 usar_lotes from CONFIGURACION_ALMACEN) = 0
	update @TEMP_STOCK set Lote_temp_st = ''

if (select top 1 USARLOCALIZACION from CONFIGURACION_ALMACEN) = 0
	update @TEMP_STOCK set Ubicacion_temp_st = -1



-- Elimina todos los registros de la unión cuya fecha sea anterior a la del último stock_inicial (inventario)
delete from @TEMP_STOCK where Fecha_temp_st < FechaStockMax_temp_st







------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Se crea latabla de salida con un registro por Artículo,Lote,Pieza,Ubicación,Almacén con el acumulado de cada operación y el cálculo de stock y previsión
------------------------------------------------------------------------------------------------------------------------------------------------------------------

INSERT INTO @output (IdArticulo, Lote,Pieza,Ubicacion,Almacen,

			Stock_Inicial ,
			Albaranes_Compra ,
			Albaranes_Venta,
			Facturas_Venta,
			Pedidos_Compra_Pendientes,
			Pedidos_Venta_Pendientes,
			Produccion_Pendiente,
			Movtos_Almacen_Origen,
			Movtos_Almacen_Destino,
			Transformaciones_Origen,
			Transformaciones_Destino,
			Produccion_Entradas,
			Produccion_Consumo,
			Historico,

			Stock,Disponible)

	select idArticulo_temp_st,Lote_temp_st,Pieza_temp_st,Ubicacion_temp_st,Almacen_temp_st,

			coalesce(sum(stock_inicial_temp_st),0) as stock_inicial,
			coalesce(sum(Albaranes_Compra_temp_st),0) as Albaranes_Compra,
			coalesce(sum(Albaranes_Venta_temp_st),0) as Albaranes_Venta,
			coalesce(sum(Facturas_Venta_temp_st),0) as Facturas_Venta,
			coalesce(sum(Pedidos_Compra_Pendientes_temp_st),0) as Pedidos_Compra_Pendientes,
			coalesce(sum(Pedidos_Venta_Pendientes_temp_st),0) as Pedidos_Venta_Pendientes,
			coalesce(sum(Produccion_Pendiente_temp_st),0) as Produccion_Pendiente,
			coalesce(sum(Movtos_Almacen_Origen_temp_st),0) as Movtos_Almacen_Origen,
			coalesce(sum(Movtos_Almacen_Destino_temp_st),0) as Movtos_Almacen_Destino,
			coalesce(sum(Transformaciones_Origen_temp_st),0) as Transformaciones_Origen,
			coalesce(sum(Transformaciones_Destino_temp_st),0) as Transformaciones_Destino,
			coalesce(sum(Produccion_Entradas_temp_st),0) as Produccion_Entradas,
			coalesce(sum(Produccion_Consumo_temp_st),0) as Produccion_Consumo,
			coalesce(sum(Historico_temp_st),0) as Historico,

			0 as stock,	0 as disponible
	from 
	(
		select * from @TEMP_STOCK 
	) temp4 group by idArticulo_temp_st,Lote_temp_st,Pieza_temp_st,Ubicacion_temp_st,Almacen_temp_st
	







	update @output
		set stock = Stock_Inicial 
					+ Albaranes_Compra 
					- Albaranes_Venta
					- Facturas_Venta
					- Movtos_Almacen_Origen
					+ Movtos_Almacen_Destino
					- Transformaciones_Origen
					+ Transformaciones_Destino
					+ Produccion_Entradas
					- Produccion_Consumo
					+ Historico


	update @output
		set disponible = Stock 
						- Pedidos_Venta_Pendientes
						+ Pedidos_Compra_Pendientes

RETURN

END