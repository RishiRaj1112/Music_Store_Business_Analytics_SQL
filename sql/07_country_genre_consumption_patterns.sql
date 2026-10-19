-- =====================================================================================
-- Project: Music Store Business Analytics using SQL
-- Database: MySQL 8.0+
-- File: 07_country_genre_consumption_patterns.sql
-- Description: Common Table Expressions (CTEs) and DENSE_RANK window functions to uncover 
--              country-wise music genre consumption patterns, regional preferences, 
--              and top customer spenders per international territory.
-- Resume Focus: "Leveraged Common Table Expressions (CTEs) and window functions 
--               (DENSE_RANK) to uncover country-wise music genre consumption patterns."
-- =====================================================================================

USE music_store_db;

-- -------------------------------------------------------------------------------------
-- 1. COUNTRY-WISE TOP MUSIC GENRE CONSUMPTION PATTERNS (DENSE_RANK)
-- -------------------------------------------------------------------------------------
-- Business Objective: Identify the most popular music genre across every international market 
-- to guide regional catalog curation, licensing, and localized digital ad campaigns.
-- Window Function: DENSE_RANK() partitions by customer country and orders by track quantity sold.
-- Why DENSE_RANK? If two genres tie for #1 in a country, DENSE_RANK preserves both without 
-- arbitrary tie-breaking or skipping ordinal ranks.

WITH genre_country_sales AS (
    SELECT 
        c.country,
        g.genre_id,
        g.name AS genre_name,
        COUNT(il.invoice_line_id) AS total_tracks_purchased,
        ROUND(SUM(il.unit_price * il.quantity), 2) AS total_genre_revenue,
        DENSE_RANK() OVER (
            PARTITION BY c.country 
            ORDER BY COUNT(il.invoice_line_id) DESC, SUM(il.unit_price * il.quantity) DESC
        ) AS genre_rank
    FROM customer c
    INNER JOIN invoice i ON c.customer_id = i.customer_id
    INNER JOIN invoice_line il ON i.invoice_id = il.invoice_id
    INNER JOIN track t ON il.track_id = t.track_id
    INNER JOIN genre g ON t.genre_id = g.genre_id
    GROUP BY c.country, g.genre_id, g.name
)
SELECT 
    country,
    genre_name,
    total_tracks_purchased,
    total_genre_revenue,
    genre_rank
FROM genre_country_sales
WHERE genre_rank = 1
ORDER BY country ASC;

-- Analytical Insight:
-- Rock is the overwhelmingly dominant genre across North America and Western Europe (e.g., USA, 
-- Canada, Brazil, Germany, UK). However, in Argentina, 'Alternative & Punk' claims the #1 position, 
-- proving the necessity of country-specific catalog customization.


-- -------------------------------------------------------------------------------------
-- 2. TOP CUSTOMER SPENDER PER COUNTRY USING DENSE_RANK()
-- -------------------------------------------------------------------------------------
-- Business Objective: Pinpoint the single highest-value customer account in each country 
-- for localized VIP relationship management and targeted loyalty perks.

WITH customer_spend_by_country AS (
    SELECT 
        c.customer_id,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        c.email,
        c.country,
        ROUND(SUM(i.total), 2) AS total_country_spend,
        COUNT(i.invoice_id) AS orders_placed,
        DENSE_RANK() OVER (
            PARTITION BY c.country 
            ORDER BY SUM(i.total) DESC
        ) AS spender_rank
    FROM customer c
    INNER JOIN invoice i ON c.customer_id = i.customer_id
    GROUP BY c.customer_id, customer_name, c.email, c.country
)
SELECT 
    country,
    customer_id,
    customer_name,
    email,
    orders_placed,
    total_country_spend,
    spender_rank
FROM customer_spend_by_country
WHERE spender_rank = 1
ORDER BY total_country_spend DESC;


-- -------------------------------------------------------------------------------------
-- 3. CUSTOMER EXPENDITURE ON THE STORE'S #1 BEST-SELLING ARTIST
-- -------------------------------------------------------------------------------------
-- Business Objective: Determine which single artist produces the highest gross sales,
-- and identify which individual customers contributed the highest spend on that artist.
-- Multi-CTE Architecture: CTE 1 finds top artist, CTE 2 aggregates customer spend on them.

WITH best_selling_artist AS (
    SELECT 
        ar.artist_id,
        ar.name AS artist_name,
        ROUND(SUM(il.unit_price * il.quantity), 2) AS total_artist_sales
    FROM invoice_line il
    INNER JOIN track t ON il.track_id = t.track_id
    INNER JOIN album al ON t.album_id = al.album_id
    INNER JOIN artist ar ON al.artist_id = ar.artist_id
    GROUP BY ar.artist_id, ar.name
    ORDER BY total_artist_sales DESC
    LIMIT 1
),
customer_artist_spending AS (
    SELECT 
        c.customer_id,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        c.country,
        bsa.artist_name,
        ROUND(SUM(il.unit_price * il.quantity), 2) AS total_spent_on_artist,
        DENSE_RANK() OVER (ORDER BY SUM(il.unit_price * il.quantity) DESC) AS customer_fan_rank
    FROM invoice i
    INNER JOIN customer c ON i.customer_id = c.customer_id
    INNER JOIN invoice_line il ON i.invoice_id = il.invoice_id
    INNER JOIN track t ON il.track_id = t.track_id
    INNER JOIN album al ON t.album_id = al.album_id
    INNER JOIN best_selling_artist bsa ON al.artist_id = bsa.artist_id
    GROUP BY c.customer_id, customer_name, c.country, bsa.artist_name
)
SELECT 
    customer_fan_rank,
    customer_id,
    customer_name,
    country,
    artist_name,
    total_spent_on_artist
FROM customer_artist_spending
ORDER BY customer_fan_rank ASC
LIMIT 10;
