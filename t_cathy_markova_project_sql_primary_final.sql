
CREATE TABLE t_cathy_markova_project_sql_primary_final AS
SELECT
	cp.id,    
	cpay.payroll_year,
    cpib.name AS industry,
    cpay.value AS average_wages,
	cpc.code as food_code,
    cpc.name AS food_category,
    cpc.price_value,
    cpc.price_unit,
    cp.value AS food_price,    
    TO_CHAR(cp.date_from, 'YYYY-mm-dd') AS price_measured_from,
    TO_CHAR(cp.date_to, 'YYYY-mm-dd') AS price_measured_to
    FROM czechia_price AS cp
JOIN czechia_price_category AS cpc ON cp.category_code = cpc.code
JOIN czechia_payroll AS cpay ON DATE_PART('year', cp.date_from) = cpay.payroll_year
    AND cpay.value_type_code = 5958
    AND cp.region_code IS NULL
JOIN czechia_payroll_industry_branch AS cpib ON cpay.industry_branch_code = cpib.code
WHERE
    cpay.value_type_code = 5958;


SELECT *
FROM t_cathy_markova_project_sql_primary_final;