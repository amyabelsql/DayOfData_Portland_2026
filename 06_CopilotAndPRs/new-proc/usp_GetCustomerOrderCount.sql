-- Returns how many orders each customer has, by status.
CREATE OR ALTER PROCEDURE dbo.usp_GetCustomerOrderCount
AS
BEGIN
    SET NOCOUNT ON;

    SELECT c.CustomerId,
           c.Name AS CustomerName,
           COUNT(o.OrderId)                                        AS TotalOrders,
           SUM(CASE WHEN o.Status = 'Active' THEN 1 ELSE 0 END)    AS ActiveOrders
    FROM dbo.Customers AS c
    LEFT JOIN dbo.Orders AS o ON o.CustomerId = c.CustomerId
    GROUP BY c.CustomerId, c.Name
    ORDER BY c.CustomerId;
END;
GO
