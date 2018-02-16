SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER FUNCTION [dbo].[fn_STOCK_Produccion_Consumo]
(
    @IdArticulo int,
	@HastaFecha date
)
RETURNS @output TABLE(IdArticulo int,Lote varchar(50),Pieza varchar(50),Ubicacion int, Almacen int,	Cantidad decimal(18,2))

BEGIN

---------------------------------------------------------------------------------------------------------------------------------------
-- Primero se define una tabla de trabajo que contiene todas las entradas de confeccion entre la fecha del ultimo inventario y la fecha a la que se pide el stock
declare @Movimientos as table(IdRow int, IdLinea int, IdArticulo int,Lote varchar(50),Pieza varchar(50),Ubicacion int, Almacen int,	Cantidad decimal(18,2))
INSERT INTO @Movimientos 
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
select * from fn_STOCK_Movtos_Produccion_Consumo(@IdArticulo,'01/01/1900',@HastaFecha,1)
---------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------

-- Ahora, para cada órden mira los artículos que tenga en el escandallo y genera una tabla de trabajo igual que la que tiene que devolver esta función.
-- Se utiliza una tabla intermedia porque la función tiene que devolver un único registro por articulo, lote, etc...
-- Solo se tienen en cuenta las órdenes ENVIADAS que tengan algo pendiente y no estén servidas manualmente

declare @Consumos as table(IdArticulo int,Lote varchar(50),Pieza varchar(50),Ubicacion int, Almacen int,Cantidad decimal(18,2))

declare @Escandallo int
declare @IdArticulo_Entrada int
declare @Cantidad_Produccion decimal(15,5)
declare @Cantidad_Consumida decimal(15,5)
declare @Almacen_Acabador int
declare @Articulo_Escandallo int
declare @Consumo_Escandallo decimal(15,5)
declare @Fecha_Entrada datetime

declare iterador cursor for 

	select 
		IdArticulo,
		movtos.Cantidad,
		movtos.Almacen,
		ENTRADA_TEJIDODISPUESTO_lineas.fecha as fecha
	from @Movimientos movtos
	left outer join ENTRADA_TEJIDODISPUESTO on ENTRADA_TEJIDODISPUESTO.idrow = movtos.idrow
	left outer join ENTRADA_TEJIDODISPUESTO_lineas on ENTRADA_TEJIDODISPUESTO_lineas.id = movtos.idLinea


open iterador
fetch next from iterador into @IdArticulo_Entrada,@Cantidad_Produccion,@Almacen_Acabador,@Fecha_Entrada
while @@fetch_status = 0
	begin
		select @Escandallo = (select coalesce(IDROW,0) from articulos_escandallos where ARTICULO = @IdArticulo_Entrada and defecto = 1)
		declare iterador_tmp2 cursor for 
		select ARTICULO,CANTIDAD from articulos_escandallo where ESCANDALLO = @Escandallo
		open iterador_tmp2
		fetch next from iterador_tmp2 into @Articulo_escandallo,@Consumo_escandallo
		while @@fetch_status = 0
			begin
				-- Solo se graba en stock si la entrada se ha producido después de la fecha del último inventario de cada complemento del escandallo
				if @Fecha_Entrada >= (select dbo.fn_Fecha_Ultimo_Inventario (@HastaFecha,@Articulo_escandallo,'','',-1,@Almacen_Acabador))
					begin
						set @Cantidad_consumida = @Cantidad_Produccion * @Consumo_escandallo
						insert into @Consumos (IdArticulo,Lote,Pieza,Ubicacion,Almacen,Cantidad)
							values (@Articulo_escandallo,'','',-1,@Almacen_Acabador,@Cantidad_consumida)
					end

				fetch next from iterador_tmp2 into @Articulo_escandallo,@Consumo_escandallo
			end
		close iterador_tmp2
		deallocate iterador_tmp2

		fetch next from iterador into @IdArticulo_Entrada,@Cantidad_Produccion,@Almacen_Acabador,@Fecha_Entrada
	end
close iterador
deallocate iterador

---------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------


-- Para finalizar se graba en la tabla de salida de la función la tabla @Consumos agrupada por artículo

INSERT INTO @output 
			(
			IdArticulo,
			Lote,
			Pieza,
			Ubicacion,
			Almacen,
			Cantidad
			)
select 
			IdArticulo,
			ltrim(rtrim(coalesce(lote,''))),
			ltrim(rtrim(coalesce(Pieza,''))),
			coalesce(ubicacion,-1),
			coalesce(almacen,0),
			coalesce(cantidad,0)
from 
(
	select IdArticulo,convert(varchar,lote) as lote,Pieza,Ubicacion,almacen,sum(cantidad) as cantidad
	from @Consumos
	group by IdArticulo,lote,Pieza,Ubicacion,Almacen
) tab1

RETURN

END