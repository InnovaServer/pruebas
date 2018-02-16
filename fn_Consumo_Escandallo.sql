/****** Devuelve una tabla con los art�culos y consumos de cada uno de ellos que tiene un determinado art�culo en su escandallo *******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[fn_Consumo_Escandallo]
(
    @IdArticulo int
)
RETURNS @output TABLE(IdArticulo_escandallo int, Cantidad_escandallo decimal(15,5))
BEGIN

INSERT INTO @output (IdArticulo_escandallo, Cantidad_escandallo) -- Para cada art�culo padre guardamos la cantidad de art�culo estudiado que se consume
	(
	SELECT	articulo_escandallo,
			Cantidad
	from 
		(
			select cab.articulo as articulo_escandallo, lin.cantidad as Cantidad
				from articulos_escandallo lin
				left outer join ARTICULOS_ESCANDALLOS cab on cab.idrow = lin.ESCANDALLO 
				where cab.defecto = 1
				and lin.articulo = @IdArticulo -- S�lo toma los que aparezca el art�culo estudiado
		) temp2
	) 

RETURN

END