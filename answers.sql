
USE classicmodels;              -- import db

/*
1. Write a query to display each customer’s name (as “Customer Name”) 
alongside the name of the employee who is responsible for that customer’s orders.
The employee name should be in a single “Sales Rep” column formatted 
as “lastName, firstName”. The output should be sorted alphabetically by 
customer name.
*/
SELECT c.customerName AS 'Customer Name',
	   CONCAT(e.lastName, ' ', e.firstName) AS 'Sales Rep' 
       -- CONCAT function concatenates two or more expressions together
FROM customers c --  aliases makes it easy to reference columns and tables
INNER JOIN employees e
ON c.salesRepEmployeeNumber = e.employeeNumber
ORDER BY customerName;

 
/*
2. Determine which products are most popular with our customers. For each product, 
list the total quantity ordered along with the total sale generated 
(total quantity ordered * buyPrice) for that product. The column headers should
be “Product Name”, “Total # Ordered” and “Total Sale”. List the products by Total 
Sale descending.
*/
SELECT p.productName AS 'Product Name',
	   SUM(o.quantityOrdered) AS 'Total # Ordered', -- SUM fuction adds across column
	   SUM(o.quantityOrdered * o.priceEach) AS 'Total Sales'
FROM products p
LEFT JOIN orderdetails o
ON p.productCode = o.productCode
GROUP BY 1                                -- you refer to column name by index #
ORDER BY 3 DESC;

 
/*
3. Write a query which lists order status and the # of orders with that status.
 Column headers should be “Order Status” and “# Orders”. Sort alphabetically 
 by status.
*/
SELECT o.status AS 'Order Status', od.quantityOrdered AS '# Orders'
FROM orders o
LEFT JOIN orderdetails od 
ON o.orderNumber = od.orderNumber
GROUP BY status
ORDER BY o.status; 

 
/*
4. Write a query to list, for each product line, the total # of products 
sold from that product line. The first column should be “Product Line” 
and the second should be “# Sold”. Order by the second column descending.
*/
SELECT productLine AS 'Product Line',
	   SUM(quantityOrdered) AS '# Sold'
FROM 
	(            -- you can pass select statements to the FROM arguement
	SELECT p.productCode,
		   p.productName,
		   od.quantityOrdered,
           p.productLine
	FROM products p 
	RIGHT JOIN orderdetails od
	ON p.productCode = od.productCode
	) AS x -- table alias only valid within the scope of the SQL statement
GROUP BY productLine
ORDER BY 2 DESC;

 
/*
5. For each employee who represents customers, output the total # of orders
that employee’s customers have placed alongside the total sale amount of 
those orders. The employee name should be output as a single column named
“Sales Rep” formatted as “lastName, firstName”. The second column should
be titled “# Orders” and the third should be “Total Sales”.Sort the 
output by Total Sales descending. Only (and all) employees with the job
title ‘Sales Rep’ should be included in the output, and if the employee
made no sales the Total Sales should display as “0.00”.
*/

/*
The following two questions seem to have a lot of code but I find it easier 
to work through the  logic chunk by chunk. There are multiple nested select
statements but the idea is that every inner SELECT represents a temporary
table that can be accesses by the outer SELECT
*/
SELECT 
    salesRep AS 'Sales Rep',
    count(quantityOrdered) AS '# Orders',
    SUM(totalSales) AS 'Total Sales'
FROM
    (
    SELECT 
			e.employeeNumber,
            CONCAT(e.lastName, ', ', e.firstName) AS salesRep,
            od.quantityOrdered,
            od.priceEach,
			-- case statement to to handle multiple returns
            CASE 
                WHEN od.quantityOrdered IS NULL THEN 0.00 
                WHEN od.quantityOrdered = 0 THEN 0.00    
                WHEN od.quantityOrdered > 0 THEN od.quantityOrdered * od.priceEach  
            END AS totalSales,     -- end CASE and assign result to alias
            e.jobTitle  -- example of why you need a table alias - cleaner code
    FROM customers c
    RIGHT JOIN 
				(   -- Nested SELECT statement
                SELECT employeeNumber, 
					   lastName, 
                       firstName, 
                       jobTitle
                FROM employees
				WHERE jobTitle = 'Sales Rep' -- return 'Sales Rep' only
				) AS e 
	ON e.employeeNumber = c.salesRepEmployeeNumber
    LEFT JOIN orders o 
    ON o.customerNumber = c.customerNumber
    LEFT JOIN orderdetails od 
    ON o.orderNumber = od.orderNumber) AS x
GROUP BY employeeNumber
ORDER BY SUM(totalSales) DESC;


/*
6. Your product team is requesting data to help them create a bar-chart of monthly
sales since the company’s inception. Write a query to output the month 
(January, February, etc.), 4-digit year, and total sales for that month. 
The first column should be labeled ‘Month’, the second ‘Year’, and the 
third should be ‘Payments Received’. Values in the third column should be 
formatted as numbers with two decimals – for example: 694,292.68.
*/

/*
SELECT 
    dateMonth AS 'Month',
    dateYear AS 'Year',
    FORMAT(salesByMonth, 2) AS 'Payments Recieved' -- FORMAT to 2 decimal places
FROM
    (
    SELECT	COUNT(*),  -- the COUNT function returns the number of rows in a table. 
            YEAR(orderDate) AS dateYear,             
                    -- YEAR/MONTH return the year/month in a date respectively
            MONTHNAME(orderDate) AS dateMonth,       
					-- MONTHNAME returns the full name of the month for a date
            SUM(totalSales) AS salesByMonth
	FROM	
		(
        SELECT 
				od.orderNumber,
				o.orderDate,
				od.quantityOrdered,
				od.priceEach,
				(quantityOrdered * priceEach) AS totalSales
		FROM
				(    -- this SELECT excludes data from Cancelled & Disputed orders
                SELECT orderNumber, 
						orderDate
				FROM 	orders
				WHERE	orders.status != 'Cancelled'
				AND orders.status != 'Disputed'
				) AS o
		LEFT JOIN orderdetails od 
		ON o.orderNumber = od.orderNumber
		) AS x
    GROUP BY YEAR(orderDate) , MONTH(orderDate)
    ORDER BY orderDate) AS y;
 */   

/* This code shorter as it uses the payments table as opposed to doing 
the total Sales calculations from the order details*/

SELECT  MONTHNAME(paymentDate) AS 'Month',
		YEAR(paymentDate) AS 'Year',
        FORMAT(SUM(amount), 2) AS 'Payments Recieved'
FROM payments
GROUP BY 2 ,1
ORDER BY paymentDate;