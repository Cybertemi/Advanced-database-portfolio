-- Portfolio 3, Demo 1: a successful order (COMMIT)
-- All five steps of placing an order succeed or fail together.

BEGIN;

INSERT INTO sales.orders (id, customer_id, shipping_address, status)
SELECT 'demo-order-1', id, 'Ibadan', 'paid'
FROM sales.customers WHERE email = 'customer1@example.com';

INSERT INTO sales.order_items (id, order_id, product_id, quantity, unit_price)
SELECT 'demo-item-1', 'demo-order-1', id, 1, price
FROM catalog.products WHERE slug = 'product-1';

INSERT INTO sales.payments (id, order_id, method, reference, amount, status, paid_at)
SELECT 'demo-pay-1', 'demo-order-1', 'demo-card', 'DEMO-PAY-1', price, 'successful', now()
FROM catalog.products WHERE slug = 'product-1';

UPDATE catalog.products SET stock_quantity = stock_quantity - 1 WHERE slug = 'product-1';

INSERT INTO sales.inventory_movements (id, product_id, order_id, change_quantity, reason)
SELECT 'demo-mov-1', id, 'demo-order-1', -1, 'sale'
FROM catalog.products WHERE slug = 'product-1';

COMMIT;

-- Check: the order exists and stock went from 5 to 4
SELECT id, status FROM sales.orders WHERE id = 'demo-order-1';
SELECT stock_quantity FROM catalog.products WHERE slug = 'product-1';