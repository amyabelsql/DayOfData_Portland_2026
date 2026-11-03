-- Rollback for dbo.usp_GetCustomerOrderCount: removes the proc. Safe to run twice.
DROP PROCEDURE IF EXISTS dbo.usp_GetCustomerOrderCount;
GO
