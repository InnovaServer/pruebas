CREATE TRIGGER trg_Stock_Dia_VAYOIL_ORDEN_CORTE ON VAYOIL_ORDEN_CORTE
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

declare @Tejido1 int
declare @Tejido2 int
declare @Cantidad_consumida1 decimal (15,5)
declare @Cantidad_consumida2 decimal (15,5)


/*
No se contemplan otros casos porque una vez inventariado no se puede hacer nada con el registro.
*/

if @Accion = 'I' or @Accion = 'U'
begin
	declare iterador cursor for 
	select ID,MADRE1_IDROW,MADRE2_IDROW,MUTILIZADOS,MUTILIZADOS2,FECHA from inserted
	open iterador
	fetch next from iterador into @Id,@Tejido1,@Tejido2,@Cantidad_consumida1,@Cantidad_consumida2,@Fecha
	while @@fetch_status = 0
	begin
		if @Tejido1 > 0
			begin
				-- Se pone a pelo el almacén 4 porque en Cándido Penalba siempre se descuenta de ese y actualmente no hay información del almacén en la orden
				EXEC sp_Stock_Dia_Insert @Tejido1,@Fecha,'','',-1,4,@Cantidad_consumida1,'Produccion_Consumo'
			end
		if @Tejido2 > 0
			begin
				-- Se pone a pelo el almacén 4 porque en Cándido Penalba siempre se descuenta de ese y actualmente no hay información del almacén en la orden
				EXEC sp_Stock_Dia_Insert @Tejido2,@Fecha,'','',-1,4,@Cantidad_consumida2,'Produccion_Consumo'
			end

		fetch next from iterador into @Id,@Tejido1,@Tejido2,@Cantidad_consumida1,@Cantidad_consumida2,@Fecha
	end
	close iterador
	deallocate iterador
end


if @Accion = 'D' or @Accion = 'U'
begin
	declare iterador cursor for 
	select ID,MADRE1_IDROW,MADRE2_IDROW,MUTILIZADOS,MUTILIZADOS2,FECHA from deleted
	open iterador
	fetch next from iterador into @Id,@Tejido1,@Tejido2,@Cantidad_consumida1,@Cantidad_consumida2,@Fecha
	while @@fetch_status = 0
	begin
		if @Tejido1 > 0
			begin
				set @Cantidad_consumida1 = @Cantidad_consumida1 * (-1)
				-- Se pone a pelo el almacén 4 porque en Cándido Penalba siempre se descuenta de ese y actualmente no hay información del almacén en la orden
				EXEC sp_Stock_Dia_Insert @Tejido1,@Fecha,'','',-1,4,@Cantidad_consumida1,'Produccion_Consumo'
			end
		if @Tejido2 > 0
			begin
				set @Cantidad_consumida2 = @Cantidad_consumida2 * (-1)
				-- Se pone a pelo el almacén 4 porque en Cándido Penalba siempre se descuenta de ese y actualmente no hay información del almacén en la orden
				EXEC sp_Stock_Dia_Insert @Tejido2,@Fecha,'','',-1,4,@Cantidad_consumida2,'Produccion_Consumo'
			end

		fetch next from iterador into @Id,@Tejido1,@Tejido2,@Cantidad_consumida1,@Cantidad_consumida2,@Fecha
	end
	close iterador
	deallocate iterador
end

END