
WITH world_comparison AS (
    SELECT
        f1990.forest_area_sqkm AS forest_area_1990,
        f2016.forest_area_sqkm AS forest_area_2016,
        f2016.forest_area_sqkm - f1990.forest_area_sqkm AS forest_area_change,
        ROUND(
            ((f2016.forest_area_sqkm - f1990.forest_area_sqkm) / f1990.forest_area_sqkm * 100)::NUMERIC,
            2
        ) AS percent_change,
        ABS(f2016.forest_area_sqkm - f1990.forest_area_sqkm) AS area_lost
    FROM
        forestation f1990
    INNER JOIN
        forestation f2016
        ON f1990.country_code = f2016.country_code
    WHERE
        f1990.country_name = 'World'
        AND f1990.year = 1990
        AND f2016.year = 2016
),
closest_country AS (
    SELECT
        f.country_name,
        f.total_area_sqkm,
        wc.area_lost,
        ABS(f.total_area_sqkm - wc.area_lost) AS difference
    FROM
        forestation f,
        world_comparison wc
    WHERE
        f.year = 2016
        AND f.country_name != 'World'
        AND f.total_area_sqkm IS NOT NULL
    ORDER BY
        difference ASC
    LIMIT 1
)
SELECT
    wc.forest_area_1990,
    wc.forest_area_2016,
    wc.forest_area_change,
    wc.percent_change,
    cc.country_name AS closest_country,
    cc.total_area_sqkm AS closest_country_area
FROM
    world_comparison wc,
    closest_country cc;
