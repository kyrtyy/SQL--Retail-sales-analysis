
--  FILE    : 05_indexes.sql
--  PURPOSE : Performance optimization via indexing
--  Author  : Yash Dewangan
--  Database: PostgreSQL




--  WHY INDEXES?
--  Without indexes, PostgreSQL does a full table scan on every
--  query. Adding targeted indexes dramatically reduces query time
--  on large datasets — especially for filtered, grouped, or
--  joined columns.



-- Index 1: sale_date
-- Used in: Q1 (date filter), Q7 (year/month extract), Q11 (rolling avg), Q14 (MoM growth)
CREATE INDEX IF NOT EXISTS idx_retail_sale_date
    ON retail_sales(sale_date);


-- Index 2: category
-- Used in: Q2, Q3, Q4, Q6, Q9, Q13 (all GROUP BY or WHERE on category)
CREATE INDEX IF NOT EXISTS idx_retail_category
    ON retail_sales(category);


-- Index 3: customer_id + sale_date (composite)
-- Used in: Q8 (lifetime value), Q12 (retention), Q15 (RFM recency)
-- Composite order matters: customer_id first for equality, sale_date for range/sort
CREATE INDEX IF NOT EXISTS idx_retail_customer_date
    ON retail_sales(customer_id, sale_date);


-- Index 4: total_sale (partial — high-value only)
-- Used in: Q5 (WHERE total_sale > 1000)
-- Partial index keeps size small by only indexing the qualifying rows
CREATE INDEX IF NOT EXISTS idx_retail_high_value
    ON retail_sales(total_sale)
    WHERE total_sale > 1000;


-- Index 5: gender
-- Used in: Q6, Q13 (GROUP BY gender)
CREATE INDEX IF NOT EXISTS idx_retail_gender
    ON retail_sales(gender);



--  VERIFY INDEXES CREATED


SELECT
    indexname,
    indexdef
FROM pg_indexes
WHERE tablename = 'retail_sales'
ORDER BY indexname;



--  CHECK QUERY PLAN (use EXPLAIN ANALYZE to confirm index usage)


-- Example: confirm idx_retail_sale_date is used
EXPLAIN ANALYZE
SELECT * FROM retail_sales
WHERE sale_date = '2022-11-05';

-- Example: confirm idx_retail_high_value partial index is used
EXPLAIN ANALYZE
SELECT * FROM retail_sales
WHERE total_sale > 1000;



--  DROP INDEXES (if needed for re-run or cleanup)

-- DROP INDEX IF EXISTS idx_retail_sale_date;
-- DROP INDEX IF EXISTS idx_retail_category;
-- DROP INDEX IF EXISTS idx_retail_customer_date;
-- DROP INDEX IF EXISTS idx_retail_high_value;
-- DROP INDEX IF EXISTS idx_retail_gender;
