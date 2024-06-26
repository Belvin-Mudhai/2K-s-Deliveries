use delivery_db;

DROP table delivtab;
-- loaded the data using import wizard

SET SQL_SAFE_UPDATES = 0;

-- After loading the data, the analysis begins
select * from deliveries limit 10;

/* There is need to change the data types of the date columns to ensure consistency as some of 
the entries were not really in the datetime type*/

-- I'll create a duplicate table first
CREATE TABLE deliveries_staging
LIKE deliveries;

INSERT INTO deliveries_staging
SELECT *
FROM deliveries;

-- cont
SELECT * FROM deliveries_staging LIMIT 1;

UPDATE deliveries_staging
SET `Order date` = STR_TO_DATE(`Order date`, '%m/%d/%Y %H:%i');

UPDATE deliveries_staging
SET `Delivery date` = STR_TO_DATE(`Delivery date`, '%m/%d/%Y %H:%i');

ALTER TABLE deliveries_staging
MODIFY COLUMN `Delivery date` DATETIME;

ALTER TABLE deliveries_staging
MODIFY COLUMN `Order date` DATETIME;

# 1. Zip code with most orders --> 15241 with 919 Orders

SELECT Zipcode, COUNT(Zipcode) AS no_orders
FROM deliveries_staging
GROUP BY Zipcode
ORDER BY no_orders DESC;

# 2. Ratio of 1-time customers to returning customers

-- One-time customers --> 792
WITH Customer_cte AS(
SELECT Customer, COUNT(Customer) AS times_ordered
FROM deliveries_staging
GROUP BY Customer)
SELECT COUNT(Customer) AS one_timers
FROM Customer_cte
WHERE times_ordered = 1;

-- Returning customers --> 958
WITH Customer_cte AS(
SELECT Customer, COUNT(Customer) AS times_ordered
FROM deliveries_staging
GROUP BY Customer)
SELECT COUNT(Customer) AS one_timers
FROM Customer_cte
WHERE times_ordered != 1;
-- Therefore the ratio of one-time to returning cutomers is about 1:1.2

# 3. Average delivery time for one-timers vs returning customers

-- One timers
WITH delitimec AS(
SELECT Warehouse, TIMESTAMPDIFF(HOUR, `Order date`, `Delivery date`) AS deli_time,
	Customer, Zipcode
FROM deliveries_staging),
	visitfreq AS (
	SELECT Customer, COUNT(Customer) AS visits, AVG(deli_time) AS average_time
	FROM delitimec
	GROUP BY Customer)
SELECT AVG(average_time) AS One_timers_deliery_time
FROM visitfreq
WHERE visits = 1;

-- Returning Customers
WITH delitimec AS(
SELECT Warehouse, TIMESTAMPDIFF(HOUR, `Order date`, `Delivery date`) AS deli_time,
	Customer, Zipcode
FROM deliveries_staging),
	visitfreq AS (
	SELECT Customer, COUNT(Customer) AS visits, AVG(deli_time) AS average_time
	FROM delitimec
	GROUP BY Customer)
SELECT AVG(average_time) AS Ret_customers_delivery_time
FROM visitfreq
WHERE visits != 1;

# 4. Average delivery time across zips and in each month

-- select min(`Order date`), max(`Order date`), min(`Delivery date`), max(`Delivery date`) from deliveries_staging;
WITH zip_deliveryc AS(
SELECT Zipcode, TIMESTAMPDIFF(HOUR, `Order date`, `Delivery date`) AS deliver_time,
		SUBSTRING(`Order date`, 1, 7) AS `Month`
FROM deliveries_staging)
SELECT Zipcode, `Month`, AVG(deliver_time) AS monthly_delivery_time
FROM zip_deliveryc
GROUP BY Zipcode, `Month`
ORDER BY 1, 2 ASC;

# 5. Warehouse with most orders in each zip

SELECT Zipcode, Warehouse, COUNT(DISTINCT Customer) AS No_Orders
FROM deliveries_staging
GROUP BY Zipcode, Warehouse
ORDER BY 1, 3 DESC;

# 6. If orders increased or decreased each month across zips

WITH zip_month_orderc AS(
SELECT Zipcode, SUBSTRING(`Order date`, 1, 7) AS yearmonth, COUNT(Customer) AS orders
FROM deliveries_staging
GROUP BY Zipcode, yearmonth
ORDER BY 1, 2 ASC)
SELECT Zipcode, yearmonth, orders, LAG(orders, 1) OVER
		(PARTITION BY Zipcode ORDER BY yearmonth) AS prev_orders,
		orders - LAG(orders, 1) OVER (ORDER BY Zipcode) AS orders_diff
FROM zip_month_orderc;

# 7. Season with fastest deliveries
-- select * from deliveries_staging limit 2;

CREATE TABLE delivery_stage2
LIKE deliveries_staging;

INSERT INTO delivery_stage2
SELECT *
FROM deliveries_staging;

SELECT * FROM delivery_stage2 LIMIT 10;

-- Season orders were made
ALTER TABLE delivery_stage2
ADD COLUMN `order_szn` VARCHAR(45) NOT NULL AFTER `Zipcode`;

UPDATE delivery_stage2
SET order_szn = 'spring'
WHERE SUBSTRING(`Order date`, 6, 2) > 3 
	AND SUBSTRING(`Order date`, 6, 2) < 7;

UPDATE delivery_stage2
SET order_szn = 'summer'
WHERE SUBSTRING(`Order date`, 6, 2) > 6 
	AND SUBSTRING(`Order date`, 6, 2) < 10;

UPDATE delivery_stage2
SET order_szn = 'winter'
WHERE SUBSTRING(`Order date`, 6, 2) IN (12, 1, 2, 3);

UPDATE delivery_stage2
SET order_szn = 'fall'
WHERE SUBSTRING(`Order date`, 6, 2) IN (10, 11);

-- Seasons deliveries were made
ALTER TABLE delivery_stage2
ADD COLUMN `deliv_szn` VARCHAR(45) NOT NULL AFTER `order_szn`;

UPDATE delivery_stage2
SET deliv_szn = 'spring'
WHERE SUBSTRING(`Order date`, 6, 2) > 3 
	AND SUBSTRING(`Order date`, 6, 2) < 7;

UPDATE delivery_stage2
SET deliv_szn = 'summer'
WHERE SUBSTRING(`Order date`, 6, 2) > 6 
	AND SUBSTRING(`Order date`, 6, 2) < 10;

UPDATE delivery_stage2
SET deliv_szn = 'winter'
WHERE SUBSTRING(`Order date`, 6, 2) IN (12, 1, 2, 3);

UPDATE delivery_stage2
SET deliv_szn = 'fall'
WHERE SUBSTRING(`Order date`, 6, 2) IN (10, 11);

SELECT * FROM delivery_stage2 LIMIT 5;
 
-- I'll try to find if all orders were delivered in the same season
SELECT COUNT(*) AS diff_szns
FROM delivery_stage2
WHERE order_szn != deliv_szn;

-- Season with fastest deliveries
SELECT order_szn, AVG(TIMESTAMPDIFF(HOUR, `Order date`, `Delivery date`)) AS Delivery_time
FROM delivery_stage2
GROUP BY order_szn
ORDER BY 2 ASC;

# 8. Warehouse with fastest deliveries

SELECT Warehouse, AVG(TIMESTAMPDIFF(HOUR, `Order date`, `Delivery date`)) AS Deliverytime
FROM deliveries_staging
GROUP BY Warehouse
ORDER BY 2 ASC;

-- Warehouse with fastest deliveries in each zipcode
SELECT Zipcode, Warehouse, AVG(TIMESTAMPDIFF(HOUR, `Order date`, `Delivery date`)) AS Deliverytime
FROM deliveries_staging
GROUP BY Warehouse, Zipcode
ORDER BY 1, 3 ASC;

-- Zipcodes with fastest deliveries
SELECT Zipcode, AVG(TIMESTAMPDIFF(HOUR, `Order date`, `Delivery date`)) AS Deliverytime
FROM deliveries_staging
GROUP BY Zipcode
ORDER BY 1, 2 ASC;
