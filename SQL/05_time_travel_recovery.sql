USE WAREHOUSE urbancart_wh;
USE DATABASE urbancart_db;
USE SCHEMA urbancart_db.retail_ops;
-- baseline
SELECT * FROM orders ORDER BY order_id;

-- the "accident"
DELETE FROM orders WHERE order_status = 'Placed';

-- confirm the damage
SELECT * FROM orders ORDER BY order_id;   -- Placed rows are gone

-- recover using Time Travel — pull back rows that existed 5 min ago but are missing now
INSERT INTO orders
SELECT * FROM orders AT (OFFSET => -60*5)
WHERE order_status = 'Placed';

-- confirm recovery
SELECT * FROM orders ORDER BY order_id;