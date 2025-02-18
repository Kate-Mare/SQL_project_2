
--- Otázka č. 5:  Má výška HDP vliv na změny ve mzdách a cenách potravin?  Neboli, pokud HDP vzroste výrazněji v jednom roce,
--- projeví se to na cenách potravin či mzdách ve stejném nebo následujícím roce výraznějším růstem?


select *
from v_prices_analysis_new vpan ;

select *
from v_wages_analysis_new vwan ;

select *
from t_cathy_markova_project_sql_secondary_final tpsf;



WITH cte_gdp AS ( -- varianta pro sledování změn GDP, cen a mezd za stejné období
    SELECT 
        tpsf.year AS year,
        tpsf.gdp AS actual_GDP,
        LAG(tpsf.gdp :: NUMERIC) OVER (ORDER BY tpsf.year) AS previous_GDP,
        ROUND((tpsf.gdp :: NUMERIC - LAG(tpsf.gdp :: NUMERIC) OVER (ORDER BY tpsf.year)) 
       		/ NULLIF(LAG(tpsf.gdp :: NUMERIC) OVER (ORDER BY tpsf.year), 0) * 100, 2) AS GDP_growth_percentage, 
        vpan.price_growth_percentage,
        vwan.wage_growth_percentage,
        CASE 
        	WHEN (tpsf.gdp - LAG(tpsf.gdp) OVER (ORDER BY tpsf.year)) > 0 THEN 'growth'
            ELSE 'decline'
        END AS GDP_trend,
        vpan.price_trend,
        vwan.wage_trend
    FROM t_cathy_markova_project_sql_secondary_final tpsf
    LEFT JOIN v_prices_analysis_new vpan ON vpan.year = tpsf.year
    LEFT JOIN v_wages_analysis_new vwan ON vwan.year = tpsf.year 
    WHERE country = 'Czech Republic'
)
SELECT *
FROM cte_gdp
WHERE gdp_growth_percentage IS NOT NULL 
	AND price_growth_percentage IS NOT NULL
	AND wage_growth_percentage IS NOT NULL;


WITH cte_gdp_next AS ( -- sledování vlivu GDP na mzdy a ceny v následujícím období
    SELECT 
        tpsf.year AS year,
        tpsf.gdp AS actual_GDP,
        LAG(tpsf.gdp :: NUMERIC) OVER (ORDER BY tpsf.year) AS previous_GDP,
        ROUND((tpsf.gdp :: NUMERIC - LAG(tpsf.gdp :: NUMERIC) OVER (ORDER BY tpsf.year)) 
        	/ NULLIF(LAG(tpsf.gdp :: NUMERIC) OVER (ORDER BY tpsf.year), 0) * 100, 2) AS GDP_growth_percentage, 
        vpan.price_growth_percentage,
        vwan.wage_growth_percentage,
        LEAD(vpan.price_growth_percentage) OVER (ORDER BY vpan.year) AS next_year_price_growth, -- posun cenového růstu o 1 rok
        LEAD(vwan.wage_growth_percentage) OVER (ORDER BY vwan.year) AS next_year_wage_growth, -- posun mzdového růstu o 1 rok
        vpan.price_trend,
        vwan.wage_trend,   
        CASE 
            WHEN (tpsf.gdp - LAG(tpsf.gdp) OVER (ORDER BY tpsf.year)) > 0 THEN 'growth'
            ELSE 'decline'
        END AS GDP_trend,
        LEAD(vpan.price_trend) OVER (ORDER BY vpan.year) AS next_year_price_trend, -- posun trendu růstu cen o 1 rok
        LEAD(vwan.wage_trend) OVER (ORDER BY vwan.year) AS next_year_wage_trend -- posun trendu růstu mezd o 1 rok 
    FROM t_cathy_markova_project_sql_secondary_final tpsf
    FULL OUTER JOIN v_prices_analysis_new vpan ON vpan.year = tpsf.year
    FULL OUTER JOIN v_wages_analysis_new vwan ON vwan.year = tpsf.year 
    WHERE country = 'Czech Republic'
)
SELECT *
FROM cte_gdp_next
WHERE GDP_growth_percentage IS NOT NULL 
	AND price_growth_percentage IS NOT NULL
	AND next_year_price_growth IS NOT NULL 
	AND next_year_wage_growth IS NOT NULL;
