# UrbanCart — Snowflake Retail Operations Project

A hands-on Snowflake project that demonstrates warehouse, database, and schema creation; table and stage setup; basic SQL data manipulation; SnowSQL file loading; Time Travel; and data recovery.

## Project Overview

**UrbanCart** is a small retail analytics data platform built in Snowflake. The project uses customer and order data to demonstrate core data-warehouse operations and Snowflake-specific features.

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
UrbanCart-Snowflake-Project/
│
├── README.md
├── T1.sql
├── T2.sql
├── T3.sql
├── T4.sql
├── T5.sql
├── customers_data.csv
│
└── screenshots/
    ├── 01_warehouse_database_schema.png
    ├── 02_tables_and_stage.png
    ├── 03_sample_data_crud.png
    ├── 04_time_travel.png
    └── 05_time_travel_recovery.png
```

> The screenshot files are named according to the order in which the project was completed. If you keep them in the same folder as this README, update the image paths below accordingly.

## Prerequisites

1. A Snowflake account with permission to create warehouses, databases, schemas, tables, and stages.
2. Snowsight access.
3. SnowSQL installed and configured for the Snowflake account.
4. A local CSV file named `customers_data.csv`.

## Step 1 — Warehouse, Database, and Schema

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
USE SCHEMA retail_ops;
```

### Verification

The active context in Snowsight should show:

- Warehouse: `URBANCART_WH`
- Database: `URBANCART_DB`
- Schema: `RETAIL_OPS`

### Evidence

![Warehouse, database, and schema setup](01_warehouse_database_schema.png)

*Figure 1: Successful creation and selection of the UrbanCart warehouse, database, and schema in Snowsight.*

## Step 2 — Tables and Internal Stage

Two tables are created:

- `customers`: master customer information.
- `orders`: transactional order information.

An internal stage named `urbancart_stage` is also created for file loading.

```sql
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

![Tables and stage creation](02_tables_and_stage.png)

*Figure 2: Table definitions and successful creation of the internal stage.*

## Step 3 — Sample Data and Basic DML

Sample customer and order records are inserted into the tables. The project demonstrates the four basic data manipulation operations:

| Operation | Example |
|---|---|
| `SELECT` | View orders sorted by `order_id` |
| `INSERT` | Add order `5006` |
| `UPDATE` | Change order `5001` to `Shipped` |
| `DELETE` | Remove cancelled order `5005` |

Example commands:

```sql
SELECT * FROM orders ORDER BY order_id;

INSERT INTO orders VALUES
    (5006, 102, 'Desk Lamp', 1, 749.00, 'Placed', '2024-03-06');

UPDATE orders
SET order_status = 'Shipped'
WHERE order_id = 5001;

DELETE FROM orders
WHERE order_id = 5005;

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

![Sample data and CRUD operations](03_sample_data_crud.png)

*Figure 3: Sample order data after insert, update, and delete operations.*

## Step 4 — CSV Data Loading Using SnowSQL

The customer table is expanded by loading a local CSV file through SnowSQL.

### CSV File

Create a file named `customers_data.csv`:

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
USE SCHEMA retail_ops;

PUT file:///full/path/to/customers_data.csv
    @urbancart_stage
    AUTO_COMPRESS=TRUE;

LIST @urbancart_stage;

COPY INTO customers
  FROM @urbancart_stage/customers_data.csv.gz
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

The `customers` table contains six records in total: the original two customers plus the four CSV-loaded customers. The copy history should show the load as successful and report four loaded rows.

> Capture the SnowSQL `PUT`/`COPY` output and the final customer query as evidence for the data-loading section.

## Step 5 — Snowflake Time Travel

Time Travel allows historical versions of table data to be queried within the account's retention period.

First, modify the current order data:

```sql
SELECT * FROM orders ORDER BY order_id;

UPDATE orders
SET order_status = 'Delivered'
WHERE order_id = 5002;

DELETE FROM orders
WHERE order_id = 5004;

SELECT * FROM orders ORDER BY order_id;
```

Then query the table as it existed approximately five minutes earlier:

```sql
SELECT *
FROM orders AT (OFFSET => -60*5)
ORDER BY order_id;
```

### Expected Result

The historical query should show:

- Order `5002` with status `Shipped` rather than `Delivered`.
- Order `5004` still present.

If five minutes have not passed, use a smaller offset or capture a timestamp before making the changes:

```sql
SELECT CURRENT_TIMESTAMP();
```

Then query using:

```sql
SELECT *
FROM orders AT (TIMESTAMP => '<captured_timestamp>')
ORDER BY order_id;
```

### Evidence

![Time Travel query](04_time_travel.png)

*Figure 4: Current order data and historical data queried using Snowflake Time Travel.*

## Step 6 — Data Recovery Using Time Travel

This step simulates an accidental cleanup that deletes all orders with status `Placed`, then restores them from a historical table version.

### Simulate the Accident

```sql
SELECT * FROM orders ORDER BY order_id;

DELETE FROM orders
WHERE order_status = 'Placed';

SELECT * FROM orders ORDER BY order_id;
```

### Recover the Deleted Records

```sql
INSERT INTO orders
SELECT *
FROM orders AT (OFFSET => -60*5)
WHERE order_status = 'Placed';
```

### Confirm Recovery

```sql
SELECT * FROM orders ORDER BY order_id;
```

The recovered records should match the `Placed` orders from the baseline state.

### Optional Table Recovery

If the entire table is accidentally dropped, Snowflake can restore it using:

```sql
DROP TABLE orders;
UNDROP TABLE orders;
```

### Evidence

![Time Travel data recovery](05_time_travel_recovery.png)

*Figure 5: Recovery workflow using historical order data.*

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

## Conclusion

The UrbanCart project demonstrates a complete beginner-level Snowflake workflow, from environment setup and table creation to data ingestion, DML operations, historical querying, and recovery. It combines Snowsight and SnowSQL to show both graphical and command-line approaches to working with Snowflake.

## Author

**Abhyudaya Mishra**
