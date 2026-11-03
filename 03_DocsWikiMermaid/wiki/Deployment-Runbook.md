# Deployment runbook

From request to production, with a way back at every step.

```mermaid
flowchart LR
    I[Issue from the form] --> P[Pull request]
    P --> T{database-tests pass?}
    T -- No --> F[Fix on the same branch] --> P
    T -- Yes --> M[Merge to main]
    M --> D[Deploy]
    D --> C{Healthy?}
    C -- Yes --> Done[Close the issue]
    C -- No --> R[Run the rollback script] --> I
```

1. Every request starts as a **Database change request** issue.
2. The pull request includes the change, a test, and a rollback script in `database/rollback/`.
3. If anything looks wrong after deploy, run the rollback script and reopen the issue.
