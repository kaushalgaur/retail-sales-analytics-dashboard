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