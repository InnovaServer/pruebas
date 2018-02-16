ALTER FUNCTION [dbo].[fn_STOCK_Movtos_Movtos_Almacen_Destino]
(
    @IdArticulo int,
	@DesdeFecha date,
	@HastaFecha date,
	@ParaStock int -- 1= La FechaDesde será la del último inventario de cada uno anterior a la FechaHasta
	               -- 0= La FechaDesde será la que le pasemos como parámetro
)

RETURNS @output TABLE(IdRow int, IdLinea int, IdArticulo int,Lote varchar(50),Pieza varchar(50),Ubicacion int, Almacen int,	Cantidad decimal(18,2))

BEGIN

INSERT INTO @output 
			(
			IdRow,
			IdLinea,
			IdArticulo,
			Lote,
			Pieza,
			Ubicacion,
			Almacen,
			Cantidad
			)
select 
			IdRow_Cabecera,
			IdLinea,
			Articulo,
			ltrim(rtrim(coalesce(lote,''))),
			'', --coalesce(grplote,''),
			coalesce(localizacion,-1),
			coalesce(almacen,0),
			coalesce(cantidad,0)
from 
(
	select cab.idrow as IdRow_Cabecera, lin.id as IdLinea, cab.ALMACENDESTINO as almacen, lin.Articulo as Articulo, 
	
	
	
			--lin.lote as lote, 
							  CASE WHEN
							  (select top 1 usar_lotes from CONFIGURACION_ALMACEN) = 0
									THEN ''
									ELSE coalesce(lin.lote,'')
							  END AS lote,

			--lin.localizacion as localizacion, 
							  CASE WHEN
							  (select top 1 USARLOCALIZACION from CONFIGURACION_ALMACEN) = 0
									THEN -1
									ELSE coalesce(lin.localizacion,-1)
							  END AS localizacion,
			lin.cantidad as cantidad
	
	
	

	from TEMP_TRASPASOALMACEN_LINEAS lin
	left outer join TEMP_TRASPASOALMACEN cab on cab.idrow = lin.idrow
	where 
		convert(date,cab.FECHA) >=
			CASE WHEN @ParaStock = 1 
				THEN dbo.fn_Fecha_Ultimo_Inventario (@HastaFecha,

														lin.ARTICULO,

																	  CASE WHEN
																	  (select top 1 usar_lotes from CONFIGURACION_ALMACEN) = 0
																			THEN ''
																			ELSE coalesce(lin.lote,'')
																	  END,

														'',

																	  CASE WHEN
																	  (select top 1 USARLOCALIZACION from CONFIGURACION_ALMACEN) = 0
																			THEN -1
																			ELSE coalesce(lin.localizacion,-1)
																	  END,

														cab.ALMACENDESTINO)


				ELSE @DesdeFecha
			END
		and cab.almacen <> cab.almacendestino
		and lin.articulo = @IdArticulo
) tab1
	
RETURN

END