CREATE DATABASE Retail_Analytics;
USE Retail_Analytics;

CREATE TABLE retail_transactions (
    InvoiceNo TEXT,
    StockCode TEXT,
    Description TEXT,
    Quantity INTEGER,
    InvoiceDate TIMESTAMP,
    UnitPrice FLOAT,
    CustomerID INTEGER,
    Country TEXT,
    Revenue FLOAT,
    Month TEXT
);
select * from retail_transactions;

SET GLOBAL local_infile = 1;

SHOW VARIABLES LIKE 'secure_file_priv';

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/retail_clean.csv'
INTO TABLE retail_transactions
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(InvoiceNo,StockCode,Description,Quantity,InvoiceDate,UnitPrice,@CustomerID,Country,Revenue,Month)
SET CustomerID = NULLIF(@CustomerID,'');

# 1.Total Revenue
SELECT 
    round(SUM(Revenue),2) AS total_revenue
FROM retail_transactions;

# 2.Total Orders
SELECT 
    COUNT(DISTINCT InvoiceNo) AS total_orders
FROM retail_transactions;

# 3.Total Customers
SELECT 
COUNT(DISTINCT CustomerID) AS total_customers
FROM retail_transactions
WHERE CustomerID IS NOT NULL;

# 4.Revenue by Country
SELECT 
    Country,
    round(SUM(Revenue),2) AS total_revenue
FROM retail_transactions
GROUP BY Country
ORDER BY total_revenue DESC;

# 5.Top 10 Products by Revenue
SELECT
Description,
ROUND(SUM(Revenue),2) AS total_revenue
FROM retail_transactions
WHERE Description IS NOT NULL
AND Description <> ''
GROUP BY Description
ORDER BY total_revenue DESC
LIMIT 10;

# 6.Top Customers by Revenue
SELECT
CustomerID,
ROUND(SUM(Revenue),2) AS total_spent
FROM retail_transactions
WHERE CustomerID IS NOT NULL
GROUP BY CustomerID
ORDER BY total_spent DESC
LIMIT 10;

# 7. Monthly Revenue Trend
SELECT 
    Month,
    round(SUM(Revenue),2) AS monthly_revenue
FROM retail_transactions
GROUP BY Month
ORDER BY Month;

# 8. Average Order Value
SELECT 
    round(SUM(Revenue) / COUNT(DISTINCT InvoiceNo),2) AS avg_order_value
FROM retail_transactions;

# 9.Order Per Customer
SELECT
CustomerID,
COUNT(DISTINCT InvoiceNo) AS total_orders
FROM retail_transactions
WHERE CustomerID IS NOT NULL
GROUP BY CustomerID
ORDER BY total_orders DESC;

# 10. Most Purchased Products (by Quantity)
SELECT
Description,
SUM(Quantity) AS total_quantity
FROM retail_transactions
WHERE Description IS NOT NULL 
AND Description <> ''
GROUP BY Description
ORDER BY total_quantity DESC
LIMIT 10;