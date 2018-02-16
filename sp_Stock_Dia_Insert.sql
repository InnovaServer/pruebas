ALTER PROCEDURE sp_Stock_Dia_Insert
(
@IdArticulo int,
@Fecha datetime,
@Lote varchar(50),
@Pieza varchar (50),
@Ubicacion int,
@Almacen int,
@Cantidad decimal(15,5),
@Campo varchar(100)
)
AS
BEGIN
	declare @sql varchar(4000)


	if (select top 1 usar_lotes from CONFIGURACION_ALMACEN) = 0
		set @Lote = ''

  	if (select top 1 USARLOCALIZACION from CONFIGURACION_ALMACEN) = 0
		set @Ubicacion = -1

	set @sql = 
		'insert into Stock_Dia (IdArticulo,Lote,Pieza,Ubicacion,Almacen,FechaHora,'+ @Campo +') 
		values 
		(' +
		convert(varchar,@IdArticulo) + ',''' +
		@Lote + ''',''' +
		@Pieza + ''',' +
		convert(varchar,@Ubicacion) + ',' +
		convert(varchar,@Almacen) + ',''' +
		--convert(varchar(50),CURRENT_TIMESTAMP,121) + ''',' +
		--convert(varchar(50),@Fecha,121) + ''',' +
		convert(varchar(50),@Fecha) + ''',' +
		convert(varchar,@Cantidad) + 
		')'

	--print @sql
	exec (@sql)
END

