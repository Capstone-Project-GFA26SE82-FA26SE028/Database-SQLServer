USE master;
GO

IF DB_ID(N'IdentityDb') IS NOT NULL
BEGIN
    ALTER DATABASE IdentityDb
        SET SINGLE_USER WITH ROLLBACK IMMEDIATE;

    DROP DATABASE IdentityDb;
END;
GO

CREATE DATABASE IdentityDb;
GO

USE IdentityDb;
GO

CREATE TABLE dbo.[Role]
(
    RoleId      varchar(50)   NOT NULL,
    RoleName    nvarchar(50)  NOT NULL,
    Description nvarchar(max) NULL,

    CONSTRAINT PK_Role PRIMARY KEY (RoleId)
);
GO

CREATE TABLE dbo.[User]
(
    UserId       uniqueidentifier NOT NULL,
    RoleId       varchar(50)       NOT NULL,
    UserName     nvarchar(100)     NOT NULL,
    Email        nvarchar(255)     NOT NULL,
    PhoneNumber  varchar(20)       NULL,
    FullName     nvarchar(255)     NOT NULL,
    AvatarUrl    nvarchar(max)     NULL,
    PasswordHash varchar(max)      NOT NULL,
    IsActive     bit               NOT NULL,
    CreatedAt    datetimeoffset(7) NOT NULL,
    UpdatedAt    datetimeoffset(7) NULL,

    CONSTRAINT PK_User PRIMARY KEY (UserId),
    CONSTRAINT FK_User_Role FOREIGN KEY (RoleId)
        REFERENCES dbo.[Role](RoleId)
);
GO

CREATE TABLE dbo.UserSession
(
    UserSessionId uniqueidentifier NOT NULL,
    UserId        uniqueidentifier NOT NULL,
    IpAddress     varchar(45)       NULL,
    UserAgent     nvarchar(max)     NULL,
    DeviceType    varchar(50)       NULL,
    LoggedInAt    datetimeoffset(7) NOT NULL,
    ExpiresAt     datetimeoffset(7) NOT NULL,

    CONSTRAINT PK_UserSession PRIMARY KEY (UserSessionId),
    CONSTRAINT FK_UserSession_User FOREIGN KEY (UserId)
        REFERENCES dbo.[User](UserId)
);
GO

CREATE TABLE dbo.AuditLog
(
    AuditLogId  uniqueidentifier NOT NULL,
    ActorUserId uniqueidentifier NULL,
    Action      varchar(100)      NOT NULL,
    EntityName  varchar(100)      NOT NULL,
    EntityId    varchar(255)      NULL,
    OldValue    nvarchar(max)     NULL,
    NewValue    nvarchar(max)     NULL,
    IpAddress   varchar(45)       NULL,
    CreatedAt   datetimeoffset(7) NOT NULL,

    CONSTRAINT PK_AuditLog PRIMARY KEY (AuditLogId),
    CONSTRAINT FK_AuditLog_User FOREIGN KEY (ActorUserId)
        REFERENCES dbo.[User](UserId)
);
GO