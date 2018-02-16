ALTER PROCEDURE sp_Stock
(
@AFecha date
)
AS
BEGIN

declare @IdArticulo int = 0
declare @UnArticulo_Solamente int =0

--------------------------------------------------------------------------------------------------------------------------------------
-- Se define una tabla de trabajo que contendrá la fecha de la última regularización de cada combinación de artículos
--------------------------------------------------------------------------------------------------------------------------------------
DECLARE @FechasRegularizacion TABLE
(
	IdArticulo_fec int, 
	Lote_fec varchar(50),
	Pieza_fec varchar(50),
	Ubicacion_fec int,
	Almacen_fec int,
	FechaMax_fec datetime,
	Cantidad_fec decimal(18,2)
)
INSERT INTO @FechasRegularizacion (IdArticulo_fec, Lote_fec, Pieza_fec, Ubicacion_fec,Almacen_fec,FechaMax_fec,Cantidad_fec)
	(
	SELECT	articulo,
			Lote,
			'', --Pieza (actualmente no hay pieza)
			coalesce(localizacion,-1),
			Almacen,
			coalesce(Fecha,0),
			cantidad
	from 
		(
			SELECT *
			FROM
			(
				--SELECT ROW_NUMBER() OVER (PARTITION BY Articulo,Lote,Almacen,Localizacion ORDER BY Fecha desc, id desc) AS Orden, Fecha,Articulo,Almacen,Lote,Cantidad,LOCALIZACION
				SELECT ROW_NUMBER() OVER (PARTITION BY Articulo,Almacen ORDER BY Fecha desc, id desc) AS Orden, Fecha,Articulo,Almacen,Lote,Cantidad,LOCALIZACION
				FROM
 				(
					select cab.fecha,lin.*
					from TEMP_CONSOLIDACIONALMACEN_LINEAS lin
					left outer join TEMP_CONSOLIDACIONALMACEN cab on cab.idrow = lin.idrow
					where 
						Lote = 
							CASE WHEN (select top 1 usar_lotes from CONFIGURACION_ALMACEN) = 0
								THEN ''
								ELSE Lote
							END

						and 

						Localizacion=
							  CASE WHEN (select top 1 USARLOCALIZACION from CONFIGURACION_ALMACEN) = 0
									THEN -1
									ELSE LOCALIZACION
							  END


						--and cab.almacen = cab.almacenDESTINO 
						and cab.fecha <= @AFecha
						and lin.cantidad >= 0
				) temp
			) T1
			WHERE Orden = 1
			and articulo = 
				case when @UnArticulo_Solamente > 0
					THEN @UnArticulo_Solamente
					ELSE articulo
				end

		) temp2
	) 
--------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------

delete from stock

Declare @IdArticulo_fn int = 0
Declare @Lote_fn varchar(50) = ''
Declare @Pieza_fn varchar(50)= ''
Declare @Ubicacion_fn int = 0
Declare @Almacen_fn int = 0
Declare @Cantidad_fn decimal(18,2) = 0

Declare @Veces int = 0

---------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Crea la tabla stock con los datos inciales de stock_inicial y fecha del ultimo inventario
declare iterador_ini cursor for
select IdRow from articulos where control = 1 --Solo procesa los artículos que tengan marcado que tienen control de stock
			and idrow = 
				case when @UnArticulo_Solamente > 0
					THEN @UnArticulo_Solamente
					ELSE idrow
				end

open iterador_ini
fetch next from iterador_ini into @IdArticulo
while @@fetch_status = 0
begin
	insert into STOCK (IdArticulo,Lote,Pieza,Ubicacion,Almacen,Fecha_Stock_Inicial,Stock_Inicial)
		select IdArticulo_fec,
				Lote_fec,
				Pieza_fec,
				Ubicacion_fec,
				Almacen_fec,
				FechaMax_fec,
				Cantidad_fec
		from @FechasRegularizacion where IdArticulo_fec = @IdArticulo
	fetch next from iterador_ini into @IdArticulo
end
close iterador_ini
deallocate iterador_ini
---------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------


declare iterador_articulos cursor for
select IdRow from articulos where control = 1 --Solo procesa los artículos que tengan marcado que tienen control de stock
			and IDROW = 
				case when @UnArticulo_Solamente > 0
					THEN @UnArticulo_Solamente
					ELSE IDROW
				end

open iterador_articulos
fetch next from iterador_articulos into @IdArticulo
while @@fetch_status = 0
begin

-- Albaranes_Compras -------------------------------------------------------------------------------------------------------------

	declare iterador_fn cursor for
	select IdArticulo,Lote,Pieza,Ubicacion,Almacen,Albaranes_Compra from fn_STOCK_Albaranes_Compra (@IdArticulo,@AFecha)
	open iterador_fn
	fetch next from iterador_fn into @IdArticulo_fn,@Lote_fn,@Pieza_fn,@Ubicacion_fn,@Almacen_fn,@Cantidad_fn
	while @@fetch_status = 0
	begin
		select @Veces = coalesce(count(*),0) from STOCK where idArticulo = @IdArticulo_fn and Lote = @Lote_fn and Pieza = @Pieza_fn and Ubicacion = @Ubicacion_fn and Almacen = @Almacen_fn
		
		if @Veces > 0
			begin
				update stock set Albaranes_Compra = @Cantidad_fn where idArticulo = @IdArticulo_fn and Lote = @Lote_fn and Pieza = @Pieza_fn and Ubicacion = @Ubicacion_fn and Almacen = @Almacen_fn
			end
		else
			begin
				insert into STOCK (IdArticulo,Lote,Pieza,Ubicacion,Almacen,Fecha_Stock_Inicial,Stock_Inicial,Albaranes_Compra)
				values (@IdArticulo_fn,@Lote_fn,@Pieza_fn,@Ubicacion_fn,@Almacen_fn,'',0,@Cantidad_fn)
			end
		
		fetch next from iterador_fn into @IdArticulo_fn,@Lote_fn,@Pieza_fn,@Ubicacion_fn,@Almacen_fn,@Cantidad_fn
	end
	close iterador_fn
	deallocate iterador_fn
------------------------------------------------------------------------------------------------------------------------------------



	



-- Albaranes_Venta -------------------------------------------------------------------------------------------------------------

	declare iterador_fn cursor for
	select IdArticulo,Lote,Pieza,Ubicacion,Almacen,Cantidad from fn_STOCK_Albaranes_Venta (@IdArticulo,@AFecha)
	open iterador_fn
	fetch next from iterador_fn into @IdArticulo_fn,@Lote_fn,@Pieza_fn,@Ubicacion_fn,@Almacen_fn,@Cantidad_fn
	while @@fetch_status = 0
	begin
		select @Veces = coalesce(count(*),0) from STOCK where idArticulo = @IdArticulo_fn and Lote = @Lote_fn and Pieza = @Pieza_fn and Ubicacion = @Ubicacion_fn and Almacen = @Almacen_fn
		
		if @Veces > 0
			begin
				update stock set Albaranes_Venta = @Cantidad_fn where idArticulo = @IdArticulo_fn and Lote = @Lote_fn and Pieza = @Pieza_fn and Ubicacion = @Ubicacion_fn and Almacen = @Almacen_fn
			end
		else
			begin
				insert into STOCK (IdArticulo,Lote,Pieza,Ubicacion,Almacen,Fecha_Stock_Inicial,Stock_Inicial,Albaranes_Venta)
				values (@IdArticulo_fn,@Lote_fn,@Pieza_fn,@Ubicacion_fn,@Almacen_fn,'',0,@Cantidad_fn)
			end
		
		fetch next from iterador_fn into @IdArticulo_fn,@Lote_fn,@Pieza_fn,@Ubicacion_fn,@Almacen_fn,@Cantidad_fn
	end
	close iterador_fn
	deallocate iterador_fn
------------------------------------------------------------------------------------------------------------------------------------



	



-- Pedidos_Compra_Pendientes -------------------------------------------------------------------------------------------------------

	declare iterador_fn cursor for
	select IdArticulo,Lote,Pieza,Ubicacion,Almacen,Cantidad from fn_STOCK_Pedidos_Compra_Pendientes (@IdArticulo,@AFecha)
	open iterador_fn
	fetch next from iterador_fn into @IdArticulo_fn,@Lote_fn,@Pieza_fn,@Ubicacion_fn,@Almacen_fn,@Cantidad_fn
	while @@fetch_status = 0
	begin
		select @Veces = coalesce(count(*),0) from STOCK where idArticulo = @IdArticulo_fn and Lote = @Lote_fn and Pieza = @Pieza_fn and Ubicacion = @Ubicacion_fn and Almacen = @Almacen_fn
		
		if @Veces > 0
			begin
				update stock set Pedidos_Compra_Pendientes = @Cantidad_fn where idArticulo = @IdArticulo_fn and Lote = @Lote_fn and Pieza = @Pieza_fn and Ubicacion = @Ubicacion_fn and Almacen = @Almacen_fn
			end
		else
			begin
				insert into STOCK (IdArticulo,Lote,Pieza,Ubicacion,Almacen,Fecha_Stock_Inicial,Stock_Inicial,Pedidos_Compra_Pendientes)
				values (@IdArticulo_fn,@Lote_fn,@Pieza_fn,@Ubicacion_fn,@Almacen_fn,'',0,@Cantidad_fn)
			end
		
		fetch next from iterador_fn into @IdArticulo_fn,@Lote_fn,@Pieza_fn,@Ubicacion_fn,@Almacen_fn,@Cantidad_fn
	end
	close iterador_fn
	deallocate iterador_fn
------------------------------------------------------------------------------------------------------------------------------------



	



-- Pedidos_Venta_Pendientes -------------------------------------------------------------------------------------------------------

	declare iterador_fn cursor for
	select IdArticulo,Lote,Pieza,Ubicacion,Almacen,Cantidad from fn_STOCK_Pedidos_Venta_Pendientes (@IdArticulo,@AFecha)
	open iterador_fn
	fetch next from iterador_fn into @IdArticulo_fn,@Lote_fn,@Pieza_fn,@Ubicacion_fn,@Almacen_fn,@Cantidad_fn
	while @@fetch_status = 0
	begin
		select @Veces = coalesce(count(*),0) from STOCK where idArticulo = @IdArticulo_fn and Lote = @Lote_fn and Pieza = @Pieza_fn and Ubicacion = @Ubicacion_fn and Almacen = @Almacen_fn
		
		if @Veces > 0
			begin
				update stock set Pedidos_Venta_Pendientes = @Cantidad_fn where idArticulo = @IdArticulo_fn and Lote = @Lote_fn and Pieza = @Pieza_fn and Ubicacion = @Ubicacion_fn and Almacen = @Almacen_fn
			end
		else
			begin
				insert into STOCK (IdArticulo,Lote,Pieza,Ubicacion,Almacen,Fecha_Stock_Inicial,Stock_Inicial,Pedidos_Venta_Pendientes)
				values (@IdArticulo_fn,@Lote_fn,@Pieza_fn,@Ubicacion_fn,@Almacen_fn,'',0,@Cantidad_fn)
			end
		
		fetch next from iterador_fn into @IdArticulo_fn,@Lote_fn,@Pieza_fn,@Ubicacion_fn,@Almacen_fn,@Cantidad_fn
	end
	close iterador_fn
	deallocate iterador_fn
------------------------------------------------------------------------------------------------------------------------------------




	



-- Movtos_Almacen_Origen -------------------------------------------------------------------------------------------------------

	declare iterador_fn cursor for -- Movimientos de almacén
	select IdArticulo,Lote,Pieza,Ubicacion,Almacen,Cantidad from fn_STOCK_Movtos_Almacen_Origen (@IdArticulo,@AFecha)
	open iterador_fn
	fetch next from iterador_fn into @IdArticulo_fn,@Lote_fn,@Pieza_fn,@Ubicacion_fn,@Almacen_fn,@Cantidad_fn
	while @@fetch_status = 0
	begin
		select @Veces = coalesce(count(*),0) from STOCK where idArticulo = @IdArticulo_fn and Lote = @Lote_fn and Pieza = @Pieza_fn and Ubicacion = @Ubicacion_fn and Almacen = @Almacen_fn
		
		if @Veces > 0
			begin
				update stock set Movtos_Almacen_Origen = Movtos_Almacen_Origen + @Cantidad_fn where idArticulo = @IdArticulo_fn and Lote = @Lote_fn and Pieza = @Pieza_fn and Ubicacion = @Ubicacion_fn and Almacen = @Almacen_fn
			end
		else
			begin
				insert into STOCK (IdArticulo,Lote,Pieza,Ubicacion,Almacen,Fecha_Stock_Inicial,Stock_Inicial,Movtos_Almacen_Origen)
				values (@IdArticulo_fn,@Lote_fn,@Pieza_fn,@Ubicacion_fn,@Almacen_fn,'',0,@Cantidad_fn)
			end
		
		fetch next from iterador_fn into @IdArticulo_fn,@Lote_fn,@Pieza_fn,@Ubicacion_fn,@Almacen_fn,@Cantidad_fn
	end
	close iterador_fn
	deallocate iterador_fn



	declare iterador_fn cursor for -- Envío de órdenes de confección (traspasa producto de escandallo al almacén del confeccionista y resta del de la empresa)
	select IdArticulo,Lote,Pieza,Ubicacion,Almacen,Cantidad from fn_STOCK_Envio_Ordenes_Confeccion_ORIGEN (@IdArticulo,@AFecha)
	open iterador_fn
	fetch next from iterador_fn into @IdArticulo_fn,@Lote_fn,@Pieza_fn,@Ubicacion_fn,@Almacen_fn,@Cantidad_fn
	while @@fetch_status = 0
	begin
		select @Veces = coalesce(count(*),0) from STOCK where idArticulo = @IdArticulo_fn and Lote = @Lote_fn and Pieza = @Pieza_fn and Ubicacion = @Ubicacion_fn and Almacen = @Almacen_fn
		
		if @Veces > 0
			begin
				update stock set Movtos_Almacen_Origen = Movtos_Almacen_Origen +  @Cantidad_fn where idArticulo = @IdArticulo_fn and Lote = @Lote_fn and Pieza = @Pieza_fn and Ubicacion = @Ubicacion_fn and Almacen = @Almacen_fn
			end
		else
			begin
				insert into STOCK (IdArticulo,Lote,Pieza,Ubicacion,Almacen,Fecha_Stock_Inicial,Stock_Inicial,Movtos_Almacen_Origen)
				values (@IdArticulo_fn,@Lote_fn,@Pieza_fn,@Ubicacion_fn,@Almacen_fn,'',0,@Cantidad_fn)
			end
		
		fetch next from iterador_fn into @IdArticulo_fn,@Lote_fn,@Pieza_fn,@Ubicacion_fn,@Almacen_fn,@Cantidad_fn
	end
	close iterador_fn
	deallocate iterador_fn


	/* Se comenta porque para hacer la orden de acabado el material YA TIENE QUE ESTAR EN EL ALMACEN DEL ACABADOR, por lo que se habrá realizado un traspaso antes.
	declare iterador_fn cursor for -- Envío de órdenes de ACABADO (traspasa producto al almacén del confeccionista y resta del de la empresa)
	select IdArticulo,Lote,Pieza,Ubicacion,Almacen,Cantidad from fn_STOCK_Envio_Ordenes_Acabado_ORIGEN (@IdArticulo,@AFecha)
	open iterador_fn
	fetch next from iterador_fn into @IdArticulo_fn,@Lote_fn,@Pieza_fn,@Ubicacion_fn,@Almacen_fn,@Cantidad_fn
	while @@fetch_status = 0
	begin
		select @Veces = coalesce(count(*),0) from STOCK where idArticulo = @IdArticulo_fn and Lote = @Lote_fn and Pieza = @Pieza_fn and Ubicacion = @Ubicacion_fn and Almacen = @Almacen_fn
		
		if @Veces > 0
			begin
				update stock set Movtos_Almacen_Origen = Movtos_Almacen_Origen +  @Cantidad_fn where idArticulo = @IdArticulo_fn and Lote = @Lote_fn and Pieza = @Pieza_fn and Ubicacion = @Ubicacion_fn and Almacen = @Almacen_fn
			end
		else
			begin
				insert into STOCK (IdArticulo,Lote,Pieza,Ubicacion,Almacen,Fecha_Stock_Inicial,Stock_Inicial,Movtos_Almacen_Origen)
				values (@IdArticulo_fn,@Lote_fn,@Pieza_fn,@Ubicacion_fn,@Almacen_fn,'',0,@Cantidad_fn)
			end
		
		fetch next from iterador_fn into @IdArticulo_fn,@Lote_fn,@Pieza_fn,@Ubicacion_fn,@Almacen_fn,@Cantidad_fn
	end
	close iterador_fn
	deallocate iterador_fn
	*/

------------------------------------------------------------------------------------------------------------------------------------




	



-- Movtos_Almacen_Destino -------------------------------------------------------------------------------------------------------

	declare iterador_fn cursor for
	select IdArticulo,Lote,Pieza,Ubicacion,Almacen,Cantidad from fn_STOCK_Movtos_Almacen_Destino (@IdArticulo,@AFecha)
	open iterador_fn
	fetch next from iterador_fn into @IdArticulo_fn,@Lote_fn,@Pieza_fn,@Ubicacion_fn,@Almacen_fn,@Cantidad_fn
	while @@fetch_status = 0
	begin
		select @Veces = coalesce(count(*),0) from STOCK where idArticulo = @IdArticulo_fn and Lote = @Lote_fn and Pieza = @Pieza_fn and Ubicacion = @Ubicacion_fn and Almacen = @Almacen_fn
		
		if @Veces > 0
			begin
				update stock set Movtos_Almacen_Destino = Movtos_Almacen_Destino + @Cantidad_fn 
				where idArticulo = @IdArticulo_fn and Lote = @Lote_fn and Pieza = @Pieza_fn and Ubicacion = @Ubicacion_fn and Almacen = @Almacen_fn
			end
		else
			begin
				insert into STOCK (IdArticulo,Lote,Pieza,Ubicacion,Almacen,Fecha_Stock_Inicial,Stock_Inicial,Movtos_Almacen_Destino)
				values (@IdArticulo_fn,@Lote_fn,@Pieza_fn,@Ubicacion_fn,@Almacen_fn,'',0,@Cantidad_fn)
			end
		
		fetch next from iterador_fn into @IdArticulo_fn,@Lote_fn,@Pieza_fn,@Ubicacion_fn,@Almacen_fn,@Cantidad_fn
	end
	close iterador_fn
	deallocate iterador_fn






	declare iterador_fn cursor for -- Envío de órdenes de confección (traspasa producto de escandallo al almacén del confeccionista y resta del de la empresa)
	select IdArticulo,Lote,Pieza,Ubicacion,Almacen,Cantidad from dbo.fn_STOCK_Envio_Ordenes_Confeccion_DESTINO (@IdArticulo,@AFecha)
	open iterador_fn
	fetch next from iterador_fn into @IdArticulo_fn,@Lote_fn,@Pieza_fn,@Ubicacion_fn,@Almacen_fn,@Cantidad_fn
	while @@fetch_status = 0
	begin
		select @Veces = coalesce(count(*),0) from STOCK where idArticulo = @IdArticulo_fn and Lote = @Lote_fn and Pieza = @Pieza_fn and Ubicacion = @Ubicacion_fn and Almacen = @Almacen_fn
		
		if @Veces > 0
			begin
				update stock set Movtos_Almacen_Destino = Movtos_Almacen_Destino +  @Cantidad_fn 
				where idArticulo = @IdArticulo_fn and Lote = @Lote_fn and Pieza = @Pieza_fn and Ubicacion = @Ubicacion_fn and Almacen = @Almacen_fn
			end
		else
			begin
				insert into STOCK (IdArticulo,Lote,Pieza,Ubicacion,Almacen,Fecha_Stock_Inicial,Stock_Inicial,Movtos_Almacen_Destino)
				values (@IdArticulo_fn,@Lote_fn,@Pieza_fn,@Ubicacion_fn,@Almacen_fn,'',0,@Cantidad_fn)
			end
		
		fetch next from iterador_fn into @IdArticulo_fn,@Lote_fn,@Pieza_fn,@Ubicacion_fn,@Almacen_fn,@Cantidad_fn
	end
	close iterador_fn
	deallocate iterador_fn




	/*
	declare iterador_fn cursor for -- Envío de órdenes de confección (traspasa producto de escandallo al almacén del confeccionista y resta del de la empresa)
	select IdArticulo,Lote,Pieza,Ubicacion,Almacen,Cantidad from dbo.fn_STOCK_Envio_Ordenes_Acabado_DESTINO (@IdArticulo,@AFecha)
	open iterador_fn
	fetch next from iterador_fn into @IdArticulo_fn,@Lote_fn,@Pieza_fn,@Ubicacion_fn,@Almacen_fn,@Cantidad_fn
	while @@fetch_status = 0
	begin
		select @Veces = coalesce(count(*),0) from STOCK where idArticulo = @IdArticulo_fn and Lote = @Lote_fn and Pieza = @Pieza_fn and Ubicacion = @Ubicacion_fn and Almacen = @Almacen_fn
		
		if @Veces > 0
			begin
				update stock set Movtos_Almacen_Destino = Movtos_Almacen_Destino +  @Cantidad_fn 
				where idArticulo = @IdArticulo_fn and Lote = @Lote_fn and Pieza = @Pieza_fn and Ubicacion = @Ubicacion_fn and Almacen = @Almacen_fn
			end
		else
			begin
				insert into STOCK (IdArticulo,Lote,Pieza,Ubicacion,Almacen,Fecha_Stock_Inicial,Stock_Inicial,Movtos_Almacen_Destino)
				values (@IdArticulo_fn,@Lote_fn,@Pieza_fn,@Ubicacion_fn,@Almacen_fn,'',0,@Cantidad_fn)
			end
		
		fetch next from iterador_fn into @IdArticulo_fn,@Lote_fn,@Pieza_fn,@Ubicacion_fn,@Almacen_fn,@Cantidad_fn
	end
	close iterador_fn
	deallocate iterador_fn
	*/

------------------------------------------------------------------------------------------------------------------------------------




	



-- Transformaciones_Origen -------------------------------------------------------------------------------------------------------

	declare iterador_fn cursor for
	select IdArticulo,Lote,Pieza,Ubicacion,Almacen,Cantidad from fn_STOCK_Transformaciones_Origen (@IdArticulo,@AFecha)
	open iterador_fn
	fetch next from iterador_fn into @IdArticulo_fn,@Lote_fn,@Pieza_fn,@Ubicacion_fn,@Almacen_fn,@Cantidad_fn
	while @@fetch_status = 0
	begin
		select @Veces = coalesce(count(*),0) from STOCK where idArticulo = @IdArticulo_fn and Lote = @Lote_fn and Pieza = @Pieza_fn and Ubicacion = @Ubicacion_fn and Almacen = @Almacen_fn
		
		if @Veces > 0
			begin
				update stock set Transformaciones_Origen = @Cantidad_fn where idArticulo = @IdArticulo_fn and Lote = @Lote_fn and Pieza = @Pieza_fn and Ubicacion = @Ubicacion_fn and Almacen = @Almacen_fn
			end
		else
			begin
				insert into STOCK (IdArticulo,Lote,Pieza,Ubicacion,Almacen,Fecha_Stock_Inicial,Stock_Inicial,Transformaciones_Origen)
				values (@IdArticulo_fn,@Lote_fn,@Pieza_fn,@Ubicacion_fn,@Almacen_fn,'',0,@Cantidad_fn)
			end
		
		fetch next from iterador_fn into @IdArticulo_fn,@Lote_fn,@Pieza_fn,@Ubicacion_fn,@Almacen_fn,@Cantidad_fn
	end
	close iterador_fn
	deallocate iterador_fn
------------------------------------------------------------------------------------------------------------------------------------




	



-- Transformaciones_Destino -------------------------------------------------------------------------------------------------------

	declare iterador_fn cursor for
	select IdArticulo,Lote,Pieza,Ubicacion,Almacen,Cantidad from fn_STOCK_Transformaciones_Destino (@IdArticulo,@AFecha)
	open iterador_fn
	fetch next from iterador_fn into @IdArticulo_fn,@Lote_fn,@Pieza_fn,@Ubicacion_fn,@Almacen_fn,@Cantidad_fn
	while @@fetch_status = 0
	begin
		select @Veces = coalesce(count(*),0) from STOCK where idArticulo = @IdArticulo_fn and Lote = @Lote_fn and Pieza = @Pieza_fn and Ubicacion = @Ubicacion_fn and Almacen = @Almacen_fn
		
		if @Veces > 0
			begin
				update stock set Transformaciones_Destino = @Cantidad_fn where idArticulo = @IdArticulo_fn and Lote = @Lote_fn and Pieza = @Pieza_fn and Ubicacion = @Ubicacion_fn and Almacen = @Almacen_fn
			end
		else
			begin
				insert into STOCK (IdArticulo,Lote,Pieza,Ubicacion,Almacen,Fecha_Stock_Inicial,Stock_Inicial,Transformaciones_Destino)
				values (@IdArticulo_fn,@Lote_fn,@Pieza_fn,@Ubicacion_fn,@Almacen_fn,'',0,@Cantidad_fn)
			end
		
		fetch next from iterador_fn into @IdArticulo_fn,@Lote_fn,@Pieza_fn,@Ubicacion_fn,@Almacen_fn,@Cantidad_fn
	end
	close iterador_fn
	deallocate iterador_fn
------------------------------------------------------------------------------------------------------------------------------------




	



-- Produccion_Entradas -------------------------------------------------------------------------------------------------------

	declare iterador_fn cursor for
	select IdArticulo,Lote,Pieza,Ubicacion,Almacen,Cantidad from fn_STOCK_Produccion_Entradas (@IdArticulo,@AFecha)
	open iterador_fn
	fetch next from iterador_fn into @IdArticulo_fn,@Lote_fn,@Pieza_fn,@Ubicacion_fn,@Almacen_fn,@Cantidad_fn
	while @@fetch_status = 0
	begin
		select @Veces = coalesce(count(*),0) from STOCK where idArticulo = @IdArticulo_fn and Lote = @Lote_fn and Pieza = @Pieza_fn and Ubicacion = @Ubicacion_fn and Almacen = @Almacen_fn
		
		if @Veces > 0
			begin
				update stock set Produccion_Entradas = @Cantidad_fn where idArticulo = @IdArticulo_fn and Lote = @Lote_fn and Pieza = @Pieza_fn and Ubicacion = @Ubicacion_fn and Almacen = @Almacen_fn
			end
		else
			begin
				insert into STOCK (IdArticulo,Lote,Pieza,Ubicacion,Almacen,Fecha_Stock_Inicial,Stock_Inicial,Produccion_Entradas)
				values (@IdArticulo_fn,@Lote_fn,@Pieza_fn,@Ubicacion_fn,@Almacen_fn,'',0,@Cantidad_fn)
			end
		
		fetch next from iterador_fn into @IdArticulo_fn,@Lote_fn,@Pieza_fn,@Ubicacion_fn,@Almacen_fn,@Cantidad_fn
	end
	close iterador_fn
	deallocate iterador_fn
------------------------------------------------------------------------------------------------------------------------------------




	

	

-- Produccion_Consumo -------------------------------------------------------------------------------------------------------


	declare iterador_fn cursor for -- Entradas de órdenes de confección (traspasa producto de escandallo al almacén del confeccionista y resta del de la empresa)
	select IdArticulo,Lote,Pieza,Ubicacion,Almacen,Cantidad from fn_STOCK_Produccion_Consumo (@IdArticulo,@AFecha)
	open iterador_fn
	fetch next from iterador_fn into @IdArticulo_fn,@Lote_fn,@Pieza_fn,@Ubicacion_fn,@Almacen_fn,@Cantidad_fn
	while @@fetch_status = 0
	begin
		select @Veces = coalesce(count(*),0) from STOCK where idArticulo = @IdArticulo_fn and Lote = @Lote_fn and Pieza = @Pieza_fn and Ubicacion = @Ubicacion_fn and Almacen = @Almacen_fn
		
		if @Veces > 0
			begin
				update stock set Produccion_Consumo = Produccion_Consumo +  @Cantidad_fn where idArticulo = @IdArticulo_fn and Lote = @Lote_fn and Pieza = @Pieza_fn and Ubicacion = @Ubicacion_fn and Almacen = @Almacen_fn
			end
		else
			begin
				insert into STOCK (IdArticulo,Lote,Pieza,Ubicacion,Almacen,Fecha_Stock_Inicial,Stock_Inicial,Produccion_Consumo)
				values (@IdArticulo_fn,@Lote_fn,@Pieza_fn,@Ubicacion_fn,@Almacen_fn,'',0,@Cantidad_fn)
			end
		
		fetch next from iterador_fn into @IdArticulo_fn,@Lote_fn,@Pieza_fn,@Ubicacion_fn,@Almacen_fn,@Cantidad_fn
	end
	close iterador_fn
	deallocate iterador_fn


	
	
	
	declare iterador_fn cursor for -- Entradas de órdenes de ACABADO (al no haber escandallo se tiene que restar el tejido entrante del almacén del proveedor)
	select IdArticulo,Lote,Pieza,Ubicacion,Almacen,Cantidad from dbo.fn_STOCK_Produccion_Consumo_Acabados (@IdArticulo,@AFecha)
	open iterador_fn
	fetch next from iterador_fn into @IdArticulo_fn,@Lote_fn,@Pieza_fn,@Ubicacion_fn,@Almacen_fn,@Cantidad_fn
	while @@fetch_status = 0
	begin
		select @Veces = coalesce(count(*),0) from STOCK where idArticulo = @IdArticulo_fn and Lote = @Lote_fn and Pieza = @Pieza_fn and Ubicacion = @Ubicacion_fn and Almacen = @Almacen_fn
		
		if @Veces > 0
			begin
				update stock set Produccion_Consumo = Produccion_Consumo + @Cantidad_fn where idArticulo = @IdArticulo_fn and Lote = @Lote_fn and Pieza = @Pieza_fn and Ubicacion = @Ubicacion_fn and Almacen = @Almacen_fn
			end
		else
			begin
				insert into STOCK (IdArticulo,Lote,Pieza,Ubicacion,Almacen,Fecha_Stock_Inicial,Stock_Inicial,Produccion_Consumo)
				values (@IdArticulo_fn,@Lote_fn,@Pieza_fn,@Ubicacion_fn,@Almacen_fn,'',0,@Cantidad_fn)
			end
		
		fetch next from iterador_fn into @IdArticulo_fn,@Lote_fn,@Pieza_fn,@Ubicacion_fn,@Almacen_fn,@Cantidad_fn
	end
	close iterador_fn
	deallocate iterador_fn
	
	



	
	declare iterador_fn cursor for -- Entradas de órdenes de corte. Descuenta el consumo de tejido del inventario
	select IdArticulo,Lote,Pieza,Ubicacion,Almacen,Cantidad from dbo.fn_STOCK_Produccion_Consumo_Tejido (@IdArticulo,@AFecha)
	open iterador_fn
	fetch next from iterador_fn into @IdArticulo_fn,@Lote_fn,@Pieza_fn,@Ubicacion_fn,@Almacen_fn,@Cantidad_fn
	while @@fetch_status = 0
	begin
		select @Veces = coalesce(count(*),0) from STOCK where idArticulo = @IdArticulo_fn and Lote = @Lote_fn and Pieza = @Pieza_fn and Ubicacion = @Ubicacion_fn and Almacen = @Almacen_fn
		
		if @Veces > 0
			begin
				update stock set Produccion_Consumo = Produccion_Consumo + @Cantidad_fn where idArticulo = @IdArticulo_fn and Lote = @Lote_fn and Pieza = @Pieza_fn and Ubicacion = @Ubicacion_fn and Almacen = @Almacen_fn
			end
		else
			begin
				insert into STOCK (IdArticulo,Lote,Pieza,Ubicacion,Almacen,Fecha_Stock_Inicial,Stock_Inicial,Produccion_Consumo)
				values (@IdArticulo_fn,@Lote_fn,@Pieza_fn,@Ubicacion_fn,@Almacen_fn,'',0,@Cantidad_fn)
			end
		
		fetch next from iterador_fn into @IdArticulo_fn,@Lote_fn,@Pieza_fn,@Ubicacion_fn,@Almacen_fn,@Cantidad_fn
	end
	close iterador_fn
	deallocate iterador_fn
	
	
------------------------------------------------------------------------------------------------------------------------------------












	fetch next from iterador_articulos into @IdArticulo
end
close iterador_articulos
deallocate iterador_articulos

--delete from stock_dia

return

END