# 6.Top Customers by Revenue
SELECT
CustomerID,
ROUND(SUM(Revenue),2) AS total_spent
FROM retail_transactions
WHERE CustomerID IS NOT NULL
GROUP BY CustomerID
ORDER BY total_spent DESC
LIMIT 10;