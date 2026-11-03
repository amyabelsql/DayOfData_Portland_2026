## What we need

Add a way to track when an order ships.

1. Add a nullable `ShippedAt datetime2(0)` column to `dbo.Orders`, in a new script in `database/schema/`.
2. Add `dbo.usp_GetShippedOrders` in `database/procs/`. It returns orders where `Status = 'Shipped'`, with the customer name and `ShippedAt`.
3. Add a test in `database/tests/` that fails with a clear `FAIL:` message if the proc returns anything that isn't Shipped.
4. Add rollback scripts in `database/rollback/` for the column and the proc.

## Rules

Follow `.github/copilot-instructions.md`. Every script must be safe to run twice.
The `database-tests` check must pass.
