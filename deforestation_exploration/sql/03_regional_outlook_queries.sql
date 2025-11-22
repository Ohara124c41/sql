-- This query returns all data needed for the Regional Outlook section

WITH regional_forest AS (
    SELECT
        r1990.region,
        ROUND(
            (SUM(r1990.forest_area_sqkm) / SUM(r1990.total_area_sqkm) * 100)::NUMERIC,
            2
        ) AS forest_percent_1990,
        ROUND(
            (SUM(r2016.forest_area_sqkm) / SUM(r2016.total_area_sqkm) * 100)::NUMERIC,
            2
        ) AS forest_percent_2016
    FROM
        forestation r1990
    INNER JOIN
        forestation r2016
        ON r1990.country_code = r2016.country_code
    WHERE
        r1990.year = 1990
        AND r2016.year = 2016
        AND r1990.forest_area_sqkm IS NOT NULL
        AND r2016.forest_area_sqkm IS NOT NULL
        AND r1990.total_area_sqkm IS NOT NULL
        AND r2016.total_area_sqkm IS NOT NULL
    GROUP BY
        r1990.region
),
world_forest AS (
    SELECT
        'World' AS region,
        percent_forest AS forest_percent_1990,
        NULL::NUMERIC AS forest_percent_2016
    FROM
        forestation
    WHERE
        country_name = 'World'
        AND year = 1990
    UNION ALL
    SELECT
        'World' AS region,
        NULL::NUMERIC AS forest_percent_1990,
        percent_forest AS forest_percent_2016
    FROM
        forestation
    WHERE
        country_name = 'World'
        AND year = 2016
)
SELECT
    COALESCE(rf.region, wf.region) AS region,
    COALESCE(rf.forest_percent_1990, MAX(wf.forest_percent_1990)) AS forest_percent_1990,
    COALESCE(rf.forest_percent_2016, MAX(wf.forest_percent_2016)) AS forest_percent_2016,
    CASE
        WHEN rf.region IS NOT NULL
        THEN rf.forest_percent_2016 - rf.forest_percent_1990
        ELSE MAX(wf.forest_percent_2016) - MAX(wf.forest_percent_1990)
    END AS percent_change
FROM
    regional_forest rf
FULL OUTER JOIN
    world_forest wf
    ON rf.region = wf.region
GROUP BY
    rf.region, rf.forest_percent_1990, rf.forest_percent_2016, wf.region
ORDER BY
    CASE WHEN COALESCE(rf.region, wf.region) = 'World' THEN 0 ELSE 1 END,
    COALESCE(rf.region, wf.region);
