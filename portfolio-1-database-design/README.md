# Portfolio 1: Database Design and Modelling

**Case study:** Netiks Store, a multi-vendor online marketplace (see the root README).

## 1. Overview
This portfolio documents the existing Netiks Store database, identifies design
weaknesses in its orders module, and presents an improved and normalised design. The
improved design was implemented in a separate PostgreSQL container so the original
Netiks Store setup was never modified.

## 2. Existing schema (as-is)
The existing schema was inspected in psql and exported with `pg_dump --schema-only`
(`01-existing-schema.sql`). Each service owns its own schema:

| Schema | Tables |
|---|---|
| identity | users, auth_sessions |
| vendor | stores |
| catalog | categories, products, orders |

Only three real foreign keys exist: auth_sessions to users, products to categories,
and orders to products.

- ER diagram: `diagrams/er-as-is.png`
- Evidence: `screenshots/[existing-tables].png`, `screenshots/[orders-structure].png`

## 3. Weaknesses found
| # | Weakness | Why it matters |
|---|---|---|
| 1 | `catalog.orders` stores buyer, payment and product details in one row | Data is repeated; one change needs many updates |
| 2 | One product per order | A buyer cannot purchase several items together |
| 3 | `total_price` and `sold_quantity` are derivable | They can disagree with the data they come from |
| 4 | Stock is a bare counter (`stock_quantity`) | No history of changes, and it is prone to race conditions |
| 5 | No CHECK constraints; free-text `status` columns | Invalid values (negative price, zero quantity) can be stored |
| 6 | `store_id` and `owner_id` have no foreign keys | The database does not enforce those links |

Weakness 6 comes from each service owning its own schema. I left those links as plain
columns in the improved design, as a trade-off to keep the services independent.

## 4. Normalisation of catalog.orders

### The problem
The original `catalog.orders` table stored everything about a purchase in one row: the buyer's details (name, email, phone, shipping address), the payment details (method, reference), the product, the quantity and the prices.

This causes two problems:
- **Repeated data.** If a buyer named Ade places two orders (a phone and a charger), their name, email and phone are saved twice. If their phone number changes, both rows must be updated, and missing one leaves the data inconsistent.
- **One product per order.** The table has a single `product_id`, so a buyer cannot purchase several items in one order.

### 1NF (first normal form)
Rule: every column holds a single value, and every row is identified by a primary key.

`catalog.orders` satisfies 1NF. Each column holds one value and `id` is the primary key.

### 2NF (second normal form)
Rule: if the key has more than one column, no other column may depend on only part of it.

The table's key is the single column `id`, so it satisfies 2NF formally. However, it
mixes order-level facts (buyer, payment) with line-level facts (product, quantity).
Once an order can hold several products, the key becomes (order_id, product_id), and
buyer details would depend on only part of that key. Separating them into `orders`
and `order_items` removes the problem.

### 3NF (third normal form)
Rule: no non-key column may depend on another non-key column.

`catalog.orders` fails 3NF:

| Dependency | Problem | Fix |
|---|---|---|
| buyer_email determines buyer_name, buyer_phone | Buyer facts are repeated on every order | Moved to `customers` |
| payment_reference determines payment_method | Payment facts belong to the payment, not the order | Moved to `payments` |
| total_price = quantity x unit_price | A derived value that can disagree with its parts | Removed; calculated by the `order_totals` view |

### Result (3NF design)
| Table | Stores |
|---|---|
| sales.customers | Buyer details, stored once |
| sales.orders | The order itself (customer, address, status) |
| sales.order_items | One row per product in an order |
| sales.payments | Payment details for an order |
| sales.inventory_movements | History of stock changes (an audit feature, not a normalisation split) |

`unit_price` is kept in `order_items` on purpose to record the price at the time
of purchase, so that later changes to `products.price` do not alter past orders. This is
a different fact from the current price, so it is not redundant.

## 5. Improved design
The existing identity, vendor and catalog tables are kept. The old orders module is
replaced by a new `sales` schema (`02-improved-module.sql`):

| Table | Purpose | Keys and constraints |
|---|---|---|
| sales.customers | Buyer details, stored once | PK id; UNIQUE email; optional FK to identity.users |
| sales.orders | The order itself | PK id; FK customer_id; CHECK on status |
| sales.order_items | One row per product in an order | PK id; FKs to orders and products; CHECK quantity > 0; UNIQUE (order_id, product_id) |
| sales.payments | Payment for an order | PK id; FK order_id; UNIQUE reference; CHECK on amount and status |
| sales.inventory_movements | History of stock changes | PK id; FK product_id; optional FK order_id; CHECK on reason |

Other changes:
- `catalog.products` gets CHECK constraints: `price >= 0` and `stock_quantity >= 0`.
- `sales.order_totals` is a view that calculates order totals instead of storing them.
- Foreign-key indexes only; further indexes are left for Portfolio 2.

- ER diagram: `diagrams/er-improved.png`
- Evidence: `screenshots/[sales-tables].png`, `screenshots/[order-items-structure].png`,
  `screenshots/[payments-structure].png`

## 6. Design decisions and trade-offs
- **Separate customers table.** Why: keeps buyer details in one place and supports
  guest checkout, since user_id is optional.
- **Stock ledger.** Why: every stock change is recorded with a reason, which gives
  an audit trail and a clear place to demonstrate concurrency in Portfolio 3.
- **unit_price kept in order_items.** Why: it records the price at purchase time,
  so past orders do not change when a product's price changes.
- **No cross-schema foreign keys for store_id and owner_id.** Why: services own
  their schemas; this is a deliberate trade-off, not an oversight.
- **A separate database for the portfolio.** [Why: so experiments, bulk data loads
  and resets never touch the real Netiks Store setup.]

## 7. Constraint testing
Valid and invalid inserts were run to show the constraints working
(`screenshots/[constraint-violations].png`): a valid order item was accepted, while
`quantity = 0`, a negative product price and an invalid order status were rejected.

## 8. How to run
1. Install Docker.
2. From the repository root run `docker compose up -d`.
3. Check the logs: `docker compose logs portfolio-postgres`.
4. Connect: `psql -h localhost -p 5433 -U portfolio netiks_portfolio`.
5. Verify: `\dt sales.*`

Postgres runs `01-existing-schema.sql` and then `02-improved-module.sql` on first
start. To rebuild from scratch: `docker compose down -v` and then `docker compose up -d`.

## 9. Files
| File | Contents |
|---|---|
| 01-existing-schema.sql | Structure exported from the existing Netiks Store database |
| 02-improved-module.sql | The sales module and added constraints |
| diagrams/ | ER diagrams (PNG and .drawio) |
| screenshots/ | Evidence of the schema, structure and constraint tests |



The original table repeated the buyer’s details (name, email, phone, address) on every order. For example, if a buyer placed two orders, their details were stored twice, and a change of phone number would need two updates. It also held only one product per order, so a buyer couldn’t purchase several items in one order.