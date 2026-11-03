-- Speeds up "orders by date" queries. Safe to run twice.
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Orders_OrderDate' AND object_id = OBJECT_ID(N'dbo.Orders'))
    CREATE INDEX IX_Orders_OrderDate ON dbo.Orders (OrderDate);
GO
