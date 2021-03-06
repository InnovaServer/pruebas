SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER FUNCTION [dbo].[fn_Fecha_Ultimo_Inventario]
(
 @AFecha date,
 @IdArticulo int,
 @Lote varchar(50),
 @Pieza varchar(50),
 @Ubicacion int,
 @Almacen int
)
returns date
as
begin
declare @value date

select @value = coalesce(max(cab.fecha),0)
				from TEMP_CONSOLIDACIONALMACEN_LINEAS lin
				left outer join TEMP_CONSOLIDACIONALMACEN cab on cab.idrow = lin.idrow
				where cab.fecha <= @AFecha
					and lin.articulo = @IdArticulo

					--and lin_lote = @Lote
					and lin.lote = CASE WHEN
									(select top 1 coalesce(usar_lotes,0) from CONFIGURACION_ALMACEN) = 0
										THEN ''
										ELSE @Lote
									END

					--and lin.Pieza = @Pieza
					and lin.localizacion = CASE WHEN
										(select top 1 coalesce(USARLOCALIZACION,0) from CONFIGURACION_ALMACEN) = 0
											THEN -1
											ELSE @Ubicacion 
										END




					and lin.almacen=@Almacen
					and lin.cantidad >= 0
return @value
end