SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER FUNCTION [dbo].[fn_STOCK_Envio_Ordenes_Confeccion_ORIGEN]
(
    @IdArticulo int,
	@HastaFecha date
)
RETURNS @output TABLE(IdArticulo int,Lote varchar(50),Pieza varchar(50),Ubicacion int, Almacen int,	Cantidad decimal(18,2))

BEGIN

---------------------------------------------------------------------------------------------------------------------------------------
-- Primero se define una tabla de trabajo que contiene todas las �rdenes de confecci�n entre la fecha del ultimo inventario y la fecha a la que se pide el stock
print @IdArticulo
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
select * from fn_STOCK_Movtos_Envio_Ordenes_Confeccion_ORIGEN(@IdArticulo,'01/01/1900',@HastaFecha,1)
---------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------

-- Ahora, para cada �rden mira los art�culos que tenga en el escandallo y genera una tabla de trabajo igual que la que tiene que devolver esta funci�n.
-- Se utiliza una tabla intermedia porque la funci�n tiene que devolver un �nico registro por articulo, lote, etc...
-- Solo se tienen en cuenta las �rdenes ENVIADAS que tengan algo pendiente y no est�n servidas manualmente

declare @Consumos as table(IdArticulo int,Lote varchar(50),Pieza varchar(50),Ubicacion int, Almacen int,Cantidad decimal(18,2))

declare @Escandallo int
declare @IdArticulo_Produccion int
declare @Cantidad_Produccion decimal(15,5)
declare @Cantidad_Consumida decimal(15,5)
declare @Almacen_MateriasPrimas int
declare @Articulo_Escandallo int
declare @Consumo_Escandallo decimal(15,5)

declare iterador cursor for 

	select 
		ARTICULO,
		DISPOSICIONES_LINEAS.PENDIENTE as cantidad,
		DISPOSICIONES.Almacen as almacen
	from @Movimientos movtos
	left outer join DISPOSICIONES on DISPOSICIONES.idrow = movtos.idrow
	left outer join DISPOSICIONES_LINEAS on DISPOSICIONES_LINEAS.id = movtos.idLinea
	where	DISPOSICIONES.Enviada = 1
		and DISPOSICIONES_LINEAS.pendiente > 0
		and DISPOSICIONES_LINEAS.completo = 0
		and DISPOSICIONES.completo = 0

open iterador
fetch next from iterador into @IdArticulo_Produccion,@Cantidad_Produccion,@Almacen_MateriasPrimas
while @@fetch_status = 0
	begin
		select @Escandallo = (select coalesce(IDROW,0) from articulos_escandallos where ARTICULO = @IdArticulo_Produccion and defecto = 1)
		declare iterador_tmp2 cursor for 
		select ARTICULO,CANTIDAD from articulos_escandallo where ESCANDALLO = @Escandallo
		open iterador_tmp2
		fetch next from iterador_tmp2 into @Articulo_escandallo,@Consumo_escandallo
		while @@fetch_status = 0
			begin
				set @Cantidad_consumida = @Cantidad_Produccion * @Consumo_escandallo
				insert into @Consumos (IdArticulo,Lote,Pieza,Ubicacion,Almacen,Cantidad)
					values (@Articulo_escandallo,'','',-1,@Almacen_MateriasPrimas,@Cantidad_consumida)

				fetch next from iterador_tmp2 into @Articulo_escandallo,@Consumo_escandallo
			end
		close iterador_tmp2
		deallocate iterador_tmp2

		fetch next from iterador into @IdArticulo_Produccion,@Cantidad_Produccion,@Almacen_MateriasPrimas
	end
close iterador
deallocate iterador

---------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------


-- Para finalizar se graba en la tabla de salida de la funci�n la tabla @Consumos agrupada por art�culo

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