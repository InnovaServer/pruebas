/*
TODO NUEVO

AAAAAAAAAAAAAAAAAAA

BBB
CCCC
DDDD

*/

CREATE TABLE [dbo].[STOCK](
	[IdArticulo] [int] NOT NULL,
	[Lote] [varchar](50) NOT NULL,
	[Pieza] [varchar](50) NOT NULL,
	[Ubicacion] [int] NOT NULL,
	[Almacen] [int] NOT NULL,
	[Fecha_Stock_Inicial] [date] NULL,
	[Stock_Inicial] [decimal](18, 2) NULL CONSTRAINT [DF_STOCK_Stock_Inicial]  DEFAULT ((0)),
	[Albaranes_Compra] [decimal](18, 2) NULL CONSTRAINT [DF_STOCK_Albaranes_Compra]  DEFAULT ((0)),
	[Albaranes_Venta] [decimal](18, 2) NULL CONSTRAINT [DF_STOCK_Albaranes_Venta]  DEFAULT ((0)),
	[Facturas_Venta] [decimal](18, 2) NULL CONSTRAINT [DF_STOCK_Facturas_Venta]  DEFAULT ((0)),
	[Pedidos_Compra_Pendientes] [decimal](18, 2) NULL CONSTRAINT [DF_STOCK_Pedidos_Compra_Pendientes]  DEFAULT ((0)),
	[Pedidos_Venta_Pendientes] [decimal](18, 2) NULL CONSTRAINT [DF_STOCK_Pedidos_Venta_Pendientes]  DEFAULT ((0)),
	[Produccion_Pendiente] [decimal](18, 2) NULL CONSTRAINT [DF_STOCK_Produccion_Pendiente]  DEFAULT ((0)),
	[Movtos_Almacen_Origen] [decimal](18, 2) NULL CONSTRAINT [DF_STOCK_Movtos_Almacen_Origen]  DEFAULT ((0)),
	[Movtos_Almacen_Destino] [decimal](18, 2) NULL CONSTRAINT [DF_STOCK_Movtos_Almacen_Destino]  DEFAULT ((0)),
	[Transformaciones_Origen] [decimal](18, 2) NULL CONSTRAINT [DF_STOCK_Transformaciones_Origen]  DEFAULT ((0)),
	[Transformaciones_Destino] [decimal](18, 2) NULL CONSTRAINT [DF_STOCK_Transformaciones_Destino]  DEFAULT ((0)),
	[Produccion_Entradas] [decimal](18, 2) NULL CONSTRAINT [DF_STOCK_Produccion_Entradas]  DEFAULT ((0)),
	[Produccion_Consumo] [decimal](18, 2) NULL CONSTRAINT [DF_STOCK_Produccion_Consumo]  DEFAULT ((0)),
	[Historico] [decimal](18, 2) NULL CONSTRAINT [DF_STOCK_Historico]  DEFAULT ((0)),
 CONSTRAINT [PK_STOCK] PRIMARY KEY CLUSTERED 
(
	[IdArticulo] ASC,
	[Lote] ASC,
	[Pieza] ASC,
	[Ubicacion] ASC,
	[Almacen] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO


