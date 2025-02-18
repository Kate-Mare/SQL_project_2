# ***ENGETO - Projekt SQL – datová analýza***

## Analýza ekonomických dat
Tento projekt analyzuje vývoj mezd, cen potravin a HDP v České republice v průběhu sledovaného období. Data pochází z několika databází obsahujících informace o průměrných mzdách, cenách potravin a makroekonomických ukazatelích, včetně HDP. 
Hlavním cílem je odpovědět na několik klíčových otázek týkajících se ekonomických trendů a souvislostí mezi faktory.

## Cíl projektu: 
- analyzovat vztah mezi vývojem mezd a cen jednotlivých kategorií potravin v České republice za sledované období 
- zjistit, zda se mzdy vyvíjejí rovnoměrně napříč hospodářskými odvětvími 
- posoudit  vliv průměrného příjmu na dostupnost vybraných kategorií potravin
- ověřit hypotézu, že výše HDP má vliv na změnu mezd a cen potravin. 

## Hlavní výzkumné otázky: 
1. Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?
2. Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období v dostupných datech cen a mezd?
3. Která kategorie potravin zdražuje nejpomaleji (je u ní nejnižší percentuální meziroční nárůst)?
4. Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (větší než 10 %)?
5. Má výška HDP vliv na změny ve mzdách a cenách potravin? Neboli, pokud HDP vzroste výrazněji v jednom roce, projeví se to na cenách potravin či mzdách ve stejném nebo následujícím roce výraznějším růstem?

## Dataset a tabulky:
Použitá data pocházejí z veřejných zdrojů, z Portálu otevřených dat ČR a zahrnují:
1. Hlavní tabulka: t_cathy_markova_project_sql_primary_final -
Obsahuje  data o mzdách a cenách za sledované období v České republice:
- payroll_year – rok výplaty mezd
- industry – hospodářské odvětví
- average_wages – průměrná hrubá mzda v tis. Kč
- food_code – kód kategorie potravin
- food_category – název kategorie potravin
- food_price – průměrná cena dané kategorie potravin
- price_value – počet měrné jednotky ceny, např. 1
- price_unit – měrná jednotka ceny, např. kg
- price_measured from, price_measured_to – počáteční a konečné datum měření ceny

2.  Sekundární  tabulka: t_cathy_markova_project_sql_secondary_final –
Obsahuje doplňující ekonomické údaje :
- GDP – hrubý domácí produkt
- GINI – statistická míra nerovnosti v rozdělení příjmů nebo bohatství v určité populaci
- population – počet obyvatelstva

## Ukázka použitého SQL skriptu:
```sql
CREATE TABLE t_cathy_markova_project_SQL_secondary_final AS
SELECT 
    c.country,
    c.population,
    e.gdp,
    e.gini,
    e.year
FROM countries c
JOIN economies e ON c.country = e.country 
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
    LEFT JOIN v_price_analysis_new vpan ON vpan.year = tpsf.year
    LEFT JOIN v_wages_analysis_new vwan ON vwan.year = tpsf.year 
    WHERE country = 'Czech Republic'
)
SELECT *
FROM cte_gdp
WHERE gdp_growth_percentage IS NOT NULL 
	AND price_growth_percentage IS NOT NULL
	AND wage_growth_percentage IS NOT NULL;
```

## Metodologie analýzy
Analýza byla provedena pomocí SQL dotazovacího jazyka s využitím relační databáze. 

## Použité techniky: 

1. ### Časové porovnání dat
- Využití LAG() a LEAD() pro porovnání hodnot mezi jednotlivými roky.
- AVG() pro výpočet průměrných hodnot mezd a cen potravin.
- EXTRACT(YEAR FROM date_column) pro seskupení dat podle roků.
2. ### Vývoj mezd v odvětvích
- PARTITION BY industry s LAG() k porovnání meziročních změn.
- CASE WHEN pro kategorizaci na "growth" (růst) a "decline" (pokles).
3. ### Koupěschopnost obyvatelstva
- Výpočet kupní síly (FLOOR(average_wage / avg_food_price)).
4. ### Identifikace nejpomalejšího růstu cen potravin
- ROW_NUMBER() OVER (PARTITION BY food_category ORDER BY percentage_price_change ASC) pro určení nejnižšího růstu cen.
5. ### Vliv HDP na mzdy a ceny potravin
- Spojení tabulek t_cathy_markova_project_sql_primary_final a t_cathy_markova_project_sql_secondary_final.
- Výpočet meziročního růstu HDP pomocí LAG() a porovnání s růstem mezd a cen.


## Struktura výstupního souboru 
Výstupní soubor má podobu SQL skriptu generujícího vstupní tabulky, mezivýsledky i výsledné tabulky.


## Shrnutí hlavních zjištění
- Mzdy dlouhodobě rostou ve všech sledovaných odvětvích, ale v některých letech dochází ke krátkodobým poklesům. 
-  Koupěschopnost se zvýšila – v roce 2018 bylo možné koupit více mléka i chleba než v roce 2006. 
- Nejmenší meziroční růst měla kategorie jakostního bílého vína (2,70 % ročně). Největší pokles cen zaznamenala rajčata červená kulatá v roce 2017 (-30,28 %).
-  Ve sledovaném období nikdy nedošlo k růstu cen potravin o více než 10 % nad růst mezd. 
-  Růst HDP má určitou souvislost s růstem mezd, ale ne vždy se projeví ve stejném roce.


## Možná omezení a doporučení
- Analýza vlivu HDP na mzdy a ceny byla možná pouze pro ČR kvůli nedostupnosti dat pro jiné země.
- Budoucí výzkum by mohl zahrnout širší ekonomické faktory, například inflaci nebo změny v produktivitě práce.


## Autor:
Kateřina Marková


