
--- otázka č. 3: Která kategorie potravin zdražuje nejpomaleji (je u ní nejnižší percentuální meziroční růst)?


SELECT *
FROM v_food_price_changes vfpc ; -- view vytvořené v otázce č. 2 - pro meziroční vývoj cen


CREATE OR REPLACE VIEW v_food_price_cross_analysis as
WITH cte_lowest_price_change AS ( -- analyzuje změny cen a najde rok s nejnižším meziročním růstem pro každou food category
    SELECT
        food_category,
        year AS year_with_lowest_increase,
        percentage_price_change,
        ROW_NUMBER() OVER (PARTITION BY food_category ORDER BY percentage_price_change ASC, year ASC) AS rn
    FROM v_food_price_changes
    WHERE percentage_price_change IS NOT NULL
),
cte_avg_price_growth AS ( -- vypočítá průměrný meziroční růst cen pro každou food category
    SELECT
        food_category,
        COUNT(percentage_price_change) AS num_years,  -- počet let s dostupnými daty
        AVG(percentage_price_change) AS avg_percentage_price_change -- průměrná procentuální změna ceny 
    FROM v_food_price_changes
    WHERE percentage_price_change IS NOT NULL
    	AND percentage_price_change > 0
    GROUP BY food_category
)
SELECT 
    apg.food_category,
    ROUND(apg.avg_percentage_price_change, 2) AS avg_percentage_price_change,  -- průměrná meziroční změna ceny
    lpc.year_with_lowest_increase, -- rok s nejnižší meziroční změnou
    lpc.percentage_price_change AS lowest_percentage_price_change  -- hodnota nejnižší meziroční změny
FROM cte_avg_price_growth apg
LEFT JOIN cte_lowest_price_change lpc ON apg.food_category = lpc.food_category 
	AND lpc.rn = 1 -- zajistí výběr pouze jednoho roku
ORDER BY apg.avg_percentage_price_change ASC;



SELECT --- ukazuje, která kategorie má nejmenší průměrný meziroční růst cen
	food_category,
	avg_percentage_price_change
FROM v_food_price_cross_analysis vfpca ;



SELECT  --- ukazuje, která kategorie má úplně nejmenší meziroční nárůst cen
	food_category,
	lowest_percentage_price_change,
	year_with_lowest_increase 
FROM v_food_price_cross_analysis vfpca 
ORDER BY lowest_percentage_price_change ASC ;
