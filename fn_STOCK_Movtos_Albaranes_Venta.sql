ALTER FUNCTION [dbo].[fn_STOCK_Movtos_Albaranes_Venta]
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
			Localizacion, --coalesce(localizacion,-1),
			coalesce(almacen,0),
			coalesce(cantidad,0)
from 
(
	select cab.idrow as IdRow_Cabecera, lin.id as IdLinea, lin.articulo,

	

							  CASE WHEN
							  (select top 1 usar_lotes from CONFIGURACION_ALMACEN) = 0
									THEN ''
									ELSE lin.lote
							  END AS lote,

							  CASE WHEN
							  (select top 1 USARLOCALIZACION from CONFIGURACION_ALMACEN) = 0
									THEN -1
									ELSE -1 -- lin.localizacion  ***Porque en albaranes de venta no hay posibilidad de poner localizaciones. Cuando se puedan poner hay que cambiarlo.
							  END AS Localizacion,


	cab.almacen, lin.CANTIDAD

	from temp_albaranlineas lin
	left outer join temp_albaran cab on cab.idrow = lin.idrow
	where 
		convert(date,cab.FECHA) >=
			CASE WHEN @ParaStock = 1 
				THEN dbo.fn_Fecha_Ultimo_Inventario (@HastaFecha,lin.ARTICULO,
							  CASE WHEN
							  (select top 1 usar_lotes from CONFIGURACION_ALMACEN) = 0
									THEN ''
									ELSE lin.lote
							  END,
						'', --Pieza
							  CASE WHEN
							  (select top 1 USARLOCALIZACION from CONFIGURACION_ALMACEN) = 0
									THEN -1
									ELSE -1 -- lin.localizacion  ***Porque en albaranes de venta no hay posibilidad de poner localizaciones. Cuando se puedan poner hay que cambiarlo.
							  END,
						cab.almacen)
				ELSE @DesdeFecha
			END
	and convert(date,cab.FECHA)<=@HastaFecha
	and	lin.ARTICULO = @IdArticulo 
) tab1
	
RETURN

END