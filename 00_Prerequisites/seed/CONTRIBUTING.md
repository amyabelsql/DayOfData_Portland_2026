# Contributing

1. File a **Database change request** from the Issues tab. The form asks for everything the DBA team needs.
2. Make your change on a branch. Include a rollback script in `database/rollback/` and a test in `database/tests/`.
3. Open a pull request. The `database-tests` check must pass before it can merge.
