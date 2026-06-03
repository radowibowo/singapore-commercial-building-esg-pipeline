-- ============================================================================
-- PROJECT: Singapore Commercial Buildings Energy Efficiency Pipeline
-- PURPOSE: End-to-End Data Ingestion, Cleaning, and ESG Compliance Analytics
-- ============================================================================

-- 1. STAGING AREA (Safe Ingestion of Raw Data)
-- A staging table with all columns set to TEXT ensures all 1,244 rows load without type-conversion failures.

DROP TABLE IF EXISTS sg_energy_raw;

CREATE TABLE sg_energy_raw (
    buildingname TEXT,
    buildingaddress TEXT,
    buildingtype TEXT,
    greenmarkstatus TEXT,
    greenmarkrating TEXT,
    greenmarkyearaward TEXT,
    buildingsize TEXT,
    grossfloorarea TEXT,
    energy_2017 TEXT,
    energy_2018 TEXT,
    voluntarydisclosure TEXT
);


-- 2. PRODUCTION AREA (Clean Production Table Structure)
-- A production table with proper data types replaces the staging table. 

DROP TABLE IF EXISTS sg_energy_clean;

CREATE TABLE sg_energy_clean (
    building_name VARCHAR(200),
    building_type VARCHAR(100),
    gross_floor_area NUMERIC(12,2),
    eui_2017 NUMERIC(6,2),
    eui_2018 NUMERIC(6,2)
);


-- 3. TRANSFORMATION & SANITATION (ETL Process)
-- Missing values ('NA') are converted to NULL, and commas are stripped from numeric fields.

INSERT INTO sg_energy_clean (building_name, building_type, gross_floor_area, eui_2017, eui_2018)
SELECT
    buildingname AS building_name,
    buildingtype AS building_type,
    REPLACE(grossfloorarea, ',', '')::NUMERIC AS gross_floor_area,
    CASE WHEN energy_2017 = 'NA' THEN NULL ELSE energy_2017::NUMERIC END AS eui_2017,
    CASE WHEN energy_2018 = 'NA' THEN NULL ELSE energy_2018::NUMERIC END AS eui_2018
FROM sg_energy_raw
WHERE buildingname IS NOT NULL AND buildingname != 'NA'
  AND grossfloorarea IS NOT NULL AND grossfloorarea != 'NA';


-- 4. FINAL ANALYTICS & AUDIT FALLBACK (Anti-Greenwashing Analytics via COALESCE)
-- Computes operational carbon risk and applies fallback logic for missing reporting periods.

SELECT
    building_name,
    building_type,
    gross_floor_area,
    eui_2017,
    eui_2018,
    COALESCE(eui_2018, eui_2017) AS effective_eui,
    CASE
        WHEN building_type = 'Office' THEN 180
        WHEN building_type = 'Retail' THEN 350
        WHEN building_type = 'Hotel' THEN 250
        ELSE 220
    END AS benchmark_eui,
    CASE
        WHEN building_type = 'Office' AND COALESCE(eui_2018, eui_2017) > 180 THEN (COALESCE(eui_2018, eui_2017) - 180) * gross_floor_area
        WHEN building_type = 'Retail' AND COALESCE(eui_2018, eui_2017) > 350 THEN (COALESCE(eui_2018, eui_2017) - 350) * gross_floor_area
        WHEN building_type = 'Hotel' AND COALESCE(eui_2018, eui_2017) > 250 THEN (COALESCE(eui_2018, eui_2017) - 250) * gross_floor_area
        ELSE 0
    END AS wasted_electricity_kwh,
    CASE
        WHEN building_type = 'Office' AND COALESCE(eui_2018, eui_2017) > 180 THEN ((COALESCE(eui_2018, eui_2017) - 180) * gross_floor_area) * 0.0004
        WHEN building_type = 'Retail' AND COALESCE(eui_2018, eui_2017) > 350 THEN ((COALESCE(eui_2018, eui_2017) - 350) * gross_floor_area) * 0.0004
        WHEN building_type = 'Hotel' AND COALESCE(eui_2018, eui_2017) > 250 THEN ((COALESCE(eui_2018, eui_2017) - 250) * gross_floor_area) * 0.0004
        ELSE 0
    END AS wasted_carbon_emissions_ton
FROM sg_energy_clean
WHERE (eui_2018 IS NOT NULL OR eui_2017 IS NOT NULL)
  AND building_type IN ('Office', 'Retail', 'Hotel')
ORDER BY wasted_electricity_kwh DESC;
