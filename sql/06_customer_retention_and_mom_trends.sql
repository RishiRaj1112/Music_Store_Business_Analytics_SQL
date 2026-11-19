-- =====================================================================================
-- Project: Music Store Business Analytics using SQL
-- Database: MySQL 8.0+
-- File: 06_customer_retention_and_mom_trends.sql
-- Description: Aggregations, GROUP BY, and Common Table Expressions (CTEs) to evaluate 
--              business growth trends, monthly sales trajectory, customer retention rate, 
--              and acquisition cohorts.
-- Resume Focus: "evaluate business growth, customer retention, and catalog performance"
-- =====================================================================================

USE music_store_db;

-- -------------------------------------------------------------------------------------
-- 1. MONTHLY BUSINESS GROWTH & REVENUE TRAJECTORY
-- -------------------------------------------------------------------------------------
-- Business Objective: Track temporal sales volume, active customer count, and total 
-- revenue month by month to analyze store growth trends.

SELECT 
    DATE_FORMAT(invoice_date, '%Y-%m') AS sales_month,
    COUNT(invoice_id) AS total_orders,
    COUNT(DISTINCT customer_id) AS active_customers,
    ROUND(SUM(total), 2) AS monthly_revenue,
    ROUND(AVG(total), 2) AS avg_order_value
FROM invoice
GROUP BY sales_month
ORDER BY sales_month ASC;


-- -------------------------------------------------------------------------------------
-- 2. ANNUAL (YEAR-OVER-YEAR) BUSINESS GROWTH SUMMARY
-- -------------------------------------------------------------------------------------
-- Business Objective: Summarize annual business growth, total transaction volume, 
-- and gross revenue generated per calendar year.

SELECT 
    YEAR(invoice_date) AS sales_year,
    COUNT(invoice_id) AS annual_orders,
    COUNT(DISTINCT customer_id) AS unique_customers,
    ROUND(SUM(total), 2) AS annual_gross_revenue,
    ROUND(AVG(total), 2) AS avg_order_value
FROM invoice
GROUP BY sales_year
ORDER BY sales_year ASC;


-- -------------------------------------------------------------------------------------
-- 3. CUSTOMER RETENTION & REPEAT PURCHASE RATE (CTE + CASE WHEN)
-- -------------------------------------------------------------------------------------
-- Business Objective: Calculate the customer retention rate by identifying what portion 
-- of the customer base makes repeat purchases (orders > 1) vs. one-time purchases.

WITH customer_purchase_counts AS (
    SELECT 
        customer_id,
        COUNT(invoice_id) AS order_frequency,
        ROUND(SUM(total), 2) AS total_spend
    FROM invoice
    GROUP BY customer_id
)
SELECT 
    COUNT(customer_id) AS total_customer_base,
    SUM(CASE WHEN order_frequency > 1 THEN 1 ELSE 0 END) AS repeat_customers,
    SUM(CASE WHEN order_frequency = 1 THEN 1 ELSE 0 END) AS one_time_customers,
    ROUND((SUM(CASE WHEN order_frequency > 1 THEN 1 ELSE 0 END) * 100.0) / COUNT(customer_id), 2) AS retention_rate_pct
FROM customer_purchase_counts;


-- -------------------------------------------------------------------------------------
-- 4. CUSTOMER ACQUISITION COHORT ANALYSIS
-- -------------------------------------------------------------------------------------
-- Business Objective: Determine when new customers were first acquired by tracking 
-- their earliest invoice date.

WITH customer_first_order AS (
    SELECT 
        customer_id,
        DATE_FORMAT(MIN(invoice_date), '%Y-%m') AS acquisition_month,
        ROUND(SUM(total), 2) AS customer_lifetime_spend
    FROM invoice
    GROUP BY customer_id
)
SELECT 
    acquisition_month,
    COUNT(customer_id) AS new_customers_acquired,
    ROUND(SUM(customer_lifetime_spend), 2) AS cohort_total_spend,
    ROUND(AVG(customer_lifetime_spend), 2) AS avg_cohort_spend
FROM customer_first_order
GROUP BY acquisition_month
ORDER BY acquisition_month ASC;
