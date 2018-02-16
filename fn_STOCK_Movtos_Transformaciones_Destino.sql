ALTER FUNCTION [dbo].[fn_STOCK_Movtos_Transformaciones_Destino]
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
			-1, --coalesce(localizacion,-1),
			coalesce(almacen,0),
			coalesce(cantidad,0)
from 
(
	select cab.idrow as IdRow_Cabecera, lin.id as IdLinea,lin.almacen as Almacen,lin.ARTICULO,



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
									ELSE -1 -- coalesce(lin.localizacion,-1) *** No hay localizaciones. Cuando se habiliten habrá que descomentar esta línea
							  END AS localizacion,
			lin.cantidad as cantidad



	from TEMP_TRANSFORMACIONES_DESTINO lin
	left outer join TEMP_TRANSFORMACIONES cab on cab.idrow = lin.idrow
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
																			ELSE -1 --lin.localizacion *** Porque no hay localizaciones
																	  END,

														lin.almacen)




				ELSE @DesdeFecha
			END
		and lin.articulo = @IdArticulo
		and convert(date,cab.fecha) <= @HastaFecha
) tab1
	
RETURN

END