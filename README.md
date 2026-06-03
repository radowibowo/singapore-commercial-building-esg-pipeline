# Singapore Commercial Buildings: Energy Efficiency & Carbon Footprint Analysis

## 1. Project Overview
This project evaluates the energy performance of over 1,200 commercial buildings (Offices, Retail Malls, and Hotels) in Singapore using open-source data from the Building and Construction Authority (BCA). By building data-driven energy benchmarks, the analysis pinpoints critical energy anomalies and calculates potential Scope 2 carbon emission reductions for corporate real estate management.

---

## 2. Business Problem & Objective
Corporate sustainability teams and asset managers must comply with strict national environmental regulations in Singapore. The key challenges this project addresses are:

- **Identifying Inefficiencies:** Spotting which commercial assets consume electricity far beyond acceptable industry standards.
- **Detecting Data Gaps (Anti-Greenwashing):** Preventing buildings from bypassing energy audits by hiding or omitting their current-year metrics.
- **Quantifying Impact:** Translating raw Energy Use Intensity (EUI) into actionable business metrics: total wasted Kilowatt-hours (kWh) and carbon dioxide emissions (CO₂).

---

## 3. Data Architecture & ELT Strategy
Real-world data is messy. To ensure integrity and avoid processing errors, a disciplined two-stage **ELT (Extract, Load, Transform)** architecture was implemented inside PostgreSQL.

### Stage 1: Staging Area (Ingestion)
The raw data contained missing values (`NaN` or `'NA'`) and non-numeric characters (comma separators in floor areas). Forcing strict numeric types during ingestion would break the pipeline.  
- **Solution:** Created a staging table (`sg_energy_raw`) where every column was set to `TEXT`, allowing the safe intake of all 1,244 raw rows without friction.

### Stage 2: Production Area (Transformation & Anti-Greenwashing)
A clean production table (`sg_energy_clean`) was built with proper data types (`NUMERIC`, `VARCHAR`).  
- **Text Cleansing:** Used `REPLACE()` to remove commas from `grossfloorarea` before casting to numeric.
- **Handling Missing Data:** Applied `CASE WHEN` to convert textual `'NA'` markers into real database `NULL` values.
- **Greenwashing Validation:** During the audit, some assets were missing their 2018 EUI data. To prevent non‑compliant buildings from escaping the energy audit loop, a fallback mechanism was engineered using SQL `COALESCE(eui_2018, eui_2017)`. If the 2018 figure is absent, the system automatically uses the 2017 baseline.

---

## 4. Core Analytical Queries & Metrics
Specific energy benchmarks aligned with Singapore real estate standards were defined:

- **Offices:** Benchmark limit of 180 EUI (kWh/m²/year)
- **Retail Malls:** Benchmark limit of 350 EUI (kWh/m²/year)
- **Hotels:** Benchmark limit of 250 EUI (kWh/m²/year)

### Environmental Impact Formulas
```
Effective EUI = COALESCE(eui_2018, eui_2017)
Wasted Electricity (kWh) = (Effective EUI − Benchmark EUI) × Gross Floor Area (m²)
Carbon Emissions (Ton CO₂) = Wasted Electricity (kWh) × 0.0004
```

### Core Operational Query (PostgreSQL)
```sql
SELECT
    building_name,
    building_type,
    gross_floor_area,
    eui_2017,
    eui_2018,
    COALESCE(eui_2018, eui_2017) AS effective_eui,
    CASE
        WHEN building_type = 'Office' AND COALESCE(eui_2018, eui_2017) > 180
            THEN (COALESCE(eui_2018, eui_2017) - 180) * gross_floor_area
        WHEN building_type = 'Retail' AND COALESCE(eui_2018, eui_2017) > 350
            THEN (COALESCE(eui_2018, eui_2017) - 350) * gross_floor_area
        WHEN building_type = 'Hotel' AND COALESCE(eui_2018, eui_2017) > 250
            THEN (COALESCE(eui_2018, eui_2017) - 250) * gross_floor_area
        ELSE 0
    END AS wasted_electricity_kwh
FROM sg_energy_clean
WHERE (eui_2018 IS NOT NULL OR eui_2017 IS NOT NULL)
  AND building_type IN ('Office', 'Retail', 'Hotel')
ORDER BY wasted_electricity_kwh DESC;
```

---

## 5. Key Insights & Environmental Impact Summary
After running advanced aggregations with the fallback logic on the cleaned Singapore dataset, the analysis uncovered substantial carbon reduction potential:

| Building Type | Total Assets | Inefficient Assets (Above Benchmark) | Total Wasted Electricity (kWh) | Potential Carbon Reduction (Tons CO₂) |
|---------------|:-----------:|:------------------------------------:|:------------------------------:|:-------------------------------------:|
| Office        | 384         | 197 (51.3%)                          | 723,602,752.00                 | 289,441.10                            |
| Retail        | 134         | 69 (51.5%)                           | 206,812,976.00                 | 82,725.19                             |
| Hotel         | 145         | 77 (53.1%)                           | 90,297,288.00                  | 36,118.92                             |
| **TOTAL**     | **663**     | **343 (51.7%)**                      | **1,020,713,016.00**           | **408,285.21**                        |

### Strategic Takeaways for Managers
- **The Office Sector Crisis:** More than 51% of office buildings in Singapore operate inefficiently, leaking over 723 million kWh of electricity. This sector must be the top priority for energy-saving retrofits.
- **Data-Gap Resolution:** By applying the historical fallback logic (`COALESCE`), missing operational data was captured, preventing systematic underreporting of building energy leakages.

---

## 6. Power BI ESG Dashboard Implementation
A high-impact executive dashboard translates database rows into actionable corporate sustainability insights.

### Data Modeling & DAX Adaptation
To maintain analytical continuity with the backend database logic, equivalent validations were modeled in Power BI:
- **effective_eui (Calculated Column):** `COALESCE(sg_energy_clean[eui_2018], sg_energy_clean[eui_2017])`
- **Wasted_kWh (Calculated Column):** Evaluates energy leaks based on the dynamic `effective_eui` metric.
- **Inefficiency_Rate (Measure):** Computes the exact percentage of properties operating outside regulatory thresholds.

### Interactive Visuals Included
1. **Executive KPI Cards:** Aggregate metrics – 1.02 Billion kWh total wasted electricity, 408K Tons of potential CO₂ reduction, and a cross-industry **51.7% Inefficiency Rate**.
2. **Sector Breakdown (Bar Chart):** Compares total energy leakage, clearly highlighting the Office sector as the highest priority for green retrofits.
3. **Asset Risk Matrix with Fallback Audit (Table Visual):** Dynamically ranks individual assets by carbon footprint penalty, displaying `eui_2017`, `eui_2018`, and `effective_eui` side-by-side for immediate data transparency checks.

---

*Developed as a practical demonstration of ELT architectures, advanced PostgreSQL scripting, and ESG data visualization for international property asset management.*
