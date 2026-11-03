-- 5 customers and 15 orders. Only inserts rows that are missing, so it's safe to run twice.
SET NOCOUNT ON;

INSERT dbo.Customers (CustomerId, Name, Email)
SELECT v.CustomerId, v.Name, v.Email
FROM (VALUES
    (1, N'Rose City Coffee',     N'orders@rosecitycoffee.example'),
    (2, N'Willamette Books',     N'hello@willamettebooks.example'),
    (3, N'Hawthorne Bikes',      N'shop@hawthornebikes.example'),
    (4, N'Pearl District Plants', N'grow@pearlplants.example'),
    (5, N'Mt Hood Outfitters',   N'gear@mthood.example')
) AS v (CustomerId, Name, Email)
WHERE NOT EXISTS (SELECT 1 FROM dbo.Customers AS c WHERE c.CustomerId = v.CustomerId);

INSERT dbo.Orders (OrderId, CustomerId, OrderDate, Status, Total)
SELECT v.OrderId, v.CustomerId, v.OrderDate, v.Status, v.Total
FROM (VALUES
    (101, 1, '2026-09-01', 'Shipped',    42.50),
    (102, 1, '2026-09-15', 'Active',     18.00),
    (103, 2, '2026-09-03', 'Shipped',    65.25),
    (104, 2, '2026-10-02', 'Active',    120.00),
    (105, 2, '2026-10-20', 'Cancelled',  15.99),
    (106, 3, '2026-08-11', 'Shipped',   899.00),
    (107, 3, '2026-10-05', 'Active',     45.00),
    (108, 3, '2026-10-28', 'Active',     12.75),
    (109, 4, '2026-09-21', 'Cancelled',  33.00),
    (110, 4, '2026-10-10', 'Shipped',    76.40),
    (111, 4, '2026-10-30', 'Active',     54.10),
    (112, 5, '2026-07-04', 'Shipped',   249.99),
    (113, 5, '2026-09-30', 'Cancelled', 150.00),
    (114, 5, '2026-10-18', 'Active',    310.00),
    (115, 5, '2026-11-01', 'Shipped',    89.95)
) AS v (OrderId, CustomerId, OrderDate, Status, Total)
WHERE NOT EXISTS (SELECT 1 FROM dbo.Orders AS o WHERE o.OrderId = v.OrderId);
GO
