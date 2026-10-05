USE master;
GO

IF DB_ID(N'CustomerDb') IS NOT NULL
BEGIN
    ALTER DATABASE CustomerDb
        SET SINGLE_USER WITH ROLLBACK IMMEDIATE;

    DROP DATABASE CustomerDb;
END;
GO

CREATE DATABASE CustomerDb;
GO

USE CustomerDb;
GO

CREATE TABLE dbo.LoyaltyTier
(
    LoyaltyTierId   uniqueidentifier NOT NULL,
    LoyaltyTierCode varchar(50)      NOT NULL,
    LoyaltyTierName varchar(100)     NOT NULL,
    RequiredSpend   decimal(18, 2)   NOT NULL,
    DiscountPercent decimal(5, 2)    NOT NULL,

    CONSTRAINT PK_LoyaltyTier PRIMARY KEY (LoyaltyTierId)
);
GO

CREATE TABLE dbo.Customer
(
    CustomerId      uniqueidentifier NOT NULL,
    NormalizedPhone varchar(20)      NOT NULL,
    CustomerName    varchar(255)     NOT NULL,
    LoyaltyTierId   uniqueidentifier NOT NULL,
    Version         rowversion       NOT NULL,

    CONSTRAINT PK_Customer PRIMARY KEY (CustomerId),
    CONSTRAINT FK_Customer_LoyaltyTier FOREIGN KEY (LoyaltyTierId)
        REFERENCES dbo.LoyaltyTier(LoyaltyTierId)
);
GO

CREATE TABLE dbo.LoyaltyPolicy
(
    PolicyId              uniqueidentifier NOT NULL,
    Version               int              NOT NULL,
    SpendPerPoint         decimal(18, 2)   NOT NULL,
    MoneyPerRedeemedPoint decimal(18, 2)   NOT NULL,
    EffectiveFrom         datetime         NOT NULL,

    CONSTRAINT PK_LoyaltyPolicy PRIMARY KEY (PolicyId)
);
GO

CREATE TABLE dbo.LoyaltyEntry
(
    LoyaltyEntryId uniqueidentifier NOT NULL,
    CustomerId     uniqueidentifier NOT NULL,
    BillRef        uniqueidentifier NULL,
    RefundRef      uniqueidentifier NULL,
    PolicyId       uniqueidentifier NOT NULL,
    Type           varchar(50)      NOT NULL,
    SignedPoint    int              NOT NULL,
    EligibleSpend  decimal(18, 2)   NOT NULL,
    SourceEventId  varchar(255)     NOT NULL,
    PostedAt       datetime         NOT NULL,

    CONSTRAINT PK_LoyaltyEntry PRIMARY KEY (LoyaltyEntryId),
    CONSTRAINT FK_LoyaltyEntry_Customer FOREIGN KEY (CustomerId)
        REFERENCES dbo.Customer(CustomerId),
    CONSTRAINT FK_LoyaltyEntry_LoyaltyPolicy FOREIGN KEY (PolicyId)
        REFERENCES dbo.LoyaltyPolicy(PolicyId)
);
GO

CREATE TABLE dbo.PointReservation
(
    PointReservationId uniqueidentifier NOT NULL,
    CustomerId         uniqueidentifier NOT NULL,
    BillRef            uniqueidentifier NOT NULL,
    Point              int              NOT NULL,
    Status             varchar(50)      NOT NULL,
    ExpiredAt          datetime         NOT NULL,

    CONSTRAINT PK_PointReservation PRIMARY KEY (PointReservationId),
    CONSTRAINT FK_PointReservation_Customer FOREIGN KEY (CustomerId)
        REFERENCES dbo.Customer(CustomerId)
);
GO

CREATE TABLE dbo.FeedbackAccess
(
    FeedbackAccessId uniqueidentifier NOT NULL,
    OrderRef         uniqueidentifier NOT NULL,
    TokenHash        varchar(255)     NOT NULL,
    ExpiredAt        datetime         NOT NULL,
    UsedAt           datetime         NULL,

    CONSTRAINT PK_FeedbackAccess PRIMARY KEY (FeedbackAccessId)
);
GO

CREATE TABLE dbo.Feedback
(
    FeedbackId  uniqueidentifier NOT NULL,
    AccessId    uniqueidentifier NOT NULL,
    OrderRef    uniqueidentifier NOT NULL,
    CustomerId  uniqueidentifier NULL,
    Star        int              NOT NULL,
    Comment     varchar(max)     NULL,
    SubmittedAt datetime         NOT NULL,

    CONSTRAINT PK_Feedback PRIMARY KEY (FeedbackId),
    CONSTRAINT UQ_Feedback_AccessId UNIQUE (AccessId),
    CONSTRAINT FK_Feedback_FeedbackAccess FOREIGN KEY (AccessId)
        REFERENCES dbo.FeedbackAccess(FeedbackAccessId),
    CONSTRAINT FK_Feedback_Customer FOREIGN KEY (CustomerId)
        REFERENCES dbo.Customer(CustomerId)
);
GO

CREATE TABLE dbo.FeedbackItem
(
    FeedbackItemId uniqueidentifier NOT NULL,
    FeedbackId     uniqueidentifier NOT NULL,
    OrderItemRef   uniqueidentifier NOT NULL,
    Star           int              NOT NULL,
    Comment        varchar(max)     NULL,

    CONSTRAINT PK_FeedbackItem PRIMARY KEY (FeedbackItemId),
    CONSTRAINT FK_FeedbackItem_Feedback FOREIGN KEY (FeedbackId)
        REFERENCES dbo.Feedback(FeedbackId)
);
GO