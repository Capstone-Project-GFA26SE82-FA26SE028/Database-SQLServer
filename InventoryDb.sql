USE master;
GO

IF DB_ID(N'InventoryDb') IS NOT NULL
BEGIN
    ALTER DATABASE InventoryDb
        SET SINGLE_USER WITH ROLLBACK IMMEDIATE;

    DROP DATABASE InventoryDb;
END;
GO

CREATE DATABASE InventoryDb;
GO

USE InventoryDb;
GO

CREATE TABLE dbo.Ingredient
(
    IngredientId      uniqueidentifier NOT NULL,
    IngredientCode    varchar(50)      NOT NULL,
    IngredientName    varchar(255)     NOT NULL,
    BaseUnit          varchar(50)      NOT NULL,
    StockQuantity     decimal(18, 6)   NOT NULL,
    LowStockThreshold decimal(18, 6)   NOT NULL,
    StockVersion      rowversion       NOT NULL,
    IsActive          bit              NOT NULL,

    CONSTRAINT PK_Ingredient PRIMARY KEY (IngredientId)
);
GO

CREATE TABLE dbo.GoodsReceipt
(
    GoodsReceiptId uniqueidentifier NOT NULL,
    ReceiptCode    varchar(50)      NOT NULL,
    Status         varchar(50)      NOT NULL,
    CreatedByRef   uniqueidentifier NOT NULL,
    CreatedAt      datetime         NOT NULL,
    ConfirmAt      datetime         NULL,
    Note           varchar(max)     NULL,

    CONSTRAINT PK_GoodsReceipt PRIMARY KEY (GoodsReceiptId)
);
GO

CREATE TABLE dbo.GoodsReceiptItem
(
    GoodsReceiptItemId uniqueidentifier NOT NULL,
    GoodsReceiptId     uniqueidentifier NOT NULL,
    IngredientId       uniqueidentifier NOT NULL,
    ReceivedQuantity   decimal(18, 6)   NOT NULL,
    ExpiryDate         date             NULL,

    CONSTRAINT PK_GoodsReceiptItem PRIMARY KEY (GoodsReceiptItemId),
    CONSTRAINT FK_GoodsReceiptItem_GoodsReceipt FOREIGN KEY (GoodsReceiptId)
        REFERENCES dbo.GoodsReceipt(GoodsReceiptId),
    CONSTRAINT FK_GoodsReceiptItem_Ingredient FOREIGN KEY (IngredientId)
        REFERENCES dbo.Ingredient(IngredientId)
);
GO

CREATE TABLE dbo.Stocktake
(
    StocktakeId   uniqueidentifier NOT NULL,
    StocktakeCode varchar(50)      NOT NULL,
    Status        varchar(50)      NOT NULL,
    CreatedByRef  uniqueidentifier NOT NULL,
    ApprovedByRef uniqueidentifier NULL,
    CreatedAt     datetime         NOT NULL,
    ConfirmedAt   datetime         NULL,

    CONSTRAINT PK_Stocktake PRIMARY KEY (StocktakeId)
);
GO

CREATE TABLE dbo.StocktakeItem
(
    StocktakeItemId    uniqueidentifier NOT NULL,
    StocktakeId        uniqueidentifier NOT NULL,
    IngredientId       uniqueidentifier NOT NULL,
    SystemQuantity     decimal(18, 6)   NOT NULL,
    ActualQuantity     decimal(18, 6)   NULL,
    SnapshotVersion    binary(8)        NOT NULL,
    DiscrepancyReason  varchar(max)     NULL,

    CONSTRAINT PK_StocktakeItem PRIMARY KEY (StocktakeItemId),
    CONSTRAINT FK_StocktakeItem_Stocktake FOREIGN KEY (StocktakeId)
        REFERENCES dbo.Stocktake(StocktakeId),
    CONSTRAINT FK_StocktakeItem_Ingredient FOREIGN KEY (IngredientId)
        REFERENCES dbo.Ingredient(IngredientId)
);
GO

CREATE TABLE dbo.StockMovement
(
    StockMovementId    uniqueidentifier NOT NULL,
    IngredientId       uniqueidentifier NOT NULL,
    GoodsReceiptItemId uniqueidentifier NULL,
    StocktakeItemId    uniqueidentifier NULL,
    MovementType       varchar(50)      NOT NULL,
    QuantityChange     decimal(18, 6)   NOT NULL,
    CookingEventRef    uniqueidentifier NULL,
    OrderItemRef       uniqueidentifier NULL,
    PerformedByRef     uniqueidentifier NULL,
    Reason             varchar(max)     NULL,
    CreatedAt          datetime         NOT NULL,

    CONSTRAINT PK_StockMovement PRIMARY KEY (StockMovementId),
    CONSTRAINT FK_StockMovement_Ingredient FOREIGN KEY (IngredientId)
        REFERENCES dbo.Ingredient(IngredientId),
    CONSTRAINT FK_StockMovement_GoodsReceiptItem FOREIGN KEY (GoodsReceiptItemId)
        REFERENCES dbo.GoodsReceiptItem(GoodsReceiptItemId),
    CONSTRAINT FK_StockMovement_StocktakeItem FOREIGN KEY (StocktakeItemId)
        REFERENCES dbo.StocktakeItem(StocktakeItemId)
);
GO