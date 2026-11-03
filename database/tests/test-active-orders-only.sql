-- usp_GetActiveOrders must return every Active order and nothing else.
SET NOCOUNT ON;

CREATE TABLE #Result (OrderId int, CustomerId int, CustomerName nvarchar(100), OrderDate date, Total decimal(12,2));
INSERT #Result EXEC dbo.usp_GetActiveOrders;

DECLARE @NotActive int = (SELECT COUNT(*) FROM #Result AS r JOIN dbo.Orders AS o ON o.OrderId = r.OrderId WHERE o.Status <> 'Active');
DECLARE @Missing   int = (SELECT COUNT(*) FROM dbo.Orders AS o WHERE o.Status = 'Active' AND o.OrderId NOT IN (SELECT OrderId FROM #Result));

IF @NotActive > 0
BEGIN
    DECLARE @Msg1 nvarchar(200) = CONCAT('FAIL: usp_GetActiveOrders returned ', @NotActive, ' orders that are not Active. Is the WHERE clause missing?');
    THROW 50001, @Msg1, 1;
END;

IF @Missing > 0
BEGIN
    DECLARE @Msg2 nvarchar(200) = CONCAT('FAIL: usp_GetActiveOrders left out ', @Missing, ' Active orders.');
    THROW 50002, @Msg2, 1;
END;
GO
