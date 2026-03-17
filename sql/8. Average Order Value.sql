# 8. Average Order Value
SELECT 
    round(SUM(Revenue) / COUNT(DISTINCT InvoiceNo),2) AS avg_order_value
FROM retail_transactions;