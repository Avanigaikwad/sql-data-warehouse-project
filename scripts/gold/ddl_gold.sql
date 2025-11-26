/*
=======================================================================
DDL Script : Create Gold Views
=======================================================================
Script Purpose:
  This script creates views for the Gold Layer in the data warehouse.
  The Gold Layer represents the finaldimension and fact tables (Star Schema)

  Each view performs transformations and combines data from the Silver Layer 
  to produce a clean, enriched, and business-ready dataset.

Usage : 
  - These views can be queried directly for analytics and reporting.
==========================================================================
*/

--=======================================================================
-- Create Dimension :gold.dim_customers
--=======================================================================
CREATE VIEW gold.dim_customers AS
SELECT
	ROW_NUMBER() OVER(ORDER BY cc.cst_id) AS customer_key,
	cc.cst_id AS customer_id,
	cc.cst_key AS customer_number,
	cc.cst_firstname AS first_name,
	cc.cst_lastname AS last_name,
	el.cntry AS country,
	CASE 
		WHEN cst_gndr IN ('Male', 'Female') THEN cc.cst_gndr
		ELSE COALESCE(ec.gen,'n/a')
	END AS gender,
	cc.cst_marital_status AS marital_status,
	ec.bdate AS birthdate,
	cc.cst_create_date AS create_date
FROM silver.crm_cust_info cc
LEFT JOIN silver.erp_cust_az12 ec
	ON cc.cst_key = ec.cid
LEFT JOIN silver.erp_loc_a101 el
	ON cc.cst_key = el.cid;

--=======================================================================
-- Create Dimension :gold.dim_products
--=======================================================================
CREATE VIEW gold.dim_products AS
SELECT
	ROW_NUMBER() OVER(ORDER BY cp.prd_start_dt) AS product_key,
	cp.prd_id AS product_id,
	cp.cat_id AS category_id,
	cp.product_key AS product_number,
	cp.prd_nm AS product_name,
	ep.cat AS category,
	ep.subcat AS subcategory,
	ep.maintenance,
	cp.prd_cost AS cost,
	cp.prd_line AS product_line,
	cp.prd_start_dt AS start_date
FROM silver.crm_prd_info cp
LEFT JOIN silver.erp_px_cat_g1v2 ep
	ON cp.cat_id  = ep.id
WHERE prd_end_dt IS NULL; -- Filter out all historical data


--=======================================================================
-- Create Fact :gold.fact_sales
--=======================================================================
CREATE VIEW gold.fact_sales AS
SELECT
	sls_ord_num AS order_number,
	dp.product_key AS product_key,
	dc.customer_key AS customer_key,
	sls_order_dt AS order_date,
	sls_ship_dt AS ship_date,
	sls_due_dt AS due_date,
	sls_sales AS sales_amount,
	sls_quantity AS quantity,
	sls_price AS price
FROM silver.crm_sales_details sd
LEFT JOIN gold.dim_customers dc
	ON sd.sls_cust_id = dc.customer_id
LEFT JOIN gold.dim_products dp
	ON sd.sls_prod_key = dp.product_number;


SELECT * FROM gold.fact_sales;
