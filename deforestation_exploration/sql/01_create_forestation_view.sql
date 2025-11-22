-- This view combines forest_area, land_area, and regions tables
-- and calculates the percentage of land area designated as forest.
-- Conversion factor: 1 sq mi = 2.59 sq km

CREATE VIEW forestation AS
SELECT
    f.country_code,
    f.country_name,
    f.year,
    f.forest_area_sqkm,
    l.total_area_sq_mi,
    -- Convert square miles to square kilometers
    l.total_area_sq_mi * 2.59 AS total_area_sqkm,
    r.region,
    r.income_group,
    -- Calculate percent of land area designated as forest
    ROUND(
        (f.forest_area_sqkm / (l.total_area_sq_mi * 2.59) * 100)::NUMERIC,
        2
    ) AS percent_forest
FROM
    forest_area f
INNER JOIN
    land_area l
    ON f.country_code = l.country_code
    AND f.year = l.year
INNER JOIN
    regions r
    ON f.country_code = r.country_code;
