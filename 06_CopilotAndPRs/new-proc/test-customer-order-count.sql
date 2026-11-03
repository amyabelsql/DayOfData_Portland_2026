-- usp_GetCustomerOrderCount must return one row per customer, and the counts must add up.
SET NOCOUNT ON;

CREATE TABLE #Result (CustomerId int, CustomerName nvarchar(100), TotalOrders int, ActiveOrders int);
INSERT #Result EXEC dbo.usp_GetCustomerOrderCount;

IF (SELECT COUNT(*) FROM #Result) <> (SELECT COUNT(*) FROM dbo.Customers)
    THROW 50011, 'FAIL: usp_GetCustomerOrderCount should return one row per customer.', 1;

IF (SELECT SUM(TotalOrders) FROM #Result) <> (SELECT COUNT(*) FROM dbo.Orders)
    THROW 50012, 'FAIL: usp_GetCustomerOrderCount totals do not match dbo.Orders.', 1;
GO
