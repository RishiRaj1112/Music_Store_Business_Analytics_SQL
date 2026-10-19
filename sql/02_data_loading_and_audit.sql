-- =====================================================================================
-- Project: Music Store Business Analytics using SQL
-- Database: MySQL 8.0+
-- File: 02_data_loading_and_audit.sql
-- Description: Automated table record count verification, data audit, and 
--              relational integrity checks confirming 3,500+ records in the catalog.
-- =====================================================================================

USE music_store_db;

-- -------------------------------------------------------------------------------------
-- 1. RECORD COUNT AUDIT ACROSS ALL 11 NORMALIZED TABLES
-- -------------------------------------------------------------------------------------
-- This query provides a single unified audit verifying total ingested records across 
-- all 11 normalized tables, validating the catalog scale (3,500+ tracks).
SELECT 'employee' AS table_name, COUNT(*) AS total_records FROM employee
UNION ALL
SELECT 'customer', COUNT(*) FROM customer
UNION ALL
SELECT 'invoice', COUNT(*) FROM invoice
UNION ALL
SELECT 'invoice_line', COUNT(*) FROM invoice_line
UNION ALL
SELECT 'artist', COUNT(*) FROM artist
UNION ALL
SELECT 'album', COUNT(*) FROM album
UNION ALL
SELECT 'track', COUNT(*) FROM track
UNION ALL
SELECT 'genre', COUNT(*) FROM genre
UNION ALL
SELECT 'media_type', COUNT(*) FROM media_type
UNION ALL
SELECT 'playlist', COUNT(*) FROM playlist
UNION ALL
SELECT 'playlist_track', COUNT(*) FROM playlist_track;

-- Expected Record Counts:
-- +----------------+---------------+
-- | table_name     | total_records |
-- +----------------+---------------+
-- | employee       | 9             |
-- | customer       | 59            |
-- | invoice        | 614           |
-- | invoice_line   | 4,757         |
-- | artist         | 275           |
-- | album          | 347           |
-- | track          | 3,503         |  <-- Confirms 3,500+ catalog tracks
-- | genre          | 25            |
-- | media_type     | 5             |
-- | playlist       | 18            |
-- | playlist_track | 8,715         |
-- +----------------+---------------+
-- | TOTAL RECORDS  | 18,327        |
-- +----------------+---------------+

-- -------------------------------------------------------------------------------------
-- 2. HIGH-LEVEL COMMERCIAL HEALTH CHECK
-- -------------------------------------------------------------------------------------
SELECT 
    COUNT(DISTINCT i.invoice_id) AS total_orders,
    COUNT(DISTINCT i.customer_id) AS active_customers,
    COUNT(DISTINCT il.track_id) AS distinct_tracks_sold,
    ROUND(SUM(i.total), 2) AS gross_revenue,
    ROUND(AVG(i.total), 2) AS average_order_value,
    MIN(i.invoice_date) AS earliest_transaction,
    MAX(i.invoice_date) AS latest_transaction
FROM invoice i
JOIN invoice_line il ON i.invoice_id = il.invoice_id;

-- -------------------------------------------------------------------------------------
-- 3. ORPHAN RECORD & REFERENTIAL INTEGRITY AUDIT
-- -------------------------------------------------------------------------------------
-- Ensure 100% referential integrity without orphan records
SELECT 
    (SELECT COUNT(*) FROM invoice WHERE customer_id NOT IN (SELECT customer_id FROM customer)) AS orphan_invoices,
    (SELECT COUNT(*) FROM invoice_line WHERE invoice_id NOT IN (SELECT invoice_id FROM invoice)) AS orphan_invoice_lines,
    (SELECT COUNT(*) FROM invoice_line WHERE track_id NOT IN (SELECT track_id FROM track)) AS orphan_line_tracks,
    (SELECT COUNT(*) FROM track WHERE album_id IS NOT NULL AND album_id NOT IN (SELECT album_id FROM album)) AS orphan_track_albums;
