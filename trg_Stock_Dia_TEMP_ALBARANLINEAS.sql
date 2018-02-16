--select * from stock_dia
ALTER TRIGGER trg_Stock_Dia_TEMP_ALBARANLINEAS ON TEMP_ALBARANLINEAS
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


if @Accion = 'I' or @Accion = 'U'
begin
	declare iterador cursor for 
	select ID,ARTICULO,LOTE,CANTIDAD from inserted
	open iterador
	fetch next from iterador into @Id,@IdArticulo,@lote,@cantidad
	while @@fetch_status = 0
	begin
		select @Almacen = coalesce((select almacen from temp_albaran where idrow = (select idrow from inserted where id = @Id)),-1)
		select @Fecha = coalesce((select fecha from temp_albaran where idrow = (select idrow from inserted where id = @Id)),getdate())
		if @Accion = 'I'
			EXEC sp_Stock_Dia_Insert @IdArticulo,@lote,'',-1,@Almacen,@Cantidad,'Albaranes_Venta'
		else
			if @Cantidad <> (select cantidad from deleted where id = @id)
			or @lote <> (select lote from deleted where id = @id)
				EXEC sp_Stock_Dia_Insert @IdArticulo,@Fecha,@lote,'',-1,@Almacen,@Cantidad,'Albaranes_Venta'

		fetch next from iterador into @Id,@IdArticulo,@lote,@cantidad
	end
	close iterador
	deallocate iterador
end
	
if @Accion = 'D' or @Accion = 'U'
begin
	declare iterador cursor for 
	select ID,ARTICULO,LOTE,CANTIDAD from deleted
	open iterador
	fetch next from iterador into @Id,@IdArticulo,@lote,@cantidad
	while @@fetch_status = 0
	begin
		select @Almacen = coalesce((select almacen from temp_albaran where idrow = (select idrow from deleted where id = @Id)),-1)
		select @Fecha = coalesce((select fecha from temp_albaran where idrow = (select idrow from deleted where id = @Id)),getdate())
		if @Accion = 'D'
			begin
				set @Cantidad = @Cantidad * (-1)
				EXEC sp_Stock_Dia_Insert @IdArticulo,@Fecha,@lote,'',-1,@Almacen,@Cantidad,'Albaranes_Venta'
			end
		else
			begin
				if @Cantidad <> (select cantidad from inserted where id = @id)
				or @lote <> (select lote from inserted where id = @id)
					begin
						set @Cantidad = @Cantidad * (-1)
						EXEC sp_Stock_Dia_Insert @IdArticulo,@Fecha,@lote,'',-1,@Almacen,@Cantidad,'Albaranes_Venta'
					end
			end
		fetch next from iterador into @Id,@IdArticulo,@lote,@cantidad
	end
	close iterador
	deallocate iterador
end


END
