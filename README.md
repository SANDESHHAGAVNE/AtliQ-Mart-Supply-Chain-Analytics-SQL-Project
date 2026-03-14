# 🚚 AtliQ Mart Supply Chain Analytics SQL Project

---

# 🔍 Problem Statement

AtliQ Mart is a growing **FMCG manufacturer headquartered in Gujarat, India**. The company supplies products such as dairy items, food products, and beverages to multiple retail customers across several cities.

Recently, some key customers have **not renewed their annual contracts** due to **service-level issues**. Internal investigations revealed that many orders were:

* Not delivered **on time**
* Not delivered **in full quantity**

To address this issue, the management wants to **analyze supply chain delivery performance** using SQL and measure key delivery service metrics.

The objective of this project is to analyze delivery performance using the following KPIs:

* **On-Time Delivery (OT%)**
* **In-Full Delivery (IF%)**
* **On-Time In-Full (OTIF%)**

This analysis helps identify **underperforming customers, delivery patterns, and operational inefficiencies**.

---

#  👥 Stakeholders

The main stakeholders for this project include:

**Supply Chain Team**

* Responsible for delivery operations.

**Logistics Team**

* Manages transportation and order dispatch.

**Customer Relationship Managers**

* Handles key client relationships.

**Senior Management**

* Uses performance metrics to make strategic decisions.

**Data Analytics Team**

* Builds analysis and insights to improve delivery performance.

---

# 🗂️ Data Exploration

The dataset consists of **six tables** used to analyze order and delivery performance.

### 1. dim_customers

Customer information.

| Column        | Description          |
| ------------- | -------------------- |
| customer_id   | Unique customer ID   |
| customer_name | Name of the customer |
| city          | Customer city        |

---

### 2. dim_products

Product information.

| Column       | Description       |
| ------------ | ----------------- |
| product_id   | Unique product ID |
| product_name | Product name      |
| category     | Product category  |

---

### 3. dim_date

Calendar dimension.

| Column  | Description    |
| ------- | -------------- |
| date    | Date           |
| mmm_yy  | Month and year |
| week_no | Week number    |

---

### 4. dim_targets_orders

Customer delivery targets.

| Column         | Description             |
| -------------- | ----------------------- |
| customer_id    | Customer identifier     |
| ontime_target% | On-time delivery target |
| infull_target% | In-full delivery target |
| otif_target%   | OTIF target             |

---

### 5. fact_order_lines

Order line-level data.

| Column               | Description                     |
| -------------------- | ------------------------------- |
| order_id             | Order identifier                |
| order_placement_date | Date order was placed           |
| customer_id          | Customer ID                     |
| product_id           | Product ID                      |
| order_qty            | Ordered quantity                |
| agreed_delivery_date | Expected delivery date          |
| actual_delivery_date | Actual delivery date            |
| delivery_qty         | Quantity delivered              |
| In Full              | Whether full quantity delivered |
| On Time              | Whether delivered on time       |
| On Time In Full      | Both conditions satisfied       |

---

### 6. fact_orders_aggregate

Order-level delivery metrics.

| Column               | Description                   |
| -------------------- | ----------------------------- |
| order_id             | Order identifier              |
| customer_id          | Customer ID                   |
| order_placement_date | Order date                    |
| on_time              | Delivered on time             |
| in_full              | Delivered in full             |
| otif                 | Delivered on time and in full |

---

# 🗺️ ER Diagram

Relationship between the tables:


<h2 align="center">ER Diagram</h2>

<p align="center">
<img src="https://raw.githubusercontent.com/SANDESHHAGAVNE/AtliQ-Mart-Supply-Chain-Analytics-SQL-Project/main/ER%20Diagram.png" width="900">
</p>

This schema enables analysis across **customers, products, delivery performance, and time**.

---

# 🧹 Data Cleaning

Before performing analysis, several data cleaning steps were performed.

## Removing Encoding Issues

Some column names contained hidden characters.

```sql
ALTER TABLE dim_date
RENAME COLUMN ï»¿date TO date;

ALTER TABLE fact_orders_aggregate
RENAME COLUMN ï»¿order_id TO order_id;
```

---

## Checking for Null Values

Null values were checked across all tables.

Example:

```sql
SELECT
COUNT(*) AS total_rows,
SUM(customer_id IS NULL) AS customer_id_nulls
FROM dim_customers;
```

This process was repeated for:

* dim_products
* dim_date
* dim_targets_orders
* fact_order_lines
* fact_orders_aggregate

---

## Standardizing Date Columns

Date fields were stored as **text**, so they were converted into proper **DATE format**.

### Adding new date columns

```sql
ALTER TABLE dim_date
ADD COLUMN new_date DATE,
ADD COLUMN new_mmm_yy INT;
```

### Updating the values

```sql
UPDATE dim_date
SET 
new_date = STR_TO_DATE(date,'%d-%b-%y'),
new_mmm_yy = MONTH(STR_TO_DATE(mmm_yy,'%d-%b-%y'));
```

---

## Fixing Week Number Data Type

```sql
ALTER TABLE dim_date
MODIFY COLUMN week_no VARCHAR(5);
```

---

## Cleaning fact_order_lines Date Columns

New columns were created to extract:

* Order placement day
* Delivery day
* Proper DATE format columns

```sql
ALTER TABLE fact_order_lines
ADD COLUMN order_placement_day VARCHAR(10),
ADD COLUMN new_order_placement_date DATE,
ADD COLUMN agreed_delivery_day VARCHAR(10),
ADD COLUMN new_agreed_delivery_date DATE,
ADD COLUMN actual_delivery_day VARCHAR(10),
ADD COLUMN new_actual_delivery_date DATE;
```

Then values were updated:

```sql
UPDATE fact_order_lines
SET
order_placement_day = SUBSTRING_INDEX(order_placement_date,',',1),
new_order_placement_date = STR_TO_DATE(SUBSTRING_INDEX(order_placement_date, ', ', -2), '%M %e, %Y'),
agreed_delivery_day = SUBSTRING_INDEX(agreed_delivery_date,',',1),
new_agreed_delivery_date = STR_TO_DATE(SUBSTRING_INDEX(agreed_delivery_date,',',-2), '%M %e, %Y'),
actual_delivery_day = SUBSTRING_INDEX(actual_delivery_date,',',1),
new_actual_delivery_date = STR_TO_DATE(SUBSTRING_INDEX(actual_delivery_date,',',-2),'%M %e, %Y');
```

Old columns were removed afterwards.

---

## Cleaning fact_orders_aggregate Date Column

```sql
ALTER TABLE fact_orders_aggregate
ADD COLUMN new_order_placement_date DATE;

UPDATE fact_orders_aggregate
SET new_order_placement_date =
STR_TO_DATE(order_placement_date,'%d-%b-%y');
```

---

# 🧩 SQL Business Questions Solved


The analysis focuses on **order performance, delivery efficiency, product demand, and customer service metrics**.

These queries demonstrate the use of:

* Joins
* Aggregations
* Date Functions
* Conditional Logic
* Subqueries
* Common Table Expressions (CTEs)

---

# 📊 Order Analysis

### 1️⃣ How many orders were placed in each month?

```sql
SELECT d.new_mmm_yy AS Month, COUNT(f.order_id) AS total_orders
FROM fact_orders_aggregate f
JOIN dim_date d ON f.new_order_placement_date = d.new_date
GROUP BY d.new_mmm_yy;
```

---

### 2️⃣ What is the weekly trend of late deliveries?

```sql
SELECT d.week_no, COUNT(f.order_id) AS late_deliveries
FROM fact_orders_aggregate f
JOIN dim_date d ON f.new_order_placement_date = d.new_date
WHERE f.on_time = 0
GROUP BY d.week_no
ORDER BY d.week_no;
```

---

### 3️⃣ Identify the month with the highest number of orders that were not delivered in full

```sql
SELECT d.new_mmm_yy AS Month, COUNT(f.order_id) AS not_in_full_orders
FROM fact_orders_aggregate f
JOIN dim_date d ON f.new_order_placement_date = d.new_date
WHERE f.in_full = 0
GROUP BY d.new_mmm_yy
ORDER BY not_in_full_orders DESC LIMIT 1;
```

---

# 🚚 Delivery Performance Analysis

### 4️⃣ Find the difference between agreed delivery dates and actual delivery dates

```sql
SELECT order_id, new_agreed_delivery_date, new_actual_delivery_date,
DATEDIFF(new_actual_delivery_date, new_agreed_delivery_date) AS days_difference
FROM fact_order_lines;
```

---

### 5️⃣ What is the OTIF performance for each city?

```sql
SELECT c.city, ROUND(AVG(f.otif) * 100, 2) AS otif_pct
FROM fact_orders_aggregate f
JOIN dim_customers c ON f.customer_id = c.customer_id
GROUP BY c.city;
```

---

### 6️⃣ What is the total number of orders delivered late?

```sql
SELECT COUNT(order_id) AS late_orders
FROM fact_orders_aggregate
WHERE on_time = 0;
```

---

# 🛒 Product Analysis

### 7️⃣ List the product categories and the number of unique products in each category

```sql
SELECT category, COUNT(DISTINCT product_id) AS unique_products
FROM dim_products
GROUP BY category;
```

---

### 8️⃣ Identify the busiest week in terms of order placement

```sql
SELECT d.week_no, COUNT(f.order_id) AS order_count
FROM fact_orders_aggregate f
JOIN dim_date d ON f.new_order_placement_date = d.new_date
GROUP BY d.week_no
ORDER BY order_count DESC LIMIT 1;
```

---

### 9️⃣ Which product categories perform best in terms of meeting OTIF targets?

```sql
SELECT p.category, ROUND(AVG(fol.`On Time In Full`) * 100, 2) AS otif_performance
FROM fact_order_lines fol
JOIN dim_products p ON fol.product_id = p.product_id
GROUP BY p.category
ORDER BY otif_performance DESC;
```

---

# 📈 KPI Analysis

### 🔟 What is the percentage of orders that met OTIF criteria?

```sql
SELECT ROUND(AVG(otif) * 100, 2) AS total_otif_pct
FROM fact_orders_aggregate;
```

---

### 1️⃣1️⃣ How many orders were placed on weekends versus weekdays?

```sql
SELECT 
CASE WHEN DAYOFWEEK(new_order_placement_date) IN (1,7) THEN 'Weekend'
ELSE 'Weekday'
END AS day_type,
COUNT(order_id) AS order_count
FROM fact_orders_aggregate
GROUP BY day_type;
```

---

### 1️⃣2️⃣ How many orders were delivered on time but not in full?

```sql
SELECT COUNT(order_id) AS order_count
FROM fact_orders_aggregate
WHERE on_time = 1 AND in_full = 0;
```

---

# 📦 Product Demand Insights

### 1️⃣3️⃣ Which product category has the highest order quantity?

```sql
SELECT p.category, SUM(fol.order_qty) AS total_qty
FROM fact_order_lines fol
JOIN dim_products p ON fol.product_id = p.product_id
GROUP BY p.category
ORDER BY total_qty DESC LIMIT 1;
```

---

# 👥 Customer Performance Analysis

### 1️⃣4️⃣ Calculate the percentage of orders delivered on-time for each customer

```sql
SELECT customer_id,
COUNT(order_id) AS total_orders,
SUM(on_time) AS on_time_orders,
ROUND((SUM(on_time)/COUNT(order_id))*100,2) AS on_time_percentage
FROM fact_orders_aggregate
GROUP BY customer_id;
```

---

### 1️⃣5️⃣ Calculate the percentage of orders successfully delivered for each customer

```sql
SELECT customer_id,
COUNT(order_id) AS total_orders,
SUM(CASE WHEN delivery_qty = order_qty THEN 1 ELSE 0 END) AS successful_orders,
ROUND(SUM(CASE WHEN delivery_qty = order_qty THEN 1 ELSE 0 END)/COUNT(order_id)*100,2) AS success_percentage
FROM fact_order_lines
GROUP BY customer_id;
```

---

# 📊 Category Performance

### 1️⃣6️⃣ For each product category, calculate the percentage of orders delivered on time

```sql
SELECT p.category,
COUNT(f.order_id) AS total_orders,
SUM(f.`On Time`) AS on_time_orders,
ROUND(SUM(f.`On Time`)/COUNT(f.order_id)*100,2) AS on_time_percentage
FROM fact_order_lines f
JOIN dim_products p
ON f.product_id = p.product_id
GROUP BY p.category;
```

---

# 🎯 Target vs Actual Performance

### 1️⃣7️⃣ Show the customers who exceeded their on-time delivery target

```sql
WITH cte AS (
SELECT c.customer_name,
ROUND(AVG(f.on_time)*100,2) AS actual_ot,
t.`ontime_target%`,
ROUND(AVG(f.on_time)*100,2) - t.`ontime_target%` AS gap
FROM fact_orders_aggregate f
JOIN dim_targets_orders t
ON f.customer_id = t.customer_id
JOIN dim_customers c
ON f.customer_id = c.customer_id
GROUP BY c.customer_name, t.`ontime_target%`
)

SELECT * FROM cte;
```

---

# 🔍 Advanced SQL Analysis

### 1️⃣8️⃣ Find customers who placed orders with quantity greater than average order quantity

```sql
SELECT customer_id,
SUM(order_qty) AS total_quantity
FROM fact_order_lines
GROUP BY customer_id
HAVING SUM(order_qty) >
(
SELECT AVG(order_qty)
FROM fact_order_lines
);
```

---

### 1️⃣9️⃣ Identify customers performing below target for both OT and IF

```sql
WITH CustomerPerformance AS (
SELECT f.customer_id,
AVG(f.on_time)*100 AS actual_ot,
AVG(f.in_full)*100 AS actual_if,
t.`ontime_target%`,
t.`infull_target%`
FROM fact_orders_aggregate f
JOIN dim_targets_orders t
ON f.customer_id = t.customer_id
GROUP BY f.customer_id, t.`ontime_target%`, t.`infull_target%`
)

SELECT *
FROM CustomerPerformance
WHERE actual_ot < `ontime_target%`
AND actual_if < `infull_target%`;
```

---

### 2️⃣0️⃣ Customers with OT and IF performance below 80%

```sql
WITH customer_performance AS (
SELECT customer_id,
ROUND(AVG(on_time)*100,2) AS on_time_percentage,
ROUND(AVG(in_full)*100,2) AS in_full_percentage
FROM fact_orders_aggregate
GROUP BY customer_id
)

SELECT *
FROM customer_performance
WHERE on_time_percentage < 80
AND in_full_percentage < 80;
```

---

### 2️⃣1️⃣ Monthly OT% and IF% per customer compared with targets

```sql
SELECT d.new_mmm_yy, c.customer_name,
ROUND(AVG(f.on_time)*100,2) AS monthly_ot_pct,
t.`ontime_target%`,
ROUND(AVG(f.in_full)*100,2) AS monthly_if_pct,
t.`infull_target%`
FROM fact_orders_aggregate f
JOIN dim_date d ON f.new_order_placement_date = d.new_date
JOIN dim_customers c ON f.customer_id = c.customer_id
JOIN dim_targets_orders t ON f.customer_id = t.customer_id
GROUP BY d.new_mmm_yy, c.customer_name, t.`ontime_target%`, t.`infull_target%`;
```

---

### 2️⃣2️⃣ Categories with highest and lowest on-time delivery rates

```sql
SELECT p.category,
ROUND(AVG(fol.`On Time`)*100,2) AS on_time_pct,
COUNT(fol.order_id) AS total_orders
FROM fact_order_lines fol
JOIN dim_products p
ON fol.product_id = p.product_id
GROUP BY p.category
HAVING total_orders > 200
ORDER BY on_time_pct DESC;
```

---

# 📊 Insights

Key findings from the analysis:

* **Total OTIF performance is only 29.02%**, which is significantly low.
* **12,999 orders were delivered late**, indicating operational inefficiencies.
* **Week 20 recorded the highest number of orders (1255)**.
* **Dairy category dominates order volume**, with over **10.5 million total quantity ordered**.
* **Food category has the highest OTIF performance (48.84%)**.
* **Most orders (22,563) were placed on weekdays**, while **9,166 orders were placed on weekends**.
* Some customers such as **Coolblue, Lotus Mart, and Acclaimed Stores** show extremely low on-time delivery performance (~28–30%).

These customers are likely experiencing **major service failures**.

---

# 💡 Suggestions and Recommendations

Based on the analysis, the following improvements are recommended:

### Improve Delivery Scheduling

Many deliveries are late. Optimizing route planning and dispatch scheduling can reduce delays.

### Improve Inventory Planning

Low **In-Full delivery percentages** indicate inventory shortages. Demand forecasting and stock planning must be improved.

### Focus on Underperforming Customers

Customers with OT% around **30%** require immediate operational attention.

### Product-Level Monitoring

The **Dairy category handles the highest order volume**, so improving operations here will significantly improve service levels.

### Real-Time Monitoring Dashboard

Implement a **real-time supply chain performance dashboard** to track OT, IF, and OTIF metrics daily.

---
