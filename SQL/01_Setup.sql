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


