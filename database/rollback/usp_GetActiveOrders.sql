-- Rollback for dbo.usp_GetActiveOrders: removes the proc. Safe to run twice.
DROP PROCEDURE IF EXISTS dbo.usp_GetActiveOrders;
GO
