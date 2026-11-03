# DemoShop data model

Two tables. Every order belongs to one customer. Scripts live in `database/schema/`.

```mermaid
erDiagram
    CUSTOMERS ||--o{ ORDERS : places
    CUSTOMERS {
        int CustomerId PK
        nvarchar Name
        nvarchar Email
        datetime2 CreatedAt
    }
    ORDERS {
        int OrderId PK
        int CustomerId FK
        date OrderDate
        varchar Status "Active, Shipped, or Cancelled"
        decimal Total
    }
```

`dbo.usp_GetActiveOrders` returns the orders where `Status = 'Active'`, with the customer name.
