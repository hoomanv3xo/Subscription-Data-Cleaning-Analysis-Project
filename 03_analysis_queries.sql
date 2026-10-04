-- ============================================================
-- 03_analysis_queries.sql
-- Analysis queries run against the cleaned subscription dataset
-- ============================================================

USE mydb;

-- ------------------------------------------------------------
-- View: customer_subscriptions
-- Convenience join of customers + subscriptions
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW customer_subscriptions AS
SELECT c.Customer_Name, c.Registration_Date, s.*
FROM customers c
JOIN subscriptions s ON c.Customer_ID = s.Customer_ID;


-- ------------------------------------------------------------
-- REVENUE ANALYSIS
-- ------------------------------------------------------------

-- Total revenue by product
SELECT p.Product_Name, SUM(s.Revenue) AS Total_Revenue, COUNT(*) AS Subscription_Count
FROM subscriptions s
JOIN products p ON s.Product_ID = p.Product_ID
GROUP BY p.Product_Name
ORDER BY Total_Revenue DESC;

-- Total revenue by customer (top 10 spenders)
SELECT c.Customer_Name, SUM(s.Revenue) AS Total_Revenue
FROM subscriptions s
JOIN customers c ON s.Customer_ID = c.Customer_ID
GROUP BY c.Customer_Name
ORDER BY Total_Revenue DESC
LIMIT 10;

-- Monthly revenue trend
SELECT DATE_FORMAT(`Order Date`, '%Y-%m') AS Month, SUM(Revenue) AS Monthly_Revenue
FROM subscriptions
GROUP BY Month
ORDER BY Month;


-- ------------------------------------------------------------
-- CANCELLATION TRENDS
-- ------------------------------------------------------------

-- Overall cancellation rate
SELECT
    COUNT(*) AS Total_Subscriptions,
    SUM(CASE WHEN `Cancel Date` IS NOT NULL THEN 1 ELSE 0 END) AS Canceled,
    ROUND(SUM(CASE WHEN `Cancel Date` IS NOT NULL THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS Cancellation_Rate_Pct
FROM subscriptions;

-- Top cancellation reasons
SELECT Cancelation_Reason1, COUNT(*) AS Count
FROM cancelations
WHERE Cancelation_Reason1 IS NOT NULL
GROUP BY Cancelation_Reason1
ORDER BY Count DESC;

-- Cancellations by product
SELECT p.Product_Name, COUNT(*) AS Cancellations
FROM cancelations ca
JOIN subscriptions s ON ca.Subscription_ID = s.`Subscription ID`
JOIN products p ON s.Product_ID = p.Product_ID
GROUP BY p.Product_Name
ORDER BY Cancellations DESC;

-- Time-to-cancellation (days between order and cancel)
SELECT s.`Subscription ID`, s.`Order Date`, s.`Cancel Date`,
       DATEDIFF(s.`Cancel Date`, s.`Order Date`) AS Days_To_Cancel
FROM subscriptions s
WHERE s.`Cancel Date` IS NOT NULL
ORDER BY Days_To_Cancel ASC;


-- ------------------------------------------------------------
-- PAYMENT STATUS ANALYSIS
-- ------------------------------------------------------------

-- Current payment status breakdown
SELECT psd.Description AS Status, COUNT(*) AS Count
FROM payment_status_log psl
JOIN payment_status_definitions psd ON psl.Status_ID = psd.Status_ID
GROUP BY psd.Description
ORDER BY Count DESC;

-- Payment status history for a specific subscription (swap the ID)
SELECT psl.Movement_Date, psd.Description AS Status
FROM payment_status_log psl
JOIN payment_status_definitions psd ON psl.Status_ID = psd.Status_ID
WHERE psl.Subscription_ID = 1
ORDER BY psl.Movement_Date;


-- ------------------------------------------------------------
-- PRODUCT PERFORMANCE
-- ------------------------------------------------------------

-- Active vs discontinued products, with active subscription counts
SELECT p.Product_Name, p.Discontinued, COUNT(s.`Subscription ID`) AS Active_Subscriptions
FROM products p
LEFT JOIN subscriptions s
    ON p.Product_ID = s.Product_ID AND s.`Cancel Date` IS NULL
GROUP BY p.Product_Name, p.Discontinued
ORDER BY Active_Subscriptions DESC;


-- ------------------------------------------------------------
-- CUSTOMER BEHAVIOR
-- ------------------------------------------------------------

-- New customers by registration month
SELECT DATE_FORMAT(Registration_Date, '%Y-%m') AS Month, COUNT(*) AS New_Customers
FROM customers
GROUP BY Month
ORDER BY Month;

-- Customers with multiple subscriptions
SELECT c.Customer_Name, COUNT(s.`Subscription ID`) AS Subscription_Count
FROM customers c
JOIN subscriptions s ON c.Customer_ID = s.Customer_ID
GROUP BY c.Customer_Name
HAVING Subscription_Count > 1
ORDER BY Subscription_Count DESC;


-- ------------------------------------------------------------
-- FRONTEND EVENT CORRELATION (exploratory)
-- ------------------------------------------------------------
-- NOTE: this join chain (frontend_event_log -> users -> customers ->
-- subscriptions) depends on frontend_event_log.User_ID matching
-- users.User_ID, and users.Customer_ID matching customers.Customer_ID.
-- Verify with DESCRIBE before relying on this one.

SELECT fe.Event_Type, COUNT(*) AS Event_Count
FROM frontend_event_log fel
JOIN frontend_events fe ON fel.Event_ID = fe.frontend_events
JOIN users u ON fel.User_ID = u.User_ID
JOIN customers c ON u.Customer_ID = c.Customer_ID
JOIN subscriptions s ON c.Customer_ID = s.Customer_ID
WHERE s.`Cancel Date` IS NOT NULL
  AND fel.Event_TimeStamp BETWEEN DATE_SUB(s.`Cancel Date`, INTERVAL 7 DAY) AND s.`Cancel Date`
GROUP BY fe.Event_Type
ORDER BY Event_Count DESC;
