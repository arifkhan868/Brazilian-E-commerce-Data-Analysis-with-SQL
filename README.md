# 📊 E-commerce Sales Analysis using SQL  
**A complete end-to-end SQL project analyzing sales, customers, payments, and delivery performance from a Brazilian E-commerce dataset.**

---

## 🧠 Overview
This project explores a real-world dataset to uncover **sales patterns, customer behavior, payment trends, and delivery performance** using SQL.  
All insights were generated using **PostgreSQL**, showcasing real business problem-solving with clean and optimized SQL queries.

---

## 🗂️ Database Schema

**Schema Name:** `target_sql`

| Table Name | Description |
|-------------|--------------|
| orders | Contains order status and timestamps |
| order_items | Includes product, price, and freight info |
| products | Product details including dimensions |
| customers | Customer location data |
| sellers | Seller information |
| payments | Payment details and type |
| geolocation | Geo coordinates of locations |
| order_review | Customer review info |

---

## 🚀 Project Objectives

✅ Analyze sales trends and seasonality  
✅ Identify top-performing and underperforming regions  
✅ Measure delivery speed and efficiency  
✅ Study customer distribution and payment preferences  

---

## 🧩 Key Business Questions Solved

| # | Question | Description |
|--|--|--|
| 1 | What’s the total time range of orders? | Found earliest and latest order timestamps |
| 2 | Which states have the most customers? | Customer distribution by region |
| 3 | Are orders increasing every year? | Year-over-year growth trend |
| 4 | Which months have the highest sales? | Monthly order volume pattern |
| 5 | What time of day are customers most active? | Order count by time slot |
| 6 | How long does delivery take? | Delivery time vs estimated time |
| 7 | Which states have the fastest and slowest deliveries? | Average delivery time by state |
| 8 | What’s the % increase in total payment from 2017 to 2018? | Yearly growth analysis |
| 9 | Which payment types are most used? | Payment trend by type and month |

---

## 🧮 SQL Concepts Used
- ✅ **Joins (INNER / LEFT JOIN)**  
- ✅ **Aggregate Functions** (`SUM`, `AVG`, `COUNT`)  
- ✅ **CTE (WITH Clause)** for temporary views  
- ✅ **Window Functions** (`LEAD`)  
- ✅ **CASE WHEN** for conditional logic  
- ✅ **Date Functions** (`EXTRACT`, `AGE`, `DATE_TRUNC`)  

---

## 🔍 Highlighted Queries & Insights

### 🗓️ 1. Yearly Order Growth Trend
```sql
SELECT
    EXTRACT(YEAR FROM order_purchase_timestamp) AS order_year,
    COUNT(DISTINCT order_id) AS total_orders
FROM target_sql.orders
GROUP BY 1
ORDER BY order_year;
```
**Insight**: Orders have grown significantly year over year, indicating increasing customer adoption and a growing market.

---
### 🌆 2. Customer Ordering Behavior by Time of Day
```
SELECT
    CASE
        WHEN EXTRACT(HOUR FROM order_purchase_timestamp) <= 6 THEN 'Dawn'
        WHEN EXTRACT(HOUR FROM order_purchase_timestamp) BETWEEN 7 AND 12 THEN 'Morning'
        WHEN EXTRACT(HOUR FROM order_purchase_timestamp) BETWEEN 13 AND 18 THEN 'Afternoon'
        ELSE 'Night'
    END AS time_of_day,
    COUNT(order_id) AS total_orders
FROM target_sql.orders
GROUP BY 1
ORDER BY total_orders DESC;
```
Insight: Most customers place orders during the afternoon, showing high engagement after work hours.
---
```
### 💸 3. Year-over-Year Payment Growth (2017 vs 2018)
WITH yearly_growth AS (
    SELECT
        EXTRACT(YEAR FROM s.order_purchase_timestamp) AS order_year,
        SUM(p.payment_value) AS total_payment
    FROM target_sql.orders s
    JOIN target_sql.payment p ON s.order_id = p.order_id
    WHERE EXTRACT(YEAR FROM s.order_purchase_timestamp) IN (2017, 2018)
      AND EXTRACT(MONTH FROM s.order_purchase_timestamp) BETWEEN 1 AND 8
    GROUP BY 1
)
SELECT
    order_year,
    ROUND(((total_payment - LEAD(total_payment) OVER (ORDER BY order_year DESC)) 
        / LEAD(total_payment) OVER (ORDER BY order_year DESC)) * 100, 2) AS percent_increase
FROM yearly_growth;
```
**Insight**: There was a steady increase in payment value from 2017 to 2018, confirming business growth.

---
### 🚚 4. Delivery Performance Analysis
```
SELECT
    order_id,
    EXTRACT(DAY FROM AGE(order_delivered_customer_date, order_purchase_timestamp)) AS days_to_deliver,
    EXTRACT(DAY FROM AGE(order_delivered_customer_date, order_estimated_delivery_date)) AS diff_estimated_delivery
FROM target_sql.orders;
```
**Insight**: Most deliveries occur within 8–10 days, with a few exceeding their estimated delivery dates.
### 🌍 5. Top 5 States with Fastest Delivery
```
SELECT
    c.customer_state,
    AVG(EXTRACT(DAY FROM AGE(o.order_delivered_customer_date, o.order_purchase_timestamp))) AS avg_delivery_days
FROM target_sql.customers c
JOIN target_sql.orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_state
ORDER BY avg_delivery_days ASC
LIMIT 5;
```
**Insight**: Some southern states outperform in delivery speed, potentially due to better logistics and proximity to warehouses








