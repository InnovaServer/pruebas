ALTER TRIGGER trg_Stock_Dia_TEMP_ALBARAN ON TEMP_ALBARAN
FOR update
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

declare @IdRow int
declare @Id int
declare @IdArticulo as int
declare @Lote as varchar(50)
declare @Pieza as varchar(50)
declare @Ubicacion as int
declare @Almacen_new as int
declare @Almacen_old as int
declare @Fecha_new as datetime
declare @Fecha_old as datetime
declare @Cantidad as decimal(15,5)

if @Accion = 'U'
begin
	declare iterador cursor for 
	select IDROW,ALMACEN,FECHA from inserted
	open iterador
	fetch next from iterador into @IdRow,@Almacen_new, @Fecha_new
	while @@fetch_status = 0
	begin
		select @Almacen_old = (select almacen from deleted where IDROW = @IdRow)
		select @Fecha_old = (select fecha from deleted where IDROW = @IdRow)
		if @Almacen_new <> @Almacen_old 
		or @fecha_new <> @Fecha_old
		begin
			if (select count(*) from TEMP_ALBARANLINEAS where idrow = @IdRow) > 0
				begin


					declare iterador2 cursor for 
					select ARTICULO,LOTE,CANTIDAD from TEMP_ALBARANLINEAS where idrow = @IdRow
					open iterador2
					fetch next from iterador2 into @IdArticulo,@lote,@cantidad
					while @@fetch_status = 0
					begin

						EXEC sp_Stock_Dia_Insert @IdArticulo,@fecha_new,@lote,'',-1,@Almacen_new,@Cantidad,'Albaranes_Venta'
						set @Cantidad = @Cantidad * (-1)
						EXEC sp_Stock_Dia_Insert @IdArticulo,@Fecha_old,@lote,'',-1,@Almacen_old,@Cantidad,'Albaranes_Venta'
		
						fetch next from iterador2 into @IdArticulo,@lote,@cantidad
					end
					close iterador2
					deallocate iterador2
				end
		end

		fetch next from iterador into @IdRow,@Almacen_new, @Fecha_new
	end
	close iterador
	deallocate iterador
end

END