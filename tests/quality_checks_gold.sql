/*
========================================================
Quality Checks
========================================================
Script Purpose:
	This script performs quality checks to validate the integrity, consistency, 
	and accuracy of the Gold Layer. These checks ensure:
	- Uniqueness of surrogate keys in dimension tables.
	- Referential integrity between fact and dimension tables.
	- Validation of relationships in the data model for analytical purposes.

Usage Notes : 
	- Run these checks after data loading silver layer.
	- Investigate and resolve any discrepancies found during the checks.
============================================================================================

*/

-- ================================================================
-- Checking 'gold.customer_key'
-- ================================================================
-- Check for the Uniqueness of customer key in gold.dim_customers
-- Expectation : No results
SELECT
	customer_key,
	COUNT(*) AS duplicate_count
FROM gold.dim_customers
GROUP BY customer_key
HAVING COUNT(*) > 1;

-- ================================================================
-- Checking 'gold.product_key'
-- ================================================================
-- Check for the Uniqueness of product key in gold.dim_products
-- Expectation : No results
SELECT
	product_key,
	COUNT(*) AS duplicate_count
FROM gold.dim_products
GROUP BY product_key
HAVING COUNT(*) > 1;

-- ================================================================
-- Checking 'gold.fact_sales'
-- ================================================================
-- Foreign Key Integrity (Dimensions)
-- Check the data model connectivity between fact and dimensions
SELECT * 
FROM gold.fact_sales fc
LEFT JOIN gold.dim_customers dc
	ON fc.customer_key = dc.customer_key
LEFT JOIN gold.dim_products dp
	ON fc.product_key = dp.product_key
WHERE dp.product_key IS NULL;
--WHERE dc.customer_key IS NULL ;
