CREATE FUNCTION [dbo].[fn_STOCK_Movtos_Produccion_Consumo_Tejido]
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
			coalesce(AlmacenOrigen,0),
			coalesce(cantidad,0)
from 
(
		-- Se mueve a pelo el almacén 4 porque es el que se utiliza en C.PENALBA y en la tabla no hay selección de almacén)
		select ID as IdRow_Cabecera,ID as IdLinea,MADRE1_IDROW as Articulo, '' as Lote, -1 as localizacion, 4 as AlmacenOrigen ,MUTILIZADOS as cantidad,FECHA 
		from VAYOIL_ORDEN_CORTE
		where
			convert(date,FECHA) >=
				CASE WHEN @ParaStock = 1 
					THEN dbo.fn_Fecha_Ultimo_Inventario (@HastaFecha,MADRE1_IDROW,
																		  CASE WHEN
																		  (select top 1 usar_lotes from CONFIGURACION_ALMACEN) = 0
																				THEN ''
																				ELSE ''--coalesce(lin.lote,'')
																		  END,
															'',
																		  CASE WHEN
																		  (select top 1 USARLOCALIZACION from CONFIGURACION_ALMACEN) = 0
																				THEN -1
																				ELSE -1 --lin.localizacion *** Porque no hay localizaciones
																		  END,
															4) -- Se mueve a pelo el almacén 4 porque es el que se utiliza en C.PENALBA y en la tabla no hay selección de almacén)
					ELSE @DesdeFecha
				END
			AND MADRE1_IDROW = @IdArticulo
			and convert(date,FECHA) <= @HastaFecha

UNION
		-- Se mueve a pelo el almacén 4 porque es el que se utiliza en C.PENALBA y en la tabla no hay selección de almacén)
		select ID as IdRow_Cabecera,ID as IdLinea,MADRE2_IDROW as Articulo, '' as Lote, -1 as localizacion, 4 as AlmacenOrigen ,MUTILIZADOS2 as cantidad,FECHA 
		from VAYOIL_ORDEN_CORTE
		where
			convert(date,FECHA) >=
				CASE WHEN @ParaStock = 1 
					THEN dbo.fn_Fecha_Ultimo_Inventario (@HastaFecha,MADRE1_IDROW,
																		  CASE WHEN
																		  (select top 1 usar_lotes from CONFIGURACION_ALMACEN) = 0
																				THEN ''
																				ELSE ''--coalesce(lin.lote,'')
																		  END,
															'',
																		  CASE WHEN
																		  (select top 1 USARLOCALIZACION from CONFIGURACION_ALMACEN) = 0
																				THEN -1
																				ELSE -1 --lin.localizacion *** Porque no hay localizaciones
																		  END,
															4) -- Se mueve a pelo el almacén 4 porque es el que se utiliza en C.PENALBA y en la tabla no hay selección de almacén)
					ELSE @DesdeFecha
				END
			AND MADRE2_IDROW = @IdArticulo
			and convert(date,FECHA) <= @HastaFecha



) tab1
	
RETURN

END