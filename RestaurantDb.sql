USE master;
GO

IF DB_ID(N'RestaurantDb') IS NOT NULL
BEGIN
    ALTER DATABASE RestaurantDb
        SET SINGLE_USER WITH ROLLBACK IMMEDIATE;

    DROP DATABASE RestaurantDb;
END;
GO

CREATE DATABASE RestaurantDb;
GO

USE RestaurantDb;
GO

CREATE TABLE dbo.Restaurant
(
    RestaurantId   uniqueidentifier NOT NULL,
    RestaurantName nvarchar(255)    NOT NULL,
    TaxCode        varchar(50)      NULL,
    Address        nvarchar(500)    NOT NULL,
    Hotline        varchar(20)      NULL,
    LogoUrl        nvarchar(max)    NULL,
    TimeZone       nvarchar(100)    NOT NULL,

    CONSTRAINT PK_Restaurant PRIMARY KEY (RestaurantId)
);
GO

CREATE TABLE dbo.OpeningHour
(
    OpeningHourId uniqueidentifier NOT NULL,
    RestaurantId  uniqueidentifier NOT NULL,
    DayOfWeek     tinyint          NOT NULL,
    OpenAt        time(0)          NOT NULL,
    CloseAt       time(0)          NOT NULL,

    CONSTRAINT PK_OpeningHour PRIMARY KEY (OpeningHourId),
    CONSTRAINT FK_OpeningHour_Restaurant FOREIGN KEY (RestaurantId)
        REFERENCES dbo.Restaurant(RestaurantId)
);
GO

CREATE TABLE dbo.Area
(
    AreaId       uniqueidentifier NOT NULL,
    RestaurantId uniqueidentifier NOT NULL,
    AreaCode     varchar(50)      NOT NULL,
    AreaName     nvarchar(100)    NOT NULL,
    ServiceType  varchar(50)      NOT NULL,
    SpaceType    varchar(50)      NOT NULL,
    IsActive     bit              NOT NULL,

    CONSTRAINT PK_Area PRIMARY KEY (AreaId),
    CONSTRAINT FK_Area_Restaurant FOREIGN KEY (RestaurantId)
        REFERENCES dbo.Restaurant(RestaurantId)
);
GO

CREATE TABLE dbo.[Table]
(
    TableId        uniqueidentifier NOT NULL,
    AreaId         uniqueidentifier NOT NULL,
    TableCode      varchar(50)      NOT NULL,
    Capacity       int              NOT NULL,
    PositionX      decimal(10, 2)   NULL,
    PositionY      decimal(10, 2)   NULL,
    IsActive       bit              NOT NULL,
    CleaningStatus varchar(50)      NOT NULL,
    Version        rowversion       NOT NULL,

    CONSTRAINT PK_Table PRIMARY KEY (TableId),
    CONSTRAINT FK_Table_Area FOREIGN KEY (AreaId)
        REFERENCES dbo.Area(AreaId)
);
GO

CREATE TABLE dbo.Qr
(
    QrId      uniqueidentifier NOT NULL,
    TableId   uniqueidentifier NOT NULL,
    TokenHash varchar(255)     NOT NULL,
    CreatedAt datetimeoffset(7) NOT NULL,
    RevokedAt datetimeoffset(7) NULL,

    CONSTRAINT PK_Qr PRIMARY KEY (QrId),
    CONSTRAINT FK_Qr_Table FOREIGN KEY (TableId)
        REFERENCES dbo.[Table](TableId)
);
GO

CREATE TABLE dbo.Reservation
(
    ReservationId uniqueidentifier NOT NULL,
    ContactName   nvarchar(255)    NOT NULL,
    Phone         varchar(20)      NOT NULL,
    PartySize     int              NOT NULL,
    StartAt       datetimeoffset(7) NOT NULL,
    EndAt         datetimeoffset(7) NOT NULL,
    HoldUntil     datetimeoffset(7) NULL,
    Status        varchar(50)      NOT NULL,
    ApprovedByRef uniqueidentifier NULL,

    CONSTRAINT PK_Reservation PRIMARY KEY (ReservationId)
);
GO

CREATE TABLE dbo.ReservationTable
(
    ReservationId uniqueidentifier NOT NULL,
    TableId       uniqueidentifier NOT NULL,

    CONSTRAINT PK_ReservationTable
        PRIMARY KEY (ReservationId, TableId),

    CONSTRAINT FK_ReservationTable_Reservation
        FOREIGN KEY (ReservationId)
        REFERENCES dbo.Reservation(ReservationId),

    CONSTRAINT FK_ReservationTable_Table
        FOREIGN KEY (TableId)
        REFERENCES dbo.[Table](TableId)
);
GO

CREATE TABLE dbo.TableSession
(
    TableSessionId     uniqueidentifier NOT NULL,
    ReservationId      uniqueidentifier NULL,
    PartySize          int              NOT NULL,
    Status             varchar(50)      NOT NULL,
    OpenedAt           datetimeoffset(7) NOT NULL,
    ClosedAt           datetimeoffset(7) NULL,
    OpenedByRef        uniqueidentifier NULL,
    JoinCodeHash       varchar(255)     NULL,
    JoinCodeSetAt      datetimeoffset(7) NULL,
    LoyaltyCustomerRef uniqueidentifier NULL,
    PrebillPrintedAt   datetimeoffset(7) NULL,

    CONSTRAINT PK_TableSession PRIMARY KEY (TableSessionId),
    CONSTRAINT FK_TableSession_Reservation FOREIGN KEY (ReservationId)
        REFERENCES dbo.Reservation(ReservationId)
);
GO

-- Mỗi reservation tối đa một session.
-- ReservationId NULL dành cho khách không đặt trước.
CREATE UNIQUE INDEX UX_TableSession_ReservationId
    ON dbo.TableSession(ReservationId)
    WHERE ReservationId IS NOT NULL;
GO

CREATE TABLE dbo.SessionTable
(
    SessionTableId uniqueidentifier NOT NULL,
    TableSessionId uniqueidentifier NOT NULL,
    TableId        uniqueidentifier NOT NULL,
    AssignedAt     datetimeoffset(7) NOT NULL,
    ReleasedAt     datetimeoffset(7) NULL,
    ChangedByRef   uniqueidentifier NULL,
    MoveReason     nvarchar(500)    NULL,

    CONSTRAINT PK_SessionTable PRIMARY KEY (SessionTableId),
    CONSTRAINT FK_SessionTable_TableSession FOREIGN KEY (TableSessionId)
        REFERENCES dbo.TableSession(TableSessionId),
    CONSTRAINT FK_SessionTable_Table FOREIGN KEY (TableId)
        REFERENCES dbo.[Table](TableId)
);
GO

CREATE TABLE dbo.ServiceRequest
(
    ServiceRequestId uniqueidentifier NOT NULL,
    TableSessionId   uniqueidentifier NOT NULL,
    Type             varchar(50)      NOT NULL,
    Status           varchar(50)      NOT NULL,
    RequestedAt      datetimeoffset(7) NOT NULL,
    AcknowledgedAt   datetimeoffset(7) NULL,
    CompletedAt      datetimeoffset(7) NULL,
    HandledByRef     uniqueidentifier NULL,

    CONSTRAINT PK_ServiceRequest PRIMARY KEY (ServiceRequestId),
    CONSTRAINT FK_ServiceRequest_TableSession FOREIGN KEY (TableSessionId)
        REFERENCES dbo.TableSession(TableSessionId)
);
GO

CREATE TABLE dbo.GuestAccess
(
    GuestAccessId  uniqueidentifier NOT NULL,
    TableSessionId uniqueidentifier NOT NULL,
    TokenHash      varchar(255)     NOT NULL,
    CreatedAt      datetimeoffset(7) NOT NULL,
    ExpiredAt      datetimeoffset(7) NOT NULL,
    RevokedAt      datetimeoffset(7) NULL,

    CONSTRAINT PK_GuestAccess PRIMARY KEY (GuestAccessId),
    CONSTRAINT FK_GuestAccess_TableSession FOREIGN KEY (TableSessionId)
        REFERENCES dbo.TableSession(TableSessionId)
);
GO