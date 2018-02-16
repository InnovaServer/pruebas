ALTER FUNCTION [dbo].[fn_STOCK_Movtos_Produccion_Consumo]
(
    @IdArticulo int,
	@DesdeFecha date,
	@HastaFecha date,
	@ParaStock int -- 1= La FechaDesde será la del último inventario de cada uno anterior a la FechaHasta
	               -- 0= La FechaDesde será la que le pasemos como parámetro
)

RETURNS @output TABLE(IdRow int, IdLinea int, IdArticulo int,Lote varchar(50),Pieza varchar(50),Ubicacion int, Almacen int,	Cantidad decimal(18,2))

BEGIN
/*
--------------------------------------------------------------------------------------------------------------------------------------
-- Se define una tabla de trabajo que contendrá todos los artículos en cuyo escandallo aparece el artículo estudiado
--------------------------------------------------------------------------------------------------------------------------------------
DECLARE @Escandallos_temp TABLE
(
	IdArticuloPadre_esca int,
	Cantidad_esca decimal(18,5)
)
INSERT INTO @Escandallos_temp (IdArticuloPadre_esca, Cantidad_esca) -- Para cada artículo padre guardamos la cantidad de artículo estudiado que se consume
	(
	SELECT	articulo_escandallo,
			Cantidad
	from 
		(
			select cab.articulo as articulo_escandallo, lin.cantidad as Cantidad
				from articulos_escandallo lin
				left outer join ARTICULOS_ESCANDALLOS cab on cab.idrow = lin.ESCANDALLO 
				where cab.defecto = 1
				and lin.articulo = @IdArticulo -- Sólo toma los que aparezca el artículo estudiado
		) temp2
	) 
--------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------
*/


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
			coalesce(AlmacenOrigen,0),
			coalesce(cantidad,0)
from 
(
		select cab.idrow as IdRow_Cabecera, lin.id as IdLinea, cab.almacen as almacen,disp.ARTICULO_CRUDO as articulo,coalesce(alm.idrow,-1) as AlmacenOrigen,

							  CASE WHEN
							  (select top 1 usar_lotes from CONFIGURACION_ALMACEN) = 0
									THEN ''
									ELSE coalesce(lin.lote,'')
							  END AS lote,

							  CASE WHEN
							  (select top 1 USARLOCALIZACION from CONFIGURACION_ALMACEN) = 0
									THEN -1
									ELSE -1 -- coalesce(lin.localizacion,-1) *** No hay localizaciones. Cuando se habiliten habrá que descomentar esta línea
							  END AS localizacion,
		lin.cantidad  as cantidad



		from ENTRADA_TEJIDODISPUESTO_lineas lin 
		left outer join DISPOSICIONES_LINEAS disp on disp.id = lin.disposicion
		left outer join ENTRADA_TEJIDODISPUESTO cab on cab.idrow = lin.idrow
		left outer join ALMACENES alm on alm.proveedor = cab.PROVEEDOR
		where 
			convert(date,cab.FECHA) >=
				CASE WHEN @ParaStock = 1 
					THEN dbo.fn_Fecha_Ultimo_Inventario (@HastaFecha,disp.ARTICULO,


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
															cab.almacen)



				ELSE @DesdeFecha
			END
		--and disp.articulo in (select IdArticuloPadre_esca from @Escandallos_temp) -- Se ejecuta para cada artículo padre
		and disp.ARTICULO_CRUDO = @IdArticulo
		and convert(date,lin.fechaentrega) <= @HastaFecha
) tab1
	
RETURN

END