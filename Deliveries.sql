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
order by The_Counts DESC;

# 2. Ratio of 1-time customers to returning customers
-- One-time customers --> 1750
SELECT COUNT(DISTINCT Customer) AS Number_of_onetimers
FROM deliveries_staging;

-- Non one-time customers --> 7719
SELECT COUNT(Customer) - COUNT(DISTINCT Customer) AS Number_of_returnees
FROM deliveries_staging;
-- Therefore the ratio is 1:4.4

# 3. Average delivery time for one-timers vs returning customers

SELECT Warehouse, timestampdiff(hour, `Order date`, `Delivery date`) AS time_to_delivery,
	Customer, Zipcode
FROM delivery_copy
Limit 10;

select Customer, avg((`delivery date`, 'dd-mm-yyyy') - format(`order date`, 'dd-mm-yyyy')) as Average_delivery_time
from delivery_copy
limit 10;

# 4. Average delivery time across zipsand in each month

# 5. Warehouse with most orders in each zip
select Zipcode, Warehouse, COUNT(Customer) as No_Customers
from delivery_copy
group by Zipcode, Warehouse
order by No_Customers DESC;

select distinct Warehouse # to confirm how many zipcodes are there.
from delivery_copy;

# 6. If orders increased or decreased each month across zips


# 7. Season with fastest deliveries


# 8. Warehouse with fastest deliveries
