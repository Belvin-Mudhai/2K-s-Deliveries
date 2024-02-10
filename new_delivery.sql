DROP SCHEMA delivery;

CREATE SCHEMA delivery_db;
use delivery_db;
CREATE TABLE deliveries (
			Customers INT,
            Delivery_date DATETIME,
            Order_date DATETIME,
            S_N VARCHAR(12),
            Warehouse VARCHAR(24),
            Zipcode VARCHAR(8)
            );
drop table delivery_copy;
use delivery_db;

# After loading the data, the analysis begins
select * from delivery_copy limit 10;

/* There is need to change the data types of the date columns to ensure consistency as some of 
the entries were not really in the datetime type*/
ALTER TABLE delivery_copy
MODIFY COLUMN `Order date` datetime;



# 1. Zip code with most orders --> 15241 with 919 Orders
SELECT Zipcode, COUNT(Zipcode) AS The_Counts
FROM delivery_copy
GROUP BY Zipcode
order by The_Counts DESC;

# 2. Ratio of 1-time customers to returning customers
# One-time customers --> 1751
SELECT COUNT(DISTINCT Customer) AS Number_of_onetimers
FROM delivery_copy;

# Non one-time customers --> 7729
SELECT COUNT(Customer) - COUNT(DISTINCT Customer) AS Number_of_returnees
FROM delivery_copy;
# Ratio is therefore 1:4.4

# 3. Average delivery time for one-timers vs returning customers
# change the order date to turn off the confusion
ALTER TABLE delivery_copy
CHANGE `Order date` Order_date DATETIME;


/* Getting the differences in time --> unix_timestamp() 
										timestampdiff()*/
SELECT Warehouse, timestampdiff(hour, `Order date`, `Delivery date`) AS time_to_delivery,
	Customer, Zipcode
FROM delivery_copy
Limit 10;


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
