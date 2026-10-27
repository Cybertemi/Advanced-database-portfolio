-- Portfolio 3: setup
-- Give "Product 1" a known stock level so the demos are predictable.

UPDATE catalog.products SET stock_quantity = 5 WHERE slug = 'product-1';

SELECT name, price, stock_quantity FROM catalog.products WHERE slug = 'product-1';