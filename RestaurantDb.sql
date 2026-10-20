-- Fresh database initialization. This script drops an existing RestaurantDb and all its data.

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
    RestaurantName varchar(255)     NOT NULL,
    TaxCode        varchar(50)      NULL,
    Address        varchar(500)     NOT NULL,
    Hotline        varchar(20)      NULL,
    LogoUrl        varchar(max)     NULL,
    TimeZone       varchar(100)     NOT NULL,

    CONSTRAINT PK_Restaurant PRIMARY KEY (RestaurantId)
);
GO

CREATE TABLE dbo.RestaurantStaff (
    RestaurantId uniqueidentifier NOT NULL,
    UserIdRef uniqueidentifier NOT NULL,
    IsActive bit NOT NULL,
    CONSTRAINT PK_RestaurantStaff PRIMARY KEY (RestaurantId, UserIdRef),
    CONSTRAINT FK_RestaurantStaff_Restaurant FOREIGN KEY (RestaurantId) REFERENCES dbo.Restaurant(RestaurantId)
);
GO

CREATE TABLE dbo.OpeningHour
(
    OpeningHourId uniqueidentifier NOT NULL,
    RestaurantId  uniqueidentifier NOT NULL,
    DayOfWeek     int              NOT NULL,
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
    AreaName     varchar(100)     NOT NULL,
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
    CreatedAt datetime         NOT NULL,
    RevokedAt datetime         NULL,

    CONSTRAINT PK_Qr PRIMARY KEY (QrId),
    CONSTRAINT FK_Qr_Table FOREIGN KEY (TableId)
        REFERENCES dbo.[Table](TableId)
);
GO

CREATE TABLE dbo.Reservation
(
    ReservationId uniqueidentifier NOT NULL,
    RestaurantId  uniqueidentifier NOT NULL,
    RequestedAreaId uniqueidentifier NOT NULL,
    ContactName   varchar(255)     NOT NULL,
    Phone         varchar(20)      NOT NULL,
    PartySize     int              NOT NULL,
    StartAt       datetime         NOT NULL,
    EndAt         datetime         NOT NULL,
    HoldUntil     datetime         NULL,
    Status        varchar(50)      NOT NULL,
    ApprovedByRef uniqueidentifier NULL,
    ConfirmedAt   datetime         NULL,
    CancelledAt   datetime         NULL,
    CancelledByRef uniqueidentifier NULL,

    CONSTRAINT PK_Reservation PRIMARY KEY (ReservationId),
    CONSTRAINT FK_Reservation_Restaurant FOREIGN KEY (RestaurantId)
        REFERENCES dbo.Restaurant(RestaurantId),
    CONSTRAINT FK_Reservation_RequestedArea FOREIGN KEY (RequestedAreaId)
        REFERENCES dbo.Area(AreaId)
);
GO

CREATE INDEX IX_Reservation_RestaurantId_Status_StartAt
    ON dbo.Reservation(RestaurantId, Status, StartAt);
GO

CREATE INDEX IX_Reservation_RequestedAreaId
    ON dbo.Reservation(RequestedAreaId);
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
    OpenedAt           datetime         NOT NULL,
    ClosedAt           datetime         NULL,
    OpenedByRef        uniqueidentifier NULL,
    JoinCodeHash       varchar(255)     NULL,
    JoinCodeSetAt      datetime         NULL,
    LoyaltyCustomerRef uniqueidentifier NULL,
    PrebillPrintedAt   datetime         NULL,

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
    AssignedAt     datetime         NOT NULL,
    ReleasedAt     datetime         NULL,
    ChangedByRef   uniqueidentifier NULL,
    MoveReason     varchar(500)     NULL,

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
    RequestedAt      datetime         NOT NULL,
    AcknowledgedAt   datetime         NULL,
    CompletedAt      datetime         NULL,
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
    CreatedAt      datetime         NOT NULL,
    ExpiredAt      datetime         NOT NULL,
    RevokedAt      datetime         NULL,

    CONSTRAINT PK_GuestAccess PRIMARY KEY (GuestAccessId),
    CONSTRAINT FK_GuestAccess_TableSession FOREIGN KEY (TableSessionId)
        REFERENCES dbo.TableSession(TableSessionId)
);
GO
