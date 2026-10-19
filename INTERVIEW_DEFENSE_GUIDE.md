# 🎯 Interview Defense Guide: Music Store Business Analytics using SQL

This guide provides verbatim talking points, architectural explanations, and technical rationales for every single bullet point written on your resume.

---

## 🎙️ 1. The 60-Second Elevator Pitch
> *"In this project, I performed commercial and customer analytics on an international digital music retail platform using MySQL. I worked with an 11-table normalized relational database comprising over 18,000 total records and a 3,500+ track catalog. Rather than just running basic lookups, I structured the analysis to answer executive-level business questions: identifying top international cities like Prague for live promotional events, evaluating rock catalog leaders, leveraging NTILE window functions to segment Customer Lifetime Value into loyalty tiers, utilizing LAG to analyze Month-over-Month revenue momentum and repurchase intervals, and applying DENSE_RANK within CTEs to identify localized genre consumption preferences across global markets."*

---

## 🔍 2. Resume Bullet Point Deep Dive & Interview Defense

### Resume Bullet 1:
> *"Imported and structured an 11-table normalized relational database across 3,500+ records in MySQL to evaluate business growth, customer retention, and catalog performance."*

#### Likely Interviewer Question:
**"How did you structure and normalize the database? Why does your resume say 3,500+ records?"**

#### Your Answer:
- **Normalization (3NF)**:
  - The database is structured in Third Normal Form (3NF) to eliminate data redundancy and anomalies.
  - Transactions are separated into **`invoice`** (header: customer, date, total, billing location) and **`invoice_line`** (line-item details: track, unit price, quantity).
  - The music catalog separates **`artist`** (artist ID, name) from **`album`** (album ID, title, artist ID) and **`track`** (track ID, name, milliseconds, unit price, foreign keys to album, genre, and media_type).
  - Many-to-many playlist associations are handled via a dedicated junction table: **`playlist_track`**.
- **Data Scale**:
  - The core product catalog table (`track`) contains **3,503 records** (hence "3,500+ records").
  - Across all 11 tables combined, the database contains **18,327 records** (with `playlist_track` having 8,715 records and `invoice_line` having 4,757 records).
- **Relational Integrity & Indexing**:
  - Defined explicit Foreign Key constraints with `ON DELETE CASCADE` on transaction details and `ON DELETE RESTRICT` on catalog lookups.
  - Added B-Tree composite indexes on foreign keys (`customer_id`, `invoice_id`, `genre_id`, `track_id`) to accelerate multi-table joins.

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
> *"Leveraged Common Table Expressions (CTEs) and window functions (DENSE_RANK, NTILE, LAG) to segment customer lifetime value (CLV) into loyalty tiers and uncover country-wise music genre consumption patterns."*

#### Likely Interviewer Question 1:
**"Why did you use `NTILE` for CLV loyalty tiers instead of hardcoded `CASE WHEN` spending brackets?"**

#### Your Answer:
- *"Hardcoding arbitrary spend thresholds (e.g., spend > $100 = VIP) introduces subjective bias and doesn't adapt dynamically as revenue scales."*
- *"By using **`NTILE(4) OVER (ORDER BY SUM(total) DESC)`**, I mathematically segmented the customer base into 4 statistically balanced quartiles:*
  - *Quartile 1 (Platinum): Top 25% of spenders.*
  - *Quartile 2 (Gold): 50th to 75th percentile.*
  - *Quartile 3 (Silver): 25th to 50th percentile.*
  - *Quartile 4 (Bronze): Bottom 25%.*
- *"The analysis revealed that the **Platinum tier generates 33.9% of our store's total revenue** with an average spend of **$106.59**, proving that retention efforts should heavily prioritize this top quartile."*

---

#### Likely Interviewer Question 2:
**"How did you use `LAG()` in your retention and Month-over-Month analysis?"**

#### Your Answer:
- **Month-over-Month (MoM) Growth**:
  - *"I aggregated revenue by year-month into a CTE, then used `LAG(monthly_revenue, 1) OVER (ORDER BY sales_month)` to pull the prior month's revenue onto the current row."*
  - *"From there, I calculated both dollar variance `(current - prior)` and percentage growth rate `((current - prior) / prior) * 100`, which revealed revenue acceleration in months like April (+37.14%) and contraction in others."*
- **Repurchase Cadence & Retention**:
  - *"I also applied `LAG(invoice_date, 1) OVER (PARTITION BY customer_id ORDER BY invoice_date)` to calculate the number of days between successive purchases for repeat customers using `DATEDIFF()`."*
  - *"This identified an average repurchase cycle of approximately 60 days, establishing a clear threshold for automated re-engagement triggers."*

---

#### Likely Interviewer Question 3:
**"Why did you choose `DENSE_RANK()` instead of `ROW_NUMBER()` or `RANK()` for country genre consumption patterns?"**

#### Your Answer:
- *"When identifying the top genre per country, two genres might tie with the exact same number of track purchases and revenue."*
- *"`ROW_NUMBER()` arbitrarily picks one genre and ignores the tie, which distorts business reality."*
- *"`RANK()` handles ties, but it skips the next rank (e.g., 1, 1, 3), which causes ranking gaps."*
- *"`DENSE_RANK()` gracefully preserves tied top genres (both receive Rank 1) without skipping ordinal numbers (1, 1, 2). Filtering by `WHERE genre_rank = 1` guarantees that all legitimate top genres in a country are captured."*
- *"This query revealed that while **Rock** is #1 in the US, Canada, Brazil, and Germany, **Alternative & Punk** is the #1 genre in Argentina."*

---

## 💡 3. Key SQL Syntax Quick Reference

### Window Function: NTILE(4)
```sql
WITH clv AS (
    SELECT customer_id, SUM(total) AS total_spend,
           NTILE(4) OVER (ORDER BY SUM(total) DESC) AS quartile
    FROM invoice GROUP BY customer_id
)
SELECT quartile, COUNT(*), MIN(total_spend), MAX(total_spend), AVG(total_spend)
FROM clv GROUP BY quartile;
```

### Window Function: LAG()
```sql
SELECT sales_month, monthly_revenue,
       LAG(monthly_revenue, 1) OVER (ORDER BY sales_month) AS prev_rev,
       ROUND(((monthly_revenue - LAG(monthly_revenue, 1) OVER (ORDER BY sales_month)) / 
              LAG(monthly_revenue, 1) OVER (ORDER BY sales_month)) * 100, 2) AS mom_pct
FROM monthly_summary;
```

### Window Function: DENSE_RANK()
```sql
WITH ranked_genres AS (
    SELECT country, genre_name, COUNT(*) AS units,
           DENSE_RANK() OVER (PARTITION BY country ORDER BY COUNT(*) DESC) AS rnk
    FROM country_sales_view GROUP BY country, genre_name
)
SELECT * FROM ranked_genres WHERE rnk = 1;
```
