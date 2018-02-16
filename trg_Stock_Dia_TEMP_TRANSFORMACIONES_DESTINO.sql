CREATE TRIGGER trg_Stock_Dia_TEMP_TRANSFORMACIONES_DESTINO ON TEMP_TRANSFORMACIONES_DESTINO
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
declare @Cantidad as decimal(15,5)
declare @Cantidad_Negativa as decimal(15,5)
declare @Fecha as datetime
declare @Inventariado_New as int
declare @Inventariado_Old as int

/*
No se contemplan otros casos porque una vez inventariado no se puede hacer nada con el registro.
*/

if @Accion = 'U' -- No se contempla el INSERT porque al insertar la línea no se genera el movimiento de almacén
begin
	declare iterador cursor for 
	select ID,ARTICULO,LOTE,CANTIDAD,STOCK,FECHA,ALMACEN from inserted
	open iterador
	fetch next from iterador into @Id,@IdArticulo,@lote,@cantidad,@Inventariado_New,@Fecha,@Almacen
	while @@fetch_status = 0
	begin
		select @Inventariado_Old= stock from deleted where id = @id

		if @Inventariado_New <> @Inventariado_Old and @Inventariado_New > 0 -- Se está inventariando
			begin
				EXEC sp_Stock_Dia_Insert @IdArticulo,@Fecha,@lote,'',@Ubicacion,@Almacen,@Cantidad,'Transformaciones_Destino'
			end

		fetch next from iterador into @Id,@IdArticulo,@lote,@cantidad,@Inventariado_New,@Fecha,@Almacen
	end
	close iterador
	deallocate iterador
end

if @Accion = 'U' -- No se contempla el DELETE porque no se puede eliminar el registro si está inventariado
begin
	declare iterador cursor for 
	select ID,ARTICULO,LOTE,CANTIDAD,STOCK,FECHA,ALMACEN from deleted
	open iterador
	fetch next from iterador into @Id,@IdArticulo,@lote,@cantidad,@Inventariado_Old,@Fecha,@Almacen
	while @@fetch_status = 0
	begin
		select @Inventariado_New= stock from inserted where id = @id
		if @Inventariado_New <> @Inventariado_Old and (@Inventariado_Old > 0) -- Se está desinventariando
			begin
				select @Cantidad_Negativa = cantidad * (-1) from inserted where id = @id
				EXEC sp_Stock_Dia_Insert @IdArticulo,@Fecha,@lote,'',@Ubicacion,@Almacen,@Cantidad_Negativa,'Transformaciones_Destino'
			end

		fetch next from iterador into @Id,@IdArticulo,@lote,@cantidad,@Inventariado_Old,@Fecha,@Almacen
	end
	close iterador
	deallocate iterador
end


END
