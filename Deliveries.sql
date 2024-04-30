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

SELECT Zipcode, COUNT(Zipcode) AS The_Counts
FROM deliveries_staging
GROUP BY Zipcode
ORDER BY The_Counts DESC;

# 2. Ratio of 1-time customers to returning customers

-- One-time customers --> 1750
SELECT COUNT(DISTINCT Customer) AS Number_of_onetimers
FROM deliveries_staging;

-- Non one-time customers --> 7719
SELECT COUNT(Customer) - COUNT(DISTINCT Customer) AS Number_of_returnees
FROM deliveries_staging;
-- Therefore the ratio is 1:4.4

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


# 7. Season with fastest deliveries


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

