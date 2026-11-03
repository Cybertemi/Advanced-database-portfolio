-- Q1: Product search by name (customer searching the catalogue)
SELECT id, name, price
FROM catalog.products
WHERE name ILIKE '%product 4567%';

-- Q2: Browse a category, filtered by price and sorted (catalogue page)
SELECT p.id, p.name, p.price
FROM catalog.products p
JOIN catalog.categories c ON c.id = p.category_id
WHERE c.slug = 'category-5' AND p.price BETWEEN 100 AND 300
ORDER BY p.price
LIMIT 20;

-- Q3: Recent paid orders (admin dashboard)
SELECT id, customer_id, created_at
FROM sales.orders
WHERE status = 'paid' AND created_at >= now() - interval '7 days'
ORDER BY created_at DESC;

-- Q4: Vendor sales report (multi-table join and aggregation)
SELECT s.name,
       SUM(oi.quantity * oi.unit_price) AS revenue,
       COUNT(DISTINCT o.id) AS orders
FROM vendor.stores s
JOIN catalog.products p ON p.store_id = s.id
JOIN sales.order_items oi ON oi.product_id = p.id
JOIN sales.orders o ON o.id = oi.order_id
WHERE s.slug = 'store-10' AND o.created_at >= now() - interval '90 days'
GROUP BY s.name;

-- Q5: Highest-value payments (admin audit)
SELECT id, order_id, amount
FROM sales.payments
WHERE amount > 3000
ORDER BY amount DESC
LIMIT 20;