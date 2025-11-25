/*
====================================================================================================
Quality Checks
====================================================================================================
Script Purpose : 
  This script performs various quality checks for data consistency, accuracy and standardization across the 'silver' schema. It includes checks for :
  - Null or duplicate primary keys.
  - Unwanted spaces in string fields.
  - Data standardization and consistency.
  - Invalid date ranges and orders
  - Data consistency between related fields.

Usage Notes : 
  - Run these checks after data loading loading silver layer
  - Investigate and resolve any discrepancies found during the checks.
====================================================================================================
*/

-- =========================================================================================
-- 1) Data Quality Checks for crm_cst_info tables
-- =========================================================================================

-- Check For NULLs or duplicates in primary key
SELECT cst_id, COUNT(*)
FROM bronze.crm_cust_info 
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL;

-- check for leading or trailing spaces in string value columns
SELECT cst_key
FROM bronze.crm_cust_info
WHERE cst_key != TRIM(cst_key);

SELECT cst_firstname
FROM bronze.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname);

SELECT cst_lastname
FROM bronze.crm_cust_info
WHERE cst_lastname != TRIM(cst_lastname);

SELECT cst_gndr
FROM bronze.crm_cust_info
WHERE cst_gndr != TRIM(cst_gndr);

SELECT cst_marital_status
FROM bronze.crm_cust_info
WHERE cst_marital_status != TRIM(cst_marital_status);

-- Data Standardization & Consistency
SELECT DISTINCT cst_marital_status 
FROM bronze.crm_cust_info;

SELECT DISTINCT cst_gndr 
FROM bronze.crm_cust_info;


-- Checks for data verification after transformations
-- (Hint: replaced bronze. to silver. in queries to cross check)

-- Check For NULLs or duplicates in primary key
SELECT cst_id, COUNT(*)
FROM bronze.crm_cust_info 
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL;

-- check for leading or trailing spaces in string value columns
SELECT cst_key
FROM silver.crm_cust_info
WHERE cst_key != TRIM(cst_key);

SELECT cst_firstname
FROM silver.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname);

SELECT cst_lastname
FROM silver.crm_cust_info
WHERE cst_lastname != TRIM(cst_lastname);

SELECT cst_gndr
FROM silver.crm_cust_info
WHERE cst_gndr != TRIM(cst_gndr);

SELECT cst_marital_status
FROM silver.crm_cust_info
WHERE cst_marital_status != TRIM(cst_marital_status);

-- Data Standardization & Consistency
SELECT DISTINCT cst_marital_status 
FROM silver.crm_cust_info;

SELECT DISTINCT cst_gndr 
FROM silver.crm_cust_info;

-- =========================================================================================
--2) Data Quality Checks for crm_prd_info table
-- =========================================================================================
-- Check for NULLs or duplicates in primary key
SELECT prd_id,
	COUNT(*)
FROM bronze.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL;

-- Forming related Derived Columns
-- prd_key and id from bronze.erp_px_cat_g1v2 are partially similar
SELECT prd_id,
	prd_key,
	REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') 
FROM bronze.crm_prd_info
WHERE REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') NOT IN (SELECT id FROM bronze.erp_px_cat_g1v2);

-- prd_key and sls_prod_key are partially similar
SELECT prd_key,
	SUBSTRING(prd_key, 7, LEN(prd_key))
FROM bronze.crm_prd_info
WHERE SUBSTRING(prd_key, 7, LEN(prd_key)) NOT IN (SELECT sls_prod_key FROM bronze.crm_sales_details);

-- check for invalid neagtive or null cost
SELECT prd_cost 
FROM bronze.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL;

-- Data standardisation and consistency
SELECT DISTINCT prd_line 
FROM bronze.crm_prd_info;

-- Check for invalid date orders
-- prd_end_date column values are less than prd_end_date 
SELECT * 
FROM bronze.crm_prd_info
WHERE prd_end_dt < prd_start_dt;

SELECT TOP 20 
prd_key,
prd_start_dt,
LEAD(prd_start_dt) OVER(PARTITION BY prd_key ORDER BY prd_start_dt)-1 AS prd_end_dt
FROM bronze.crm_prd_info;

-- DDL for silver.crm_prd_info table
IF OBJECT_ID ('silver.crm_prd_info', 'U') IS NOT NULL
	DROP TABLE silver.crm_prd_info;
CREATE TABLE silver.crm_prd_info (
	prd_id			INT,
	cat_id			NVARCHAR(50),
    product_key		NVARCHAR(50),
    prd_nm			NVARCHAR(50),
    prd_cost		INT,
    prd_line		NVARCHAR(50),
    prd_start_dt	DATE,
    prd_end_dt		DATE,
    dwh_create_date DATETIME2 DEFAULT GETDATE()
);


-- Checks for data verification after transformations
-- (Hint: replaced bronze. to silver. in queries to cross check)
-- Check for NULLs or duplicates in primary key
SELECT prd_id,
	COUNT(*)
FROM silver.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL;

-- check for invalid neagtive or null cost
SELECT prd_cost 
FROM silver.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL;

-- Data standardisation and consistency
SELECT DISTINCT prd_line 
FROM silver.crm_prd_info;

-- Check for invalid date orders
-- prd_end_date column values are less than prd_end_date 
SELECT * 
FROM silver.crm_prd_info
WHERE prd_end_dt < prd_start_dt;

USE DataWarehouse;
SELECT TOP 10 * FROM bronze.crm_prd_info;
SELECT TOP 10 * FROM bronze.erp_px_cat_g1v2;
SELECT TOP 10 * FROM silver.crm_prd_info;
SELECT TOP 10 * FROM bronze.crm_sales_details;
SELECT TOP 10 * FROM bronze.crm_cust_info;

-- =========================================================================================
--3) Data Quality Checks for crm_sales_details
-- =========================================================================================
--Check for leading or trailing spaces in string columns
SELECT sls_ord_num 
FROM bronze.crm_sales_details
WHERE sls_ord_num != TRIM(sls_ord_num);

-- Check for columns are properly related or not
SELECT sls_ord_num,
	sls_prod_key,
	sls_cust_id,
	sls_order_dt,
	sls_ship_dt,
	sls_due_dt,
	sls_sales,
	sls_quantity,
	sls_price
FROM bronze.crm_sales_details
WHERE sls_cust_id NOT IN (SELECT cst_id FROM bronze.crm_cust_info); -- to check if there is not any cust_id is present in sales details table
-- WHERE sls_prod_key NOT IN ( SELECT product_key FROM silver.crm_prd_info);

-- Check for invalid dates
SELECT sls_order_dt 
FROM bronze.crm_sales_details
WHERE sls_order_dt <= 0 OR LEN(sls_order_dt) != 8;

SELECT sls_ship_dt 
FROM bronze.crm_sales_details
WHERE sls_ship_dt <= 0 OR LEN(sls_ship_dt) != 8;

SELECT sls_due_dt 
FROM bronze.crm_sales_details
WHERE sls_due_dt <= 0 OR LEN(sls_due_dt) != 8;

-- Check for invalid date orders
SELECT *
FROM bronze.crm_sales_details
WHERE sls_order_dt > sls_ship_dt OR sls_order_dt > sls_due_dt;

-- Check data consistency between sales, quantity and price
-- sales = quantity * price
-- Values must not be null, negative or zero

SELECT sls_sales,
	sls_quantity,
	sls_price,
	CASE			-- If sales are null or zero or negative, derive it using quantity and price
		WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price)
		THEN sls_quantity * ABS(sls_price )
		ELSE sls_sales
	END AS sales,
	CASE			-- If price is null or zero calculate it using sales and quantity
	WHEN sls_price IS NULL OR sls_price <= 0 
	THEN sls_sales / NULLIF(sls_quantity, 0)
	ELSE sls_price
	END AS price
FROM bronze.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
	OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
	OR sls_sales <= 0 OR sls_quantity <= 0 OR sls_price <= 0
ORDER BY sls_sales, sls_quantity, sls_price;

-- DDL for silver.crm_sales_details
IF OBJECT_ID ('silver.crm_sales_details', 'U') IS NOT NULL
	DROP TABLE silver.crm_sales_details;
CREATE TABLE silver.crm_sales_details(
	sls_ord_num NVARCHAR(50),
	sls_prod_key NVARCHAR(50),
	sls_cust_id INT,
	sls_order_dt DATE,
	sls_ship_dt DATE,
	sls_due_dt DATE,
	sls_sales INT,
	sls_quantity INT,
	sls_price INT,
	dwh_create_date DATETIME2 DEFAULT GETDATE()
);

-- Checks for data verification after transformations
-- (Hint: replaced bronze. to silver. in queries to cross check)
-- Check for invalid date orders
SELECT *
FROM silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt OR sls_order_dt > sls_due_dt;

-- Check data consistency between sales, quantity and price
-- sales = quantity * price
-- Values must not be null, negative or zero
SELECT sls_sales,
	sls_quantity,
	sls_price
FROM silver.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
	OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
	OR sls_sales <= 0 OR sls_quantity <= 0 OR sls_price <= 0
ORDER BY sls_sales, sls_quantity, sls_price;

SELECT * FROM silver.crm_sales_details;

-- =========================================================================================
--4) Data Quality Checks for erp_cust_az12
-- =========================================================================================

SELECT * FROM bronze.erp_cust_az12;
SELECT * FROM silver.crm_cust_info;

-- check for unwanted spaces
SELECT cid
FROM bronze.erp_cust_az12
WHERE cid != TRIM(cid);

-- change cid alike cst_key from crm_cust_info table
SELECT cid,
CASE 
	WHEN cid like 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
	ELSE cid
END
FROM bronze.erp_cust_az12;

-- check for invalid dates
SELECT cid, 
	bdate
FROM bronze.erp_cust_az12
WHERE bdate = NULL OR bdate > GETDATE() OR bdate < '1930-01-01';

-- Data standardization
SELECT DISTINCT gen
FROM bronze.erp_cust_az12;

SELECT DISTINCT gen,
CASE 
	WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
	WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
	ELSE 'n/a'
END AS gen
FROM bronze.erp_cust_az12;

-- Checks for data verification after transformations
-- (Hint: replaced bronze. to silver. in queries to cross check)
SELECT cid,
	bdate
FROM silver.erp_cust_az12
WHERE cid NOT IN(SELECT cid FROM silver.crm_cust_info);

-- check for invalid dates
SELECT cid, 
	bdate
FROM silver.erp_cust_az12
WHERE bdate > GETDATE();

-- Data Standardization check
SELECT DISTINCT gen
FROM silver.erp_cust_az12;

SELECT * FROM silver.erp_cust_az12;

-- =========================================================================================
--5) Data Quality Checks for erp_loc_a101
-- =========================================================================================

SELECT * FROM bronze.erp_loc_a101;
SELECT * FROM bronze.crm_cust_info;

-- Data Standardization
SELECT cid,
REPLACE(cid, '-', '')
FROM bronze.erp_loc_a101;

-- Data Standardization
SELECT DISTINCT cntry
FROM bronze.erp_loc_a101;

-- Checks for data verification after transformations
-- (Hint: replaced bronze. to silver. in queries to cross check)
SELECT * FROM silver.erp_loc_a101;
-- Data Standardization check
SELECT cid
FROM silver.erp_loc_a101;

-- Data Standardization
SELECT DISTINCT cntry
FROM silver.erp_loc_a101;

-- =========================================================================================
--6) Data Quality Checks for erp_px_cat_g1v2
-- =========================================================================================

SELECT * FROM bronze.erp_px_cat_g1v2;

-- Check for unwanted spaces
SELECT * 
FROM bronze.erp_px_cat_g1v2
WHERE cat != TRIM(cat) OR subcat != TRIM(subcat) OR subcat != TRIM(maintenance);

-- Data Standardization & Consistency
SELECT DISTINCT cat 
FROM bronze.erp_px_cat_g1v2;

SELECT DISTINCT subcat 
FROM bronze.erp_px_cat_g1v2;

SELECT DISTINCT maintenance 
FROM bronze.erp_px_cat_g1v2;

-- Checks for data verification after transformations
-- (Hint: replaced bronze. to silver. in queries to cross check)
SELECT * FROM silver.erp_px_cat_g1v2;
