
USE WAREHOUSE urbancart_wh;
USE DATABASE urbancart_db;
USE SCHEMA urbancart_db.retail_ops;

CREATE OR REPLACE TABLE customers (
    customer_id   INT,
    customer_name STRING,
    city          STRING,
    email         STRING,
    signup_date   DATE
);
CREATE OR REPLACE TABLE orders (
    order_id     INT,
    customer_id  INT,
    product_name STRING,
    quantity     INT,
    order_amount NUMBER(10,2),
    order_status STRING,
    order_date   DATE
);
CREATE OR REPLACE STAGE urbancart_stage;

