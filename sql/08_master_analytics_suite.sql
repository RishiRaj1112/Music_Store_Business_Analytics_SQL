-- =====================================================================================
-- Project: Music Store Business Analytics using SQL
-- Database: MySQL 8.0+
-- File: 08_master_analytics_suite.sql
-- Description: Consolidated master script containing end-to-end analytical queries.
--              Includes multi-table JOINs, nested subqueries, CTEs, and window functions
--              (DENSE_RANK, NTILE, LAG).
-- =====================================================================================

USE music_store_db;

-- =====================================================================================
-- SECTION 1: DATABASE AUDIT & CATALOG SCALE (3,500+ RECORDS)
-- =====================================================================================

-- Verify record counts across all 11 normalized tables
SELECT 'employee' AS table_name, COUNT(*) AS total_records FROM employee
UNION ALL SELECT 'customer', COUNT(*) FROM customer
UNION ALL SELECT 'invoice', COUNT(*) FROM invoice
UNION ALL SELECT 'invoice_line', COUNT(*) FROM invoice_line
UNION ALL SELECT 'artist', COUNT(*) FROM artist
UNION ALL SELECT 'album', COUNT(*) FROM album
UNION ALL SELECT 'track', COUNT(*) FROM track
UNION ALL SELECT 'genre', COUNT(*) FROM genre
UNION ALL SELECT 'media_type', COUNT(*) FROM media_type
UNION ALL SELECT 'playlist', COUNT(*) FROM playlist
UNION ALL SELECT 'playlist_track', COUNT(*) FROM playlist_track;


-- =====================================================================================
-- SECTION 2: BUSINESS EXPANSION & EVENT MARKETING
-- =====================================================================================

-- Question: Which city has generated the highest cumulative revenue for hosting a promotional music festival?
SELECT 
    i.billing_city,
    i.billing_country,
    COUNT(DISTINCT i.customer_id) AS unique_customers,
    COUNT(i.invoice_id) AS total_orders,
    ROUND(SUM(i.total), 2) AS total_revenue,
    ROUND(AVG(i.total), 2) AS avg_order_value
FROM invoice i
GROUP BY i.billing_city, i.billing_country
ORDER BY total_revenue DESC
LIMIT 5;

-- Senior-most employee based on organizational levels
SELECT 
    employee_id,
    CONCAT(first_name, ' ', last_name) AS employee_name,
    title,
    levels
FROM employee
ORDER BY levels DESC
LIMIT 1;


-- =====================================================================================
-- SECTION 3: CATALOG & ROCK ARTIST PERFORMANCE
-- =====================================================================================

-- Question: Who are the top 10 artists with the most extensive Rock catalog footprint?
SELECT 
    ar.artist_id,
    ar.name AS artist_name,
    COUNT(t.track_id) AS total_rock_tracks
FROM track t
INNER JOIN album al ON t.album_id = al.album_id
INNER JOIN artist ar ON al.artist_id = ar.artist_id
INNER JOIN genre g ON t.genre_id = g.genre_id
WHERE g.name = 'Rock'
GROUP BY ar.artist_id, ar.name
ORDER BY total_rock_tracks DESC
LIMIT 10;

-- Question: Identify tracks longer than the average song length in the catalog
SELECT 
    t.name AS track_name,
    ROUND(t.milliseconds / 60000.0, 2) AS duration_minutes
FROM track t
WHERE t.milliseconds > (SELECT AVG(milliseconds) FROM track)
ORDER BY t.milliseconds DESC
LIMIT 10;


-- =====================================================================================
-- SECTION 4: CUSTOMER LIFETIME VALUE (CLV) & LOYALTY TIERS (NTILE)
-- =====================================================================================

-- Question: Segment customers into 4 data-driven loyalty tiers using NTILE(4)
WITH customer_clv AS (
    SELECT 
        c.customer_id,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        c.country,
        ROUND(SUM(i.total), 2) AS lifetime_spend,
        COUNT(i.invoice_id) AS total_orders,
        NTILE(4) OVER (ORDER BY SUM(i.total) DESC) AS clv_quartile
    FROM customer c
    INNER JOIN invoice i ON c.customer_id = i.customer_id
    GROUP BY c.customer_id, customer_name, c.country
)
SELECT 
    clv_quartile,
    CASE 
        WHEN clv_quartile = 1 THEN 'Platinum'
        WHEN clv_quartile = 2 THEN 'Gold'
        WHEN clv_quartile = 3 THEN 'Silver'
        ELSE 'Bronze'
    END AS loyalty_tier,
    COUNT(customer_id) AS customer_count,
    ROUND(MIN(lifetime_spend), 2) AS min_spend,
    ROUND(MAX(lifetime_spend), 2) AS max_spend,
    ROUND(AVG(lifetime_spend), 2) AS avg_spend,
    ROUND(SUM(lifetime_spend), 2) AS tier_revenue,
    ROUND((SUM(lifetime_spend) / (SELECT SUM(total) FROM invoice)) * 100, 2) AS revenue_share_pct
FROM customer_clv
GROUP BY clv_quartile
ORDER BY clv_quartile;


-- =====================================================================================
-- SECTION 5: CUSTOMER RETENTION & MONTH-OVER-MONTH REVENUE (LAG)
-- =====================================================================================

-- Question: Track Month-over-Month (MoM) revenue growth using LAG()
WITH monthly_revenue_summary AS (
    SELECT 
        DATE_FORMAT(invoice_date, '%Y-%m') AS sales_month,
        ROUND(SUM(total), 2) AS monthly_revenue,
        COUNT(invoice_id) AS total_orders
    FROM invoice
    GROUP BY sales_month
)
SELECT 
    sales_month,
    monthly_revenue,
    LAG(monthly_revenue, 1) OVER (ORDER BY sales_month) AS prior_month_revenue,
    ROUND(monthly_revenue - LAG(monthly_revenue, 1) OVER (ORDER BY sales_month), 2) AS mom_variance,
    ROUND(
        ((monthly_revenue - LAG(monthly_revenue, 1) OVER (ORDER BY sales_month)) / 
        LAG(monthly_revenue, 1) OVER (ORDER BY sales_month)) * 100.0, 
        2
    ) AS mom_growth_rate_pct
FROM monthly_revenue_summary
ORDER BY sales_month ASC;


-- =====================================================================================
-- SECTION 6: COUNTRY-WISE GENRE PATTERNS & SPENDERS (DENSE_RANK)
-- =====================================================================================

-- Question: Determine the #1 music genre consumed in each country using DENSE_RANK()
WITH genre_country_sales AS (
    SELECT 
        c.country,
        g.name AS genre_name,
        COUNT(il.invoice_line_id) AS tracks_purchased,
        ROUND(SUM(il.unit_price * il.quantity), 2) AS total_spending,
        DENSE_RANK() OVER (
            PARTITION BY c.country 
            ORDER BY COUNT(il.invoice_line_id) DESC, SUM(il.unit_price * il.quantity) DESC
        ) AS genre_rank
    FROM customer c
    INNER JOIN invoice i ON c.customer_id = i.customer_id
    INNER JOIN invoice_line il ON i.invoice_id = il.invoice_id
    INNER JOIN track t ON il.track_id = t.track_id
    INNER JOIN genre g ON t.genre_id = g.genre_id
    GROUP BY c.country, g.name
)
SELECT 
    country,
    genre_name,
    tracks_purchased,
    total_spending,
    genre_rank
FROM genre_country_sales
WHERE genre_rank = 1
ORDER BY country ASC;

-- Question: Top-spending customer in each country using DENSE_RANK()
WITH country_top_spenders AS (
    SELECT 
        c.customer_id,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        c.country,
        ROUND(SUM(i.total), 2) AS total_spent,
        DENSE_RANK() OVER (
            PARTITION BY c.country 
            ORDER BY SUM(i.total) DESC
        ) AS spender_rank
    FROM customer c
    INNER JOIN invoice i ON c.customer_id = i.customer_id
    GROUP BY c.customer_id, customer_name, c.country
)
SELECT 
    country,
    customer_id,
    customer_name,
    total_spent
FROM country_top_spenders
WHERE spender_rank = 1
ORDER BY total_spent DESC;
