
--  FILE    : 03_eda.sql
--  PURPOSE : Exploratory Data Analysis + Data Cleaning
--  Author  : Yash Dewangan
--  Database: PostgreSQL




--  PART A: DATA QUALITY CHECKS


-- A1. Null audit across all critical columns
SELECT
    COUNT(*)                                          AS total_rows,
    COUNT(*) FILTER (WHERE sale_date IS NULL)         AS null_sale_date,
    COUNT(*) FILTER (WHERE customer_id IS NULL)       AS null_customer_id,
    COUNT(*) FILTER (WHERE gender IS NULL)            AS null_gender,
    COUNT(*) FILTER (WHERE age IS NULL)               AS null_age,
    COUNT(*) FILTER (WHERE category IS NULL)          AS null_category,
    COUNT(*) FILTER (WHERE quantity IS NULL)          AS null_quantity,
    COUNT(*) FILTER (WHERE price_per_unit IS NULL)    AS null_price,
    COUNT(*) FILTER (WHERE cogs IS NULL)              AS null_cogs,
    COUNT(*) FILTER (WHERE total_sale IS NULL)        AS null_total_sale
FROM retail_sales;

-- A2. Delete all records with any NULL in critical columns
DELETE FROM retail_sales
WHERE
    sale_date IS NULL OR sale_time IS NULL OR customer_id IS NULL OR
    gender IS NULL OR age IS NULL OR category IS NULL OR
    quantity IS NULL OR price_per_unit IS NULL OR cogs IS NULL OR total_sale IS NULL;

-- A3. Flag price calculation mismatches (rounding tolerance: $0.50)
SELECT
    transactions_id,
    total_sale,
    quantity * price_per_unit AS expected_total,
    ABS(total_sale - (quantity * price_per_unit)) AS discrepancy
FROM retail_sales
WHERE ABS(total_sale - (quantity * price_per_unit)) > 0.50
ORDER BY discrepancy DESC;

-- A4. Flag invalid quantities
SELECT * FROM retail_sales
WHERE quantity <= 0;

-- A5. Flag anomalous customer ages
SELECT * FROM retail_sales
WHERE age < 16 OR age > 100;


--  PART B: DATASET OVERVIEW

-- B1. High-level snapshot
SELECT
    COUNT(*)                                         AS total_transactions,
    COUNT(DISTINCT customer_id)                      AS unique_customers,
    COUNT(DISTINCT category)                         AS product_categories,
    MIN(sale_date)                                   AS earliest_sale,
    MAX(sale_date)                                   AS latest_sale,
    ROUND(AVG(total_sale), 2)                        AS avg_transaction_value,
    ROUND(SUM(total_sale), 2)                        AS total_revenue,
    ROUND(SUM(profit), 2)                            AS total_profit,
    ROUND(AVG(profit / total_sale) * 100, 2)         AS avg_profit_margin_pct
FROM retail_sales;

-- B2. Distinct categories
SELECT DISTINCT category FROM retail_sales ORDER BY category;

-- B3. Distinct genders
SELECT DISTINCT gender FROM retail_sales;

-- B4. Age distribution summary
SELECT
    MIN(age)               AS min_age,
    MAX(age)               AS max_age,
    ROUND(AVG(age), 1)     AS avg_age,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY age) AS median_age
FROM retail_sales;


--  PART C: CATEGORY & DEMOGRAPHIC BREAKDOWN

-- C1. Revenue and profitability by category
SELECT
    category,
    COUNT(*)                                                          AS total_orders,
    SUM(quantity)                                                     AS units_sold,
    ROUND(SUM(total_sale), 2)                                         AS revenue,
    ROUND(SUM(profit), 2)                                             AS total_profit,
    ROUND(AVG(profit / total_sale) * 100, 2)                          AS profit_margin_pct,
    ROUND(SUM(total_sale) * 100.0 / SUM(SUM(total_sale)) OVER (), 2) AS revenue_share_pct
FROM retail_sales
GROUP BY category
ORDER BY revenue DESC;

-- C2. Orders by gender
SELECT
    gender,
    COUNT(*)                     AS total_orders,
    ROUND(SUM(total_sale), 2)    AS total_revenue,
    ROUND(AVG(total_sale), 2)    AS avg_order_value
FROM retail_sales
GROUP BY gender
ORDER BY total_revenue DESC;

-- C3. Customer demographics: age group x gender
SELECT
    CASE
        WHEN age BETWEEN 16 AND 24 THEN '16-24 (Gen Z)'
        WHEN age BETWEEN 25 AND 40 THEN '25-40 (Millennial)'
        WHEN age BETWEEN 41 AND 56 THEN '41-56 (Gen X)'
        ELSE '57+ (Boomer+)'
    END                          AS age_group,
    gender,
    COUNT(*)                     AS orders,
    ROUND(AVG(total_sale), 2)    AS avg_order_value,
    ROUND(SUM(total_sale), 2)    AS total_spend
FROM retail_sales
GROUP BY age_group, gender
ORDER BY total_spend DESC;

-- C4. Sales volume by day of week
SELECT
    TO_CHAR(sale_date, 'Day')    AS day_of_week,
    EXTRACT(DOW FROM sale_date)  AS dow_num,
    COUNT(*)                     AS total_orders,
    ROUND(SUM(total_sale), 2)    AS total_revenue
FROM retail_sales
GROUP BY day_of_week, dow_num
ORDER BY dow_num;
