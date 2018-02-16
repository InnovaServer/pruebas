ALTER TRIGGER trg_Stock_Dia_ENTRADA_TEJIDODISPUESTO_LINEAS ON ENTRADA_TEJIDODISPUESTO_LINEAS
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
declare @IdRow int
declare @IdArticulo as int
declare @Lote as varchar(50)
declare @Pieza as varchar(50)
declare @Ubicacion as int
declare @Almacen as int
declare @Cantidad as decimal(15,5)
declare @Cantidad_Negativa as decimal(15,5)
declare @Fecha as datetime
declare @Disposicion as int
declare @Inventariado_Old as int

/*
No se contemplan otros casos porque una vez inventariado no se puede hacer nada con el registro.
*/

if @Accion = 'I' or @Accion = 'U'
begin
	declare iterador cursor for 
	select ID,LOTE,CANTIDAD,FECHAENTREGA,DISPOSICION,IDROW from inserted
	open iterador
	fetch next from iterador into @Id,@lote,@cantidad,@Fecha,@Disposicion,@IdRow
	while @@fetch_status = 0
	begin
		select @IdArticulo = articulo from DISPOSICIONES_LINEAS where ID = @Disposicion
		select @Almacen = coalesce(almacen,-1) from ENTRADA_TEJIDODISPUESTO where idrow = @IdRow

		if @Accion = 'I'
			EXEC sp_Stock_Dia_Insert @IdArticulo,@Fecha,@lote,'',@Ubicacion,@Almacen,@Cantidad,'Produccion_Entradas'
		else
			if @Cantidad <> (select cantidad from deleted where id = @id)
			or @lote <> (select lote from deleted where id = @id)
				EXEC sp_Stock_Dia_Insert @IdArticulo,@Fecha,@lote,'',@Ubicacion,@Almacen,@Cantidad,'Produccion_Entradas'

		fetch next from iterador into @Id,@lote,@cantidad,@Fecha,@Disposicion,@IdRow
	end
	close iterador
	deallocate iterador
end


if @Accion = 'D' or @Accion = 'U'
begin
	declare iterador cursor for 
	select ID,LOTE,CANTIDAD,FECHAENTREGA,DISPOSICION,IDROW from deleted
	open iterador
	fetch next from iterador into @Id,@lote,@cantidad,@Fecha,@Disposicion,@IdRow
	while @@fetch_status = 0
	begin
		select @IdArticulo = articulo from DISPOSICIONES_LINEAS where ID = @Disposicion
		select @Almacen = coalesce(almacen,-1) from ENTRADA_TEJIDODISPUESTO where idrow = @IdRow

		if @Accion = 'D'
			begin
				set @Cantidad = @Cantidad * (-1)
				EXEC sp_Stock_Dia_Insert @IdArticulo,@Fecha,@lote,'',-1,@Almacen,@Cantidad,'Produccion_Entradas'
			end
		else
			begin
				if @Cantidad <> (select cantidad from inserted where id = @id)
				or @lote <> (select lote from inserted where id = @id)
					begin
						set @Cantidad = @Cantidad * (-1)
						EXEC sp_Stock_Dia_Insert @IdArticulo,@Fecha,@lote,'',-1,@Almacen,@Cantidad,'Produccion_Entradas'
					end
			end

		fetch next from iterador into @Id,@lote,@cantidad,@Fecha,@Disposicion,@IdRow
	end
	close iterador
	deallocate iterador
end

END