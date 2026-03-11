
--  FILE    : 04_business_queries.sql
--  PURPOSE : Business-driven SQL queries
--  Author  : Yash dewangan
--  Database: PostgreSQL




--  Q1: All sales on a specific date


SELECT *
FROM retail_sales
WHERE sale_date = '2022-11-05'
ORDER BY sale_time;



--  Q2: Clothing transactions with quantity >= 4 in Nov 2022


SELECT *
FROM retail_sales
WHERE
    category = 'Clothing'
    AND TO_CHAR(sale_date, 'YYYY-MM') = '2022-11'
    AND quantity >= 4
ORDER BY total_sale DESC;



--  Q3: Total revenue and orders per category


SELECT
    category,
    COUNT(*)                     AS total_orders,
    SUM(total_sale)              AS net_revenue,
    ROUND(AVG(total_sale), 2)    AS avg_order_value
FROM retail_sales
GROUP BY category
ORDER BY net_revenue DESC;



--  Q4: Average customer age per category


SELECT
    category,
    ROUND(AVG(age), 1)    AS avg_customer_age,
    MIN(age)              AS youngest,
    MAX(age)              AS oldest
FROM retail_sales
GROUP BY category
ORDER BY avg_customer_age;



--  Q5: High-value transactions above $1,000


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



--  Q6: Transactions and revenue by gender per category
--      (includes gender split % within each category)


SELECT
    category,
    gender,
    COUNT(*)                                                                   AS total_transactions,
    ROUND(SUM(total_sale), 2)                                                  AS revenue,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY category), 1)   AS gender_pct_in_category
FROM retail_sales
GROUP BY category, gender
ORDER BY category, gender;



--  Q7: Best-selling month per year (by average sale value)


WITH monthly_stats AS (
    SELECT
        EXTRACT(YEAR FROM sale_date)    AS year,
        EXTRACT(MONTH FROM sale_date)   AS month,
        TO_CHAR(sale_date, 'Month')     AS month_name,
        ROUND(AVG(total_sale), 2)       AS avg_sale,
        ROUND(SUM(total_sale), 2)       AS total_revenue,
        RANK() OVER (
            PARTITION BY EXTRACT(YEAR FROM sale_date)
            ORDER BY AVG(total_sale) DESC
        )                               AS rank
    FROM retail_sales
    GROUP BY 1, 2, 3
)
SELECT year, month_name, avg_sale, total_revenue
FROM monthly_stats
WHERE rank = 1
ORDER BY year;



--  Q8: Top 5 customers by lifetime value


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



--  Q9: Unique customers and avg orders per category


SELECT
    category,
    COUNT(DISTINCT customer_id)                                        AS unique_customers,
    COUNT(*)                                                           AS total_orders,
    ROUND(COUNT(*)::NUMERIC / COUNT(DISTINCT customer_id), 2)         AS avg_orders_per_customer
FROM retail_sales
GROUP BY category
ORDER BY unique_customers DESC;



--  Q10: Orders and revenue by time-of-day shift


WITH shift_data AS (
    SELECT *,
        CASE
            WHEN EXTRACT(HOUR FROM sale_time) < 12              THEN 'Morning (Before 12pm)'
            WHEN EXTRACT(HOUR FROM sale_time) BETWEEN 12 AND 17 THEN 'Afternoon (12-5pm)'
            ELSE                                                      'Evening (After 5pm)'
        END AS shift
    FROM retail_sales
)
SELECT
    shift,
    COUNT(*)                                                     AS total_orders,
    ROUND(SUM(total_sale), 2)                                    AS shift_revenue,
    ROUND(AVG(total_sale), 2)                                    AS avg_order_value,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)           AS pct_of_orders
FROM shift_data
GROUP BY shift
ORDER BY total_orders DESC;



--  Q11: 30-day rolling revenue average


SELECT
    sale_date,
    ROUND(SUM(total_sale), 2)                                AS daily_revenue,
    ROUND(AVG(SUM(total_sale)) OVER (
        ORDER BY sale_date
        ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
    ), 2)                                                    AS rolling_30d_avg
FROM retail_sales
GROUP BY sale_date
ORDER BY sale_date;



--  Q12: Customer retention — one-time vs occasional vs loyal


WITH purchase_counts AS (
    SELECT customer_id, COUNT(*) AS num_purchases
    FROM retail_sales
    GROUP BY customer_id
)
SELECT
    CASE
        WHEN num_purchases = 1              THEN 'One-Time Buyer'
        WHEN num_purchases BETWEEN 2 AND 4  THEN 'Occasional Buyer'
        ELSE                                     'Loyal Customer'
    END                                                      AS customer_segment,
    COUNT(*)                                                 AS num_customers,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)       AS pct_of_customers
FROM purchase_counts
GROUP BY customer_segment
ORDER BY num_customers DESC;



--  Q13: Profit margin leaders by category and gender


SELECT
    category,
    gender,
    ROUND(SUM(profit), 2)                        AS total_profit,
    ROUND(AVG(profit / total_sale) * 100, 2)     AS avg_margin_pct,
    RANK() OVER (ORDER BY SUM(profit) DESC)      AS profit_rank
FROM retail_sales
GROUP BY category, gender
ORDER BY total_profit DESC;



--  Q14: Month-over-month revenue growth


WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC('month', sale_date)    AS month,
        SUM(total_sale)                   AS revenue
    FROM retail_sales
    GROUP BY 1
)
SELECT
    TO_CHAR(month, 'YYYY-MM')                                        AS month,
    ROUND(revenue, 2)                                                AS revenue,
    ROUND(LAG(revenue) OVER (ORDER BY month), 2)                     AS prev_month_revenue,
    ROUND(
        (revenue - LAG(revenue) OVER (ORDER BY month)) /
        NULLIF(LAG(revenue) OVER (ORDER BY month), 0) * 100
    , 1)                                                             AS mom_growth_pct
FROM monthly_revenue
ORDER BY month;



--  Q15: RFM Customer Segmentation
--       Recency (R), Frequency (F), Monetary (M)
--       Each scored 1-5 using NTILE; higher = better


WITH rfm_base AS (
    SELECT
        customer_id,
        MAX(sale_date)                          AS last_purchase_date,
        CURRENT_DATE - MAX(sale_date)           AS recency_days,
        COUNT(*)                                AS frequency,
        ROUND(SUM(total_sale), 2)               AS monetary
    FROM retail_sales
    GROUP BY customer_id
),
rfm_scores AS (
    SELECT *,
        NTILE(5) OVER (ORDER BY recency_days ASC)  AS r_score,  -- lower recency = better
        NTILE(5) OVER (ORDER BY frequency DESC)    AS f_score,
        NTILE(5) OVER (ORDER BY monetary DESC)     AS m_score
    FROM rfm_base
)
SELECT
    customer_id,
    last_purchase_date,
    recency_days,
    frequency,
    monetary,
    r_score,
    f_score,
    m_score,
    (r_score + f_score + m_score)   AS rfm_total,
    CASE
        WHEN r_score >= 4 AND f_score >= 4  THEN 'Champion'
        WHEN r_score >= 3 AND f_score >= 3  THEN 'Loyal Customer'
        WHEN r_score >= 4 AND f_score <= 2  THEN 'Recent Customer'
        WHEN r_score <= 2 AND f_score >= 3  THEN 'At Risk'
        ELSE                                     'Needs Attention'
    END                             AS rfm_segment
FROM rfm_scores
ORDER BY rfm_total DESC;
