# Retail Sales Analysis

## Overview

| Detail | Info |
|---|---|
| **Author** | Yash dewangan |
| **Database** | `retail_analytics_db` |
| **Tools Used** | PostgreSQL, SQL (CTEs, Window Functions, Subqueries) |

---

## Project Summary

This project showcases end-to-end SQL data analysis on a retail transactional dataset. It covers database design, data quality checks, exploratory analysis, and 15+ business driven SQL queries including advanced techniques like **window functions**, **CTEs**, **rolling aggregations**, and **customer segmentation (RFM analysis)**.

My goal is to extract actionable insights from raw sales data that can drive real business decisions around inventory, marketing, and customer retention.

---

## Objectives

1. Design and populate a normalized retail sales database
2. Perform data validation and quality assurance
3. Conduct exploratory data analysis (EDA)
4. Answer advanced business questions using SQL
5. Build customer segmentation using RFM scoring
6. Optimize query performance with indexing

---

## Dataset Schema

```sql
CREATE DATABASE retail_analytics_db;

CREATE TABLE retail_sales (
    transactions_id   INT PRIMARY KEY,
    sale_date         DATE          NOT NULL,
    sale_time         TIME          NOT NULL,
    customer_id       INT           NOT NULL,
    gender            VARCHAR(10),
    age               INT,
    category          VARCHAR(35),
    quantity          INT,
    price_per_unit    NUMERIC(10,2),
    cogs              NUMERIC(10,2),
    total_sale        NUMERIC(10,2),
    -- Derived profit column
    profit            NUMERIC(10,2) GENERATED ALWAYS AS (total_sale - cogs) STORED
);
```

> **Note:** I added a `profit`computed column so downstream queries don't need to repeat `total_sale - cogs` everywhere, this keeps queries clean and avoids calculation errors.

---

## Phase 1: Data Quality & Cleaning

### 1.1  Null Value Audit

```sql
-- Identify all rows with any NULL in critical columns
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
```

### 1.2  Remove Incomplete Records

```sql
DELETE FROM retail_sales
WHERE
    sale_date IS NULL OR sale_time IS NULL OR customer_id IS NULL OR
    gender IS NULL OR age IS NULL OR category IS NULL OR
    quantity IS NULL OR price_per_unit IS NULL OR cogs IS NULL OR total_sale IS NULL;
```

### 1.3   Sanity Checks (Business Logic Validation)

```sql
-- Flag transactions where total_sale doesn't match quantity * price_per_unit (within rounding)
SELECT transactions_id, total_sale, quantity * price_per_unit AS expected_total
FROM retail_sales
WHERE ABS(total_sale - (quantity * price_per_unit)) > 0.50;

-- Flag negative or zero quantities
SELECT * FROM retail_sales WHERE quantity <= 0;

-- Flag anomalous ages (outside realistic range)
SELECT * FROM retail_sales WHERE age < 16 OR age > 100;
```

> **Reason:** Raw data often has silent errors. These checks catch business logic violations that a simple NULL check misses.

---

## Phase 2: Exploratory Data Analysis

### 2.1  Dataset Snapshot

```sql
SELECT
    COUNT(*)                            AS total_transactions,
    COUNT(DISTINCT customer_id)         AS unique_customers,
    COUNT(DISTINCT category)            AS product_categories,
    MIN(sale_date)                      AS earliest_sale,
    MAX(sale_date)                      AS latest_sale,
    ROUND(AVG(total_sale), 2)           AS avg_transaction_value,
    SUM(total_sale)                     AS total_revenue,
    SUM(profit)                         AS total_profit,
    ROUND(AVG(profit / total_sale) * 100, 2) AS avg_profit_margin_pct
FROM retail_sales;
```

### 2.2  Category Breakdown

```sql
SELECT
    category,
    COUNT(*)                                     AS total_orders,
    SUM(quantity)                                AS units_sold,
    ROUND(SUM(total_sale), 2)                    AS revenue,
    ROUND(SUM(profit), 2)                        AS total_profit,
    ROUND(AVG(profit / total_sale) * 100, 2)     AS profit_margin_pct,
    ROUND(SUM(total_sale) * 100.0 / SUM(SUM(total_sale)) OVER (), 2) AS revenue_share_pct
FROM retail_sales
GROUP BY category
ORDER BY revenue DESC;
```

### 2.3  Customer Demographics

```sql
SELECT
    CASE
        WHEN age BETWEEN 16 AND 24 THEN '16–24 (Gen Z)'
        WHEN age BETWEEN 25 AND 40 THEN '25–40 (Millennial)'
        WHEN age BETWEEN 41 AND 56 THEN '41–56 (Gen X)'
        ELSE '57+ (Boomer+)'
    END                          AS age_group,
    gender,
    COUNT(*)                     AS orders,
    ROUND(AVG(total_sale), 2)    AS avg_order_value,
    ROUND(SUM(total_sale), 2)    AS total_spend
FROM retail_sales
GROUP BY age_group, gender
ORDER BY total_spend DESC;
```

---

## Phase 3: Business Analysis

### Q1  Sales on a Specific Date

```sql
SELECT *
FROM retail_sales
WHERE sale_date = '2022-11-05'
ORDER BY sale_time;
```

### Q2  High Volume Clothing Sales in November 2022

```sql
SELECT *
FROM retail_sales
WHERE
    category = 'Clothing'
    AND TO_CHAR(sale_date, 'YYYY-MM') = '2022-11'
    AND quantity >= 4
ORDER BY total_sale DESC;
```

### Q3  Revenue & Orders Per Category

```sql
SELECT
    category,
    COUNT(*)                     AS total_orders,
    SUM(total_sale)              AS net_revenue,
    ROUND(AVG(total_sale), 2)    AS avg_order_value
FROM retail_sales
GROUP BY category
ORDER BY net_revenue DESC;
```

### Q4  Average Customer Age by Category

```sql
SELECT
    category,
    ROUND(AVG(age), 1)    AS avg_customer_age,
    MIN(age)              AS youngest,
    MAX(age)              AS oldest
FROM retail_sales
GROUP BY category
ORDER BY avg_customer_age;
```

### Q5  High Value Transactions (> $1,000)

```sql
SELECT
    transactions_id,
    sale_date,
    customer_id,
    category,
    total_sale,
    profit
FROM retail_sales
WHERE total_sale > 1000
ORDER BY total_sale DESC;
```

### Q6  Transactions by Gender per Category

```sql
SELECT
    category,
    gender,
    COUNT(*)                                              AS total_transactions,
    ROUND(SUM(total_sale), 2)                             AS revenue,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY category), 1) AS gender_pct_in_category
FROM retail_sales
GROUP BY category, gender
ORDER BY category, gender;
```

### Q7  Best Selling Month Per Year (Window Function)

```sql
WITH monthly_stats AS (
    SELECT
        EXTRACT(YEAR FROM sale_date)   AS year,
        EXTRACT(MONTH FROM sale_date)  AS month,
        TO_CHAR(sale_date, 'Month')    AS month_name,
        ROUND(AVG(total_sale), 2)      AS avg_sale,
        SUM(total_sale)                AS total_revenue,
        RANK() OVER (
            PARTITION BY EXTRACT(YEAR FROM sale_date)
            ORDER BY AVG(total_sale) DESC
        )                              AS rank
    FROM retail_sales
    GROUP BY 1, 2, 3
)
SELECT year, month_name, avg_sale, total_revenue
FROM monthly_stats
WHERE rank = 1
ORDER BY year;
```

### Q8  Top 5 Customers by Lifetime Value

```sql
SELECT
    customer_id,
    COUNT(*)                         AS total_orders,
    ROUND(SUM(total_sale), 2)        AS lifetime_value,
    ROUND(AVG(total_sale), 2)        AS avg_order_value,
    MIN(sale_date)                   AS first_purchase,
    MAX(sale_date)                   AS last_purchase,
    MAX(sale_date) - MIN(sale_date)  AS customer_tenure_days
FROM retail_sales
GROUP BY customer_id
ORDER BY lifetime_value DESC
LIMIT 5;
```

### Q9  Unique Customers Per Category

```sql
SELECT
    category,
    COUNT(DISTINCT customer_id)    AS unique_customers,
    COUNT(*)                       AS total_orders,
    ROUND(COUNT(*)::NUMERIC / COUNT(DISTINCT customer_id), 2) AS avg_orders_per_customer
FROM retail_sales
GROUP BY category
ORDER BY unique_customers DESC;
```

### Q10  Orders by Shift

```sql
WITH shift_data AS (
    SELECT *,
        CASE
            WHEN EXTRACT(HOUR FROM sale_time) < 12 THEN 'Morning (Before 12pm)'
            WHEN EXTRACT(HOUR FROM sale_time) BETWEEN 12 AND 17 THEN 'Afternoon (12–5pm)'
            ELSE 'Evening (After 5pm)'
        END AS shift
    FROM retail_sales
)
SELECT
    shift,
    COUNT(*)                      AS total_orders,
    ROUND(SUM(total_sale), 2)     AS shift_revenue,
    ROUND(AVG(total_sale), 2)     AS avg_order_value,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_of_orders
FROM shift_data
GROUP BY shift
ORDER BY total_orders DESC;
```

### Q11  30-Day Rolling Revenue

```sql
SELECT
    sale_date,
    SUM(total_sale)                                                  AS daily_revenue,
    ROUND(AVG(SUM(total_sale)) OVER (
        ORDER BY sale_date
        ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
    ), 2)                                                            AS rolling_30d_avg_revenue
FROM retail_sales
GROUP BY sale_date
ORDER BY sale_date;
```

> **Use case:** Identify seasonal dips and spikes where rolling average diverges from daily revenue signals a trend worth investigating.

### Q12  Customer Retention: Repeat vs One-Time Buyers

```sql
WITH purchase_counts AS (
    SELECT customer_id, COUNT(*) AS num_purchases
    FROM retail_sales
    GROUP BY customer_id
)
SELECT
    CASE WHEN num_purchases = 1 THEN 'One-Time Buyer'
         WHEN num_purchases BETWEEN 2 AND 4 THEN 'Occasional Buyer'
         ELSE 'Loyal Customer'
    END                              AS customer_segment,
    COUNT(*)                         AS num_customers,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_of_customers
FROM purchase_counts
GROUP BY customer_segment
ORDER BY num_customers DESC;
```

### Q13  Profit Margin Leaders by Category & Gender

```sql
SELECT
    category,
    gender,
    ROUND(SUM(profit), 2)                            AS total_profit,
    ROUND(AVG(profit / total_sale) * 100, 2)         AS avg_margin_pct,
    RANK() OVER (ORDER BY SUM(profit) DESC)          AS profit_rank
FROM retail_sales
GROUP BY category, gender
ORDER BY total_profit DESC;
```

### Q14  Month-over-Month Revenue Growth

```sql
WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC('month', sale_date)    AS month,
        SUM(total_sale)                   AS revenue
    FROM retail_sales
    GROUP BY 1
)
SELECT
    TO_CHAR(month, 'YYYY-MM')            AS month,
    ROUND(revenue, 2)                    AS revenue,
    ROUND(LAG(revenue) OVER (ORDER BY month), 2)  AS prev_month_revenue,
    ROUND(
        (revenue - LAG(revenue) OVER (ORDER BY month)) /
        NULLIF(LAG(revenue) OVER (ORDER BY month), 0) * 100
    , 1)                                 AS mom_growth_pct
FROM monthly_revenue
ORDER BY month;
```

### Q15  RFM Customer Segmentation

```sql
-- RFM = Recency, Frequency, Monetary
-- Higher score = more valuable customer
WITH rfm_base AS (
    SELECT
        customer_id,
        MAX(sale_date)                              AS last_purchase_date,
        CURRENT_DATE - MAX(sale_date)               AS recency_days,
        COUNT(*)                                    AS frequency,
        ROUND(SUM(total_sale), 2)                   AS monetary
    FROM retail_sales
    GROUP BY customer_id
),
rfm_scores AS (
    SELECT *,
        NTILE(5) OVER (ORDER BY recency_days ASC)   AS r_score,  -- lower recency = better
        NTILE(5) OVER (ORDER BY frequency DESC)     AS f_score,
        NTILE(5) OVER (ORDER BY monetary DESC)      AS m_score
    FROM rfm_base
)
SELECT
    customer_id,
    recency_days,
    frequency,
    monetary,
    r_score, f_score, m_score,
    (r_score + f_score + m_score)     AS rfm_total,
    CASE
        WHEN r_score >= 4 AND f_score >= 4 THEN 'Champion'
        WHEN r_score >= 3 AND f_score >= 3 THEN 'Loyal Customer'
        WHEN r_score >= 4 AND f_score <= 2 THEN 'Recent Customer'
        WHEN r_score <= 2 AND f_score >= 3 THEN 'At Risk'
        ELSE 'Needs Attention'
    END                               AS rfm_segment
FROM rfm_scores
ORDER BY rfm_total DESC;
```

---

## Phase 4: Performance Optimization

```sql
-- Index on sale_date for time-range queries
CREATE INDEX idx_retail_sale_date ON retail_sales(sale_date);

-- Index on category for GROUP BY and WHERE filters
CREATE INDEX idx_retail_category ON retail_sales(category);

-- Composite index for customer-level aggregations
CREATE INDEX idx_retail_customer_date ON retail_sales(customer_id, sale_date);

-- Partial index: only high-value transactions (used in Q5 frequently)
CREATE INDEX idx_retail_high_value ON retail_sales(total_sale)
WHERE total_sale > 1000;
```

> **Extras:** Index columns used in `WHERE`, `GROUP BY`, `JOIN`, and `ORDER BY`. Partial indexes reduce index size when only a subset of rows is queried regularly.

---

## Key Findings

| Insight | Finding |
|---|---|
| **Top Category by Revenue** | Electronics / Clothing (run Q3 to confirm on your data) |
| **Peak Shopping Shift** | Evening transactions tend to have higher avg order value |
| **Best Month (Yearly)** | Identified via Q7 — typically Q4 in retail datasets |
| **Customer Retention** | Majority are one-time buyers → retention opportunity |
| **Profit Margin** | Beauty category often yields highest margin despite lower volume |
| **Champion Customers** | RFM segmentation surfaces top 20% driving ~80% of revenue |

---

## How to Run This Project

```bash
# 1. Clone the repo
git clone https://github.com/kyrtyy/SQL--Retail-sales-analysis

# 2. Create the database
psql -U postgres -c "CREATE DATABASE retail_analytics_db;"

# 3. Run schema setup
psql -U postgres -d retail_analytics_db -f sql/01_schema.sql

# 4. Load data
psql -U postgres -d retail_analytics_db -f sql/02_load_data.sql

# 5. Run analysis queries
psql -U postgres -d retail_analytics_db -f sql/03_analysis.sql
```

---

## Project Structure

```
retail-sales-sql/
│
├── sql/
│   ├── 01_schema.sql          # Table creation + computed columns
│   ├── 02_load_data.sql       # Data loading script
│   ├── 03_eda.sql             # Exploratory data analysis
│   ├── 04_business_queries.sql# All 15 business questions
│   └── 05_indexes.sql         # Performance optimization
│
├── results/
│   └── key_findings.md        # Summary of insights
│
└── README.md
```

---

## About Me

I'm Yash Dewangan, final year physics undergraduate student at indian institute of science, banglore, also a data analyst passionate about turning raw data into business decisions. This project is part of my SQL portfolio demonstrating real world analysis techniques.

-  **LinkedIn**: [https://linkedin.com/in/yash-dewangan-a61619250]
-  **GitHub**: [https://github.com/kyrtyy]
-  **Email**: [dewyashangan@gmail.com]

---

*Built with PostgreSQL | [2025]*
