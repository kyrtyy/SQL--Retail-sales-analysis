-- ============================================================
--  FILE    : 02_load_data.sql
--  PURPOSE : Load data into retail_sales + post-load validation
--  Author  : Yash Dewangan
--  Database: PostgreSQL
-- ============================================================


-- ----------------------------------------------------------------
--  OPTION A: Load from CSV file
--  Place your CSV in the same directory and update the path below
-- ----------------------------------------------------------------

COPY retail_sales (
    transactions_id,
    sale_date,
    sale_time,
    customer_id,
    gender,
    age,
    category,
    quantity,
    price_per_unit,
    cogs,
    total_sale
)
FROM '/path/to/retail_sales.csv'
DELIMITER ','
CSV HEADER;


-- ----------------------------------------------------------------
--  OPTION B: Manual sample inserts (for testing schema only)
-- ----------------------------------------------------------------

-- INSERT INTO retail_sales (transactions_id, sale_date, sale_time, customer_id, gender, age, category, quantity, price_per_unit, cogs, total_sale)
-- VALUES
--     (1, '2022-01-05', '08:15:00', 101, 'Male',   28, 'Electronics', 2, 499.99, 800.00, 999.98),
--     (2, '2022-01-06', '14:30:00', 102, 'Female', 34, 'Beauty',      1, 120.00, 80.00,  120.00),
--     (3, '2022-01-07', '19:45:00', 103, 'Male',   45, 'Clothing',    3, 89.99,  180.00, 269.97);


-- ----------------------------------------------------------------
--  POST-LOAD VALIDATION
-- ----------------------------------------------------------------

-- Check total rows loaded
SELECT COUNT(*) AS total_rows_loaded FROM retail_sales;

-- Preview first 10 rows
SELECT * FROM retail_sales LIMIT 10;

-- Confirm profit computed column is working
SELECT transactions_id, total_sale, cogs, profit FROM retail_sales LIMIT 5;
