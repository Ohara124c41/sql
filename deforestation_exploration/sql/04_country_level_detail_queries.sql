-- This query returns all data needed for the Country-Level Detail section
-- Results are labeled by category for easy identification

WITH success_absolute AS (
    SELECT
        'SUCCESS_ABSOLUTE' AS query_type,
        f1990.country_name,
        f1990.region,
        f2016.forest_area_sqkm - f1990.forest_area_sqkm AS change_value,
        NULL AS quartile
    FROM
        forestation f1990
    INNER JOIN
        forestation f2016
        ON f1990.country_code = f2016.country_code
    WHERE
        f1990.year = 1990
        AND f2016.year = 2016
        AND f1990.country_name != 'World'
        AND f1990.forest_area_sqkm IS NOT NULL
        AND f2016.forest_area_sqkm IS NOT NULL
        AND f2016.forest_area_sqkm > f1990.forest_area_sqkm
    ORDER BY
        change_value DESC
    LIMIT 2
),
success_percent AS (
    SELECT
        'SUCCESS_PERCENT' AS query_type,
        f1990.country_name,
        f1990.region,
        ROUND(
            ((f2016.forest_area_sqkm - f1990.forest_area_sqkm) / f1990.forest_area_sqkm * 100)::NUMERIC,
            2
        ) AS change_value,
        NULL AS quartile
    FROM
        forestation f1990
    INNER JOIN
        forestation f2016
        ON f1990.country_code = f2016.country_code
    WHERE
        f1990.year = 1990
        AND f2016.year = 2016
        AND f1990.country_name != 'World'
        AND f1990.forest_area_sqkm IS NOT NULL
        AND f2016.forest_area_sqkm IS NOT NULL
        AND f1990.forest_area_sqkm > 0
        AND f2016.forest_area_sqkm > f1990.forest_area_sqkm
    ORDER BY
        change_value DESC
    LIMIT 1
),
concern_absolute AS (
    SELECT
        'CONCERN_ABSOLUTE' AS query_type,
        f1990.country_name,
        f1990.region,
        f2016.forest_area_sqkm - f1990.forest_area_sqkm AS change_value,
        NULL AS quartile
    FROM
        forestation f1990
    INNER JOIN
        forestation f2016
        ON f1990.country_code = f2016.country_code
    WHERE
        f1990.year = 1990
        AND f2016.year = 2016
        AND f1990.country_name != 'World'
        AND f1990.forest_area_sqkm IS NOT NULL
        AND f2016.forest_area_sqkm IS NOT NULL
    ORDER BY
        change_value ASC
    LIMIT 5
),
concern_percent AS (
    SELECT
        'CONCERN_PERCENT' AS query_type,
        f1990.country_name,
        f1990.region,
        ROUND(
            ((f2016.forest_area_sqkm - f1990.forest_area_sqkm) / f1990.forest_area_sqkm * 100)::NUMERIC,
            2
        ) AS change_value,
        NULL AS quartile
    FROM
        forestation f1990
    INNER JOIN
        forestation f2016
        ON f1990.country_code = f2016.country_code
    WHERE
        f1990.year = 1990
        AND f2016.year = 2016
        AND f1990.country_name != 'World'
        AND f1990.forest_area_sqkm IS NOT NULL
        AND f2016.forest_area_sqkm IS NOT NULL
        AND f1990.forest_area_sqkm > 0
    ORDER BY
        change_value ASC
    LIMIT 5
),
quartile_counts AS (
    SELECT
        'QUARTILE_COUNT' AS query_type,
        quartile AS country_name,
        NULL AS region,
        COUNT(*)::NUMERIC AS change_value,
        quartile
    FROM (
        SELECT
            CASE
                WHEN percent_forest <= 25 THEN '0-25%'
                WHEN percent_forest > 25 AND percent_forest <= 50 THEN '25-50%'
                WHEN percent_forest > 50 AND percent_forest <= 75 THEN '50-75%'
                ELSE '75-100%'
            END AS quartile
        FROM
            forestation
        WHERE
            year = 2016
            AND percent_forest IS NOT NULL
            AND country_name != 'World'
    ) sub
    GROUP BY
        quartile
),
top_quartile AS (
    SELECT
        'TOP_QUARTILE' AS query_type,
        country_name,
        region,
        percent_forest AS change_value,
        '75-100%' AS quartile
    FROM
        forestation
    WHERE
        year = 2016
        AND percent_forest > 75
        AND country_name != 'World'
),
us_comparison AS (
    SELECT
        'US_COMPARISON' AS query_type,
        'Countries above US' AS country_name,
        NULL AS region,
        (
            SELECT COUNT(*)::NUMERIC
            FROM forestation f1
            WHERE f1.year = 2016
                AND f1.country_name != 'World'
                AND f1.percent_forest > (
                    SELECT percent_forest
                    FROM forestation
                    WHERE country_name = 'United States'
                        AND year = 2016
                )
                AND f1.percent_forest IS NOT NULL
        ) AS change_value,
        NULL AS quartile
)
SELECT * FROM success_absolute
UNION ALL
SELECT * FROM success_percent
UNION ALL
SELECT * FROM concern_absolute
UNION ALL
SELECT * FROM concern_percent
UNION ALL
SELECT * FROM quartile_counts
UNION ALL
SELECT * FROM top_quartile
UNION ALL
SELECT * FROM us_comparison
ORDER BY
    query_type,
    change_value DESC;
