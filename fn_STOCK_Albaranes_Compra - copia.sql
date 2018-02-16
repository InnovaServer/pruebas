
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER FUNCTION [dbo].[fn_STOCK_Albaranes_Compra]
(
    @IdArticulo int,
	@HastaFecha date
)
RETURNS @output TABLE(IdArticulo int,Lote varchar(50),Pieza varchar(50),Ubicacion int, Almacen int,	Albaranes_Compra decimal(18,2))

BEGIN

INSERT INTO @output 
			(
			IdArticulo,
			Lote,
			Pieza,
			Ubicacion,
			Almacen,
			Albaranes_Compra
			)
select 
			Articulo,
			coalesce(lote,''),
			coalesce(grplote,''),
			coalesce(localizacion,-1),
			coalesce(almacen,0),
			coalesce(cantidad,0)
from 
(
	select Articulo,convert(varchar,lote) as lote,grplote,localizacion,almacen,sum(cantidad) as cantidad
	from
	(
		select cab.fecha,cab.estado as estado_cab,lin.* 
		from temp_entregaproveedorlineas lin
		left outer join temp_entregaproveedor cab on cab.idrow = lin.idrow
		where lin.ARTICULO = @IdArticulo and convert(date,cab.FECHA) >= dbo.fn_Fecha_Ultimo_Inventario (@HastaFecha,lin.ARTICULO,lin.lote,lin.grplote,lin.localizacion,lin.almacen)
										 and convert(date,cab.FECHA)<=@HastaFecha
										 and cab.estado <> 0 --Se quitan albaranes que no estén verificados
	) temp1
	group by Articulo,lote,grplote,localizacion,almacen
) tab1
	
RETURN

END