ALTER FUNCTION [dbo].[fn_STOCK_CantidadPendienteLineaPedido] 
(
 @idlineapedido int
)  
RETURNS decimal(18,5)
AS  
BEGIN 
declare @cantidadservida decimal(18,2)=0
declare @cantidadPendiente decimal(18,2)=0

if (select coalesce(servido_manual,0) from TEMP_PEDIDOCLIENTELINEAS where id = @idlineapedido) = 1 -- La línea está marcada como "Servida Manual"
	set @cantidadPendiente = 0
else
	BEGIN
		/* Recoge las líneas servidas en los albaranes*/
		select @cantidadservida = isnull(sum(cantidad),0) from temp_albaranlineas 
			 where pedidolinea = @idlineapedido

		/* Recoge las líneas servidas en los X_albaranes*/
		select @cantidadservida = @cantidadservida+ isnull(sum(cantidad),0) from xtemp_albaranlineas 
			 where pedidolinea = @idlineapedido

		set @cantidadPendiente = (select coalesce(cantidad,0) from TEMP_PEDIDOCLIENTELINEAS where id = @idlineapedido) - @cantidadservida
	END

return @cantidadPendiente
END