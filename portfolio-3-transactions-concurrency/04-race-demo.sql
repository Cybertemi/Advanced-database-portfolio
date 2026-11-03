-- Portfolio 3: concurrency demo, the last item
-- Run in TWO psql sessions (Terminal A and Terminal B) connected to netiks_portfolio.
-- Paste the steps in the order shown; do not run this file with -f.

-- ===== Reset (Terminal A) =====
UPDATE catalog.products SET stock_quantity = 1 WHERE slug = 'product-1';

-- ===== Demo 3: the problem (no lock) =====

-- Terminal A:
BEGIN;
SELECT stock_quantity FROM catalog.products WHERE slug = 'product-1';   -- shows 1

-- Terminal B (before A does anything else):
BEGIN;
SELECT stock_quantity FROM catalog.products WHERE slug = 'product-1';   -- also shows 1

-- Terminal A:
UPDATE catalog.products SET stock_quantity = 0 WHERE slug = 'product-1';
INSERT INTO sales.orders (id, customer_id, shipping_address, status)
SELECT 'race-order-a', id, 'Ibadan', 'paid'
FROM sales.customers WHERE email = 'customer1@example.com';
COMMIT;

-- Terminal B (acts on the stale value it read earlier):
UPDATE catalog.products SET stock_quantity = 0 WHERE slug = 'product-1';
INSERT INTO sales.orders (id, customer_id, shipping_address, status)
SELECT 'race-order-b', id, 'Ibadan', 'paid'
FROM sales.customers WHERE email = 'customer1@example.com';
COMMIT;

-- Either terminal: two orders exist for one item
SELECT id FROM sales.orders WHERE id IN ('race-order-a', 'race-order-b');
SELECT stock_quantity FROM catalog.products WHERE slug = 'product-1';

-- Clean up (Terminal A):
DELETE FROM sales.orders WHERE id IN ('race-order-a', 'race-order-b');
UPDATE catalog.products SET stock_quantity = 1 WHERE slug = 'product-1';

-- ===== Demo 4: the fix (row lock with FOR UPDATE) =====

-- Terminal A:
BEGIN;
SELECT stock_quantity FROM catalog.products WHERE slug = 'product-1' FOR UPDATE;   -- shows 1, row locked

-- Terminal B (this WAITS until A finishes):
BEGIN;
SELECT stock_quantity FROM catalog.products WHERE slug = 'product-1' FOR UPDATE;

-- Terminal A buys it and releases the lock:
UPDATE catalog.products SET stock_quantity = stock_quantity - 1 WHERE slug = 'product-1';
INSERT INTO sales.orders (id, customer_id, shipping_address, status)
SELECT 'lock-order-a', id, 'Ibadan', 'paid'
FROM sales.customers WHERE email = 'customer1@example.com';
COMMIT;

-- Terminal B now sees stock 0 and does not buy:
ROLLBACK;

-- Check: only one order exists, and stock is 0
SELECT id FROM sales.orders WHERE id IN ('lock-order-a', 'lock-order-b');
SELECT stock_quantity FROM catalog.products WHERE slug = 'product-1';

-- Clean up (Terminal A):
DELETE FROM sales.orders WHERE id = 'lock-order-a';
UPDATE catalog.products SET stock_quantity = 5 WHERE slug = 'product-1';