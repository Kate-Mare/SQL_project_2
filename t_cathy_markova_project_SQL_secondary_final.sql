
CREATE TABLE t_cathy_markova_project_SQL_secondary_final AS
SELECT 
    c.country,
    c.population,
    e.gdp,
    e.gini,
    e.year
FROM countries c
JOIN economies e ON c.country = e.country 
	AND c.population = e.population
WHERE c.continent = 'Europe'
    AND e.gini IS NOT NULL 
    AND e.gdp IS NOT NULL 
    AND e.year BETWEEN (
        SELECT CAST(MIN(DATE_PART('year', price_measured_from :: DATE)) AS INTEGER)
        FROM t_cathy_markova_project_sql_primary_final) 
    AND (
        SELECT CAST(MAX(DATE_PART('year', price_measured_to :: DATE)) AS INTEGER)
        FROM t_cathy_markova_project_sql_primary_final
    )
ORDER BY e.year;


select * from t_cathy_markova_project_sql_secondary_final tpsf;