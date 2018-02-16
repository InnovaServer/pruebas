
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER FUNCTION [dbo].[fn_STOCK_Pedidos_Compra_Pendientes]
(
    @IdArticulo int,
	@HastaFecha date
)
RETURNS @output TABLE(IdArticulo int,Lote varchar(50),Pieza varchar(50),Ubicacion int, Almacen int,	Cantidad decimal(18,2))

BEGIN

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
			Articulo,
			ltrim(rtrim(coalesce(lote,''))),
			ltrim(rtrim(coalesce(grplote,''))),
			coalesce(localizacion,-1),
			coalesce(almacen_cabecera,0),
			coalesce(cantidad,0)
from 
(
	select Articulo,convert(varchar,lote) as lote,'' as grplote,-1 as localizacion,almacen_cabecera,sum(cantidad) as cantidad
	from
	(
		select cab.fecha,cab.estado as estado_cab, cab.almacen as almacen_cabecera,lin.articulo, lin.pendiente as cantidad,'' as lote
		from TEMP_PEDIDOPROVEEDORLINEAS lin
		left outer join TEMP_PEDIDOPROVEEDOR cab on cab.idrow = lin.idrow
		where lin.articulo = @IdArticulo 
			and convert(date,cab.fecha) <= @HastaFecha
			and lin.pendiente <> 0 
			and cab.estado <> 3 
	) temp1
	--group by Articulo,lote,grplote,localizacion,almacen
	group by Articulo,lote,almacen_cabecera
) tab1
	
RETURN

END

/*
select cab.numero,cab.fecha, lin.* 
from TEMP_PEDIDOPROVEEDORLINEAS lin
left outer join TEMP_PEDIDOPROVEEDOR cab on cab.idrow = lin.idrow
where lin.pendiente <> 0 and cab.estado <> 3
order by cab.numero asc
*/
