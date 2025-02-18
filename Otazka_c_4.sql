
--- Otázka č. 4: Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (větší než 10%)?


CREATE OR REPLACE VIEW v_wages_analysis_new AS --  view pro analýzu průměrných mezd bez rozlišení odvětví
WITH wage_analysis AS (
    SELECT
        payroll_year AS year,
        ROUND(AVG(average_wages)) AS average_wage,
        ROUND(LAG(AVG(average_wages)) OVER (ORDER BY payroll_year)) AS previous_year_wages,
        ROUND((AVG(average_wages) - LAG(AVG(average_wages)) OVER (ORDER BY payroll_year))
        	/ NULLIF(LAG(AVG(average_wages)) OVER (ORDER BY payroll_year),0) *100, 2) AS wage_growth_percentage,
        CASE 
            WHEN (AVG(average_wages) - LAG(AVG(average_wages)) OVER (ORDER BY payroll_year)) > 0 THEN 'growth'
            ELSE 'decline'
        END AS wage_trend
    FROM t_katerina_markova_project_sql_primary_final tppf
    GROUP BY year
)
SELECT *
FROM wage_analysis
WHERE previous_year_wages IS NOT NULL
ORDER BY year, wage_trend;


SELECT * FROM v_wages_analysis_new ;



CREATE OR REPLACE VIEW v_prices_analysis_new AS -- vytvoření view pro analýzu cen bez rozlišení kategorie zboží
WITH price_aggregated_data AS ( 
    SELECT 
        EXTRACT(YEAR FROM price_measured_from :: DATE) AS year,
        AVG(food_price) :: NUMERIC AS average_food_price
    FROM t_cathy_markova_project_sql_primary_final tppf
    GROUP BY year
),
price_analysis AS (
    SELECT 
        year,
        ROUND(average_food_price, 2) AS average_price,
        ROUND(LAG(average_food_price) OVER (ORDER BY year), 2) AS previous_year_food_price,
        ROUND((average_food_price - LAG(average_food_price) OVER (ORDER BY YEAR))
        	/ NULLIF(LAG((average_food_price)) OVER (ORDER BY year), 0) * 100, 2) AS price_growth_percentage,
        CASE 
       		WHEN (average_food_price - LAG((average_food_price)) OVER (ORDER BY year)) > 0 THEN 'growth'
    		else 'decline'
    	END AS price_trend
	FROM price_aggregated_data
	)
SELECT *
FROM price_analysis
WHERE previous_year_food_price IS NOT NULL
ORDER BY year;


select *
from v_prices_analysis_new vpan ;



SELECT  --- výsledný spojený select růstových hodnot pro porovnání změn cen a mezd 
	vpan.year AS year,
	vpan.price_growth_percentage,
	vwan.wage_growth_percentage,
	vpan.price_growth_percentage - vwan.wage_growth_percentage AS price_wage_rel_difference
FROM v_prices_analysis_new vpan 
JOIN v_wages_analysis_new vwan ON vpan.year = vwan.year
WHERE price_growth_percentage IS NOT NULL
	AND wage_growth_percentage IS NOT NULL
	AND price_growth_percentage  > 0
	AND wage_growth_percentage > 0
	AND vpan.price_growth_percentage > vwan.wage_growth_percentage
ORDER BY year;