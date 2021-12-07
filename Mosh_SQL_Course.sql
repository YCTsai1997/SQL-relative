
USE sql_store;

SELECT 
	o.order_date, 
	o.order_id,
    c.first_name, 
    s.name as shipper, 
    os.name as status
FROM orders as o
LEFT JOIN customers as c 
	ON o.customer_id = c.customer_id
LEFT JOIN shippers as s
	ON o.shipper_id = s.shipper_id
LEFT JOIN order_statuses as os 
	ON o.status = os.order_status_id;
    

 -- Using clause : for same column only
SELECT 
	o.order_id,
    c.first_name
FROM orders as o
LEFT JOIN customers as c 
	ON o.customer_id = c.customer_id;

SELECT 
	o.order_id,
    c.first_name
FROM orders as o
LEFT JOIN customers as c 
	USING (customer_id);
    
-- Natural JOin 
SELECT 
	o.order_id, 
    c.first_name
FROM orders o 
NATURAL JOIN customer as c;

-- Insert multiple rows
insert into products values 
	(DEFAULT, 'apple', 3, 50),
    (DEFAULT, 'apple', 3, 50),
    (DEFAULT, 'apple', 3, 50);

-- Insert Hierarchical Rows: Use LAST_INSERT_ID() function)

-- Creating a copy of a table (AI will be removed in the new table if exists in the original one)
create table order_archived as 
	select * from orders;

-- only get the partitial of the table! 
INSERT INTO order_archived 
SELECT * 
FROM orders
WHERE order_date < '2019-01-01';

-- UPDATE a single row 
USE sql_invoicing;

UPDATE invoices 
SET payment_total = 10, payment_dtae = '2019-03-01'
WHERE invoice_id = 1;

-- UPDATE a multiple row 
UPDATE invoices 
SET payment_total = 10, payment_dtae = '2019-03-01'
WHERE client_id = 3;

-- Delete rows 
DELETE FROM invoice 
WHERE invoice_id = (
	SELECT *
    FROM clients
    WHERE name = 'Myworks'
);

-- The Having clause
USE sql_store;

SELECT 
		c.customer_id, 
		c.first_name,
		SUM(quantity * unit_price) as total_spend
FROM customers as c
JOIN orders as o USING (customer_id)
JOIN order_items as oi USING (order_id)
WHERE state = 'VA'
GROUP BY c.customer_id, c.first_name
HAVING total_spend > 100;

-- Rollup Operator : For aggragate values;
USE sql_invoicing;

SELECT 
	client_id, 
    SUM(invoice_total) as total_sales
FROM invoices
GROUP BY client_id WITH ROLLUP;

-- Get the summary by group! (Only in MySQL)
SELECT 
	state,
    city,
    SUM(invoice_total) as total_sales
FROM invoices as i
JOIN clients as c USING (client_id)
GROUP BY state, city WITH ROLLUP;

-- Example: using with roll up function, you have to use the acutal column name in group by! Can not use alias!
SELECT 
	pm.name as payment_method, 
    SUM(amount) as total
FROM payments as p
JOIN payment_methods as pm 
	ON p.payment_method = pm.payment_method_id
GROUP BY pm.name WITH ROLLUP;

-- Subquery
USE sql_hr;

SELECT *
FROM employees 
WHERE salary > (
	SELECT AVG(salary) as avg_salary
    FROM employees 
);

-- Subquery using IN operator
--  Find the products that have never been ordered
USE sql_store;

SELECT *
FROM products 
WHERE product_id NOT IN ( 
	SELECT DISTINCT product_id
	FROM order_items
);

-- Find clients without invoices 
USE sql_invoicing;

SELECT *
FROM clients
WHERE client_id NOT IN (
	SELECT DISTINCT client_id 
	FROM invoices
);

-- Subqueries vs Joins
-- Find clients without invoices 
SELECT *
FROM clients 
LEFT JOIN invoices USING (client_id)
WHERE invoice_id is null;



-- Find custoemr who have order lettuce (id = 3) Using both syntax: subquery and join 
-- Select customer_id, first_name, last_name
USE sql_store;

SELECT DISTINCT c.customer_id, first_name, last_name
FROM orders as o 
JOIN (
	SELECT order_id
	FROM order_items
	WHERE product_id = 3) as oi USING (order_id)
JOIN customers as c USING (customer_id);

SELECT DISTINCT c.customer_id, first_name, last_name
FROM orders as o
JOIN customers as c USING (customer_id)
WHERE order_id in (
	SELECT order_id
	FROM order_items
	WHERE product_id = 3);

-- The all keyword 
-- Select invoices larger than all invoices of client 3
USE sql_invoicing;

SELECT invoice_id, client_id, invoice_total
FROM invoices
WHERE invoice_total > (
	SELECT max(invoice_total)
	FROM invoices
	WHERE client_id = 3
);

SELECT invoice_id, client_id, invoice_total
FROM invoices
WHERE invoice_total > ALL (
	-- This will generate multiple rows
	SELECT invoice_total
	FROM invoices
	WHERE client_id = 3
);

-- The any keyword
-- select clients with at least two invoices
SELECT * 
FROM clients
WHERE client_id IN (
	SELECT client_id
	FROM invoices
	GROUP BY client_id
	HAVING COUNT(*) >= 2
);

-- It is the same as the previous one
SELECT * 
FROM clients
WHERE client_id = ANY (
	SELECT client_id
	FROM invoices
	GROUP BY client_id
	HAVING COUNT(*) >= 2
);


-- Correlated Subqueries-----------------------------------------------------------------
-- Select employees whose salary is above the avarage in their office 
USE sql_hr;

SELECT *
FROM employees as a
JOIN (
	SELECT office_id, AVG(salary) as avg_salary
	FROM employees
	GROUP BY office_id
) as b on a.office_id=b.office_id and salary > avg_salary;

-- provide by Mosh
-- The subquery will be execute each time for the main query, those this will be slow compares to getting entire list at once!
SELECT * 
FROM employees as e
where salary > (
	SELECT AVG(salary)
    FROM employees
    WHERE office_id = e.office_id
);

-- Exercise: Get invoices that are larger than the client's average invoice amount 
USE sql_invoicing;

SELECT *
FROM invoices as i
WHERE invoice_total > (
	SELECT AVG(invoice_total)
    FROM invoices
    WHERE client_id = i.client_id
);

-- Need to fix this!
SELECT *
FROM invoices as i 
JOIN (
	SELECT client_id, AVG(invoice_total) as avg_it
    FROM invoices
    GROUP BY client_id) as ij 
    ON i.client_id= ij.client_id
WHERE i.invoice_total> ij.avg_it and i.client_id = ij.client_id;


-- Exists -----------------------------------------------------------------
-- Select clients that have an invoice
-- If the list after in function is large, than use exists will be faster than using in!
SELECT *
FROM clients
WHERE client_id in (
	SELECT DISTINCT client_id
	FROM invoices
);

SELECT *
FROM clients as c
JOIN invoices as i USING (client_id);

SELECT *
FROM clients as c 
WHERE EXISTS (
	-- Does not return the result set to outer query!
	SELECT client_id
    FROM invoices
    WHERE client_id = c.client_id
);


-- Example: Find the product that have never been ordered
USE sql_store;

SELECT *
FROM products 
WHERE product_id not in (
	SELECT product_id
    FROM order_items
);

SELECT *
FROM products as p
-- before not exists, you do not need a column to specified!
WHERE NOT EXISTS (
	SELECT product_id
    FROM order_items 
    WHERE product_id = p.product_id
);

-- Subquery in the select clause
USE sql_invoicing;

SELECT 
	invoice_id, 
    invoice_total,
    (SELECT AVG(invoice_total) 
		FROM invoices) AS invoice_avaerage, 
	invoice_total - (SELECT invoice_avaerage) as Difference
FROM invoices;

-- Or 
SELECT 
	invoice_id, 
    invoice_total,
    (SELECT AVG(invoice_total) 
		FROM invoices) AS invoice_avaerage, 
	invoice_total - (SELECT AVG(invoice_total) FROM invoices) as Difference
FROM invoices;

-- Example: Get the total_sales by each client and average for all client, then difference between the two
SELECT 
	client_id, 
	name,
    (SELECT SUM(invoice_total)
		From invoices
		WHERE client_id = c.client_id) AS total_sales, 
	(SELECT AVG(invoice_total) FROM invoices) AS average_total,
    (SELECT total_sales - average_total) AS difference
FROM clients as c;

-- Subqueriees in the from clause -----------------------------------------------------
-- If you are using sub query in from, then you need to put alias no matter you are using that name or not!
SELECT * 
FROM (
	SELECT 
	client_id, 
	name,
    (SELECT SUM(invoice_total)
		From invoices
		WHERE client_id = c.client_id) AS total_sales, 
	(SELECT AVG(invoice_total) FROM invoices) AS average_total,
    (SELECT total_sales - average_total) AS difference
	FROM clients as c
) AS sales_summary
WHERE total_sales is not null;














