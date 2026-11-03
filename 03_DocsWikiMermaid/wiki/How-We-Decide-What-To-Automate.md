# How we decide what to automate

**The 3 F's** tell us if a task is worth it: it happens **F**requently, it's **F**iddly, and it's a **F**ailure risk when a person does it by hand.

**The 4 R's** tell us if it's ready: it's **R**epeatable, it has **R**ules we can write down, the result is **R**eviewable, and we can **R**oll it back.

```mermaid
flowchart TD
    A[A task keeps coming up] --> B{Frequent?}
    B -- No --> M[Keep doing it by hand. Write it down.]
    B -- Yes --> C{Fiddly or a failure risk?}
    C -- No --> M
    C -- Yes --> D{Repeatable with clear rules?}
    D -- No --> W[Write a runbook first]
    D -- Yes --> E{Reviewable and can we roll it back?}
    E -- No --> W
    E -- Yes --> F[Automate it]
```
