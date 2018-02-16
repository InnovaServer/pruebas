
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[fn_STOCK_Pedidos_Venta_Pendientes]
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
			'',--Lote
			'',--Pieza
			-1,--Ubicación
			(select top 1 ALMACEN_PRINCIPAL from CONFIGURACION_ALMACEN),--Como los pedidos de venta no tienen almacén, se toma el almacén principal
			coalesce(cantidad,0)
from 
(
	select Articulo,sum(CantidadPendiente) as cantidad
	from
	(
		select dbo.fn_STOCK_CantidadPendienteLineaPedido(lin.id) as CantidadPendiente,lin.Articulo
		from temp_pedidoclientelineas lin
		left outer join temp_pedidocliente cab on cab.idrow = lin.idrow
		where lin.articulo = @IdArticulo 
			-- No se busca la fecha de origen porque en los pedidos no hay lote, almacén, etc... y además hay que sacar TODO lo pendiente anterior a la fecha de estudio
			--and convert(date,cab.FECHA) >= dbo.fn_Fecha_Ultimo_Inventario (@HastaFecha,lin.ARTICULO,'','',0,0)

			and convert(date,cab.FECHA) <= @HastaFecha
			and lin.SERVIDO_MANUAL = 0
	) temp1
	--group by Articulo,lote,grplote,localizacion,almacen
	group by Articulo
) tab1
	
RETURN

END
