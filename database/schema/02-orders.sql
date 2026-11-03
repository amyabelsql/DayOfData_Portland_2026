-- dbo.Orders. Every order belongs to a customer. Safe to run twice.
IF OBJECT_ID(N'dbo.Orders', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Orders
    (
        OrderId    int           NOT NULL CONSTRAINT PK_Orders PRIMARY KEY,
        CustomerId int           NOT NULL CONSTRAINT FK_Orders_Customers REFERENCES dbo.Customers (CustomerId),
        OrderDate  date          NOT NULL,
        Status     varchar(10)   NOT NULL CONSTRAINT CK_Orders_Status CHECK (Status IN ('Active', 'Shipped', 'Cancelled')),
        Total      decimal(12,2) NOT NULL CONSTRAINT CK_Orders_Total CHECK (Total >= 0)
    );
END;
GO
