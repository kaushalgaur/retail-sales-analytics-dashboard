# 4.Revenue by Country
SELECT 
    Country,
    round(SUM(Revenue),2) AS total_revenue
FROM retail_transactions
GROUP BY Country
ORDER BY total_revenue DESC;