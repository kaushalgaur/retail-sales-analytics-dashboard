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