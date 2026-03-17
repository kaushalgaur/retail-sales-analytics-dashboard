# 7. Monthly Revenue Trend
SELECT 
    Month,
    round(SUM(Revenue),2) AS monthly_revenue
FROM retail_transactions
GROUP BY Month
ORDER BY Month;