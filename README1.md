# Singapore Building Energy Audit & ESG Compliance Dashboard

## 📌 Project Overview
An end-to-end data analytics project designed to evaluate energy efficiency and calculate carbon tax financial liabilities across a commercial real estate portfolio in Singapore. 

This project cleans and benchmarks raw performance data against the official **Building and Construction Authority (BCA) Singapore Regulatory Thresholds** to flag underperforming assets and mitigate financial risks.

---

## 💼 Business Case & Objectives
* **The Problem:** The company faces rising operational costs and upcoming strict carbon tax hikes in Singapore. Executive leadership lacks a centralized, validated view to identify which properties violate energy efficiency laws.
* **The Goal:** Build an automated data pipeline and an interactive dashboard to:
    1. Monitor **Energy Use Intensity (EUI)** across all commercial facilities.
    2. Benchmark asset performance against BCA targets (Office: 180 | Hotel: 250 | Retail: 350 EUI).
    3. Quantify absolute **Total Carbon Tax Exposure (SGD)** to prioritize green-building retrofitting budgets.

---

## 🛠️ Tech Stack & Skills
* **Data Extraction & Cleansing:** SQL (Standard ANSI) - Text normalization (`TRIM`, `UPPER`), handling missing values (`CASE WHEN`), and building reusable data layers using `VIEW`.
* **Data Transformation:** Power Query (UTF-8 encoding enforcement, null-value handling).
* **Data Modeling & Analytics:** Power BI Desktop (DAX formulas, multi-threshold static line integration).
* **Data Visualization:** Scatter Plots for asset distribution, Donut Charts for emission breakdown, and conditional risk-flagging.

---

## 📐 Data Cleansing Pipeline (SQL Snippet)
This secure database view layer was built to clean human-entry errors and standardize property segments before feeding the reporting dashboard:

```sql
CREATE VIEW v_singapore_esg_carbon_audit_clean_ok AS
SELECT 
    -- 1. Cleaning text inconsistencies from manual inputs
    TRIM(building_name) AS building_name,
    UPPER(property_type) AS property_type,
    
    -- 2. Standardizing building metrics
    gross_floor_area_sqm,
    calibrated_eui_2019,
    
    -- 3. Categorizing regulatory compliance based on official BCA targets
    CASE 
        WHEN property_type = 'Office' AND calibrated_eui_2019 > 180 THEN 'Over Threshold'
        WHEN property_type = 'Hotel' AND calibrated_eui_2019 > 250 THEN 'Over Threshold'
        WHEN property_type = 'Retail' AND calibrated_eui_2019 > 350 THEN 'Over Threshold'
        ELSE 'Compliant'
    END AS bca_compliance_status
FROM raw_singapore_building_esg
WHERE property_type IN ('Office', 'Retail', 'Hotel');

-- Note: Mixed Development assets are excluded from EUI benchmarking due to complex, non-flat regulatory baselines.
```
## 📈 Key Insights & Dashboard Features
Full Portfolio Scope: Successfully audited 200+ active commercial assets in Singapore after executing data scope fixes.

Clear Regulatory Benchmarking: Implemented a 3-tier constant line baseline (180, 250, 350 EUI) on the central Scatter Plot to instantly separate compliant assets from critical risk properties.

Financial Risk Mapping: Provided C-level executives with an absolute metric of Total Carbon Tax Exposure (SGD) to justify immediate energy mitigation investments.

---

## 🎨 Dashboard Preview

(Insert your Power BI dashboard screenshot here)

---
*Developed as a practical demonstration of ELT architectures, advanced PostgreSQL scripting, and ESG data visualization for international property asset management.*

---
