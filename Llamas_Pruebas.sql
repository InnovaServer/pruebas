/*
select * from stock
select * from stock_dia
select * from fn_STOCK (1234)
*/

declare @Fecha date 
set @Fecha = convert(date, getdate())


--select * from fn_STOCK_Movtos_Produccion_Consumo_Acabados(3572,'01/01/1900',@Fecha,0)
execute sp_STOCK @Fecha

select * from stock
select * from STOCK order by idarticulo

select top 50 * from ENTRADA_TEJIDODISPUESTO_lineas order by id desc
select top 50 * from DISPOSICIONES_LINEAS order by id desc

select * from disposiciones where idrow = 9252
update disposiciones set enviada = 1 where idrow = 9261







