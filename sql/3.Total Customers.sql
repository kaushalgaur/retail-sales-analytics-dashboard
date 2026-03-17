# 3.Total Customers
SELECT 
COUNT(DISTINCT CustomerID) AS total_customers
FROM retail_transactions
WHERE CustomerID IS NOT NULL;