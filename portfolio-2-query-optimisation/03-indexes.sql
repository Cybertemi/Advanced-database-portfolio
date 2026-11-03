-- Portfolio 2: indexes added after the baseline measurements

-- Q1: trigram index for "contains" searches on product names
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE INDEX ix_products_name_trgm ON catalog.products USING gin (name gin_trgm_ops);

-- Q2: composite index for category browsing sorted by price
CREATE INDEX ix_products_category_price ON catalog.products (category_id, price);

-- Q3: composite index for recent orders by status
CREATE INDEX ix_orders_status_created ON sales.orders (status, created_at);

-- Q5: index for highest-value payments
CREATE INDEX ix_payments_amount ON sales.payments (amount);

-- Q4: covering index so order dates can be read from the index
CREATE INDEX ix_orders_id_created ON sales.orders (id) INCLUDE (created_at);

-- Refresh statistics and visibility information for the planner
VACUUM ANALYZE;