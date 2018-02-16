--select * from stock_dia
ALTER TRIGGER trg_Stock_Dia_TEMP_TRASPASOALMACEN_LINEAS ON TEMP_TRASPASOALMACEN_LINEAS
FOR INSERT, update, delete
AS
BEGIN
---------------------------------------------------------------------------------------------------------------------------
-- Devuelve en la variable @Action si es una operacion de insert, update o delete
--
	DECLARE @Accion as char(1);
    SET @Accion = (CASE WHEN EXISTS(SELECT * FROM INSERTED)  -- Si es update se produce un delete con el valor antiguo y un insert con el nuevo
                         AND EXISTS(SELECT * FROM DELETED)
								THEN 'U'  -- Update
                        WHEN EXISTS(SELECT * FROM INSERTED)
								THEN 'I'  -- Insert
                        WHEN EXISTS(SELECT * FROM DELETED)
								THEN 'D'  -- Delete
                        ELSE NULL -- Se produce un error en la operación con la base de datos y no se produce la acción
                    END)
---------------------------------------------------------------------------------------------------------------------------

	declare @Id int
	declare @IdArticulo as int
	declare @Lote as varchar(50)
	declare @Pieza as varchar(50)
	declare @Ubicacion as int
	declare @Almacen as int
	declare @Fecha as datetime
	declare @Cantidad as decimal(15,5)
	declare @Cantidad_Negativa as decimal(15,5)

	declare @Almacen_Origen as int
	declare @Almacen_Destino as int


if @Accion = 'I' or @Accion = 'U'
begin
	declare iterador cursor for 
	select ID,ARTICULO,LOTE,CANTIDAD,ORIGEN,DESTINO,LOCALIZACION from inserted
	open iterador
	fetch next from iterador into @Id,@IdArticulo,@lote,@cantidad,@Almacen_Origen,@Almacen_Destino,@Ubicacion
	while @@fetch_status = 0
	begin
		select @Fecha = coalesce((select FechaEntrega from TEMP_TRASPASOALMACEN where idrow = (select idrow from inserted where id = @Id)),getdate())

		set @Cantidad_Negativa = @Cantidad * (-1)
		if @Accion = 'I'
			begin
				EXEC sp_Stock_Dia_Insert @IdArticulo,@Fecha,@lote,'',@Ubicacion,@Almacen_origen,@Cantidad_Negativa,'Movtos_Almacen_Origen'
				EXEC sp_Stock_Dia_Insert @IdArticulo,@Fecha,@lote,'',@Ubicacion,@Almacen_destino,@Cantidad,'Movtos_Almacen_Destino'
			end
		else
			if @Cantidad <> (select cantidad from deleted where id = @id)
			or @lote <> (select lote from deleted where id = @id)
				begin
					EXEC sp_Stock_Dia_Insert @IdArticulo,@Fecha,@lote,'',@Ubicacion,@Almacen_origen,@Cantidad_Negativa,'Movtos_Almacen_Origen'
					EXEC sp_Stock_Dia_Insert @IdArticulo,@Fecha,@lote,'',@Ubicacion,@Almacen_destino,@Cantidad,'Movtos_Almacen_Destino'
				end
		fetch next from iterador into @Id,@IdArticulo,@lote,@cantidad,@Almacen_Origen,@Almacen_Destino,@Ubicacion
	end
	close iterador
	deallocate iterador
end
	
if @Accion = 'D' or @Accion = 'U'
begin
	declare iterador cursor for 
	select ID,ARTICULO,LOTE,CANTIDAD,ORIGEN,DESTINO,LOCALIZACION  from deleted
	open iterador
	fetch next from iterador into @Id,@IdArticulo,@lote,@cantidad,@Almacen_Origen,@Almacen_Destino,@Ubicacion
	while @@fetch_status = 0
	begin
		select @Fecha = coalesce((select FechaEntrega from TEMP_TRASPASOALMACEN where idrow = (select idrow from deleted where id = @Id)),getdate())
		set @Cantidad_Negativa = @Cantidad * (-1)
		if @Accion = 'D'
			begin
				EXEC sp_Stock_Dia_Insert @IdArticulo,@Fecha,@lote,'',@Ubicacion,@Almacen_origen,@Cantidad,'Movtos_Almacen_Origen'
				EXEC sp_Stock_Dia_Insert @IdArticulo,@Fecha,@lote,'',@Ubicacion,@Almacen_destino,@Cantidad_Negativa,'Movtos_Almacen_Destino'
			end
		else
			begin
				if @Cantidad <> (select cantidad from inserted where id = @id)
				or @lote <> (select lote from inserted where id = @id)
					begin
						EXEC sp_Stock_Dia_Insert @IdArticulo,@Fecha,@lote,'',@Ubicacion,@Almacen_origen,@Cantidad,'Movtos_Almacen_Origen'
						EXEC sp_Stock_Dia_Insert @IdArticulo,@Fecha,@lote,'',@Ubicacion,@Almacen_destino,@Cantidad_Negativa,'Movtos_Almacen_Destino'
					end
			end
		fetch next from iterador into @Id,@IdArticulo,@lote,@cantidad,@Almacen_Origen,@Almacen_Destino,@Ubicacion
	end
	close iterador
	deallocate iterador
end


END
