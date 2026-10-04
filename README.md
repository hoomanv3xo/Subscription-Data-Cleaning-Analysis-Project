# Subscription-Data-Cleaning-Analysis-Project
## Overview

This project involved setting up a local MySQL database, importing nine raw CSV datasets related to a subscription business (customers, products, subscriptions, payments, cancellations, and frontend events), cleaning and standardizing the data, and preparing it for relational analysis.

The raw source files contained common real-world data quality issues — inconsistent date formats, encoding artifacts, and placeholder strings in place of nulls — which had to be resolved before any meaningful analysis could be done.

## Tech Stack

- **Database:** MySQL Server 8.0
- **Tool:** MySQL Workbench

## Setup

1. Installed MySQL Server 8.0 (Community Edition) via the MySQL Installer, configured as a Windows service.
2. Connected to the local instance (`127.0.0.1:3306`) using MySQL Workbench.
3. Created a working schema (`mydb`) to hold all imported tables.

## Tables

| Table | Description |
|---|---|
| `customers` | Customer records — ID, name, registration date, address, phone |
| `products` | Product catalog — ID, name, discontinued flag, creation date |
| `subscriptions` | Subscription records linking customers to products, including order/cancel dates |
| `cancelations` | Cancellation reasons and dates per subscription |
| `payment_status_definitions` | Lookup table of payment status codes |
| `payment_status_log` | History of payment status changes per subscription |
| `frontend_events` | Lookup table of frontend event types |
| `frontend_event_log` | Log of user-triggered frontend events, timestamped |
| `users` | Internal user accounts (admins/staff), linked to customers |

## Data Cleaning Steps

### 1. CSV Import
All tables were imported using MySQL Workbench's **Table Data Import Wizard**. Source files originally in `.xlsx` were first converted to `.csv` via Excel's "Save As" function.

### 2. Encoding / BOM Fixes
Several CSV files (exported from Excel) carried a UTF-8 Byte Order Mark (BOM), which corrupted the first column name on import (e.g. `Customer_ID` became `ï»¿Customer_ID`). Fixed with:
```sql
ALTER TABLE customers CHANGE `ï»¿Customer_ID` Customer_ID int;
```

### 3. Date Format Standardization
Date columns arrived in multiple inconsistent formats and were imported as `TEXT` to avoid failed imports, then converted to proper `DATE`/`DATETIME` columns:

- **`DD-MM-YYYY`** format (e.g. `customers.Registration_Date`, `products.Created_At`, `cancelations.Cancel_Date`, `subscriptions.Order Date` / `Cancel Date`):
```sql
UPDATE products SET Created_At_fixed = STR_TO_DATE(Created_At, '%d-%m-%Y');
```

- **ISO 8601 with timezone** format (e.g. `frontend_event_log.Event_TimeStamp`, `payment_status_log.Movement_Date`), which also required stripping a trailing UTC offset:
```sql
UPDATE frontend_event_log
SET Event_TimeStamp_fixed = STR_TO_DATE(LEFT(Event_TimeStamp, 19), '%Y-%m-%dT%H:%i:%s');
```

### 4. Data Quality Issues Found & Resolved
- **Corrupted year values:** `frontend_event_log.Event_TimeStamp` contained a four-digit year off by one leading character (`0023` instead of `2023`) across all 50 rows. Fixed with a targeted string replace before date parsing:
```sql
UPDATE frontend_event_log
SET Event_TimeStamp = CONCAT('2', SUBSTRING(Event_TimeStamp, 2));
```
- **Placeholder nulls:** `subscriptions.Cancel Date` contained the literal string `"None"` (a Python/pandas export artifact) for 30 still-active subscriptions, rather than a true `NULL`. Resolved with:
```sql
UPDATE subscriptions
SET Cancel_Date_fixed = STR_TO_DATE(NULLIF(`Cancel Date`, 'None'), '%d-%m-%Y');
```
- **Non-numeric phone numbers:** Phone columns were imported as `TEXT` rather than numeric types, since values contained dashes, parentheses, and slashes (e.g. `(833)3329182`).

### 5. Column Type Corrections
After cleaning, temporary `_fixed` helper columns were dropped and renamed back to their original names with the correct type (`DATE` or `DATETIME`).

## Relationships / Joins

A view was created to join customer and subscription data for easier querying:
```sql
CREATE VIEW customer_subscriptions AS
SELECT c.Customer_Name, c.Registration_Date, s.*
FROM customers c
JOIN subscriptions s ON c.Customer_ID = s.Customer_ID;
```

Other likely joins across the schema (by shared ID columns):

| Table A | Join Column | Table B |
|---|---|---|
| `customers` | `Customer_ID` | `subscriptions` |
| `products` | `Product_ID` | `subscriptions` |
| `subscriptions` | `Subscription_ID` | `cancelations` |
| `subscriptions` | `Subscription_ID` | `payment_status_log` |
| `payment_status_log` | `Status_ID` | `payment_status_definitions` |
| `users` | `Customer_ID` | `customers` |

## Lessons Learned / Notes

- Always check for a BOM when importing CSVs exported from Excel on Windows.
- Don't assume a single date format across a dataset — different source systems (manual entry vs. automated exports) produced different formats across tables.
- Watch for placeholder strings (`"None"`, `"N/A"`, empty strings) masquerading as nulls, especially in data exported from Python.
- MySQL Workbench's Safe Update Mode blocks bulk `UPDATE`/`DELETE` statements without a `WHERE` on a key column — toggle with `SET SQL_SAFE_UPDATES = 0;` / `= 1;` when intentionally updating full tables.

## Next Steps (Planned Analysis)

- [ ] Add primary keys / foreign keys to formalize relationships between tables
- [ ] Add indexes on frequently joined columns (`Customer_ID`, `Subscription_ID`, `Product_ID`)
- [ ] Revenue analysis by product / customer
- [ ] Subscription cancellation trends (by reason, by product, over time)
- [ ] Payment status funnel analysis
- [ ] Frontend event correlation with cancellations/upgrades
