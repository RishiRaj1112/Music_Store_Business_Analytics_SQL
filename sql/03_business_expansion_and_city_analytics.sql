-- =====================================================================================
-- Project: Music Store Business Analytics using SQL
-- Database: MySQL 8.0+
-- File: 03_business_expansion_and_city_analytics.sql
-- Description: Multi-table INNER JOINs, aggregations, and subqueries to identify 
--              revenue-maximizing global cities for promotional music events, 
--              international market penetration, and internal sales performance.
-- Resume Focus: "revenue-maximizing global cities for promotional music events"
-- =====================================================================================

USE music_store_db;

-- -------------------------------------------------------------------------------------
-- 1. REVENUE-MAXIMIZING GLOBAL CITIES FOR PROMOTIONAL MUSIC FESTIVAL
-- -------------------------------------------------------------------------------------
-- Business Objective: Marketing wants to host a live promotional music festival 
-- in the city generating the highest cumulative revenue and transaction density.
-- Evaluates total gross revenue, order volume, unique customers, and AOV.

SELECT 
    i.billing_city,
    i.billing_country,
    COUNT(DISTINCT i.customer_id) AS unique_customers,
    COUNT(i.invoice_id) AS total_orders,
    ROUND(SUM(i.total), 2) AS total_revenue,
    ROUND(AVG(i.total), 2) AS avg_order_value,
    ROUND((SUM(i.total) / (SELECT SUM(total) FROM invoice)) * 100, 2) AS pct_of_global_revenue
FROM invoice i
GROUP BY i.billing_city, i.billing_country
ORDER BY total_revenue DESC
LIMIT 10;

-- Key Finding:
-- Prague, Czech Republic leads globally with $273.24 generated across 30 orders 
-- and an average order value of $9.11, making it the #1 candidate city for live events.


-- -------------------------------------------------------------------------------------
-- 2. GLOBAL COUNTRY PERFORMANCE & MARKET PENETRATION
-- -------------------------------------------------------------------------------------
-- Business Objective: Determine top international customer markets by revenue and order volume.

SELECT 
    i.billing_country,
    COUNT(DISTINCT i.customer_id) AS customer_count,
    COUNT(i.invoice_id) AS total_invoices,
    ROUND(SUM(i.total), 2) AS total_revenue,
    ROUND(AVG(i.total), 2) AS avg_invoice_value,
    ROUND((SUM(i.total) / (SELECT SUM(total) FROM invoice)) * 100, 2) AS revenue_share_pct
FROM invoice i
GROUP BY i.billing_country
ORDER BY total_revenue DESC;


-- -------------------------------------------------------------------------------------
-- 3. INTERNAL ORGANIZATIONAL HIERARCHY & SENIOR LEADERSHIP
-- -------------------------------------------------------------------------------------
-- Business Objective: Identify the senior-most leadership hierarchy and reporting structure.

SELECT 
    e.employee_id,
    CONCAT(e.first_name, ' ', e.last_name) AS employee_name,
    e.title,
    e.levels,
    CONCAT(m.first_name, ' ', m.last_name) AS reports_to_manager
FROM employee e
LEFT JOIN employee m ON e.reports_to = m.employee_id
ORDER BY e.levels DESC, e.employee_id ASC;


-- -------------------------------------------------------------------------------------
-- 4. SALES SUPPORT AGENT COMMERCIAL CONTRIBUTION
-- -------------------------------------------------------------------------------------
-- Business Objective: Measure revenue attributed to each dedicated support representative.

SELECT 
    e.employee_id,
    CONCAT(e.first_name, ' ', e.last_name) AS support_agent_name,
    COUNT(DISTINCT c.customer_id) AS assigned_customers,
    COUNT(i.invoice_id) AS total_orders_closed,
    ROUND(SUM(i.total), 2) AS total_revenue_generated,
    ROUND(AVG(i.total), 2) AS avg_order_value
FROM employee e
JOIN customer c ON e.employee_id = c.support_rep_id
JOIN invoice i ON c.customer_id = i.customer_id
GROUP BY e.employee_id, support_agent_name
ORDER BY total_revenue_generated DESC;
