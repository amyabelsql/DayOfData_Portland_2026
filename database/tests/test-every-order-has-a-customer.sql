-- Every order must point at a real customer, and the proc must show the customer name.
SET NOCOUNT ON;

DECLARE @Orphans int = (SELECT COUNT(*) FROM dbo.Orders AS o WHERE NOT EXISTS (SELECT 1 FROM dbo.Customers AS c WHERE c.CustomerId = o.CustomerId));
IF @Orphans > 0
BEGIN
    DECLARE @Msg1 nvarchar(200) = CONCAT('FAIL: ', @Orphans, ' orders have no matching customer.');
    THROW 50003, @Msg1, 1;
END;

CREATE TABLE #Result (OrderId int, CustomerId int, CustomerName nvarchar(100), OrderDate date, Total decimal(12,2));
INSERT #Result EXEC dbo.usp_GetActiveOrders;

IF EXISTS (SELECT 1 FROM #Result WHERE CustomerName IS NULL OR CustomerName = N'')
    THROW 50004, 'FAIL: usp_GetActiveOrders returned an order without a customer name.', 1;
GO
