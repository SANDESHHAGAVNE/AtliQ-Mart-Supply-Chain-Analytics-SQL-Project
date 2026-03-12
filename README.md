# AtliQ-Mart-Supply-Chain-Analytics-SQL-Project

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

# 4️⃣ ER Diagram

Relationship between the tables:

```
dim_customers
     |
     | customer_id
     |
fact_orders_aggregate
     |
     | order_id
     |
fact_order_lines
     |
     | product_id
     |
dim_products

fact_orders_aggregate
     |
     | customer_id
     |
dim_targets_orders

fact_orders_aggregate
     |
     | new_order_placement_date
     |
dim_date
```

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

# ❓ Business Questions Solved Using SQL

The following business questions were analyzed using SQL.

1. How many orders were placed in each month?
2. What is the weekly trend of late deliveries?
3. Identify the month with the highest number of orders that were not delivered in full.
4. Find the difference between agreed delivery dates and actual delivery dates for all orders.
5. What is the OTIF performance for each city?
6. What is the total number of orders delivered late?
7. List the product categories along with the number of unique products in each category.
8. Identify the busiest week in terms of order placement.
9. Which product categories perform best in terms of meeting OTIF targets?
10. What is the percentage of orders that met OTIF criteria?
11. How many orders were placed on weekends versus weekdays?
12. How many orders were delivered on time but not in full?
13. Which product category has the highest order quantity?
14. Calculate the percentage of orders delivered on-time for each customer.
15. Calculate the percentage of orders successfully delivered (delivery_qty = order_qty).
16. For each product category, calculate the percentage of orders delivered on time.
17. Show the customers who exceeded their "ontime_target %".
18. Find customers who placed orders with total quantity greater than average order quantity.
19. Identify customers performing below target for both OT and IF metrics.
20. Identify customers with OT and IF performance below 80%.
21. Calculate monthly OT% and IF% per customer and compare with targets.
22. Identify categories with highest and lowest on-time delivery rates.

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
