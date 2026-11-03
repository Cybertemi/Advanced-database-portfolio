# Portfolio 2: Query Processing and Optimisation

**Case study:** Netiks Store (see the root README).

## 1. Overview
This portfolio measures five realistic Netiks Store queries on a database with
hundreds of thousands of rows, records their execution plans before any
optimisation, adds indexes chosen for each query, and compares the results.
All measurements use `EXPLAIN (ANALYZE, BUFFERS)`, run twice, with the second
(warm-cache) run recorded.

## 2. Test data
Synthetic data was generated with `01-load-data.sql` using `generate_series`:

| Table | Rows |
|---|---|
| identity.users | 1,000 |
| vendor.stores | 200 |
| catalog.categories | 20 |
| catalog.products | 50,000 |
| sales.customers | 50,000 |
| sales.orders | 200,000 |
| sales.order_items | 400,000 |
| sales.payments | 200,000 |

Evidence: `screenshots/01-data-loaded.png`

## 3. The five queries (`02-queries.sql`)
| # | Business purpose | What it exercises |
|---|---|---|
| Q1 | Customer searches products by part of a name | Text search with a leading wildcard |
| Q2 | Browse a category by price range, cheapest first | Filter, join and sort with a limit |
| Q3 | Admin views recent paid orders | Filter on two columns, then sort |
| Q4 | Vendor sales report for 90 days | Four-table join and aggregation |
| Q5 | Admin audits the largest payments | Filter, sort and limit on one column |

## 4. Baseline (before optimisation)
Only the original Netiks indexes existed at this point.

| Query | Main plan node | Execution time |
|---|---|---|
| Q1 | Seq Scan on products (49,989 of 50,000 rows discarded) | 75.98 ms |
| Q2 | Bitmap Heap Scan (1,839 pages read) plus top-N sort | 4.60 ms |
| Q3 | Parallel Seq Scan on orders plus sort | 38.23 ms |
| Q4 | Nested loops over existing foreign-key indexes | 24.52 ms |
| Q5 | Parallel Seq Scan on payments plus top-N sort | 37.00 ms |

Evidence: `screenshots/02-q1-baseline.png` to `06-q5-baseline.png`

## 5. Indexes added (`03-indexes.sql`)
| Index | Table and columns | Targets |
|---|---|---|
| ix_products_name_trgm | products(name), GIN trigram | Q1 |
| ix_products_category_price | products(category_id, price) | Q2 |
| ix_orders_status_created | orders(status, created_at) | Q3 |
| ix_orders_id_created | orders(id) INCLUDE (created_at) | Q4 |
| ix_payments_amount | payments(amount) | Q5 |

Evidence: `screenshots/07-indexes-created.png`

## 6. Results and analysis
| Query | Before | After | Change | Plan change |
|---|---|---|---|---|
| Q1 | 75.98 ms | 3.01 ms | about 25x faster | Seq Scan became Bitmap Index Scan; 2 table pages read instead of 1,839 |
| Q2 | 4.60 ms | 4.74 ms | none | Index used and pages halved, but the Sort remained |
| Q2 (rewritten) | 4.60 ms | 0.59 ms | about 8x faster | Index Scan, no Sort, 24 buffers read |
| Q3 | 38.23 ms | 1.67 ms | about 23x faster | Parallel Seq Scan became Bitmap Index Scan |
| Q4 | 24.52 ms | 22.09 ms | about 10% (within normal variation) | Became an Index Only Scan with 0 heap fetches |
| Q5 | 37.00 ms | 0.11 ms | about 325x faster | Became Index Scan Backward; no scan, no Sort |

Evidence: `screenshots/08-q1-after.png` to `12-q5-after.png` and `09b-q2-rewrite-after.png`

**Q1.** Searching for part of a product name was slow (75.98 ms) because the
search starts with `%`, which a normal index cannot use, so Postgres had to do a
sequential scan and read all 50,000 products. I added a trigram index, which
breaks each name into 3-letter pieces so Postgres can look up the pieces and go
directly to the matching rows. It read 2 table pages instead of 1,839, and the
time dropped to 3.01 ms.

**Q2.** This query was already quick (4.60 ms). I added an index on category and
price, but the time stayed at 4.74 ms, because the join to categories stopped
Postgres from reading the index in price order. When I rewrote the query to look
up the category first, Postgres read the index in order and stopped after 20
rows, which took 0.59 ms. This shows that how a query is written matters as well
as the index.

**Q3.** Finding recent paid orders was slow (38.23 ms) because Postgres read all
200,000 orders to find 604. I added an index on status and date, so Postgres goes
straight to the paid orders from the last 7 days. The time dropped to 1.67 ms.

**Q4.** The vendor sales report was already using indexes from Portfolio 1, so
there was little wasted work to remove. My new index let Postgres skip visiting
the table for the order dates, but the time barely changed (24.52 ms to 22.09 ms).
This query was already well served.

**Q5.** Finding the 20 largest payments was slow (37.00 ms) because Postgres read
every payment and sorted them. I added an index on amount, which keeps the values
in order. Postgres now reads the 20 largest from the end of the index and stops,
with no scan and no sort, so it takes 0.11 ms. This was the biggest improvement.

## 7. Trade-offs and lessons
- **Indexes are not free.** Each one uses disk space and must be updated on every
  insert, update and delete. The five indexes I added take about 23 MB in total:
  13 MB (id with date), 4.4 MB (amount), 3.3 MB (category and price), 1.4 MB
  (status and date) and 1.4 MB (trigram on name)
  (`screenshots/13-index-sizes.png`). The largest, `ix_orders_id_created`, gave
  almost no speed-up on Q4, so in a real system I would remove it. The smaller
  indexes for Q1, Q3 and Q5 each made their query more than 20 times faster.

## 8. How to reproduce
1. Start the database (`docker compose up -d` from the repository root).
2. Load the data: `psql -h localhost -p 5433 -U portfolio -d netiks_portfolio -f portfolio-2-query-optimisation/01-load-data.sql`
3. Run `\pset pager off`, then each query in `02-queries.sql` with
   `EXPLAIN (ANALYZE, BUFFERS)` in front, twice, and record the second run.
4. Run `03-indexes.sql`, then `VACUUM ANALYZE;`, and repeat step 3.

## 9. Files
| File | Contents |
|---|---|
| 01-load-data.sql | Synthetic data generation |
| 02-queries.sql | The five queries |
| 03-indexes.sql | The indexes added |
| screenshots/ | Baseline plans, after plans, index list, index sizes, query results |

## 10.  Query results
Each query was also run without EXPLAIN to show the rows it returns:
`screenshots/14-q1-result.png` to `18-q5-result.png`. Q3 shows the first 10 of
604 matching rows.

