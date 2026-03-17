# 9.Order Per Customer
SELECT
CustomerID,
COUNT(DISTINCT InvoiceNo) AS total_orders
FROM retail_transactions
WHERE CustomerID IS NOT NULL
GROUP BY CustomerID
ORDER BY total_orders DESC;