-- ============================================================
--  FILE    : 01_schema.sql
--  PURPOSE : Database and table creation
--  Author  : Yash Dewangan
--  Database: PostgreSQL
-- ============================================================


-- Create the database (run this separately before connecting)
-- CREATE DATABASE retail_analytics_db;

-- Drop table if re-running setup
DROP TABLE IF EXISTS retail_sales;

CREATE TABLE retail_sales (
    transactions_id   INT            PRIMARY KEY,
    sale_date         DATE           NOT NULL,
    sale_time         TIME           NOT NULL,
    customer_id       INT            NOT NULL,
    gender            VARCHAR(10),
    age               INT,
    category          VARCHAR(35),
    quantity          INT,
    price_per_unit    NUMERIC(10,2),
    cogs              NUMERIC(10,2),
    total_sale        NUMERIC(10,2),
    -- Computed column: avoids repeating (total_sale - cogs) in every query
    profit            NUMERIC(10,2)  GENERATED ALWAYS AS (total_sale - cogs) STORED
);