# UrbanCart — Snowflake Retail Operations Project

A hands-on Snowflake project that demonstrates warehouse, database, and schema creation; table and stage setup; basic SQL data manipulation; SnowSQL file loading; Time Travel; and data recovery.

## Project Overview

**UrbanCart** is a retail analytics data platform built in Snowflake. The project uses customer and order data to demonstrate core data-warehouse operations and Snowflake-specific features.

### Objectives

- Create and configure a Snowflake warehouse.
- Create a database and schema.
- Create customer and order tables.
- Create an internal stage for file ingestion.
- Perform `SELECT`, `INSERT`, `UPDATE`, and `DELETE` operations.
- Load CSV data using SnowSQL.
- Verify ingestion using `COPY_HISTORY`.
- Query historical table states using Time Travel.
- Recover accidentally deleted records using Time Travel.

## Technologies Used

- Snowflake
- Snowsight Worksheets
- SnowSQL
- SQL
- CSV
- Snowflake Time Travel

## Project Structure

```text
UrbanCart_Snowflake_SQL/
├── Csv/
│   └── customer_data.csv
├── Output Images/
│   ├── 01_project_setup.png
│   ├── 02_table_and_stage_creation.png
│   ├── 03_crud_operations.png
│   ├── 04_time_travel.png
│   └── 05_data_recovery.png
├── SQL/
│   ├── 01_Setup.sql
│   ├── 02_Create_Tables.sql
│   ├── 03_insert_data.sql
│   ├── 04_dml_operations.sql
│   └── 05_time_travel_recovery.sql
└── README.md
```

## Prerequisites

1. A Snowflake account with permission to create warehouses, databases, schemas, tables, and stages.
2. Snowsight access.
3. SnowSQL installed and configured for the Snowflake account.
4. The local CSV file `customer_data.csv` (located in the [`Csv/`](Csv/customer_data.csv) folder).

---

## Step 1 — Warehouse, Database, and Schema

**Script:** [`SQL/01_Setup.sql`](SQL/01_Setup.sql)

The first step creates the Snowflake compute warehouse and the logical database objects.

```sql
CREATE WAREHOUSE IF NOT EXISTS urbancart_wh
  WAREHOUSE_SIZE      = 'XSMALL'
  AUTO_SUSPEND         = 60
  AUTO_RESUME          = TRUE
  INITIALLY_SUSPENDED  = TRUE;

CREATE DATABASE IF NOT EXISTS urbancart_db;
CREATE SCHEMA IF NOT EXISTS urbancart_db.retail_ops;

USE WAREHOUSE urbancart_wh;
USE DATABASE urbancart_db;
USE SCHEMA urbancart_db.retail_ops;
```

### Verification

The active context in Snowsight should show:

- Warehouse: `URBANCART_WH`
- Database: `URBANCART_DB`
- Schema: `RETAIL_OPS`

### Evidence

![Warehouse, database, and schema setup](Output%20Images/01_project_setup.png)

*Figure 1: Successful creation and selection of the UrbanCart warehouse, database, and schema in Snowsight.*

---

## Step 2 — Tables and Internal Stage

**Script:** [`SQL/02_Create_Tables.sql`](SQL/02_Create_Tables.sql)

Two tables are created:

- `customers`: master customer information.
- `orders`: transactional order information.

An internal stage named `urbancart_stage` is also created for file loading.

```sql
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
```

### Verification

```sql
SHOW TABLES;
SHOW STAGES;
```

### Evidence

![Tables and stage creation](Output%20Images/02_table_and_stage_creation.png)

*Figure 2: Table definitions and successful creation of the internal stage.*

---

## Step 3 — Sample Data and Basic DML

**Script:** [`SQL/03_insert_data.sql`](SQL/03_insert_data.sql)

Sample customer and order records are inserted into the tables. The project demonstrates the four basic data manipulation operations:

| Operation | Example |
|---|---|
| `SELECT` | View orders sorted by `order_id` |
| `INSERT` | Add order `5006` |
| `UPDATE` | Change order `5001` to `Shipped` |
| `DELETE` | Remove cancelled order `5005` |

Example commands:

```sql
USE WAREHOUSE urbancart_wh;
USE DATABASE urbancart_db;
USE SCHEMA urbancart_db.retail_ops;

-- Initial seed data
INSERT INTO customers VALUES
    (101, 'Ananya Rao',    'Chennai',   'ananya@mail.com', '2024-01-05'),
    (102, 'Rahul Mehta',   'Mumbai',    'rahul@mail.com',  '2024-02-10');

INSERT INTO orders VALUES
    (5001, 101, 'Wireless Mouse',     2,  899.00, 'Placed',    '2024-03-01'),
    (5002, 102, 'Mechanical Keyboard', 1, 3499.00, 'Placed',    '2024-03-02'),
    (5003, 101, 'USB-C Hub',          1, 1299.00, 'Shipped',   '2024-03-03'),
    (5004, 102, 'Laptop Stand',       1, 1599.00, 'Placed',    '2024-03-04'),
    (5005, 101, 'Webcam',             1, 2199.00, 'Cancelled', '2024-03-05');

SELECT * FROM orders ORDER BY order_id;

-- CRUD modifications
INSERT INTO orders VALUES (5006, 102, 'Desk Lamp', 1, 749.00, 'Placed', '2024-03-06');
UPDATE orders SET order_status = 'Shipped' WHERE order_id = 5001;
DELETE FROM orders WHERE order_id = 5005;

SELECT * FROM orders ORDER BY order_id;
```

### Expected Result

The final order table contains five records:

- `5001`
- `5002`
- `5003`
- `5004`
- `5006`

Order `5001` has status `Shipped`, and order `5005` has been deleted.

### Evidence

![Sample data and CRUD operations](Output%20Images/03_crud_operations.png)

*Figure 3: Sample order data after insert, update, and delete operations.*

---

## Step 4 — CSV Data Loading Using SnowSQL

The customer table is expanded by loading a local CSV file through SnowSQL.

### CSV Dataset

The dataset is located at [`Csv/customer_data.csv`](Csv/customer_data.csv):

```csv
customer_id,customer_name,city,email,signup_date
103,Priya Nair,Bengaluru,priya@mail.com,2024-02-15
104,Karthik Iyer,Hyderabad,karthik@mail.com,2024-02-20
105,Sneha Kulkarni,Pune,sneha@mail.com,2024-03-01
106,Devansh Patel,Delhi,devansh@mail.com,2024-03-05
```

### Connect to Snowflake

Run this command in a terminal:

```bash
snowsql -a <account_identifier> -u <username>
```

### Upload and Load the File

Inside the SnowSQL session:

```sql
USE WAREHOUSE urbancart_wh;
USE DATABASE urbancart_db;
USE SCHEMA urbancart_db.retail_ops;

-- Stage the local file
PUT file:///full/path/to/UrbanCart_Snowflake_SQL/Csv/customer_data.csv
    @urbancart_stage
    AUTO_COMPRESS=TRUE;

LIST @urbancart_stage;

-- Load data from stage into customers table
COPY INTO customers
  FROM @urbancart_stage/customer_data.csv.gz
  FILE_FORMAT = (
      TYPE = CSV
      FIELD_DELIMITER = ','
      SKIP_HEADER = 1
  )
  ON_ERROR = 'ABORT_STATEMENT';
```

### Verification

```sql
SELECT *
FROM customers
ORDER BY customer_id;

SELECT *
FROM TABLE(
    INFORMATION_SCHEMA.COPY_HISTORY(
        TABLE_NAME => 'CUSTOMERS',
        START_TIME => DATEADD(HOURS, -1, CURRENT_TIMESTAMP())
    )
);
```

### Expected Result

The `customers` table contains six records in total: the original two customers plus the four CSV-loaded customers. The copy history confirms the load was successful with four loaded rows.

---

## Step 5 — Snowflake Time Travel

**Script:** [`SQL/04_dml_operations.sql`](SQL/04_dml_operations.sql)

Time Travel allows historical versions of table data to be queried within the account's retention period.

First, modify the current order data:

```sql
USE WAREHOUSE urbancart_wh;
USE DATABASE urbancart_db;
USE SCHEMA urbancart_db.retail_ops;

-- Current state
SELECT * FROM orders ORDER BY order_id;

-- Modify state: update and delete
UPDATE orders SET order_status = 'Delivered' WHERE order_id = 5002;
DELETE FROM orders WHERE order_id = 5004;

-- Current state now differs
SELECT * FROM orders ORDER BY order_id;
```

Then query the table as it existed approximately five minutes earlier:

```sql
-- Query table state ~5 minutes ago before the changes
SELECT * FROM orders AT (OFFSET => -60*5) ORDER BY order_id;
```

### Expected Result

The historical query shows:

- Order `5002` with status `Placed` / `Shipped` rather than `Delivered`.
- Order `5004` still present.

If five minutes have not passed, use a smaller offset or capture a timestamp before making the changes:

```sql
SELECT CURRENT_TIMESTAMP();

SELECT *
FROM orders AT (TIMESTAMP => '<captured_timestamp>')
ORDER BY order_id;
```

### Evidence

![Time Travel query](Output%20Images/04_time_travel.png)

*Figure 4: Current order data and historical data queried using Snowflake Time Travel.*

---

## Step 6 — Data Recovery Using Time Travel

**Script:** [`SQL/05_time_travel_recovery.sql`](SQL/05_time_travel_recovery.sql)

This step simulates an accidental cleanup that deletes all orders with status `Placed`, then restores them from a historical table version.

### Simulate the Accident

```sql
USE WAREHOUSE urbancart_wh;
USE DATABASE urbancart_db;
USE SCHEMA urbancart_db.retail_ops;

-- Baseline state
SELECT * FROM orders ORDER BY order_id;

-- Accidental deletion
DELETE FROM orders WHERE order_status = 'Placed';

-- Confirm the damage (Placed rows are gone)
SELECT * FROM orders ORDER BY order_id;
```

### Recover the Deleted Records

```sql
-- Recover using Time Travel: pull back rows that existed 5 min ago but are missing now
INSERT INTO orders
SELECT * FROM orders AT (OFFSET => -60*5)
WHERE order_status = 'Placed';
```

### Confirm Recovery

```sql
-- Confirm recovery: Placed rows restored
SELECT * FROM orders ORDER BY order_id;
```

The recovered records match the `Placed` orders from the baseline state.

### Optional Table Recovery

If an entire table is accidentally dropped, Snowflake can restore it immediately using `UNDROP`:

```sql
DROP TABLE orders;
UNDROP TABLE orders;
```

### Evidence

![Time Travel data recovery](Output%20Images/05_data_recovery.png)

*Figure 5: Recovery workflow using historical order data.*

---

## Key Snowflake Concepts Demonstrated

### Warehouse
A warehouse provides compute resources for executing SQL statements and data-processing operations.

### Database and Schema
A database organizes data objects, while a schema groups related tables, stages, views, and other objects within a database.

### Internal Stage
An internal stage temporarily stores files before they are loaded into Snowflake tables.

### SnowSQL
SnowSQL is Snowflake's command-line client. In this project, it is used to upload the CSV file with `PUT` and load it into the table with `COPY INTO`.

### Time Travel
Time Travel provides access to historical data so that users can investigate changes and recover accidentally modified or deleted records.

---

## Author

**Abhyudaya Mishra**
