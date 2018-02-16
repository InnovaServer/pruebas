ALTER FUNCTION [dbo].[fn_STOCK_Movtos_Produccion_Consumo_Acabados]
(
    @IdArticulo int,
	@DesdeFecha date,
	@HastaFecha date,
	@ParaStock int -- 1= La FechaDesde ser� la del �ltimo inventario de cada uno anterior a la FechaHasta
	               -- 0= La FechaDesde ser� la que le pasemos como par�metro
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
			almacen,
			coalesce(cantidad,0)
from 
(
		select cab.idrow as IdRow_Cabecera, lin.id as IdLinea, coalesce(alm.idrow, -1) as almacen,disp.ARTICULO_CRUDO as articulo,

							  CASE WHEN
							  (select top 1 usar_lotes from CONFIGURACION_ALMACEN) = 0
									THEN ''
									ELSE coalesce(lin.lote,'')
							  END AS lote,

							  CASE WHEN
							  (select top 1 USARLOCALIZACION from CONFIGURACION_ALMACEN) = 0
									THEN -1
									ELSE -1 -- coalesce(lin.localizacion,-1) *** No hay localizaciones. Cuando se habiliten habr� que descomentar esta l�nea
							  END AS localizacion,
		lin.cantidad  as cantidad


		from ENTRADA_TEJIDODISPUESTO_lineas lin 
		left outer join DISPOSICIONES_LINEAS disp on disp.id = lin.disposicion
		left outer join ENTRADA_TEJIDODISPUESTO cab on cab.idrow = lin.idrow
		left outer join ALMACENES alm on alm.proveedor = cab.PROVEEDOR
		left outer join DISPOSICIONES cab2 on cab2.idrow = disp.idrow
		where 
			convert(date,cab.FECHA) >=
				CASE WHEN @ParaStock = 1 
					THEN dbo.fn_Fecha_Ultimo_Inventario (@HastaFecha,disp.ARTICULO_CRUDO,


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
															coalesce(alm.idrow, -1))



				ELSE @DesdeFecha
			END
		--and disp.articulo in (select IdArticuloPadre_esca from @Escandallos_temp) -- Se ejecuta para cada art�culo padre
		and disp.ARTICULO_CRUDO = @IdArticulo
		and convert(date,lin.fechaentrega) <= @HastaFecha
		and cab2.tipo = 2
) tab1
	
RETURN

END