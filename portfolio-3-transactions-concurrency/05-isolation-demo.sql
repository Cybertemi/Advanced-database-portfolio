-- Portfolio 3: isolation level demos
-- Run in TWO psql sessions (Terminal A and Terminal B).
-- Paste the steps in the order shown; do not run this file with -f.

-- ===== Reset (Terminal A) =====
UPDATE catalog.products SET stock_quantity = 5 WHERE slug = 'product-1';

-- ===== Demo 5: READ COMMITTED (the default) =====

-- Terminal A:
BEGIN;
SHOW transaction_isolation;                                              -- read committed
SELECT stock_quantity FROM catalog.products WHERE slug = 'product-1';   -- 5

-- Terminal B (changes the stock but does NOT commit yet):
BEGIN;
UPDATE catalog.products SET stock_quantity = 3 WHERE slug = 'product-1';

-- Terminal A:
SELECT stock_quantity FROM catalog.products WHERE slug = 'product-1';   -- still 5 (no dirty read)

-- Terminal B:
COMMIT;

-- Terminal A (same query, same transaction):
SELECT stock_quantity FROM catalog.products WHERE slug = 'product-1';   -- now 3 (non-repeatable read)
COMMIT;

-- ===== Demo 6: REPEATABLE READ =====

-- Reset (Terminal A):
UPDATE catalog.products SET stock_quantity = 5 WHERE slug = 'product-1';

-- Terminal A:
BEGIN ISOLATION LEVEL REPEATABLE READ;
SHOW transaction_isolation;                                              -- repeatable read
SELECT stock_quantity FROM catalog.products WHERE slug = 'product-1';   -- 5

-- Terminal B (commits immediately):
UPDATE catalog.products SET stock_quantity = 3 WHERE slug = 'product-1';

-- Terminal A:
SELECT stock_quantity FROM catalog.products WHERE slug = 'product-1';   -- still 5 (snapshot)
COMMIT;
SELECT stock_quantity FROM catalog.products WHERE slug = 'product-1';   -- now 3

-- ===== Extra: serialization error =====

-- Reset (Terminal A):
UPDATE catalog.products SET stock_quantity = 5 WHERE slug = 'product-1';

-- Terminal A:
BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT stock_quantity FROM catalog.products WHERE slug = 'product-1';

-- Terminal B:
UPDATE catalog.products SET stock_quantity = 3 WHERE slug = 'product-1';

-- Terminal A (fails: could not serialize access due to concurrent update):
UPDATE catalog.products SET stock_quantity = stock_quantity - 1 WHERE slug = 'product-1';
ROLLBACK;

-- Final clean up:
UPDATE catalog.products SET stock_quantity = 5 WHERE slug = 'product-1';