/*
-- Essential MySQL Functions
-- Views
*/


-- Numeric functions ------------------------------------------------------

Select ROUND(5.73);

-- STRING functions
SELECT LTRIM('     sky');
SELECT SUBSTRING('Kingengarden', 3, 5);
SELECT SUBSTRING('Kingengarden', 3); -- will return from position 3 to the end of the string!
SELECT LOCATE('n','Kingengarden'); -- Searching is not case sensitive
SELECT replace('Kingengarden','garden','garten');
SELECT CONCAT('first', 'last');

USE sql_store;

SELECT CONCAT(first_name, ' ', last_name) as full_name
FROM customers;

-- Date functions ------------------------------------------------------
SELECT NOW(), CURDATE(), CURTIME();
SELECT DAYNAME(NOW()); -- MOnday
SELECT EXTRACT(DAY FROM NOW());

-- Exercise Get the orders in current year!
SELECT *
FROM orders
WHERE YEAR(order_date) >= YEAR(NOW());

-- Formatting Dates and times ------------------------------------------------------
-- mySQL date formate string
SELECT date_format(NOW(),'%M %d, %y');
SELECT date_format(NOW(),'%Y');

-- Calculating Dates and times ------------------------------------------------------
SELECT DATE_ADD(NOW(), INTERVAL 1 DAY);
SELECT DATE_ADD(NOW(), INTERVAL -1 YEAR); -- GEt last year
SELECT DATE_SUB(NOW(), interval 1 DAY);
SELECT DATEDIFF('2019-01-05','2019-01-01'); -- only get day different
SELECT TIME_TO_SEC('09:00');
SELECT TIME_TO_SEC('09:02') - TIME_TO_SEC('09:00');

-- The IFNULL and COALESCE functions ------------------------------------------------------
USE sql_store;

SELECT order_id, 
		IFNULL(shipper_id, 'NOT assigned') as shipper
FROM orders;


SELECT order_id, 
		COALESCE(shipper_id, comments, 'NOT assigned') as shipper
FROM orders;

-- Exercise
SELECT CONCAT(first_name, ' ', last_name) as name, 
		IFNULL(phone, 'unknown') as phone
FROM customers;

-- Results will be the same
SELECT CONCAT(first_name, ' ', last_name) as name, 
		COALESCE(phone, 'unknown') as phone
FROM customers;

-- The if function ---------------------------------------
-- Classified the orders into 2 category: unoin, if
SELECT 
	order_id, 
    order_date,
    IF(
		year(order_date) = YEAR(NOW()), 
        'Active',
        'Archived') as category
FROM orders;

-- Exercise
SELECT 
	product_id, 
    (SELECT name
	FROM products
    WHERE product_id = oi.product_id) as name,
    COUNT(product_id) as orders, 
    IF(COUNT(product_id)>1, 'Many times','Once') as frequency
FROM order_items as oi
GROUP BY product_id;

-- Provide by Mosh (Think the structure based on the final table format!
SELECT 
	Product_id, 
    name, 
    Count(*) as orders,
    IF(count(*) > 1, 'Many times','Once') as frequency
FROM products 
JOIN order_items USING (product_id)
GROUP BY product_id, name;

-- The case operator ------------------------------------------------------
SELECT 
	order_id, 
    CASE
		WHEN YEAR(order_date) = YEAR(NOW()) THEN 'ACTIVE'
        WHEN YEAR(order_date) = YEAR(NOW()) - 3 THEN 'Last Year'
        WHEN YEAR(order_date) < YEAR(NOW()) - 3 THEN 'Archived'
        ELSE 'Future' 
	END AS category
FROM orders;

-- Views -------------------------------------------------------------------
USE sql_invoicing;

CREATE VIEW sales_by_client AS 
SELECT 
	c.client_id, 
    c.name, 
    SUM(invoice_total) as total_sales
FROM clients as c
JOIN invoices i USING (Client_id)
GROUP BY c.client_id, c.name;


-- Exercise
-- Creare a view to see the balance for each client. 

CREATE VIEW clients_balance AS
SELECT 
	c.client_id, 
	c.name,
    sum(invoice_total - payment_total) AS balance
FROM clients as c
JOIN invoices as i USING (CLient_id)
GROUP BY c.client_id, name;


-- Altering or Dropping views -----------------------------------
-- IF you want to make changes you can click the table in schemas with ranch, and then make modification then click apply
DROP VIEW clients_balance;

CREATE OR REPLACE VIEW clients_balance AS
SELECT 
	c.client_id, 
	c.name,
    sum(invoice_total - payment_total) AS balance
FROM clients as c
JOIN invoices as i USING (CLient_id)
GROUP BY c.client_id, name;


-- Updatable views -----------------------------------
CREATE OR REPLACE VIEW invoices_with_balance AS
SELECT
	invoice_id, 
    number, 
    client_id, 
    invoice_total, 
    Payment_total,
    invoice_total - payment_total AS balance,
    invoice_date, 
    Due_date, 
    Payment_date
FROM invoices 
WHERE (invoice_total - payment_total ) > 0 ;

-- You can just delete rows 
DELETE FROM invoices_with_balance
WHERE invoice_id = 1;


UPDATE invoices_with_balance
SET due_date = DATE_ADD(due_date, INTERVAL 2 DAY)
WHERE invoice_id = 1;


-- The WITH OPTION CHECK CLause -----------------------
-- AFter updating this, invoice_id= 2 disappears! This is default behavior of views!
-- When you update or delete through a view, some rows may disappear!
UPDATE invoices_with_balance 
SET  payment_total = invoice_total
WHERE invoice_id = 2;

-- To prevent this, we will need to add with check option will prevent update or delete statements from excluding rows from the view!
-- But if you are update or delete in view, you will get an error, due to you are trying to modify a row that is no longer exists!
CREATE OR REPLACE VIEW invoices_with_balance AS
SELECT
	invoice_id, 
    number, 
    client_id, 
    invoice_total, 
    Payment_total,
    invoice_total - payment_total AS balance,
    invoice_date, 
    Due_date, 
    Payment_date
FROM invoices 
WHERE (invoice_total - payment_total ) > 0 
WITH CHECK OPTION;


-- Other benefits of views ------------------------------------------------------------
-- Restrict access to the data
-- Simplified queries
-- Reduce impact of changes




