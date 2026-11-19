# 🎯 Interview Defense Guide: Music Store Business Analytics using SQL

This guide provides verbatim talking points, architectural explanations, and technical rationales for every single bullet point written on your resume.

---

## 🎙️ 1. The 60-Second Elevator Pitch
> *"In this project, I performed commercial and customer analytics on an international digital music retail platform using MySQL. I worked with an 11-table normalized relational database comprising over 18,000 total records and a 3,500+ track catalog. Rather than just running basic lookups, I structured the analysis to answer executive-level business questions: identifying top international cities like Prague for live promotional events, evaluating rock catalog leaders, ranking Customer Lifetime Value (CLV) and segmenting customers into loyalty tiers using CTEs and DENSE_RANK, evaluating business growth and customer retention rates, and uncovering country-wise music genre consumption patterns."*

---

## 🔍 2. Resume Bullet Point Deep Dive & Interview Defense

### Resume Bullet 1:
> *"Imported and structured an 11-table normalized relational database across 3,500+ records in MySQL to evaluate business growth, customer retention, and catalog performance."*

#### Likely Interviewer Question:
**"How did you structure and normalize the database? How did you evaluate customer retention?"**

#### Your Answer:
- **Normalization (3NF)**:
  - The database is structured in Third Normal Form (3NF) to eliminate data redundancy and anomalies.
  - Transactions are separated into **`invoice`** (header: customer, date, total, billing location) and **`invoice_line`** (line-item details: track, unit price, quantity).
  - The music catalog separates **`artist`** (artist ID, name) from **`album`** (album ID, title, artist ID) and **`track`** (track ID, name, milliseconds, unit price, foreign keys to album, genre, and media_type).
  - Many-to-many playlist associations are handled via a dedicated junction table: **`playlist_track`**.
- **Customer Retention**:
  - *"To evaluate retention, I used a CTE to aggregate total orders per customer, then applied `CASE WHEN order_frequency > 1 THEN 1 ELSE 0 END` to distinguish repeat buyers from one-time purchasers and calculate the store's retention rate."*
- **Data Scale**:
  - The core product catalog table (`track`) contains **3,503 records** (hence "3,500+ records").
  - Across all 11 tables combined, the database contains **18,327 records**.

---

### Resume Bullet 2:
> *"Executed multi-table INNER JOINs, nested subqueries, and aggregations to identify high-spending customer cohorts, top catalog rock artists, and revenue-maximizing global cities for promotional music events."*

#### Likely Interviewer Question:
**"Walk me through how you identified the city for the promotional event and how you joined tables."**

#### Your Answer:
- **Event City Identification**:
  - *"We wanted to find where the business has the highest commercial density to throw a promotional music festival. I aggregated invoice totals grouped by `billing_city` and `billing_country`, computing both cumulative gross revenue and Average Order Value (AOV)."*
  - *"The results showed that **Prague, Czech Republic** ranked #1 with **$273.24** in revenue across 30 orders and an AOV of **$9.11**, outperforming Mountain View ($169.29) and London ($166.32)."*
- **Rock Artist Footprint**:
  - *"To find rock catalog leaders, I executed a 4-table INNER JOIN connecting `artist` ➔ `album` ➔ `track` ➔ `genre`, filtering on `genre.name = 'Rock'`. **Led Zeppelin** ranked first with 114 rock tracks, followed by **U2** (112), **Deep Purple** (92), and **Iron Maiden** (81)."*
- **Nested Subquery Audience Targeting**:
  - *"To target rock music listeners for promotional outreach without duplicating customer records, I used a nested subquery: filtering `customer` records where `track_id IN (SELECT track_id FROM track JOIN genre WHERE genre.name = 'Rock')`."*

---

### Resume Bullet 3:
> *"Leveraged Common Table Expressions (CTEs) and window functions (DENSE_RANK) to segment customer lifetime value (CLV) into loyalty tiers and uncover country-wise music genre consumption patterns."*

#### Likely Interviewer Question 1:
**"How did you calculate Customer Lifetime Value (CLV) and assign loyalty tiers?"**

#### Your Answer:
- *"I created a Common Table Expression (CTE) called `customer_clv` that aggregated total spend per customer by joining the `customer` and `invoice` tables."*
- *"Inside the CTE, I applied the **`DENSE_RANK() OVER (ORDER BY SUM(total) DESC)`** window function to assign every customer an ordinal ranking from highest to lowest spender."*
- *"Then, in the main query, I used a clean **`CASE WHEN`** statement to bucket them into clear business loyalty tiers:*
  - *Platinum Tier: Customers spending **$100+**.*
  - *Gold Tier: Customers spending **$75 - $99.99**.*
  - *Silver Tier: Customers spending **$50 - $74.99**.*
  - *Bronze Tier: Customers spending **under $50**.*"
- *"This combination of CTE, DENSE_RANK, and conditional logic gave marketing an immediate view of top customers for VIP loyalty perks."*

---

#### Likely Interviewer Question 2:
**"Why did you choose `DENSE_RANK()` instead of `ROW_NUMBER()` or `RANK()` for country genre consumption patterns?"**

#### Your Answer:
- *"When identifying the top genre per country, two genres might tie with the exact same number of track purchases and revenue."*
- *"`ROW_NUMBER()` arbitrarily picks one genre and ignores the tie, which distorts business reality."*
- *"`RANK()` handles ties, but it skips the next rank (e.g., 1, 1, 3), creating ranking gaps."*
- *"`DENSE_RANK()` gracefully preserves tied top genres (both receive Rank 1) without skipping ordinal numbers (1, 1, 2). Filtering by `WHERE genre_rank = 1` guarantees that all legitimate top genres in a country are captured."*
- *"This query revealed that while **Rock** is #1 in the US, Canada, Brazil, and Germany, **Alternative & Punk** is the #1 genre in Argentina."*

---

## 💡 3. Key SQL Syntax Quick Reference

### Window Function: DENSE_RANK() for Spender Ranking
```sql
WITH customer_clv AS (
    SELECT customer_id, SUM(total) AS total_spend,
           DENSE_RANK() OVER (ORDER BY SUM(total) DESC) AS customer_rank
    FROM invoice
    GROUP BY customer_id
)
SELECT customer_id, total_spend, customer_rank,
       CASE 
           WHEN total_spend >= 100 THEN 'Platinum'
           WHEN total_spend >= 75  THEN 'Gold'
           WHEN total_spend >= 50  THEN 'Silver'
           ELSE 'Bronze'
       END AS loyalty_tier
FROM customer_clv;
```

### Customer Retention Rate (CTE + CASE WHEN)
```sql
WITH customer_orders AS (
    SELECT customer_id, COUNT(invoice_id) AS order_freq
    FROM invoice
    GROUP BY customer_id
)
SELECT 
    COUNT(customer_id) AS total_customers,
    SUM(CASE WHEN order_freq > 1 THEN 1 ELSE 0 END) AS repeat_customers,
    ROUND((SUM(CASE WHEN order_freq > 1 THEN 1 ELSE 0 END) * 100.0) / COUNT(customer_id), 2) AS retention_rate_pct
FROM customer_orders;
```

### Window Function: DENSE_RANK() for Regional Preferences
```sql
WITH ranked_genres AS (
    SELECT country, genre_name, COUNT(*) AS units,
           DENSE_RANK() OVER (PARTITION BY country ORDER BY COUNT(*) DESC) AS rnk
    FROM country_sales_view 
    GROUP BY country, genre_name
)
SELECT * FROM ranked_genres WHERE rnk = 1;
```
