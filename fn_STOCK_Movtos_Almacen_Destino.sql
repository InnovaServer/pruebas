SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER FUNCTION [dbo].[fn_STOCK_Movtos_Almacen_Destino]
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
			IdArticulo,
			ltrim(rtrim(coalesce(lote,''))),
			ltrim(rtrim(coalesce(Pieza,''))),
			coalesce(ubicacion,-1),
			coalesce(almacen,0),
			coalesce(cantidad,0)
from 
(
	select IdArticulo,convert(varchar,lote) as lote,Pieza,Ubicacion,almacen,sum(cantidad) as cantidad
	from
	(
		select *
		from fn_STOCK_Movtos_Movtos_Almacen_Destino(@IdArticulo,'01/01/1900',@HastaFecha,1) -- Como se piden movimientos para stock, la FechaDesde no sirve para nada
	) temp1
	group by IdArticulo,lote,Pieza,Ubicacion,Almacen
) tab1
	
RETURN

END