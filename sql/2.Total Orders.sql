# 2.Total Orders
SELECT 
    COUNT(DISTINCT InvoiceNo) AS total_orders
FROM retail_transactions;