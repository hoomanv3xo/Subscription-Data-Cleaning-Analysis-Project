-- ============================================================
-- 01_schema.sql
-- Schema setup for the subscription data cleaning project
-- ============================================================

CREATE DATABASE IF NOT EXISTS mydb;
USE mydb;

-- Note: most tables in this project were originally created via
-- MySQL Workbench's Table Data Import Wizard directly from CSV
-- files, which auto-generates the table and infers column types.
-- The CUSTOMERS table below was created manually as an example;
-- the remaining tables reflect the structure produced after import
-- and cleanup (see 02_data_cleaning.sql).

CREATE TABLE IF NOT EXISTS CUSTOMERS (
    CUS_CODE      INT,
    CUS_LNAME     VARCHAR(15),
    CUS_FNAME     VARCHAR(15),
    CUS_INITIAL   VARCHAR(1),
    CUS_AREACODE  VARCHAR(3),
    CUS_PHONE     VARCHAR(8),
    CUS_BALANCE   FLOAT(8)
);

CREATE TABLE IF NOT EXISTS INVOICE (
    INV_NUMBER   INT,
    CUS_CODE     INT,
    INV_DATE     DATE,
    INV_SUBTOTAL DECIMAL(9,2),
    INV_TAX      DECIMAL(9,2),
    INV_TOTAL    DECIMAL(9,2)
);

-- Imported tables (created via Import Wizard, structure shown post-cleaning)

CREATE TABLE IF NOT EXISTS customers (
    Customer_ID       INT,
    Customer_Name     TEXT,
    Registration_Date DATE,
    Address           TEXT,
    Phone             TEXT
);

CREATE TABLE IF NOT EXISTS products (
    Product_ID    INT,
    Product_Name  TEXT,
    Discontinued  INT,
    Created_At    DATE
);

CREATE TABLE IF NOT EXISTS subscriptions (
    Customer_ID             INT,
    Product_ID               INT,
    `Subscription ID`        INT,
    `Contract ID`             INT,
    `Purchased Users`         INT,
    `Current Payment Status`  TEXT,
    Revenue                   INT,
    `Cancel Date`              DATE,
    `Order Date`               DATE,
    Active                    INT,
    `Upgrded Sub`              TEXT
);

CREATE TABLE IF NOT EXISTS cancelations (
    Subscription_ID     INT,
    Cancel_Date          DATE,
    Cancelation_Reason1  TEXT,
    Cancelation_Reason2  TEXT,
    Cancelation_Reason3  TEXT
);

CREATE TABLE IF NOT EXISTS payment_status_definitions (
    Status_ID    INT,
    Description  TEXT
);

CREATE TABLE IF NOT EXISTS payment_status_log (
    Status_Movement_ID  INT,
    Subscription_ID      INT,
    Status_ID             INT,
    Movement_Date          DATETIME
);

CREATE TABLE IF NOT EXISTS frontend_events (
    frontend_events INT,
    Description      TEXT,
    Event_Type        TEXT
);

CREATE TABLE IF NOT EXISTS frontend_event_log (
    Event_Log_ID    INT,
    User_ID          TEXT,
    Event_ID          INT,
    Event_TimeStamp    DATETIME
);

CREATE TABLE IF NOT EXISTS users (
    User_ID      TEXT,
    Name          TEXT,
    Department     TEXT,
    Email            TEXT,
    Customer_ID       BIGINT,
    Admin_ID           TEXT
);
