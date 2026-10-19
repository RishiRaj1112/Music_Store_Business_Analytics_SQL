-- =====================================================================================
-- Project: Music Store Business Analytics using SQL
-- Database: MySQL 8.0+
-- File: 06_customer_retention_and_mom_trends.sql
-- Description: Common Table Expressions (CTEs) and LAG window functions to evaluate 
--              business growth, Month-over-Month (MoM) revenue trajectory, customer 
--              retention, and repeat purchase cadence.
-- Resume Focus: "evaluate business growth, customer retention... window functions (LAG)"
-- =====================================================================================

USE music_store_db;

-- -------------------------------------------------------------------------------------
-- 1. MONTH-OVER-MONTH (MoM) REVENUE GROWTH ANALYSIS USING LAG()
-- -------------------------------------------------------------------------------------
-- Business Objective: Track temporal revenue fluctuations, sales acceleration, and 
-- calculate MoM growth percentages across all operational months.
-- Window Function: LAG() looks back 1 row ordered by invoice month.

WITH monthly_sales AS (
    SELECT 
        DATE_FORMAT(invoice_date, '%Y-%m') AS sales_month,
        COUNT(invoice_id) AS total_monthly_orders,
        COUNT(DISTINCT customer_id) AS unique_purchasers,
        ROUND(SUM(total), 2) AS monthly_revenue
    FROM invoice
    GROUP BY sales_month
)
SELECT 
    sales_month,
    total_monthly_orders,
    unique_purchasers,
    monthly_revenue,
    LAG(monthly_revenue, 1) OVER (ORDER BY sales_month) AS prior_month_revenue,
    ROUND(monthly_revenue - LAG(monthly_revenue, 1) OVER (ORDER BY sales_month), 2) AS mom_dollar_variance,
    ROUND(
        ((monthly_revenue - LAG(monthly_revenue, 1) OVER (ORDER BY sales_month)) / 
        LAG(monthly_revenue, 1) OVER (ORDER BY sales_month)) * 100.0, 
        2
    ) AS mom_growth_rate_pct
FROM monthly_sales
ORDER BY sales_month ASC;


-- -------------------------------------------------------------------------------------
-- 2. CUSTOMER REPEAT PURCHASE CADENCE & RETENTION GAP ANALYSIS
-- -------------------------------------------------------------------------------------
-- Business Objective: Determine customer purchasing frequency and time gap between 
-- consecutive transactions to identify churn risk thresholds.
-- Window Function: LAG(invoice_date) PARTITION BY customer_id ORDER BY invoice_date.

WITH customer_order_timeline AS (
    SELECT 
        customer_id,
        invoice_id,
        invoice_date,
        total,
        LAG(invoice_date, 1) OVER (
            PARTITION BY customer_id 
            ORDER BY invoice_date
        ) AS previous_order_date
    FROM invoice
),
order_gaps AS (
    SELECT 
        customer_id,
        invoice_id,
        invoice_date,
        previous_order_date,
        DATEDIFF(invoice_date, previous_order_date) AS days_between_orders
    FROM customer_order_timeline
    WHERE previous_order_date IS NOT NULL
)
SELECT 
    ROUND(AVG(days_between_orders), 1) AS avg_days_between_purchases,
    MIN(days_between_orders) AS min_repurchase_gap_days,
    MAX(days_between_orders) AS max_repurchase_gap_days,
    COUNT(*) AS total_repeat_orders_analyzed
FROM order_gaps;


-- -------------------------------------------------------------------------------------
-- 3. CUSTOMER ACQUISITION COHORT ANALYSIS
-- -------------------------------------------------------------------------------------
-- Business Objective: Evaluate customer acquisition volume by cohort month and track 
-- aggregate revenue generated per cohort.

WITH customer_cohorts AS (
    SELECT 
        c.customer_id,
        DATE_FORMAT(MIN(i.invoice_date), '%Y-%m') AS cohort_month,
        ROUND(SUM(i.total), 2) AS customer_cumulative_spend,
        COUNT(i.invoice_id) AS customer_invoice_count
    FROM customer c
    INNER JOIN invoice i ON c.customer_id = i.customer_id
    GROUP BY c.customer_id
)
SELECT 
    cohort_month,
    COUNT(customer_id) AS new_customers_acquired,
    ROUND(SUM(customer_cumulative_spend), 2) AS total_cohort_lifetime_revenue,
    ROUND(AVG(customer_cumulative_spend), 2) AS avg_clv_per_cohort_customer,
    SUM(customer_invoice_count) AS total_cohort_orders
FROM customer_cohorts
GROUP BY cohort_month
ORDER BY cohort_month ASC;
