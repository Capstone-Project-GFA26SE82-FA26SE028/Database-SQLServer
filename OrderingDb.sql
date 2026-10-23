USE master;
GO

IF DB_ID(N'OrderingDb') IS NOT NULL
BEGIN
    ALTER DATABASE OrderingDb
        SET SINGLE_USER WITH ROLLBACK IMMEDIATE;

    DROP DATABASE OrderingDb;
END;
GO

CREATE DATABASE OrderingDb;
GO

USE OrderingDb;
GO

CREATE TABLE dbo.Cart
(
    CartId          uniqueidentifier NOT NULL,
    TableSessionRef uniqueidentifier NOT NULL,
    GuestAccessRef  uniqueidentifier NULL,
    ExpiredAt       datetime         NOT NULL,

    CONSTRAINT PK_Cart PRIMARY KEY (CartId)
);
GO

CREATE TABLE dbo.CartItem
(
    CartItemId uniqueidentifier NOT NULL,
    CartId     uniqueidentifier NOT NULL,
    ItemRef    uniqueidentifier NOT NULL,
    Quantity   int              NOT NULL,
    Note       varchar(max)     NULL,

    CONSTRAINT PK_CartItem PRIMARY KEY (CartItemId),
    CONSTRAINT FK_CartItem_Cart FOREIGN KEY (CartId)
        REFERENCES dbo.Cart(CartId)
);
GO

CREATE TABLE dbo.CartItemOption
(
    CartItemOptionId uniqueidentifier NOT NULL,
    CartItemId       uniqueidentifier NOT NULL,
    OptionRef        uniqueidentifier NOT NULL,
    Quantity         int              NOT NULL,

    CONSTRAINT PK_CartItemOption PRIMARY KEY (CartItemOptionId),
    CONSTRAINT FK_CartItemOption_CartItem FOREIGN KEY (CartItemId)
        REFERENCES dbo.CartItem(CartItemId)
);
GO

CREATE TABLE dbo.[Order]
(
    OrderId        uniqueidentifier NOT NULL,
    OrderNumber    varchar(50)      NOT NULL,
    TableSessionRef uniqueidentifier NULL,
    CustomerRef    uniqueidentifier NULL,
    Channel        varchar(50)      NOT NULL,
    CreatedByRef   uniqueidentifier NULL,
    IdempotencyKey varchar(255)     NOT NULL,
    RequestHash    varchar(255)     NOT NULL,
    CreatedAt      datetime         NOT NULL,
    Status         varchar(50)      NOT NULL,
    Version        rowversion       NOT NULL,
    ConfirmedAt    datetime         NULL,
    ConfirmedByRef uniqueidentifier NULL,

    CONSTRAINT PK_Order PRIMARY KEY (OrderId)
);
GO

CREATE TABLE dbo.OrderItem
(
    OrderItemId       uniqueidentifier NOT NULL,
    OrderId           uniqueidentifier NOT NULL,
    ItemRef           uniqueidentifier NOT NULL,
    RecipeVersionRef  uniqueidentifier NULL,
    OriginalTableRef  uniqueidentifier NULL,
    ComboGroupId      uniqueidentifier NULL,
    NameSnapshot      varchar(255)     NOT NULL,
    UnitPriceSnapshot decimal(18, 2)   NOT NULL,
    Quantity          int              NOT NULL,
    CancelledQuantity int              NOT NULL,
    Note              varchar(max)     NULL,
    Status            varchar(50)      NOT NULL,
    Version           rowversion       NOT NULL,

    CONSTRAINT PK_OrderItem PRIMARY KEY (OrderItemId),
    CONSTRAINT FK_OrderItem_Order FOREIGN KEY (OrderId)
        REFERENCES dbo.[Order](OrderId)
);
GO

CREATE TABLE dbo.OrderItemOption
(
    Id                 uniqueidentifier NOT NULL,
    OrderItemId        uniqueidentifier NOT NULL,
    OptionRef          uniqueidentifier NOT NULL,
    NameSnapshot       varchar(255)     NOT NULL,
    ExtraPriceSnapshot decimal(18, 2)   NOT NULL,
    Quantity           int              NOT NULL,

    CONSTRAINT PK_OrderItemOption PRIMARY KEY (Id),
    CONSTRAINT FK_OrderItemOption_OrderItem FOREIGN KEY (OrderItemId)
        REFERENCES dbo.OrderItem(OrderItemId)
);
GO

CREATE TABLE dbo.ServiceRecord
(
    ServiceRecordId uniqueidentifier NOT NULL,
    OrderItemId     uniqueidentifier NOT NULL,
    QuantityServed  int              NOT NULL,
    WaiterUserRef   uniqueidentifier NOT NULL,
    ServedAt        datetime         NOT NULL,
    IdempotencyKey  varchar(255)     NOT NULL,

    CONSTRAINT PK_ServiceRecord PRIMARY KEY (ServiceRecordId),
    CONSTRAINT FK_ServiceRecord_OrderItem FOREIGN KEY (OrderItemId)
        REFERENCES dbo.OrderItem(OrderItemId)
);
GO

CREATE TABLE dbo.CancellationRequest
(
    CancellationRequestId uniqueidentifier NOT NULL,
    OrderItemId           uniqueidentifier NOT NULL,
    Quantity              int              NOT NULL,
    Reason                varchar(max)     NOT NULL,
    RequestedByRef        uniqueidentifier NOT NULL,
    DecidedByRef          uniqueidentifier NULL,
    Status                varchar(50)      NOT NULL,
    RequestedAt           datetime         NOT NULL,

    CONSTRAINT PK_CancellationRequest PRIMARY KEY (CancellationRequestId),
    CONSTRAINT FK_CancellationRequest_OrderItem FOREIGN KEY (OrderItemId)
        REFERENCES dbo.OrderItem(OrderItemId)
);
GO

CREATE TABLE dbo.KitchenStation
(
    KitchenStationId   uniqueidentifier NOT NULL,
    KitchenStationCode varchar(50)      NOT NULL,
    KitchenStationName varchar(255)     NOT NULL,
    IsActive           bit              NOT NULL,

    CONSTRAINT PK_KitchenStation PRIMARY KEY (KitchenStationId)
);
GO

CREATE TABLE dbo.KitchenAssignment
(
    KitchenStationId uniqueidentifier NOT NULL,
    UserRef          uniqueidentifier NOT NULL,

    CONSTRAINT PK_KitchenAssignment PRIMARY KEY (KitchenStationId),
    CONSTRAINT FK_KitchenAssignment_KitchenStation
        FOREIGN KEY (KitchenStationId)
        REFERENCES dbo.KitchenStation(KitchenStationId)
);
GO

CREATE TABLE dbo.KitchenTask
(
    KitchenTaskId    uniqueidentifier NOT NULL,
    KitchenStationId uniqueidentifier NOT NULL,
    OrderItemId      uniqueidentifier NOT NULL,
    BatchNumber      int              NOT NULL,
    Quantity         int              NOT NULL,
    Status           varchar(50)      NOT NULL,
    Priority         int              NOT NULL,
    QueuedAt         datetime         NOT NULL,
    CookingAt        datetime         NULL,
    ReadyAt          datetime         NULL,
    EstimatedMinutes int              NOT NULL,
    Version          rowversion       NOT NULL,

    CONSTRAINT PK_KitchenTask PRIMARY KEY (KitchenTaskId),
    CONSTRAINT FK_KitchenTask_KitchenStation FOREIGN KEY (KitchenStationId)
        REFERENCES dbo.KitchenStation(KitchenStationId),
    CONSTRAINT FK_KitchenTask_OrderItem FOREIGN KEY (OrderItemId)
        REFERENCES dbo.OrderItem(OrderItemId)
);
GO

CREATE TABLE dbo.[Event]
(
    EventId       uniqueidentifier NOT NULL,
    KitchenTaskId uniqueidentifier NOT NULL,
    FromStatus    varchar(50)      NULL,
    ToStatus      varchar(50)      NOT NULL,
    ActorUserRef  uniqueidentifier NULL,
    OccurredAt    datetime         NOT NULL,

    CONSTRAINT PK_Event PRIMARY KEY (EventId),
    CONSTRAINT FK_Event_KitchenTask FOREIGN KEY (KitchenTaskId)
        REFERENCES dbo.KitchenTask(KitchenTaskId)
);
GO