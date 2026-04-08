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

-- =========================================
-- 1. DATA CLEANING LAYER
-- =========================================

CREATE VIEW clean_retail AS
SELECT *
FROM retail_transactions
WHERE CustomerID IS NOT NULL
AND Quantity > 0
AND UnitPrice > 0
AND InvoiceNo NOT LIKE 'C%';

-- =========================================
-- 2. KPI LAYER
-- =========================================

-- 1. Total Revenue
SELECT 
    ROUND(SUM(Revenue), 2) AS total_revenue
FROM clean_retail;
-- 8832003.28

-- 2. Total Orders
SELECT 
    COUNT(DISTINCT InvoiceNo) AS total_orders
FROM clean_retail;
-- 19213

-- 3. Total Customers
SELECT 
    COUNT(DISTINCT CustomerID) AS total_customers
FROM clean_retail;
-- 4312


-- 4. Average Order Value (AOV)
SELECT 
    ROUND(SUM(Revenue) / COUNT(DISTINCT InvoiceNo), 2) AS avg_order_value
FROM clean_retail;
-- 459.69


-- 5. Revenue per Customer (NEW 🔥)
SELECT 
    ROUND(SUM(Revenue) / COUNT(DISTINCT CustomerID), 2) AS revenue_per_customer
FROM clean_retail;
-- 2048.24

-- 6. Orders per Customer (NEW 🔥)
SELECT 
    ROUND(COUNT(DISTINCT InvoiceNo) / COUNT(DISTINCT CustomerID), 2) AS orders_per_customer
FROM clean_retail;
-- 4.46

-- 7. Repeat Customer Rate (VERY IMPORTANT 🔥)
SELECT 
    ROUND(
        COUNT(DISTINCT CASE WHEN order_count > 1 THEN CustomerID END) 
        * 100.0
        / COUNT(DISTINCT CustomerID), 
    2) AS repeat_customer_rate
FROM (
    SELECT 
        CustomerID,
        COUNT(DISTINCT InvoiceNo) AS order_count
    FROM clean_retail
    GROUP BY CustomerID
) t;
-- 67.09

-- =========================================
-- 3. CUSTOMER ANALYSIS LAYER
-- =========================================

-- 1. Customer Level Summary (CLV Base 🔥)
SELECT 
    CustomerID,
    COUNT(DISTINCT InvoiceNo) AS total_orders,
    ROUND(SUM(Revenue), 2) AS total_spent,
    ROUND(SUM(Revenue) / COUNT(DISTINCT InvoiceNo), 2) AS avg_order_value
FROM clean_retail
GROUP BY CustomerID
ORDER BY total_spent DESC;


-- 2. Top 10 High-Value Customers
SELECT 
    CustomerID,
    ROUND(SUM(Revenue), 2) AS total_spent
FROM clean_retail
GROUP BY CustomerID
ORDER BY total_spent DESC
LIMIT 10;


-- 3. Customer Purchase Frequency Distribution 🔥
SELECT 
    order_count,
    COUNT(CustomerID) AS number_of_customers
FROM (
    SELECT 
        CustomerID,
        COUNT(DISTINCT InvoiceNo) AS order_count
    FROM clean_retail
    GROUP BY CustomerID
) t
GROUP BY order_count
ORDER BY order_count DESC;


-- 4. One-time vs Repeat Customers 🔥
SELECT 
    CASE 
        WHEN order_count = 1 THEN 'One-Time Customers'
        ELSE 'Repeat Customers'
    END AS customer_type,
    COUNT(CustomerID) AS total_customers
FROM (
    SELECT 
        CustomerID,
        COUNT(DISTINCT InvoiceNo) AS order_count
    FROM clean_retail
    GROUP BY CustomerID
) t
GROUP BY customer_type;


-- 5. Revenue Contribution by Customer Type 🔥
SELECT 
    CASE 
        WHEN order_count = 1 THEN 'One-Time Customers'
        ELSE 'Repeat Customers'
    END AS customer_type,
    ROUND(SUM(total_spent), 2) AS revenue
FROM (
    SELECT 
        CustomerID,
        COUNT(DISTINCT InvoiceNo) AS order_count,
        SUM(Revenue) AS total_spent
    FROM clean_retail
    GROUP BY CustomerID
) t
GROUP BY customer_type;


-- 6. Average Revenue per Customer Segment 🔥
SELECT 
    CASE 
        WHEN order_count = 1 THEN 'One-Time'
        WHEN order_count BETWEEN 2 AND 5 THEN 'Occasional'
        ELSE 'Frequent'
    END AS customer_segment,
    COUNT(CustomerID) AS customers,
    ROUND(AVG(total_spent), 2) AS avg_revenue
FROM (
    SELECT 
        CustomerID,
        COUNT(DISTINCT InvoiceNo) AS order_count,
        SUM(Revenue) AS total_spent
    FROM clean_retail
    GROUP BY CustomerID
) t
GROUP BY customer_segment
ORDER BY avg_revenue DESC;



-- =========================================
-- 4. PRODUCT ANALYSIS LAYER
-- =========================================

-- 1. Top 10 Products by Revenue
SELECT 
    Description,
    ROUND(SUM(Revenue), 2) AS total_revenue
FROM clean_retail
WHERE Description IS NOT NULL AND Description <> ''
GROUP BY Description
ORDER BY total_revenue DESC
LIMIT 10;


-- 2. Top 10 Products by Quantity Sold
SELECT 
    Description,
    SUM(Quantity) AS total_quantity
FROM clean_retail
WHERE Description IS NOT NULL AND Description <> ''
GROUP BY Description
ORDER BY total_quantity DESC
LIMIT 10;


-- 3. Products Driving Most Customers (Demand 🔥)
SELECT 
    Description,
    COUNT(DISTINCT CustomerID) AS unique_customers
FROM clean_retail
GROUP BY Description
ORDER BY unique_customers DESC
LIMIT 10;


-- 4. Products Driving Repeat Purchases 🔥🔥
SELECT 
    Description,
    COUNT(*) AS total_purchases,
    COUNT(DISTINCT CustomerID) AS unique_customers,
    ROUND(COUNT(*) / COUNT(DISTINCT CustomerID), 2) AS avg_purchase_per_customer
FROM clean_retail
GROUP BY Description
HAVING COUNT(DISTINCT CustomerID) > 50
ORDER BY avg_purchase_per_customer DESC
LIMIT 10;


-- 5. High Revenue but Low Customer Reach (Opportunity 🔥)
SELECT 
    Description,
    ROUND(SUM(Revenue), 2) AS total_revenue,
    COUNT(DISTINCT CustomerID) AS unique_customers
FROM clean_retail
GROUP BY Description
HAVING unique_customers < 50
ORDER BY total_revenue DESC
LIMIT 10;


-- 6. Product Performance Segmentation 🔥
SELECT 
    Description,
    ROUND(SUM(Revenue), 2) AS revenue,
    SUM(Quantity) AS quantity,
    COUNT(DISTINCT CustomerID) AS customers,
    CASE 
        WHEN SUM(Revenue) > 50000 THEN 'High Value'
        WHEN SUM(Revenue) BETWEEN 10000 AND 50000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS product_segment
FROM clean_retail
GROUP BY Description
ORDER BY revenue DESC;

-- =========================================
-- 5. TIME ANALYSIS + WINDOW FUNCTIONS
-- =========================================

-- 1. Monthly Revenue Trend
SELECT 
    DATE_FORMAT(InvoiceDate, '%Y-%m') AS month,
    ROUND(SUM(Revenue), 2) AS monthly_revenue
FROM clean_retail
GROUP BY month
ORDER BY month;


-- 2. Monthly Revenue with Cumulative Revenue 🔥
SELECT 
    month,
    monthly_revenue,
    SUM(monthly_revenue) OVER (ORDER BY month) AS cumulative_revenue
FROM (
    SELECT 
        DATE_FORMAT(InvoiceDate, '%Y-%m') AS month,
        SUM(Revenue) AS monthly_revenue
    FROM clean_retail
    GROUP BY month
) t;


-- 3. Month-over-Month Growth (MoM %) 🔥🔥
SELECT 
    month,
    monthly_revenue,
    ROUND(
        (monthly_revenue - LAG(monthly_revenue) OVER (ORDER BY month)) 
        / LAG(monthly_revenue) OVER (ORDER BY month) * 100, 
    2) AS mom_growth_percentage
FROM (
    SELECT 
        DATE_FORMAT(InvoiceDate, '%Y-%m') AS month,
        SUM(Revenue) AS monthly_revenue
    FROM clean_retail
    GROUP BY month
) t;


-- 4. Rank Months by Revenue 🔥
SELECT 
    month,
    monthly_revenue,
    RANK() OVER (ORDER BY monthly_revenue DESC) AS revenue_rank
FROM (
    SELECT 
        DATE_FORMAT(InvoiceDate, '%Y-%m') AS month,
        SUM(Revenue) AS monthly_revenue
    FROM clean_retail
    GROUP BY month
) t;


-- 5. Top Performing Month vs Worst Month 🔥
SELECT 
    MAX(monthly_revenue) AS highest_monthly_revenue,
    MIN(monthly_revenue) AS lowest_monthly_revenue
FROM (
    SELECT 
        DATE_FORMAT(InvoiceDate, '%Y-%m') AS month,
        SUM(Revenue) AS monthly_revenue
    FROM clean_retail
    GROUP BY month
) t;


-- =========================================
-- 6. RFM SEGMENTATION
-- =========================================

-- Step 1: Calculate RFM Metrics
WITH rfm AS (
    SELECT 
        CustomerID,
        MAX(InvoiceDate) AS last_purchase,
        COUNT(DISTINCT InvoiceNo) AS frequency,
        ROUND(SUM(Revenue), 2) AS monetary
    FROM clean_retail
    GROUP BY CustomerID
),

-- Step 2: Calculate Recency
rfm_calc AS (
    SELECT 
        *,
        DATEDIFF(
            (SELECT MAX(InvoiceDate) FROM clean_retail), 
            last_purchase
        ) AS recency
    FROM rfm
),

-- Step 3: Assign RFM Scores
rfm_score AS (
    SELECT 
        *,
        NTILE(5) OVER (ORDER BY recency DESC) AS R_score,
        NTILE(5) OVER (ORDER BY frequency) AS F_score,
        NTILE(5) OVER (ORDER BY monetary) AS M_score
    FROM rfm_calc
)

-- Step 4: Final Output with Segments 🔥
SELECT 
    CustomerID,
    recency,
    frequency,
    monetary,
    R_score,
    F_score,
    M_score,
    
    CASE 
        WHEN R_score >= 4 AND F_score >= 4 AND M_score >= 4 THEN 'Champions'
        WHEN F_score >= 4 AND M_score >= 3 THEN 'Loyal Customers'
        WHEN R_score >= 4 AND F_score >= 2 THEN 'Potential Loyalists'
        WHEN R_score <= 2 AND F_score >= 3 THEN 'At Risk'
        WHEN R_score <= 2 AND F_score <= 2 THEN 'Lost Customers'
        ELSE 'Others'
    END AS customer_segment

FROM rfm_score
ORDER BY monetary DESC;

-- =========================================
-- 7. COHORT ANALYSIS
-- =========================================

-- Step 1: Assign Cohort Month (First Purchase)
WITH cohort AS (
    SELECT 
        CustomerID,
        DATE_FORMAT(MIN(InvoiceDate), '%Y-%m') AS cohort_month
    FROM clean_retail
    GROUP BY CustomerID
),

-- Step 2: Customer Activity by Month
activity AS (
    SELECT 
        c.CustomerID,
        c.cohort_month,
        DATE_FORMAT(t.InvoiceDate, '%Y-%m') AS activity_month
    FROM clean_retail t
    JOIN cohort c 
        ON t.CustomerID = c.CustomerID
)

-- Step 3: Cohort Retention Table
SELECT 
    cohort_month,
    activity_month,
    COUNT(DISTINCT CustomerID) AS active_customers
FROM activity
GROUP BY cohort_month, activity_month
ORDER BY cohort_month, activity_month;

-- Cohort Size (Initial Customers)
WITH cohort AS (
    SELECT 
        CustomerID,
        DATE_FORMAT(MIN(InvoiceDate), '%Y-%m') AS cohort_month
    FROM clean_retail
    GROUP BY CustomerID
)
SELECT 
    cohort_month,
    COUNT(DISTINCT CustomerID) AS cohort_size
FROM cohort
GROUP BY cohort_month
ORDER BY cohort_month;


/*
# 📄 1. SQL INSIGHTS (PUT IN README / DOCUMENTATION)

Revenue & Growth
* Total revenue is **~8.83M**, showing strong business scale
* Peak revenue observed in **Nov 2010 (~1.17M)** → seasonal spike (likely holidays)
* Significant drop in **Dec 2010 (-73%)** → potential data cut-off or post-season decline

---

Customer Behavior
* 67% customers are repeat buyers
* Repeat customers contribute ~94% of total revenue
* Frequent customers spend ~18x more than one-time customers

Insight: Business heavily depends on loyal customers

---

Product Insights
* Certain products drive high repeat purchases → loyalty drivers
* Some products have high revenue but low customer reach → growth opportunity
* Product segmentation shows clear high / medium / low value products

---

Time Analysis
* Revenue shows clear seasonal trends (Q4 spike)
* Month-over-month growth fluctuates → indicates demand variability
* Cumulative revenue shows consistent growth over time

---

RFM Segmentation (MOST IMPORTANT)
* Identified Champions, Loyal, At Risk, Lost customers
* Top customers have:

  * high frequency
  * high spending
  * recent purchases

Insight: Small group of customers drives majority revenue

---

Cohort Analysis

* Strong initial retention but gradual drop over months
* Some cohorts retain better → indicates customer quality variation

Insight: Retention strategies needed after first purchase

---

2. BUSINESS RECOMMENDATIONS (VERY IMPORTANT)

Marketing Strategy
* Target Champions & Loyal customers with loyalty programs
* Re-engage At Risk customers using discounts

---

Product Strategy
* Promote high repeat purchase products
* Expand reach for high revenue but low customer products

---

Retention Strategy
* Improve onboarding for new customers
* Run campaigns after first purchase to reduce churn

---

