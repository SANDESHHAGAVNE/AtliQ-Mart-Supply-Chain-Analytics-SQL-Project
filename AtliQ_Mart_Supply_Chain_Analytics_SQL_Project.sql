CREATE DATABASE `Supply Chain 1`;

SELECT * FROM dim_customers;
SELECT * FROM dim_products;
SELECT * FROM dim_date;
SELECT * FROM dim_targets_orders;
SELECT * FROM fact_order_lines;
SELECT * FROM fact_orders_aggregate;

-- Data Cleaning

### Removed Encoding Issues
ALTER TABLE dim_date
RENAME COLUMN ï»¿date TO date;

ALTER TABLE fact_orders_aggregate
RENAME COLUMN ï»¿order_id TO order_id;

### Checking for Null Values
#For dim_customers
SELECT
COUNT(*) AS total_rows,
SUM(customer_id IS NULL) AS customer_id_nulls,
SUM(customer_name IS NULL) AS customer_name_nulls,
SUM(city IS NULL) AS city_nulls
FROM dim_customers;

#For dim_products
SELECT
COUNT(*) AS total_rows,
SUM(product_name IS NULL) AS product_name_nulls,
SUM(product_id IS NULL) AS product_id_nulls,
SUM(category IS NULL) AS category_nulls
FROM dim_products;

#For dim_date
SELECT
COUNT(*) AS total_rows,
SUM(new_date IS NULL) AS date_nulls,
SUM(new_mmm_yy IS NULL) AS mmm_yy_nulls,
SUM(week_no IS NULL) AS week_no_nulls
FROM dim_date;


#For dim_targets_orders
SELECT
COUNT(*) AS total_rows,
SUM(customer_id IS NULL) AS customer_id_nulls,
SUM(`ontime_target%` IS NULL) AS `ontime_target%_nulls`,
SUM(`infull_target%` IS NULL) AS `infull_target%_nulls`,
SUM(`otif_target%` IS NULL) AS `otif_target%_nulls`
FROM dim_targets_orders;


#For fact_order_lines
SELECT
COUNT(*) AS total_rows,
SUM(order_id IS NULL) AS order_id_nulls,
SUM(order_placement_date IS NULL) AS order_placement_date_nulls,
SUM(customer_id IS NULL) AS customer_id_nulls,
SUM(product_id IS NULL) AS product_id_nulls,
SUM(order_qty IS NULL) AS order_qty_nulls,
SUM(agreed_delivery_date IS NULL) AS agreed_delivery_date_nulls,
SUM(actual_delivery_date IS NULL) AS actual_delivery_date_nulls,
SUM(delivery_qty IS NULL) AS delivery_qty_nulls,
SUM(`In Full` IS NULL) AS In_Full_nulls,
SUM(`On Time` IS NULL) AS On_Time_nulls,
SUM(`On Time In Full` IS NULL) AS On_Time_In_Full_nulls
FROM fact_order_lines;


#For fact_orders_aggregate
SELECT
COUNT(*) AS total_rows,
SUM(order_id IS NULL) AS order_id_nulls,
SUM(customer_id IS NULL) AS customer_id_nulls,
SUM(order_placement_date IS NULL) AS order_placement_date_nulls,
SUM(on_time IS NULL) AS on_time_nulls,
SUM(in_full IS NULL) AS in_full_nulls,
SUM(otif IS NULL) AS otif_nulls
FROM fact_orders_aggregate;




# Standardizing Date Columns
ALTER TABLE dim_date
ADD COLUMN new_date DATE,
ADD COLUMN new_mmm_yy INT;

SET SQL_SAFE_UPDATES = 0;

UPDATE dim_date
SET 
new_date = STR_TO_DATE(date,'%d-%b-%y'),
new_mmm_yy = MONTH(STR_TO_DATE(mmm_yy,'%d-%b-%y'));

SET SQL_SAFE_UPDATES = 1;

#Old columns were removed afterwards.
ALTER TABLE dim_date
DROP COLUMN date,
DROP COLUMN mmm_yy;

#Fixing Week Number Data Type
ALTER TABLE dim_date
MODIFY COLUMN week_no VARCHAR(5);

#Cleaning fact_order_lines Date Columns
ALTER TABLE fact_order_lines
ADD COLUMN order_placement_day VARCHAR(10),
ADD COLUMN new_order_placement_date DATE,
ADD COLUMN agreed_delivery_day VARCHAR(10),
ADD COLUMN new_agreed_delivery_date DATE,
ADD COLUMN actual_delivery_day VARCHAR(10),
ADD COLUMN new_actual_delivery_date DATE;



SET SQL_SAFE_UPDATES = 0;

#values were updated
UPDATE fact_order_lines
SET
order_placement_day = SUBSTRING_INDEX(order_placement_date,',',1),
new_order_placement_date = STR_TO_DATE(SUBSTRING_INDEX(order_placement_date, ', ', -2), '%M %e, %Y'),
agreed_delivery_day = SUBSTRING_INDEX(agreed_delivery_date,',',1),
new_agreed_delivery_date = STR_TO_DATE(SUBSTRING_INDEX(agreed_delivery_date,',',-2), '%M %e, %Y'),
actual_delivery_day = SUBSTRING_INDEX(actual_delivery_date,',',1),
new_actual_delivery_date = STR_TO_DATE(SUBSTRING_INDEX(actual_delivery_date,',',-2),'%M %e, %Y');


SET SQL_SAFE_UPDATES = 1;

#Old columns were removed afterwards
ALTER TABLE fact_order_lines
DROP COLUMN order_placement_date,
DROP COLUMN agreed_delivery_date,
DROP COLUMN actual_delivery_date;

#Cleaning fact_orders_aggregate Date Columns
ALTER TABLE fact_orders_aggregate
ADD COLUMN new_order_placement_date DATE;


SET SQL_SAFE_UPDATES = 0;

#values were updated
UPDATE fact_orders_aggregate
SET new_order_placement_date =
STR_TO_DATE(order_placement_date,'%d-%b-%y');


SET SQL_SAFE_UPDATES = 1;

#Old columns were removed afterwards
ALTER TABLE fact_orders_aggregate
DROP COLUMN order_placement_date;



#Order Analysis
#1. How many orders were placed in each month?
SELECT d.new_mmm_yy AS Month, COUNT(f.order_id) AS total_orders
FROM fact_orders_aggregate f
JOIN dim_date d ON f.new_order_placement_date = d.new_date
GROUP BY d.new_mmm_yy;

#2. What is the weekly trend of late deliveries?
SELECT d.week_no, COUNT(f.order_id) AS late_deliveries
FROM fact_orders_aggregate f
JOIN dim_date d ON f.new_order_placement_date = d.new_date
WHERE f.on_time = 0
GROUP BY d.week_no
ORDER BY d.week_no;

#3. Identify the month with the highest number of orders that were not delivered in full
SELECT d.new_mmm_yy AS Month, COUNT(f.order_id) AS not_in_full_orders
FROM fact_orders_aggregate f
JOIN dim_date d ON f.new_order_placement_date = d.new_date
WHERE f.in_full = 0
GROUP BY d.new_mmm_yy
ORDER BY not_in_full_orders DESC LIMIT 1;

#Delivery Performance Analysis
#4. Find the difference between agreed delivery dates and actual delivery dates for all orders
SELECT order_id, new_agreed_delivery_date, new_actual_delivery_date,
       DATEDIFF(new_actual_delivery_date, new_agreed_delivery_date) AS days_difference
FROM fact_order_lines;

#5. What is the OTIF performance for each city?
SELECT c.city, ROUND(AVG(f.otif) * 100, 2) AS otif_pct
FROM fact_orders_aggregate f
JOIN dim_customers c ON f.customer_id = c.customer_id
GROUP BY c.city;


#6. What is the total number of orders delivered late?
SELECT COUNT(order_id) AS late_orders
FROM fact_orders_aggregate
WHERE on_time = 0;

#Product Analysis
#7. List the product categories along with the number of unique products in each category
SELECT category, COUNT(DISTINCT product_id) AS unique_products
FROM dim_products
GROUP BY category;

#8. Identify the busiest week in terms of order placement
SELECT d.week_no, COUNT(f.order_id) AS order_count
FROM fact_orders_aggregate f
JOIN dim_date d ON f.new_order_placement_date = d.new_date
GROUP BY d.week_no
ORDER BY order_count DESC LIMIT 1;

#9. Which product categories perform best in terms of meeting OTIF targets?
SELECT p.category, ROUND(AVG(fol.`On Time In Full`) * 100, 2) AS otif_performance
FROM fact_order_lines fol
JOIN dim_products p ON fol.product_id = p.product_id
GROUP BY p.category
ORDER BY otif_performance DESC;

#KPI Analysis
#10. What is the percentage of orders that met OTIF criteria?
SELECT ROUND(AVG(otif) * 100, 2) AS total_otif_pct
FROM fact_orders_aggregate;

#11. How many orders were placed on weekends versus weekdays?
SELECT 
    CASE WHEN DAYOFWEEK(new_order_placement_date) IN (1, 7) THEN 'Weekend' ELSE 'Weekday' END AS day_type,
    COUNT(order_id) AS order_count
FROM fact_orders_aggregate
GROUP BY day_type;

#12. How many orders were delivered on time but not in full?
SELECT COUNT(order_id) as Order_count
FROM fact_orders_aggregate 
WHERE on_time = 1 AND in_full = 0;

#Product Demand Insights
#13. Which product category has the highest order quantity?
SELECT p.category, SUM(fol.order_qty) AS total_qty
FROM fact_order_lines fol
JOIN dim_products p ON fol.product_id = p.product_id
GROUP BY p.category
ORDER BY total_qty DESC LIMIT 1;

#Customer Performance Analysis
#14. Calculate the percentage of orders delivered on-time for each customer
SELECT 
customer_id,
COUNT(order_id) AS total_orders,
SUM(on_time) AS on_time_orders,
ROUND((SUM(on_time) / COUNT(order_id)) * 100, 2) AS on_time_percentage
FROM fact_orders_aggregate
GROUP BY customer_id;

#15. Calculate the percentage of orders that were successfully delivered (i.e., delivered_qty = order_qty) for each customer
SELECT 
customer_id,
COUNT(order_id) AS total_orders,
SUM(CASE 
        WHEN delivery_qty = order_qty THEN 1 
        ELSE 0 
    END) AS successful_orders,
ROUND(
    SUM(CASE 
            WHEN delivery_qty = order_qty THEN 1 
            ELSE 0 
        END) / COUNT(order_id) * 100, 
2) AS success_percentage
FROM fact_order_lines
GROUP BY customer_id;

#Category Performance
#16. For each product category, calculate the percentage of orders that were delivered on time.
SELECT 
p.category,
COUNT(f.order_id) AS total_orders,
SUM(f.`On Time`) AS on_time_orders,
ROUND(SUM(f.`On Time`) / COUNT(f.order_id) * 100, 2) AS on_time_percentage
FROM fact_order_lines f
JOIN dim_products p
ON f.product_id = p.product_id
GROUP BY p.category;

#Target vs Actual Performance
#17. Show the customers who exceeded their "ontime_target %" based on their actual delivery performance
WITH cte AS (
SELECT 
c.customer_name, 
ROUND(AVG(f.on_time) * 100, 2) AS actual_ot, 
t.`ontime_target%`,
ROUND(AVG(f.on_time) * 100, 2) - t.`ontime_target%` AS gap
FROM fact_orders_aggregate f
JOIN dim_targets_orders t 
ON f.customer_id = t.customer_id
JOIN dim_customers c 
ON f.customer_id = c.customer_id
GROUP BY c.customer_name, t.`ontime_target%`
)

SELECT *
FROM cte;

#Advanced SQL Analysis
#18. Find customers who placed orders with total product quantity greater than the average order quantity
SELECT 
customer_id,
SUM(order_qty) AS total_quantity
FROM fact_order_lines
GROUP BY customer_id
HAVING SUM(order_qty) > (
        SELECT AVG(order_qty)
        FROM fact_order_lines
);

#19. Create a CTE to calculate delivery performance for each customer. Then, use the CTE to select customers whose performance is below the target for both on-time and in-full delivery
WITH CustomerPerformance AS (
    SELECT f.customer_id, 
           AVG(f.on_time) * 100 AS actual_ot, 
           AVG(f.in_full) * 100 AS actual_if,
           t.`ontime_target%`, t.`infull_target%`
    FROM fact_orders_aggregate f
    JOIN dim_targets_orders t ON f.customer_id = t.customer_id
    GROUP BY f.customer_id, t.`ontime_target%`, t.`infull_target%`
)
SELECT * FROM CustomerPerformance
WHERE actual_ot < `ontime_target%` AND actual_if < `infull_target%`;


#20. Use a CTE to calculate the percentage of orders delivered on-time and in-full for each customer, then select the customers with performance below 80% for both metrics
WITH customer_performance AS (
SELECT 
customer_id,
ROUND(AVG(on_time) * 100,2) AS on_time_percentage,
ROUND(AVG(in_full) * 100,2) AS in_full_percentage
FROM fact_orders_aggregate
GROUP BY customer_id
)

SELECT *
FROM customer_performance
WHERE on_time_percentage < 80
AND in_full_percentage < 80;



#21. For each customer, calculate the monthly percentage of on-time and in-full deliveries. Compare these results against the targets to identify any underperforming customers
SELECT d.new_mmm_yy, c.customer_name,
       ROUND(AVG(f.on_time) * 100, 2) AS monthly_ot_pct,
       t.`ontime_target%`,
       ROUND(AVG(f.in_full) * 100, 2) AS monthly_if_pct,
       t.`infull_target%`
FROM fact_orders_aggregate f
JOIN dim_date d ON f.new_order_placement_date = d.new_date
JOIN dim_customers c ON f.customer_id = c.customer_id
JOIN dim_targets_orders t ON f.customer_id = t.customer_id
GROUP BY d.new_mmm_yy, c.customer_name, t.`ontime_target%`, t.`infull_target%`;

#22. Identify the categories with the highest and lowest on-time delivery rates over the past year. Show the on-time percentage for each category and filter out categories with fewer than 200 total orders.
SELECT p.category, 
       ROUND(AVG(fol.`On Time`) * 100, 2) AS on_time_pct,
       COUNT(fol.order_id) AS total_orders
FROM fact_order_lines fol
JOIN dim_products p ON fol.product_id = p.product_id
GROUP BY p.category
HAVING total_orders > 200
ORDER BY on_time_pct DESC;



