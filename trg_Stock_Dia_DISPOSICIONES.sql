ALTER TRIGGER trg_Stock_Dia_DISPOSICIONES ON DISPOSICIONES
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
declare @Enviado as int
declare @Enviado_old as int

declare @Proveedor int
declare @Escandallo int
declare @Tejido int
declare @Articulo_escandallo int
declare @Consumo_escandallo decimal (15,5)
declare @Consumo_Tejido decimal (15,5)
declare @Cantidad_consumida decimal (15,5)

declare @Fecha_Orden datetime
declare @Fecha_StockInicial datetime
declare @Orden_Enviada int
declare @Orden_Enviada_OLD int
declare @Cantidad_Pendiente decimal(15,5)
declare @Completada int
declare @Almacen_MateriasPrimas int
declare @Almacen_Proveedor int

if @Accion = 'U'
	begin
		declare iterador cursor for 
		select IDROW,ENVIADA,FECHA,ALMACEN,PROVEEDOR from inserted
		open iterador
		fetch next from iterador into @IdRow,@Orden_Enviada,@Fecha_Orden,@Almacen_MateriasPrimas,@Proveedor
		while @@fetch_status = 0
		begin
			select @Orden_Enviada_OLD = ENVIADA from deleted where IDROW = @IdRow
			if @Orden_Enviada = 1 and @Orden_Enviada_OLD = 0 -- Si se marca ENVIADA y antes NO estaba ENVIADA
				begin
					select @Almacen_Proveedor = (select coalesce(idrow,-1) from almacenes where proveedor = @Proveedor)

					declare iterador_tmp cursor for 
					select ID,ARTICULO,PENDIENTE from DISPOSICIONES_LINEAS where IDROW = @IdRow and COMPLETO = 0 --Solo procesa los artículos con cantidad pendiente
					open iterador_tmp
					fetch next from iterador_tmp into @Id,@IdArticulo,@Cantidad_Pendiente
					while @@fetch_status = 0
						begin
							select @Fecha_StockInicial = Fecha_Stock_Inicial from STOCK where idArticulo = @IdArticulo and lote = '' and almacen = @Almacen_MateriasPrimas and ubicacion = -1 and pieza = ''
							select @Escandallo = (select coalesce(IDROW,0) from articulos_escandallos where ARTICULO = @IdArticulo and defecto = 1)
							declare iterador_tmp2 cursor for 
							select ARTICULO,CANTIDAD from articulos_escandallo where ESCANDALLO = @Escandallo
							open iterador_tmp2
							fetch next from iterador_tmp2 into @Articulo_escandallo,@Consumo_escandallo
							while @@fetch_status = 0
								begin
									set @Cantidad_consumida = @Cantidad_Pendiente * @Consumo_escandallo
									EXEC sp_Stock_Dia_Insert @Articulo_escandallo,@Fecha_Orden,'','',-1,@Almacen_Proveedor,@Cantidad_consumida,'Movtos_Almacen_Destino'
									if @Fecha_Orden > @Fecha_StockInicial -- Solo se genera el movimiento de origen (salida de stock) si la fecha de la orden es posterior a la del último inventario
										begin
											EXEC sp_Stock_Dia_Insert @Articulo_escandallo,@Fecha_Orden,'','',-1,@Almacen_MateriasPrimas,@Cantidad_consumida,'Movtos_Almacen_Origen'
										end
									fetch next from iterador_tmp2 into @Articulo_escandallo,@Consumo_escandallo
								end
							close iterador_tmp2
							deallocate iterador_tmp2

							fetch next from iterador_tmp into @Id,@IdArticulo,@Cantidad_Pendiente
						end
					close iterador_tmp
					deallocate iterador_tmp
				end
			else
				begin
					if @Orden_Enviada = 0 and @Orden_Enviada_OLD = 1 -- Si se desmarca ENVIADA y antes estaba ENVIADA
						begin
							select @Almacen_Proveedor = (select coalesce(idrow,-1) from almacenes where proveedor = @Proveedor)

							declare iterador_tmp cursor for 
							select ID,ARTICULO,PENDIENTE from DISPOSICIONES_LINEAS where IDROW = @IdRow and COMPLETO = 0 --Solo procesa los artículos con cantidad pendiente
							open iterador_tmp
							fetch next from iterador_tmp into @Id,@IdArticulo,@Cantidad_Pendiente
							while @@fetch_status = 0
								begin
									select @Fecha_StockInicial = Fecha_Stock_Inicial from STOCK where idArticulo = @IdArticulo and lote = '' and almacen = @Almacen_MateriasPrimas and ubicacion = -1 and pieza = ''
									select @Escandallo = (select coalesce(IDROW,0) from articulos_escandallos where ARTICULO = @IdArticulo and defecto = 1)
									declare iterador_tmp2 cursor for 
									select ARTICULO,CANTIDAD from articulos_escandallo where ESCANDALLO = @Escandallo
									open iterador_tmp2
									fetch next from iterador_tmp2 into @Articulo_escandallo,@Consumo_escandallo
									while @@fetch_status = 0
										begin
											set @Cantidad_consumida = (@Cantidad_Pendiente * @Consumo_escandallo) * (-1)
											EXEC sp_Stock_Dia_Insert @Articulo_escandallo,@Fecha_Orden,'','',-1,@Almacen_Proveedor,@Cantidad_consumida,'Movtos_Almacen_Destino'
											if @Fecha_Orden > @Fecha_StockInicial -- Solo se genera el movimiento de origen (salida de stock) si la fecha de la orden es posterior a la del último inventario
												begin
													EXEC sp_Stock_Dia_Insert @Articulo_escandallo,@Fecha_Orden,'','',-1,@Almacen_MateriasPrimas,@Cantidad_consumida,'Movtos_Almacen_Origen'
												end
											fetch next from iterador_tmp2 into @Articulo_escandallo,@Consumo_escandallo
										end
									close iterador_tmp2
									deallocate iterador_tmp2

									fetch next from iterador_tmp into @Id,@IdArticulo,@Cantidad_Pendiente
								end
							close iterador_tmp
							deallocate iterador_tmp
						end
				end
			fetch next from iterador into @IdRow,@Orden_Enviada,@Fecha_Orden,@Almacen_MateriasPrimas,@Proveedor
		end
		close iterador
		deallocate iterador
	end


END