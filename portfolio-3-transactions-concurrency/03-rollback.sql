-- Portfolio 3, Demo 2: a failing order (ROLLBACK)
-- A buyer tries to purchase 10 items while only 4 are in stock.
-- The stock update breaks CHECK (stock_quantity >= 0), so everything is undone.

BEGIN;

INSERT INTO sales.orders (id, customer_id, shipping_address, status)
SELECT 'demo-order-2', id, 'Ibadan', 'paid'
FROM sales.customers WHERE email = 'customer1@example.com';

INSERT INTO sales.order_items (id, order_id, product_id, quantity, unit_price)
SELECT 'demo-item-2', 'demo-order-2', id, 10, price
FROM catalog.products WHERE slug = 'product-1';

-- This fails with: violates check constraint "chk_products_stock_nonneg"
UPDATE catalog.products SET stock_quantity = stock_quantity - 10 WHERE slug = 'product-1';

-- After the error, Postgres refuses further commands in this transaction.
ROLLBACK;

-- Check: nothing was saved
SELECT count(*) FROM sales.orders WHERE id = 'demo-order-2';              -- expect 0
SELECT stock_quantity FROM catalog.products WHERE slug = 'product-1';     -- still 4


-- Demo 2b: manual rollback

BEGIN;
UPDATE catalog.products SET stock_quantity = 0 WHERE slug = 'product-1';
SELECT stock_quantity FROM catalog.products WHERE slug = 'product-1';     -- shows 0
ROLLBACK;
SELECT stock_quantity FROM catalog.products WHERE slug = 'product-1';     -- back to 4