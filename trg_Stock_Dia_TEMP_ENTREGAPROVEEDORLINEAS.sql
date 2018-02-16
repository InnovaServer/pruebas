ALTER TRIGGER trg_Stock_Dia_TEMP_ENTREGAPROVEEDORLINEAS ON TEMP_ENTREGAPROVEEDORLINEAS
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
declare @Lote_old as varchar(50)
declare @Pieza as varchar(50)
declare @Ubicacion as int
declare @Almacen as int
declare @Cantidad as decimal(15,5)
declare @Inventariado_new int
declare @Inventariado_old int
declare @Fecha datetime


if @Accion = 'I' or @Accion = 'U'
begin
	declare iterador cursor for 
	select ID,ARTICULO,LOTE,CANTIDAD,coalesce(STOCK,0) as STOCK from inserted
	open iterador
	fetch next from iterador into @Id,@IdArticulo,@lote,@cantidad,@Inventariado_new
	while @@fetch_status = 0
	begin
		select @Almacen = coalesce((select almacen from TEMP_ENTREGAPROVEEDOR where idrow = (select idrow from inserted where id = @Id)),-1)
		select @Fecha = coalesce((select fecha from TEMP_ENTREGAPROVEEDOR where idrow = (select idrow from inserted where id = @Id)),getdate())
		select @Inventariado_old = coalesce(STOCK,0) from deleted where id = @id

		if @Accion = 'U' -- Como el movimiento se produce al inventariar o desinventariar, no se tiene en cuenta el insert o el delete de las líneas
			begin
				if @Inventariado_new <> @Inventariado_old
					begin
						if @Inventariado_old = 0 --Se está inventariando
							begin
								EXEC sp_Stock_Dia_Insert @IdArticulo,@Fecha,@lote,'',-1,@Almacen,@Cantidad,'Albaranes_Compra'
							end
						if @Inventariado_new = 0 -- Se está desinventariando
							begin
								select @IdArticulo = Articulo from deleted where id = @Id
								select @lote = Lote from deleted where id = @Id
								select @Cantidad = Cantidad from deleted where id = @Id
								set @Cantidad = @Cantidad * (-1)
								EXEC sp_Stock_Dia_Insert @IdArticulo,@Fecha,@lote,'',-1,@Almacen,@Cantidad,'Albaranes_Compra'
							end
					end
				else
					begin -- Controla el posible cambio de lote cuando la línea está inventariada
						select @lote_old = Lote from deleted where id = @Id
						if @Inventariado_new > 0 and @Lote <> @Lote_old
							begin
								EXEC sp_Stock_Dia_Insert @IdArticulo,@lote,'',-1,@Almacen,@Cantidad,'Albaranes_Compra' -- Suma al lote nuevo
								select @IdArticulo = Articulo from deleted where id = @Id
								select @Cantidad = Cantidad from deleted where id = @Id
								set @Cantidad = @Cantidad * (-1)
								EXEC sp_Stock_Dia_Insert @IdArticulo,@Fecha,@Lote_old,'',-1,@Almacen,@Cantidad,'Albaranes_Compra' -- Resta en el lote viejo
							end
					end
			end
			

		fetch next from iterador into @Id,@IdArticulo,@lote,@cantidad,@Inventariado_new
	end
	close iterador
	deallocate iterador
end
END