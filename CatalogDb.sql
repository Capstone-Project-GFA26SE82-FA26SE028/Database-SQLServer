USE master;
GO

IF DB_ID(N'CatalogDb') IS NOT NULL
BEGIN
    ALTER DATABASE CatalogDb
        SET SINGLE_USER WITH ROLLBACK IMMEDIATE;

    DROP DATABASE CatalogDb;
END;
GO

CREATE DATABASE CatalogDb;
GO

USE CatalogDb;
GO

CREATE TABLE dbo.Category
(
    CategoryId   uniqueidentifier NOT NULL,
    CategoryCode varchar(50)      NOT NULL,
    CategoryName varchar(255)     NOT NULL,
    IsActive     bit              NOT NULL,

    CONSTRAINT PK_Category PRIMARY KEY (CategoryId)
);
GO

CREATE TABLE dbo.Item
(
    ItemId                  uniqueidentifier NOT NULL,
    CategoryId              uniqueidentifier NOT NULL,
    ItemCode                varchar(50)      NOT NULL,
    ItemName                varchar(255)     NOT NULL,
    Description             varchar(max)     NULL,
    ImageUrl                varchar(max)     NULL,
    Availability            varchar(50)      NOT NULL,
    PreparationTimeMinutes  INT              NULL,
    KitchenStationRef       uniqueidentifier NULL,
    Version                 rowversion       NOT NULL,

    CONSTRAINT PK_Item PRIMARY KEY (ItemId),
    CONSTRAINT FK_Item_Category FOREIGN KEY (CategoryId)
        REFERENCES dbo.Category(CategoryId)
);
GO

CREATE TABLE dbo.Price
(
    PriceId       uniqueidentifier NOT NULL,
    ItemId        uniqueidentifier NOT NULL,
    Channel       varchar(50)      NOT NULL,
    Amount        decimal(18, 2)   NOT NULL,
    EffectiveFrom datetime         NOT NULL,
    EffectiveTo   datetime         NULL,
    DailyStart    time(0)          NULL,
    DailyEnd      time(0)          NULL,

    CONSTRAINT PK_Price PRIMARY KEY (PriceId),
    CONSTRAINT FK_Price_Item FOREIGN KEY (ItemId)
        REFERENCES dbo.Item(ItemId)
);
GO

CREATE TABLE dbo.OptionGroup
(
    OptionGroupId   uniqueidentifier NOT NULL,
    OptionGroupName varchar(255)     NOT NULL,

    CONSTRAINT PK_OptionGroup PRIMARY KEY (OptionGroupId)
);
GO

CREATE TABLE dbo.[Option]
(
    OptionId      uniqueidentifier NOT NULL,
    OptionGroupId uniqueidentifier NOT NULL,
    OptionName    varchar(255)     NOT NULL,
    ExtraPrice    decimal(18, 2)   NOT NULL,
    Availability  varchar(50)      NOT NULL,

    CONSTRAINT PK_Option PRIMARY KEY (OptionId),
    CONSTRAINT FK_Option_OptionGroup FOREIGN KEY (OptionGroupId)
        REFERENCES dbo.OptionGroup(OptionGroupId)
);
GO

CREATE TABLE dbo.ItemOptionGroup
(
    ItemId        uniqueidentifier NOT NULL,
    OptionGroupId uniqueidentifier NOT NULL,
    MinSelection  int              NOT NULL,
    MaxSelection  int              NOT NULL,

    CONSTRAINT PK_ItemOptionGroup
        PRIMARY KEY (ItemId, OptionGroupId),

    CONSTRAINT FK_ItemOptionGroup_Item FOREIGN KEY (ItemId)
        REFERENCES dbo.Item(ItemId),

    CONSTRAINT FK_ItemOptionGroup_OptionGroup FOREIGN KEY (OptionGroupId)
        REFERENCES dbo.OptionGroup(OptionGroupId)
);
GO

CREATE TABLE dbo.RecipeVersion
(
    RecipeVersionId uniqueidentifier NOT NULL,
    ItemId          uniqueidentifier NULL,
    OptionId        uniqueidentifier NULL,
    Version         int              NOT NULL,
    EffectiveFrom   datetime         NOT NULL,
    EffectiveTo     datetime         NULL,
    Instructions    varchar(max)     NULL,

    CONSTRAINT PK_RecipeVersion PRIMARY KEY (RecipeVersionId),
    CONSTRAINT FK_RecipeVersion_Item FOREIGN KEY (ItemId)
        REFERENCES dbo.Item(ItemId),
    CONSTRAINT FK_RecipeVersion_Option FOREIGN KEY (OptionId)
        REFERENCES dbo.[Option](OptionId)
);
GO

CREATE TABLE dbo.RecipeIngredient
(
    RecipeIngredientId       uniqueidentifier NOT NULL,
    RecipeVersionId          uniqueidentifier NOT NULL,
    IngredientRef            uniqueidentifier NOT NULL,
    UnitRef                  uniqueidentifier NOT NULL,
    Quantity                 decimal(18, 6)   NOT NULL,
    BaseQuantitySnapshot     decimal(18, 6)   NOT NULL,
    ConversionFactorSnapshot decimal(18, 6)   NOT NULL,

    CONSTRAINT PK_RecipeIngredient PRIMARY KEY (RecipeIngredientId),
    CONSTRAINT FK_RecipeIngredient_RecipeVersion FOREIGN KEY (RecipeVersionId)
        REFERENCES dbo.RecipeVersion(RecipeVersionId)
);
GO

CREATE TABLE dbo.RecipeMedia
(
    RecipeMediaId   uniqueidentifier NOT NULL,
    RecipeVersionId uniqueidentifier NOT NULL,
    MediaType       varchar(50)      NOT NULL,
    Url             varchar(max)     NOT NULL,
    DisplayOrder    int              NOT NULL,

    CONSTRAINT PK_RecipeMedia PRIMARY KEY (RecipeMediaId),
    CONSTRAINT FK_RecipeMedia_RecipeVersion FOREIGN KEY (RecipeVersionId)
        REFERENCES dbo.RecipeVersion(RecipeVersionId)
);
GO