USE WAREHOUSE urbancart_wh;
USE DATABASE urbancart_db;
USE SCHEMA urbancart_db.retail_ops;

-- current state
SELECT * FROM orders ORDER BY order_id;

-- an order gets updated and one gets cancelled/deleted
UPDATE orders SET order_status = 'Delivered' WHERE order_id = 5002;
DELETE FROM orders WHERE order_id = 5004;

-- current state now differs
SELECT * FROM orders ORDER BY order_id;

-- query the table as it looked ~5 minutes ago, before these two changes
SELECT * FROM orders AT (OFFSET => -60*5) ORDER BY order_id;