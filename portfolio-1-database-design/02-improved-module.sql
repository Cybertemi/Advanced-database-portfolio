-- Portfolio 1: improved order module for Netiks Store
-- Runs after 01-existing-schema.sql

CREATE SCHEMA IF NOT EXISTS sales;

-- Safety rules on the existing products table (portfolio copy only)
ALTER TABLE catalog.products
  ADD CONSTRAINT chk_products_price_nonneg CHECK (price >= 0),
  ADD CONSTRAINT chk_products_stock_nonneg CHECK (stock_quantity >= 0);

-- Buyers, stored once. user_id is optional to allow guest checkout.
CREATE TABLE sales.customers (
  id         varchar(36) PRIMARY KEY DEFAULT gen_random_uuid()::text,
  user_id    varchar(36) REFERENCES identity.users(id) ON DELETE SET NULL,
  full_name  varchar(120) NOT NULL,
  email      varchar(255) NOT NULL UNIQUE,
  phone      varchar(40),
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Order header only: who, where, what state
CREATE TABLE sales.orders (
  id               varchar(36) PRIMARY KEY DEFAULT gen_random_uuid()::text,
  customer_id      varchar(36) NOT NULL REFERENCES sales.customers(id) ON DELETE RESTRICT,
  shipping_address text NOT NULL,
  status           varchar(20) NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending','paid','shipped','delivered','cancelled')),
  created_at       timestamptz NOT NULL DEFAULT now(),
  updated_at       timestamptz NOT NULL DEFAULT now()
);

-- One row per product in an order
CREATE TABLE sales.order_items (
  id         varchar(36) PRIMARY KEY DEFAULT gen_random_uuid()::text,
  order_id   varchar(36) NOT NULL REFERENCES sales.orders(id) ON DELETE CASCADE,
  product_id varchar(36) NOT NULL REFERENCES catalog.products(id) ON DELETE RESTRICT,
  quantity   integer NOT NULL CHECK (quantity > 0),
  unit_price numeric(10,2) NOT NULL CHECK (unit_price >= 0),  -- price at purchase time
  UNIQUE (order_id, product_id)
);

-- Payment attempts for an order
CREATE TABLE sales.payments (
  id         varchar(36) PRIMARY KEY DEFAULT gen_random_uuid()::text,
  order_id   varchar(36) NOT NULL REFERENCES sales.orders(id) ON DELETE RESTRICT,
  method     varchar(40) NOT NULL DEFAULT 'demo-card',
  reference  varchar(80) NOT NULL UNIQUE,
  amount     numeric(10,2) NOT NULL CHECK (amount >= 0),
  status     varchar(20) NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending','successful','failed','refunded')),
  paid_at    timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Stock ledger: every stock change is recorded with a reason
CREATE TABLE sales.inventory_movements (
  id              varchar(36) PRIMARY KEY DEFAULT gen_random_uuid()::text,
  product_id      varchar(36) NOT NULL REFERENCES catalog.products(id) ON DELETE RESTRICT,
  order_id        varchar(36) REFERENCES sales.orders(id) ON DELETE SET NULL,
  change_quantity integer NOT NULL CHECK (change_quantity <> 0),
  reason          varchar(20) NOT NULL
    CHECK (reason IN ('restock','sale','cancellation','adjustment')),
  created_at      timestamptz NOT NULL DEFAULT now()
);

-- Order totals are calculated, not stored
CREATE VIEW sales.order_totals AS
SELECT o.id AS order_id, SUM(oi.quantity * oi.unit_price) AS total
FROM sales.orders o
JOIN sales.order_items oi ON oi.order_id = o.id
GROUP BY o.id;

-- Foreign-key indexes only (more are left for Portfolio 2 to justify)
CREATE INDEX ix_sales_orders_customer_id ON sales.orders(customer_id);
CREATE INDEX ix_sales_order_items_product_id ON sales.order_items(product_id);
CREATE INDEX ix_sales_payments_order_id ON sales.payments(order_id);
CREATE INDEX ix_sales_inventory_product_id ON sales.inventory_movements(product_id);