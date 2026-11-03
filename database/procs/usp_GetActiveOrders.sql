-- Returns the orders that are still Active, with the customer name.
CREATE OR ALTER PROCEDURE dbo.usp_GetActiveOrders
AS
BEGIN
    SET NOCOUNT ON;

    SELECT o.OrderId,
           o.CustomerId,
           c.Name AS CustomerName,
           o.OrderDate,
           o.Total
    FROM dbo.Orders AS o
    JOIN dbo.Customers AS c ON c.CustomerId = o.CustomerId
    WHERE o.Status = 'Active'
    ORDER BY o.OrderDate, o.OrderId;
END;
GO
