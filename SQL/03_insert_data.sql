
USE WAREHOUSE urbancart_wh;
USE DATABASE urbancart_db;
USE SCHEMA urbancart_db.retail_ops;
INSERT INTO customers VALUES
    (101, 'Ananya Rao',    'Chennai',   'ananya@mail.com', '2024-01-05'),
    (102, 'Rahul Mehta',   'Mumbai',    'rahul@mail.com',  '2024-02-10');
INSERT INTO orders VALUES
    (5001, 101, 'Wireless Mouse',    2, 899.00,  'Placed',   '2024-03-01'),
    (5002, 102, 'Mechanical Keyboard',1, 3499.00, 'Placed',   '2024-03-02'),
    (5003, 101, 'USB-C Hub',         1, 1299.00, 'Shipped',  '2024-03-03'),
    (5004, 102, 'Laptop Stand',      1, 1599.00, 'Placed',   '2024-03-04'),
    (5005, 101, 'Webcam',            1, 2199.00, 'Cancelled','2024-03-05');
SELECT * FROM orders ORDER BY order_id;
INSERT INTO orders VALUES (5006, 102, 'Desk Lamp', 1, 749.00, 'Placed', '2024-03-06');
UPDATE orders SET order_status = 'Shipped' WHERE order_id = 5001;
DELETE FROM orders WHERE order_id = 5005;
SELECT * FROM orders ORDER BY order_id;