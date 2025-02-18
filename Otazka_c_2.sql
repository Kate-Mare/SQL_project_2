
--- otázka č. 2:  Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období v dostupných datech cen a mezd?


CREATE OR REPLACE VIEW v_weekly_food_prices AS -- view pro týdenní vývoj cen, nejprve seskupíme data podle týdnů
SELECT
    food_category,
    price_measured_from,
    price_measured_to,
    ROUND(AVG(food_price) :: NUMERIC, 2) AS weekly_avg_food_price
FROM t_cathy_markova_project_sql_primary_final tppf
WHERE food_code IN ('111301', '114201') -- filtr na chléb a mléko
GROUP BY price_measured_from, price_measured_to, food_category;


CREATE OR REPLACE VIEW v_yearly_food_prices as -- view pro roční průměry cen
SELECT
    food_category,
    EXTRACT(YEAR FROM price_measured_from::DATE) AS year,
    ROUND(AVG(weekly_avg_food_price) :: NUMERIC, 2) AS avg_annual_food_price
FROM v_weekly_food_prices
GROUP BY year, food_category; --seskupení data podle roku, aby se dal porovnat konkrétní rok s původním payroll_year


CREATE materialized VIEW v_food_price_changes AS -- view pro meziroční vývoj cen
SELECT
    food_category,
    year,
    avg_annual_food_price,
    LAG(avg_annual_food_price) OVER (PARTITION BY food_category ORDER BY year) AS previous_avg_food_price,
    ROUND(((avg_annual_food_price - LAG(avg_annual_food_price) OVER (PARTITION BY food_category ORDER BY year))
        / NULLIF(LAG(avg_annual_food_price) OVER (PARTITION BY food_category ORDER BY year), 0)) * 100, 2) AS percentage_price_change
FROM v_yearly_food_prices;


WITH cte_first_last_years AS ( -- získání prvního a posledního roku
    SELECT 
        food_category,
        MIN(year) AS first_year, 
        MAX(year) AS last_year
    FROM v_yearly_food_prices
    GROUP BY food_category
)
select -- výsledný select pro zobrazení prům. mzdy, prům. ceny a množství zboží, které je možné si zakoupit
    yd.food_category,
    yd.year AS payroll_year,
    ROUND(AVG(tppf.average_wages) :: NUMERIC, 2) AS avg_annual_wage,
    yd.avg_annual_food_price,
    FLOOR(AVG(tppf.average_wages) / yd.avg_annual_food_price) AS purchasable_quantity
FROM v_yearly_food_prices yd
JOIN cte_first_last_years fly ON yd.food_category = fly.food_category 
	AND (yd.year = fly.first_year OR yd.year = fly.last_year)
JOIN t_cathy_markova_project_sql_primary_final tppf ON CAST(yd.year AS INTEGER) = EXTRACT(YEAR FROM tppf.price_measured_from :: DATE)  
GROUP BY yd.food_category, yd.year, yd.avg_annual_food_price
ORDER BY payroll_year, food_category;

