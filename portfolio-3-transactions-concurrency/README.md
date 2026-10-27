# Portfolio 3: Transactions and Concurrency

**Case study:** Netiks Store (see the root README).

## 1. Overview
This portfolio demonstrates how PostgreSQL keeps data correct when orders are placed
and when several users act at the same time. It covers:
- **Commit and rollback:** placing an order as a single all-or-nothing unit.
- **A concurrency problem:** two buyers purchasing the last item (overselling).
- **A control mechanism:** a row lock (`SELECT ... FOR UPDATE`) that prevents it.
- **Isolation levels:** READ COMMITTED against REPEATABLE READ.

Placing an order in Netiks Store involves five steps: create the order, add the order
item, record the payment, reduce the product stock, and log the stock change. These
must all succeed together or not at all.

## 2. Setup
All demos use one product (`product-1`) with a known stock level so results are
predictable. Concurrency demos use two psql sessions (Terminal A and Terminal B)
connected to the same database.

```sql
UPDATE catalog.products SET stock_quantity = 5 WHERE slug = 'product-1';
```
Script: `01-setup.sql`. Evidence: `screenshots/01-setup.png`

## 3. Commit and rollback (atomicity)

### 3.1 Successful order (COMMIT)
The five steps of an order run inside one transaction (`BEGIN ... COMMIT`). After the
commit, the order exists and the stock went from 5 to 4.

Script: `02-commit-rollback.sql`. Evidence: `screenshots/02-commit.png`

### 3.2 Failed order (ROLLBACK)
A buyer tries to purchase 10 items while only 4 are in stock. The stock update breaks the
`CHECK (stock_quantity >= 0)` constraint added in Portfolio 1, so PostgreSQL raises an
error. The transaction is rolled back, and even the order and order item inserted before
the error are undone. Afterwards, the order does not exist and the stock is still 4.

Script: `03-rollback.sql`. Evidence: `screenshots/03-rollback.png`
Script: `03-rollback.sql`. Evidence: `screenshots/04-manual-rollback.png`

Evidence: `screenshots/03-rollback.png`

### 3.3 Manual rollback
Changing the stock inside a transaction and then issuing `ROLLBACK` restores the
original value.

Evidence: `screenshots/04-manual-rollback.png`

**Why this matters.** Atomicity means an order is carried out as all-or-nothing, so a
failure part-way through never leaves a paid order without a stock deduction.

## 4. Concurrency: the last item

### 4.1 The problem (no lock)
Stock was set to 1. Terminal A and Terminal B each read the stock inside a transaction and
both saw 1. Then both updated the stock to 0 and created an order, and both committed.
Result: two orders exist for one item, so the item was sold twice.

```sql
SELECT stock_quantity FROM catalog.products WHERE slug = 'product-1';
```
Script: 04-race-demo.sql
Evidence: `screenshots/05-race-problem.png`

### 4.2 The fix (row lock)
The same race with `FOR UPDATE` added to the read:

```sql
SELECT stock_quantity FROM catalog.products WHERE slug = 'product-1' FOR UPDATE;
```
Terminal A read the stock and locked the row. Terminal B's identical read waited. After A
bought the item and committed, B read the new stock of 0 and did not buy. Result: one
order, and the item was sold once.

Script: 04-race-demo.sql
Evidence: `screenshots/06-lock-waiting.png` (B waiting) and `screenshots/07-lock-fixed.png`

### 4.3 Comparison
| | No lock | With `FOR UPDATE` |
|---|---|---|
| Does the second buyer wait? | No | Yes, until the first commits |
| Stock the second buyer reads | 1 (out of date) | 0 (current) |
| Orders created | 2 | 1 |
| Outcome | Item sold twice | Item sold once |

### 4.4 Why it happened and how the lock fixed it
The buyer's steps were "check, then act". The check was out of date by
the time it was used, because the second buyer read before the first had finished.
`FOR UPDATE` locks the row, so the second buyer must wait and then sees the real value.

### 4.5 Alternatives
- **Atomic update:** `UPDATE ... SET stock_quantity = stock_quantity - 1 WHERE stock_quantity >= 1`
  checks and changes the stock in one statement, so there is no gap to exploit.
- **CHECK constraint:** `stock_quantity >= 0` is a safety net that stops stock going negative
  even if the application code is careless.

## 5. Isolation levels
Isolation controls how much of other transactions' work a transaction can see.

### 5.1 READ COMMITTED (the default)
Terminal A read the stock (5). Terminal B changed it to 3 without committing, and A still
saw 5, so there are no dirty reads. After B committed, the same query in A's still-open
transaction returned 3. The same question gave two different answers inside one
transaction which is a non-repeatable read.

Script: 05-isolation-demo.sql
Evidence: `screenshots/08-read-committed.png`

### 5.2 REPEATABLE READ
The same sequence with `BEGIN ISOLATION LEVEL REPEATABLE READ`. A read 5, B committed 3,
and A still read 5 for the rest of its transaction because it works from a snapshot. After
A committed, a new query showed 3.

Script: 05-isolation-demo.sql
Evidence: `screenshots/09-repeatable-read.png`

### 5.3 Serialization error
When a REPEATABLE READ transaction tried to update a row that another transaction had
changed after its snapshot, PostgreSQL refused with
`could not serialize access due to concurrent update`. The application is expected to
retry the transaction.

Script: 05-isolation-demo.sql
Evidence: `screenshots/10-serialization-error.png`

### 5.4 Summary
| Level | What a transaction sees | Trade-off |
|---|---|---|
| READ COMMITTED | The latest committed data at each statement | Repeated reads can differ |
| REPEATABLE READ | One snapshot for the whole transaction | Updates may fail and need a retry |
| SERIALIZABLE | As if transactions ran one at a time | Strictest, most retries (not demonstrated) |

PostgreSQL never allows dirty reads at any level.

## 6. Design decisions and lessons
- **Checkout uses READ COMMITTED with `FOR UPDATE`.**  it is the default and needs no retries, and the lock stops overselling. REPEATABLE READ suits reports that need
  a consistent snapshot.
- **Locks make users wait.** The second buyer waited in Demo 4.2. That wait is the price of
  correctness, so locks should be held for as short a time as possible.
- **Forgotten transactions block others.** During testing, an update hung because another
  terminal still had an open transaction holding a lock on the product row. Ending it with
  `ROLLBACK` released the lock. In a real system this is why transactions should be kept
  short and always finished.
- **Constraints and transactions work together.** The CHECK rule from Portfolio 1 is what
  caused the failure in 3.2, and the rollback is what made that failure safe.

## 7. Files
| File | Contents |
|---|---|
| 01-setup.sql | Sets the test product's stock |
| 02-commit-rollback.sql | The successful order (commit) |
| 03-rollback.sql | The failed order and the manual rollback |
| 04-race-demo.sql | The race and lock demos, with comments marking Terminal A and B |
| 05-isolation-demo.sql | The isolation level demos |
| screenshots/ | Evidence for each demo (01 to 10) |
