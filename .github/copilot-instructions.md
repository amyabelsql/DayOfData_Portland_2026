# House rules for Copilot

This repo holds the DemoShop SQL Server database and the demo scripts for the talk.
When you write or review T-SQL here, follow these rules.

- Use `CREATE OR ALTER` for procs, views, and functions.
- Start every proc with `SET NOCOUNT ON`.
- Schema-qualify every object, like `dbo.Orders`, never just `Orders`.
- Every script must be safe to run twice. Guard creates with `IF OBJECT_ID(...) IS NULL` or `IF NOT EXISTS`.
- Every change includes a rollback script in `database/rollback/` and a test in `database/tests/`.
- Tests are plain T-SQL. When a check fails, `THROW` with a message that starts with `FAIL:`.
- No passwords or keys in any file.
- Keep it short and readable. A DBA should understand any script in a minute.
