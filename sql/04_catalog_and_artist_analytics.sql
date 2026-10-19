-- =====================================================================================
-- Project: Music Store Business Analytics using SQL
-- Database: MySQL 8.0+
-- File: 04_catalog_and_artist_analytics.sql
-- Description: Multi-table INNER JOINs, nested subqueries, and aggregations to evaluate 
--              catalog performance, top rock artists, listeners, and track duration anomalies.
-- Resume Focus: "top catalog rock artists... nested subqueries, and aggregations"
-- =====================================================================================

USE music_store_db;

-- -------------------------------------------------------------------------------------
-- 1. TOP CATALOG ROCK ARTISTS
-- -------------------------------------------------------------------------------------
-- Business Objective: Identify the top 10 artists with the most extensive Rock music
-- catalog footprint to invite for promotional sponsorships and live showcases.
-- Multi-table INNER JOIN: track -> album -> artist -> genre

SELECT 
    ar.artist_id,
    ar.name AS artist_name,
    COUNT(t.track_id) AS total_rock_tracks,
    ROUND(SUM(t.milliseconds) / 60000.0, 2) AS total_catalog_duration_minutes
FROM track t
INNER JOIN album al ON t.album_id = al.album_id
INNER JOIN artist ar ON al.artist_id = ar.artist_id
INNER JOIN genre g ON t.genre_id = g.genre_id
WHERE g.name = 'Rock'
GROUP BY ar.artist_id, ar.name
ORDER BY total_rock_tracks DESC
LIMIT 10;

-- Top Rock Catalog Leaders:
-- 1. Led Zeppelin (114 tracks)
-- 2. U2 (112 tracks)
-- 3. Deep Purple (92 tracks)
-- 4. Iron Maiden (81 tracks)
-- 5. Pearl Jam (54 tracks)


-- -------------------------------------------------------------------------------------
-- 2. ROCK MUSIC AUDIENCE IDENTIFICATION FOR TARGETED MARKETING
-- -------------------------------------------------------------------------------------
-- Business Objective: Retrieve unique contact records of all customers who purchased Rock
-- tracks for targeted email campaigns regarding upcoming rock festivals.
-- Implemented using nested subqueries and multi-table joins.

SELECT DISTINCT 
    c.customer_id,
    c.first_name,
    c.last_name,
    c.email,
    c.country
FROM customer c
INNER JOIN invoice i ON c.customer_id = i.customer_id
INNER JOIN invoice_line il ON i.invoice_id = il.invoice_id
WHERE il.track_id IN (
    SELECT t.track_id
    FROM track t
    INNER JOIN genre g ON t.genre_id = g.genre_id
    WHERE g.name = 'Rock'
)
ORDER BY c.email ASC;


-- -------------------------------------------------------------------------------------
-- 3. TRACK DURATION ANOMALY ANALYSIS (LONGER THAN AVERAGE)
-- -------------------------------------------------------------------------------------
-- Business Objective: Identify outlier songs exceeding the overall catalog average track length.
-- Uses a nested scalar subquery to calculate dynamic catalog average.

SELECT 
    t.track_id,
    t.name AS track_name,
    ar.name AS artist_name,
    ROUND(t.milliseconds / 60000.0, 2) AS duration_minutes,
    (SELECT ROUND(AVG(milliseconds) / 60000.0, 2) FROM track) AS catalog_avg_minutes
FROM track t
INNER JOIN album al ON t.album_id = al.album_id
INNER JOIN artist ar ON al.artist_id = ar.artist_id
WHERE t.milliseconds > (SELECT AVG(milliseconds) FROM track)
ORDER BY t.milliseconds DESC
LIMIT 15;


-- -------------------------------------------------------------------------------------
-- 4. GENRE CATALOG DISTRIBUTION & COMMERCIAL SHARE
-- -------------------------------------------------------------------------------------
-- Business Objective: Evaluate breadth and unit volume of all genres across the 3,500+ track catalog.

SELECT 
    g.name AS genre_name,
    COUNT(t.track_id) AS catalog_tracks_available,
    ROUND((COUNT(t.track_id) / (SELECT COUNT(*) FROM track)) * 100, 2) AS catalog_share_pct,
    COALESCE(COUNT(il.invoice_line_id), 0) AS units_sold,
    COALESCE(ROUND(SUM(il.unit_price * il.quantity), 2), 0.00) AS total_genre_revenue
FROM genre g
LEFT JOIN track t ON g.genre_id = t.genre_id
LEFT JOIN invoice_line il ON t.track_id = il.track_id
GROUP BY g.genre_id, g.name
ORDER BY units_sold DESC;
