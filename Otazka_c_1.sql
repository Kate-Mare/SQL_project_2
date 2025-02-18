
--- otázka č.1: Rostou v průběhu let mzdy ve všech odvětvích, nebo v někerých klesají?


WITH cte_wage_analysis AS ( -- analýza vývoje mezd
    SELECT
        payroll_year,
        industry,
        ROUND(AVG(average_wages) :: NUMERIC) AS average_wage,
        ROUND(LAG(AVG(average_wages)) OVER (PARTITION BY industry ORDER BY payroll_year) :: NUMERIC) AS previous_year_wages,
    	ROUND((AVG(average_wages) - LAG(AVG(average_wages)) OVER (PARTITION BY industry ORDER BY payroll_year)) 
    		/ LAG(AVG(average_wages)) OVER (PARTITION BY industry ORDER BY payroll_year) * 100, 3) AS wage_growth_percentage,
        CASE 
            WHEN (AVG(average_wages) - LAG(AVG(average_wages)) OVER (PARTITION BY industry ORDER BY payroll_year)) > 0 THEN 'growth'
            ELSE 'decline'
        END AS trend
    FROM t_katerina_markova_project_sql_primary_final tppf
    GROUP BY payroll_year, industry
)
SELECT *
FROM cte_wage_analysis
WHERE previous_year_wages IS NOT NULL
ORDER BY industry, payroll_year, trend
;


