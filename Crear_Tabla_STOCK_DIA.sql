/****** Object:  Table [dbo].[STOCK_DIA]    Script Date: 02/01/2018 12:25:05 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[STOCK_DIA](
	[IdArticulo] [int] NOT NULL,
	[Lote] [varchar](50) NOT NULL,
	[Pieza] [varchar](50) NOT NULL,
	[Ubicacion] [int] NOT NULL,
	[Almacen] [int] NOT NULL,
	[FechaHora] [datetime] NOT NULL,
	[Stock_Inicial] [decimal](18, 2) NULL CONSTRAINT [DF_STOCK_DIA_Cantidad]  DEFAULT ((0)),
	[Albaranes_Compra] [decimal](18, 2) NULL CONSTRAINT [DF_STOCK_DIA_Stock_Inicial1]  DEFAULT ((0)),
	[Albaranes_Venta] [decimal](18, 2) NULL CONSTRAINT [DF_STOCK_DIA_Albaranes_Compra1]  DEFAULT ((0)),
	[Facturas_Venta] [decimal](18, 2) NULL CONSTRAINT [DF_STOCK_DIA_Albaranes_Compra1_1]  DEFAULT ((0)),
	[Pedidos_Compra_Pendientes] [decimal](18, 2) NULL CONSTRAINT [DF_STOCK_DIA_Albaranes_Compra1_2]  DEFAULT ((0)),
	[Pedidos_Venta_Pendientes1] [decimal](18, 2) NULL CONSTRAINT [DF_STOCK_DIA_Pedidos_Compra_Pendientes1]  DEFAULT ((0)),
	[Produccion_Pendiente] [decimal](18, 2) NULL CONSTRAINT [DF_STOCK_DIA_Pedidos_Venta_Pendientes11]  DEFAULT ((0)),
	[Movtos_Almacen_Origen] [decimal](18, 2) NULL CONSTRAINT [DF_STOCK_DIA_Produccion_Pendiente1]  DEFAULT ((0)),
	[Movtos_Almacen_Destino] [decimal](18, 2) NULL CONSTRAINT [DF_STOCK_DIA_Movtos_Almacen_Origen1]  DEFAULT ((0)),
	[Transformaciones_Origen] [decimal](18, 2) NULL CONSTRAINT [DF_STOCK_DIA_Movtos_Almacen_Destino1]  DEFAULT ((0)),
	[Transformaciones_Destino] [decimal](18, 2) NULL CONSTRAINT [DF_STOCK_DIA_Transformaciones_Origen1]  DEFAULT ((0)),
	[Produccion_Entradas] [decimal](18, 2) NULL CONSTRAINT [DF_STOCK_DIA_Transformaciones_Destino1]  DEFAULT ((0)),
	[Produccion_Consumo] [decimal](18, 2) NULL CONSTRAINT [DF_STOCK_DIA_Produccion_Entradas1]  DEFAULT ((0)),
	[Historico] [decimal](18, 2) NULL CONSTRAINT [DF_STOCK_DIA_Produccion_Consumo1]  DEFAULT ((0)),
 CONSTRAINT [PK_STOCK_DIA_1] PRIMARY KEY CLUSTERED 
(
	[IdArticulo] ASC,
	[Lote] ASC,
	[Pieza] ASC,
	[Ubicacion] ASC,
	[Almacen] ASC,
	[FechaHora] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO


