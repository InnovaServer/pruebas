ALTER TRIGGER trg_Stock_Dia_ENTRADA_TEJIDODISPUESTO_LINEAS_CONSUMO ON ENTRADA_TEJIDODISPUESTO_LINEAS
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

declare @Proveedor int
declare @Escandallo int
declare @Tejido int
declare @Articulo_escandallo int
declare @Consumo_escandallo decimal (15,5)
declare @Consumo_Tejido decimal (15,5)
declare @Cantidad_consumida decimal (15,5)

--select * from ARTICULOS_ESCANDALLOS
--select * from fn_Consumo_Escandallo (1037)



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
		--select @Almacen = coalesce(almacen,-1) from ENTRADA_TEJIDODISPUESTO where idrow = @IdRow
		select @Proveedor = coalesce(PROVEEDOR,-1) from ENTRADA_TEJIDODISPUESTO where idrow = @IdRow
		select @Almacen = (select coalesce(idrow,-1) from almacenes where proveedor = @Proveedor)
		select @Escandallo = (select coalesce(IDROW,0) from articulos_escandallos where ARTICULO = @IdArticulo and defecto = 1)

		select @Consumo_Tejido = (select coalesce(MADRE1_TOTALCONSUMO,0) from articulos_escandallos where ARTICULO = @IdArticulo and defecto = 1)
		select @Tejido = (select coalesce(ARTICULO_CRUDO,0) from DISPOSICIONES_LINEAS where ID = @Disposicion)

		print @Accion
		if @Accion = 'I'
			begin
				declare iterador_tmp cursor for 
				select ARTICULO,CANTIDAD from articulos_escandallo where ESCANDALLO = @Escandallo
				open iterador_tmp
				fetch next from iterador_tmp into @Articulo_escandallo,@Consumo_escandallo
				while @@fetch_status = 0
				begin
					set @Cantidad_consumida = @Cantidad * @Consumo_escandallo
					EXEC sp_Stock_Dia_Insert @Articulo_escandallo,@Fecha,'','',-1,@Almacen,@Cantidad_consumida,'Produccion_Consumo'

					fetch next from iterador_tmp into @Articulo_escandallo,@Consumo_escandallo
				end
				close iterador_tmp
				deallocate iterador_tmp
/*
				-- Después de descontar todos los consumos del escandallo, calcula y resta el consumo de tejido
				declare iterador_tmp cursor for 
				select BASE,TOTALCONSUMO from ARTICULOS_ESCANDALLOS_EXTENDED where IDROW = @Escandallo
				open iterador_tmp
				fetch next from iterador_tmp into @Articulo_escandallo,@Consumo_escandallo
				while @@fetch_status = 0
				begin
					if @Consumo_escandallo > 0
						begin
							set @Cantidad_consumida = @Cantidad * @Consumo_escandallo
							EXEC sp_Stock_Dia_Insert @Articulo_escandallo,@Fecha,'','',-1,@Almacen,@Cantidad_consumida,'Produccion_Consumo'
						end

					fetch next from iterador_tmp into @Articulo_escandallo,@Consumo_escandallo
				end
				close iterador_tmp
				deallocate iterador_tmp
*/
			end	
		else
			begin
				if @Cantidad <> (select cantidad from deleted where id = @id)
					begin
						declare iterador_tmp cursor for 
						select ARTICULO,CANTIDAD from articulos_escandallo where ESCANDALLO = @Escandallo
						open iterador_tmp
						fetch next from iterador_tmp into @Articulo_escandallo,@Consumo_escandallo
						while @@fetch_status = 0
						begin
							set @Cantidad_consumida = @Cantidad * @Consumo_escandallo
							EXEC sp_Stock_Dia_Insert @Articulo_escandallo,@Fecha,'','',-1,@Almacen,@Cantidad_consumida,'Produccion_Consumo'

							fetch next from iterador_tmp into @Articulo_escandallo,@Consumo_escandallo
						end
						close iterador_tmp
						deallocate iterador_tmp

/*
						-- Después de descontar todos los consumos del escandallo, calcula y resta el consumo de tejido
						declare iterador_tmp cursor for 
						select BASE,TOTALCONSUMO from ARTICULOS_ESCANDALLOS_EXTENDED where IDROW = @Escandallo
						open iterador_tmp
						fetch next from iterador_tmp into @Articulo_escandallo,@Consumo_escandallo
						while @@fetch_status = 0
						begin
							if @Consumo_escandallo > 0
								begin
									set @Cantidad_consumida = @Cantidad * @Consumo_escandallo
									EXEC sp_Stock_Dia_Insert @Articulo_escandallo,@Fecha,'','',-1,@Almacen,@Cantidad_consumida,'Produccion_Consumo'
								end

							fetch next from iterador_tmp into @Articulo_escandallo,@Consumo_escandallo
						end
						close iterador_tmp
						deallocate iterador_tmp
*/
					end	
			end

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
		--select @Almacen = coalesce(almacen,-1) from ENTRADA_TEJIDODISPUESTO where idrow = @IdRow
		select @Proveedor = coalesce(PROVEEDOR,-1) from ENTRADA_TEJIDODISPUESTO where idrow = @IdRow
		select @Almacen = (select coalesce(idrow,-1) from almacenes where proveedor = @Proveedor)
		select @Escandallo = (select coalesce(IDROW,0) from articulos_escandallos where ARTICULO = @IdArticulo and defecto = 1)
--		select @Tejido = (select coalesce(ARTICULO_CRUDO,0) from DISPOSICIONES_LINEAS where ID = @Disposicion)

		if @Accion = 'D'
			begin
				declare iterador_tmp cursor for 
				select ARTICULO,CANTIDAD from articulos_escandallo where ESCANDALLO = @Escandallo
				open iterador_tmp
				fetch next from iterador_tmp into @Articulo_escandallo,@Consumo_escandallo
				while @@fetch_status = 0
				begin
					set @Cantidad_consumida = @Cantidad * @Consumo_escandallo * (-1)
					EXEC sp_Stock_Dia_Insert @Articulo_escandallo,@Fecha,'','',-1,@Almacen,@Cantidad_consumida,'Produccion_Consumo'

					fetch next from iterador_tmp into @Articulo_escandallo,@Consumo_escandallo
				end
				close iterador_tmp
				deallocate iterador_tmp

/*
				-- Después de descontar todos los consumos del escandallo, calcula y resta el consumo de tejido
				declare iterador_tmp cursor for 
				select BASE,TOTALCONSUMO from ARTICULOS_ESCANDALLOS_EXTENDED where IDROW = @Escandallo
				open iterador_tmp
				fetch next from iterador_tmp into @Articulo_escandallo,@Consumo_escandallo
				while @@fetch_status = 0
				begin
					if @Consumo_escandallo > 0
						begin
							set @Cantidad_consumida = @Cantidad * @Consumo_escandallo * (-1)
							EXEC sp_Stock_Dia_Insert @Articulo_escandallo,@Fecha,'','',-1,@Almacen,@Cantidad_consumida,'Produccion_Consumo'
						end

					fetch next from iterador_tmp into @Articulo_escandallo,@Consumo_escandallo
				end
				close iterador_tmp
				deallocate iterador_tmp
*/
			end	
		else
			begin
				if @Cantidad <> (select cantidad from inserted where id = @id)
					begin
						declare iterador_tmp cursor for 
						select ARTICULO,CANTIDAD from articulos_escandallo where ESCANDALLO = @Escandallo
						open iterador_tmp
						fetch next from iterador_tmp into @Articulo_escandallo,@Consumo_escandallo
						while @@fetch_status = 0
						begin
							set @Cantidad_consumida = @Cantidad * @Consumo_escandallo * (-1)
							EXEC sp_Stock_Dia_Insert @Articulo_escandallo,@Fecha,'','',-1,@Almacen,@Cantidad_consumida,'Produccion_Consumo'

							fetch next from iterador_tmp into @Articulo_escandallo,@Consumo_escandallo
						end
						close iterador_tmp
						deallocate iterador_tmp

/*				
						-- Después de descontar todos los consumos del escandallo, calcula y resta el consumo de tejido
						declare iterador_tmp cursor for 
						select BASE,TOTALCONSUMO from ARTICULOS_ESCANDALLOS_EXTENDED where IDROW = @Escandallo
						open iterador_tmp
						fetch next from iterador_tmp into @Articulo_escandallo,@Consumo_escandallo
						while @@fetch_status = 0
						begin
							if @Consumo_escandallo > 0
								begin
									set @Cantidad_consumida = @Cantidad * @Consumo_escandallo * (-1)
									EXEC sp_Stock_Dia_Insert @Articulo_escandallo,@Fecha,'','',-1,@Almacen,@Cantidad_consumida,'Produccion_Consumo'
								end

							fetch next from iterador_tmp into @Articulo_escandallo,@Consumo_escandallo
						end
						close iterador_tmp
						deallocate iterador_tmp
*/
					end	
			end

		fetch next from iterador into @Id,@lote,@cantidad,@Fecha,@Disposicion,@IdRow
	end
	close iterador
	deallocate iterador
end

END