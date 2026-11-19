-- =====================================================================================
-- Project: Music Store Business Analytics using SQL
-- Database: MySQL 8.0+
-- File: 05_clv_and_loyalty_tier_segmentation.sql
-- Description: Common Table Expressions (CTEs), DENSE_RANK() window function, and 
--              CASE WHEN statements to calculate Customer Lifetime Value (CLV), 
--              segment customers into loyalty tiers, and evaluate spending cohorts.
-- Resume Focus: "Leveraged Common Table Expressions (CTEs) and window functions 
--               (DENSE_RANK) to segment customer lifetime value (CLV) into loyalty tiers"
-- =====================================================================================

USE music_store_db;

-- -------------------------------------------------------------------------------------
-- 1. CUSTOMER LIFETIME VALUE (CLV) & LOYALTY TIER SEGMENTATION (DENSE_RANK + CASE WHEN)
-- -------------------------------------------------------------------------------------
-- Business Objective: Calculate lifetime spending per customer, rank spenders from #1 
-- downwards using DENSE_RANK(), and assign intuitive loyalty tiers (Platinum, Gold, Silver, Bronze).

WITH customer_clv AS (
    SELECT 
        c.customer_id,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        c.email,
        c.city,
        c.country,
        COUNT(i.invoice_id) AS total_orders,
        ROUND(SUM(i.total), 2) AS lifetime_spend,
        ROUND(AVG(i.total), 2) AS average_order_value,
        DENSE_RANK() OVER (ORDER BY SUM(i.total) DESC) AS customer_rank
    FROM customer c
    INNER JOIN invoice i ON c.customer_id = i.customer_id
    GROUP BY c.customer_id, customer_name, c.email, c.city, c.country
)
SELECT 
    customer_id,
    customer_name,
    country,
    total_orders,
    lifetime_spend,
    average_order_value,
    customer_rank,
    CASE 
        WHEN lifetime_spend >= 100.00 THEN 'Platinum Tier ($100+)'
        WHEN lifetime_spend >= 75.00  THEN 'Gold Tier ($75 - $99.99)'
        WHEN lifetime_spend >= 50.00  THEN 'Silver Tier ($50 - $74.99)'
        ELSE 'Bronze Tier (< $50)'
    END AS loyalty_tier
FROM customer_clv
ORDER BY lifetime_spend DESC;


-- -------------------------------------------------------------------------------------
-- 2. LOYALTY TIER EXECUTIVE SUMMARY & REVENUE CONCENTRATION
-- -------------------------------------------------------------------------------------
-- Business Objective: Group customers by loyalty tier to quantify member counts, 
-- average spend, and gross revenue share across each tier.

WITH customer_spend AS (
    SELECT 
        c.customer_id,
        ROUND(SUM(i.total), 2) AS lifetime_spend
    FROM customer c
    INNER JOIN invoice i ON c.customer_id = i.customer_id
    GROUP BY c.customer_id
),
customer_tiers AS (
    SELECT 
        customer_id,
        lifetime_spend,
        CASE 
            WHEN lifetime_spend >= 100.00 THEN 'Platinum ($100+)'
            WHEN lifetime_spend >= 75.00  THEN 'Gold ($75 - $99.99)'
            WHEN lifetime_spend >= 50.00  THEN 'Silver ($50 - $74.99)'
            ELSE 'Bronze (< $50)'
        END AS loyalty_tier
    FROM customer_spend
)
SELECT 
    loyalty_tier,
    COUNT(customer_id) AS total_members,
    ROUND(MIN(lifetime_spend), 2) AS min_spend,
    ROUND(MAX(lifetime_spend), 2) AS max_spend,
    ROUND(AVG(lifetime_spend), 2) AS avg_member_spend,
    ROUND(SUM(lifetime_spend), 2) AS total_tier_revenue,
    ROUND((SUM(lifetime_spend) / (SELECT SUM(total) FROM invoice)) * 100, 2) AS revenue_share_pct
FROM customer_tiers
GROUP BY loyalty_tier
ORDER BY total_tier_revenue DESC;


-- -------------------------------------------------------------------------------------
-- 3. TOP 5 HIGHEST SPENDING CUSTOMERS GLOBALLY
-- -------------------------------------------------------------------------------------
-- Business Objective: Identify the top 5 high-value customers using DENSE_RANK() for VIP outreach.

WITH ranked_customers AS (
    SELECT 
        c.customer_id,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        c.country,
        ROUND(SUM(i.total), 2) AS total_spent,
        COUNT(i.invoice_id) AS total_orders,
        DENSE_RANK() OVER (ORDER BY SUM(i.total) DESC) AS rank_position
    FROM customer c
    INNER JOIN invoice i ON c.customer_id = i.customer_id
    GROUP BY c.customer_id, customer_name, c.country
)
SELECT 
    rank_position,
    customer_id,
    customer_name,
    country,
    total_orders,
    total_spent
FROM ranked_customers
WHERE rank_position <= 5;
