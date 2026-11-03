-- dbo.Customers. Safe to run twice.
IF OBJECT_ID(N'dbo.Customers', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Customers
    (
        CustomerId int           NOT NULL CONSTRAINT PK_Customers PRIMARY KEY,
        Name       nvarchar(100) NOT NULL,
        Email      nvarchar(255) NOT NULL,
        CreatedAt  datetime2(0)  NOT NULL CONSTRAINT DF_Customers_CreatedAt DEFAULT SYSUTCDATETIME()
    );
END;
GO
