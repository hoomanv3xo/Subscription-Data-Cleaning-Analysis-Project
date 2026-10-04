-- ============================================================
-- 02_data_cleaning.sql
-- Data cleaning steps applied after importing raw CSV files
-- ============================================================
-- Run this after importing the raw CSVs via MySQL Workbench's
-- Table Data Import Wizard. Each section documents a specific
-- data quality issue found in the source data and how it was
-- resolved.
-- ============================================================

USE mydb;

-- ------------------------------------------------------------
-- 1. BOM (Byte Order Mark) fix on ID columns
-- ------------------------------------------------------------
-- Several CSVs exported from Excel carried a UTF-8 BOM, which
-- corrupted the first column name on import
-- (e.g. "Customer_ID" became "ï»¿Customer_ID").

ALTER TABLE customers CHANGE `ï»¿Customer_ID` Customer_ID INT;
ALTER TABLE products  CHANGE `ï»¿Product_ID`  Product_ID  INT;
-- Repeat as needed for any other imported table showing this issue;
-- check with: DESCRIBE <table_name>;

-- ------------------------------------------------------------
-- 2. Date format standardization: DD-MM-YYYY -> DATE
-- ------------------------------------------------------------
-- Affected columns were imported as TEXT (to avoid failed imports)
-- and converted here using STR_TO_DATE().

SET SQL_SAFE_UPDATES = 0;

-- customers.Registration_Date
ALTER TABLE customers ADD COLUMN Registration_Date_fixed DATE;
UPDATE customers SET Registration_Date_fixed = STR_TO_DATE(Registration_Date, '%d-%m-%Y');
ALTER TABLE customers DROP COLUMN Registration_Date;
ALTER TABLE customers CHANGE Registration_Date_fixed Registration_Date DATE;

-- products.Created_At
ALTER TABLE products ADD COLUMN Created_At_fixed DATE;
UPDATE products SET Created_At_fixed = STR_TO_DATE(Created_At, '%d-%m-%Y');
ALTER TABLE products DROP COLUMN Created_At;
ALTER TABLE products CHANGE Created_At_fixed Created_At DATE;

-- cancelations.Cancel_Date
ALTER TABLE cancelations ADD COLUMN Cancel_Date_fixed DATE;
UPDATE cancelations SET Cancel_Date_fixed = STR_TO_DATE(Cancel_Date, '%d-%m-%Y');
ALTER TABLE cancelations DROP COLUMN Cancel_Date;
ALTER TABLE cancelations CHANGE Cancel_Date_fixed Cancel_Date DATE;

SET SQL_SAFE_UPDATES = 1;

-- ------------------------------------------------------------
-- 3. subscriptions: two date columns + placeholder "None" values
-- ------------------------------------------------------------
-- subscriptions.`Cancel Date` contained the literal string "None"
-- (a Python/pandas export artifact) for ~30 still-active
-- subscriptions, instead of a true NULL. NULLIF() converts these
-- to real NULLs before parsing.

SET SQL_SAFE_UPDATES = 0;

ALTER TABLE subscriptions ADD COLUMN Cancel_Date_fixed DATE;
UPDATE subscriptions SET Cancel_Date_fixed = STR_TO_DATE(NULLIF(`Cancel Date`, 'None'), '%d-%m-%Y');
ALTER TABLE subscriptions DROP COLUMN `Cancel Date`;
ALTER TABLE subscriptions CHANGE Cancel_Date_fixed `Cancel Date` DATE;

ALTER TABLE subscriptions ADD COLUMN Order_Date_fixed DATE;
UPDATE subscriptions SET Order_Date_fixed = STR_TO_DATE(NULLIF(`Order Date`, 'None'), '%d-%m-%Y');
ALTER TABLE subscriptions DROP COLUMN `Order Date`;
ALTER TABLE subscriptions CHANGE Order_Date_fixed `Order Date` DATE;

SET SQL_SAFE_UPDATES = 1;

-- ------------------------------------------------------------
-- 4. ISO 8601 timestamps with a corrupted year + timezone suffix
-- ------------------------------------------------------------
-- frontend_event_log.Event_TimeStamp and payment_status_log.Movement_Date
-- arrived in ISO 8601 format with a trailing UTC offset
-- (e.g. '2023-04-10T20:29:49+00:00'), and additionally all rows
-- in frontend_event_log had a corrupted leading year digit
-- ('0023' instead of '2023').

SET SQL_SAFE_UPDATES = 0;

-- Fix corrupted year prefix (0023 -> 2023)
UPDATE frontend_event_log
SET Event_TimeStamp = CONCAT('2', SUBSTRING(Event_TimeStamp, 2));

-- Convert to DATETIME, stripping the trailing timezone offset
ALTER TABLE frontend_event_log ADD COLUMN Event_TimeStamp_fixed DATETIME;
UPDATE frontend_event_log
SET Event_TimeStamp_fixed = STR_TO_DATE(LEFT(Event_TimeStamp, 19), '%Y-%m-%dT%H:%i:%s');
ALTER TABLE frontend_event_log DROP COLUMN Event_TimeStamp;
ALTER TABLE frontend_event_log CHANGE Event_TimeStamp_fixed Event_TimeStamp DATETIME;

-- payment_status_log.Movement_Date (same ISO 8601 + timezone pattern, no year corruption)
ALTER TABLE payment_status_log ADD COLUMN Movement_Date_fixed DATETIME;
UPDATE payment_status_log
SET Movement_Date_fixed = STR_TO_DATE(LEFT(Movement_Date, 19), '%Y-%m-%dT%H:%i:%s');
ALTER TABLE payment_status_log DROP COLUMN Movement_Date;
ALTER TABLE payment_status_log CHANGE Movement_Date_fixed Movement_Date DATETIME;

SET SQL_SAFE_UPDATES = 1;

-- ------------------------------------------------------------
-- 5. Verification
-- ------------------------------------------------------------
-- Spot-check each cleaned table after running the above.

-- DESCRIBE customers;
-- DESCRIBE products;
-- DESCRIBE cancelations;
-- DESCRIBE subscriptions;
-- DESCRIBE frontend_event_log;
-- DESCRIBE payment_status_log;

-- SELECT * FROM customers LIMIT 5;
-- SELECT * FROM subscriptions LIMIT 5;
