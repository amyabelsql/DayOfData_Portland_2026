# Branching

`main` is always deployable. Every change goes on a short branch and comes back through a pull request. Branches should live for days, not weeks. The longer a branch lives, the harder it is to merge.

## How a change moves

1. Create a branch from `main`. Name it using the [[Naming conventions|Naming-Conventions]], like `dba/add-orderdate-index`.
2. Commit your change, the test, and the rollback script.
3. Push and open a pull request.
4. If the tests fail, fix it on the same branch. Don't open a new pull request.
5. Once it's approved and green, it merges. The branch gets deleted automatically.

```mermaid
gitGraph
    commit id: "v1.0.0"
    branch dba/add-orderdate-index
    checkout dba/add-orderdate-index
    commit id: "Add IX_Orders_OrderDate"
    commit id: "Add test and rollback"
    checkout main
    merge dba/add-orderdate-index id: "Merge after review"
    branch hotfix/orders-blocking
    checkout hotfix/orders-blocking
    commit id: "Batch the nightly update"
    checkout main
    merge hotfix/orders-blocking id: "Merge during incident"
    commit id: "v1.1.0"
```

## Hotfixes

During an incident, branch from `main` and name it `hotfix/...`. It still needs a pull request and the tests still have to pass. The only difference is that it can skip the maintenance window and gets reviewed right away.
