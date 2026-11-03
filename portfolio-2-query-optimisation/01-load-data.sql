-- Portfolio 2: synthetic data load
-- Sizes: 1,000 users, 200 stores, 20 categories, 50,000 products,
--        50,000 customers, 200,000 orders, 400,000 order items, 200,000 payments

-- Users (every 10th is an admin, the rest are vendors)
INSERT INTO identity.users (id, full_name, email, password_hash, role)
SELECT gen_random_uuid()::text, 'User ' || g, 'user' || g || '@example.com', 'x',
       CASE WHEN g % 10 = 0 THEN 'admin' ELSE 'vendor' END
FROM generate_series(1, 1000) g;

-- Stores: owned by the first 200 users
INSERT INTO vendor.stores (id, owner_id, name, slug, description, contact_email)
SELECT gen_random_uuid()::text, u.id, 'Store ' || u.rn, 'store-' || u.rn,
       'Demo store', 'store' || u.rn || '@example.com'
FROM (SELECT id, row_number() OVER (ORDER BY id) AS rn
      FROM identity.users LIMIT 200) u;

-- Categories
INSERT INTO catalog.categories (id, name, slug)
SELECT gen_random_uuid()::text, 'Category ' || g, 'category-' || g
FROM generate_series(1, 20) g;

-- Products: spread evenly across stores and categories
WITH s AS (SELECT id, owner_id, row_number() OVER (ORDER BY id) AS rn FROM vendor.stores),
     c AS (SELECT id, row_number() OVER (ORDER BY id) AS rn FROM catalog.categories)
INSERT INTO catalog.products
  (id, store_id, owner_id, category_id, name, slug, description, price, stock_quantity, sku, status)
SELECT gen_random_uuid()::text, s.id, s.owner_id, c.id,
       'Product ' || g, 'product-' || g, 'Demo product ' || g,
       round((random() * 500 + 1)::numeric, 2), (random() * 200)::int,
       'SKU-' || g, 'active'
FROM generate_series(1, 50000) g
JOIN s ON s.rn = (g % 200) + 1
JOIN c ON c.rn = (g % 20) + 1;

-- Customers
INSERT INTO sales.customers (id, full_name, email, phone)
SELECT gen_random_uuid()::text, 'Customer ' || g, 'customer' || g || '@example.com',
       '0801' || lpad(g::text, 7, '0')
FROM generate_series(1, 50000) g;

-- Orders: spread over customers and over the last year, with mixed statuses
WITH cust AS (SELECT id, row_number() OVER (ORDER BY id) AS rn FROM sales.customers)
INSERT INTO sales.orders (id, customer_id, shipping_address, status, created_at, updated_at)
SELECT gen_random_uuid()::text, cust.id, 'Address ' || g,
       (ARRAY['pending','paid','shipped','delivered','cancelled'])[1 + (g % 5)],
       now() - make_interval(days => (random() * 365)::int), now()
FROM generate_series(1, 200000) g
JOIN cust ON cust.rn = (g % 50000) + 1;

-- Order items: two different products per order
WITH o AS (SELECT id, row_number() OVER (ORDER BY id) AS rn FROM sales.orders),
     p AS (SELECT id, price, row_number() OVER (ORDER BY id) AS rn FROM catalog.products)
INSERT INTO sales.order_items (id, order_id, product_id, quantity, unit_price)
SELECT gen_random_uuid()::text, o.id, p.id, 1 + (o.rn % 5), p.price
FROM o
CROSS JOIN generate_series(1, 2) k
JOIN p ON p.rn = ((o.rn * 7 + k * 13) % 50000) + 1;

-- Payments: one per order, amount taken from the order_totals view
INSERT INTO sales.payments (id, order_id, method, reference, amount, status, paid_at)
SELECT gen_random_uuid()::text, t.order_id, 'demo-card',
       'PAY-' || row_number() OVER (), t.total, 'successful', now()
FROM sales.order_totals t;

-- Refresh planner statistics so the plans we measure are accurate
ANALYZE;