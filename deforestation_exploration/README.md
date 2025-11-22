# Deforestation Exploration Project

A comprehensive SQL data analysis project examining global deforestation trends from 1990 to 2016 using World Bank data. This project was completed as part of the Udacity Data Analysis curriculum.

## Project Overview

ForestQuery, a non-profit organization focused on reducing global deforestation, requires analysis of World Bank data to identify:
- Countries and regions with shrinking forests
- Areas with the most significant forest coverage (by amount and percentage)
- Trends to inform initiatives, communications, and resource allocation

## Project Structure

```
deforestation_exploration/
├── sql/                                    # SQL query files
│   ├── 01_create_forestation_view.sql     # Creates main analytical view
│   ├── 02_global_situation_queries.sql    # Global deforestation metrics
│   ├── 03_regional_outlook_queries.sql    # Regional forest comparisons
│   └── 04_country_level_detail_queries.sql# Country-specific analysis
├── results/                                # Query output files
│   ├── q2_results.csv                     # Global situation results
│   ├── q3_results.csv                     # Regional outlook results
│   └── q4_results.csv                     # Country-level detail results
├── docs/                                   # Documentation and reports
│   ├── template.md                        # Original report template
│   └── deforestation_report.html          # Final HTML report (print to PDF)
├── sqlwidget/dbs/                         # Database files
│   └── forest_query.sql                   # Source database with all tables
└── README.md                              # This file
```

## Database Schema

The project uses three primary tables from the World Bank:

### 1. `forest_area`
- `country_code` - Country identifier
- `country_name` - Country name
- `year` - Year (1990-2016)
- `forest_area_sqkm` - Forest area in square kilometers

### 2. `land_area`
- `country_code` - Country identifier
- `country_name` - Country name
- `year` - Year (1990-2016)
- `total_area_sq_mi` - Total land area in square miles

### 3. `regions`
- `country_code` - Country identifier
- `country_name` - Country name
- `region` - Geographic region
- `income_group` - World Bank income classification

## How to Run

### Step 1: Create the Forestation View

Run the view creation script first:

```bash
sql/01_create_forestation_view.sql
```

This creates a unified `forestation` view that:
- Joins all three tables (forest_area, land_area, regions)
- Converts square miles to square kilometers (1 sq mi = 2.59 sq km)
- Calculates percent of land area designated as forest

### Step 2: Run Analysis Queries

Execute each query file in order:

```bash
sql/02_global_situation_queries.sql     # Save output as results/q2_results.csv
sql/03_regional_outlook_queries.sql     # Save output as results/q3_results.csv
sql/04_country_level_detail_queries.sql # Save output as results/q4_results.csv
```

Each query returns comprehensive results needed for that section of the report.

## Key Findings

### Global Situation
- **1990 Forest Area**: 41,282,694.9 sq km
- **2016 Forest Area**: 39,958,245.9 sq km
- **Loss**: 1,324,449 sq km (3.21%)
- **Equivalent**: Approximately the entire land area of Peru

### Regional Trends
- **Highest Forestation (2016)**: Latin America & Caribbean (46.16%)
- **Lowest Forestation (2016)**: Middle East & North Africa (2.07%)
- **Regions with Decline**: Latin America & Caribbean (-4.87%), Sub-Saharan Africa (-3.89%)

### Country Highlights

**Success Stories:**
- China: +527,229 sq km increase
- Iceland: +213.66% increase

**Greatest Concerns:**
- Brazil: -541,510 sq km (largest absolute loss)
- Togo: -75.45% (largest percentage loss)
- Nigeria: Appears in both top 5 lists (absolute and percent loss)

### Quartile Distribution (2016)
- **0-25% forest**: 85 countries
- **25-50% forest**: 72 countries
- **50-75% forest**: 38 countries
- **75-100% forest**: 9 countries

## SQL Techniques Used

The project demonstrates proficiency in:

- ✅ **Views** - Creating analytical views with JOIN operations
- ✅ **JOINs** - INNER JOIN, self-joins for temporal comparisons
- ✅ **Aggregations** - SUM, COUNT, GROUP BY
- ✅ **Window Functions** - ROUND, ABS
- ✅ **CTEs** - Common Table Expressions for complex queries
- ✅ **CASE Statements** - Quartile categorization
- ✅ **Subqueries** - Nested SELECT statements
- ✅ **Boolean Operators** - Complex WHERE conditions with AND/OR
- ✅ **ORDER BY & LIMIT** - Result sorting and filtering
- ✅ **UNION ALL** - Combining multiple result sets

## Report Sections

The final report includes:

1. **GLOBAL SITUATION** - World forest area changes from 1990-2016
2. **REGIONAL OUTLOOK** - Regional forest percentages and trends
3. **COUNTRY-LEVEL DETAIL** - Success stories, concerns, and quartile analysis
4. **RECOMMENDATIONS** - Strategic recommendations for ForestQuery
5. **APPENDIX** - All SQL queries used in the analysis

## Recommendations Summary

Based on the analysis, recommended resource allocation:

- **40%** - Sub-Saharan Africa (critical intervention needed)
- **35%** - Latin America & Caribbean (large-scale impact opportunity)
- **15%** - East Asia & Pacific (knowledge transfer from China's success)

**Priority Countries:**
- Nigeria (appears in both top 5 concern lists)
- Brazil (largest absolute forest loss)
- Togo, Uganda, Mauritania (highest percentage losses)

**Success Story Studies:**
- China's reforestation policies (527,229 sq km increase)
- Iceland's forest growth strategies (213.66% increase)

## Viewing the Report

Open the final report in your browser:

```bash
docs/deforestation_report.html
```

Print to PDF using your browser's print function (Ctrl+P or Cmd+P).

## Project Requirements Met

✅ Created `forestation` view joining all three tables
✅ Calculated percent forest area with proper unit conversion
✅ Answered all questions in Global Situation section
✅ Answered all questions in Regional Outlook section
✅ Answered all questions in Country-Level Detail section
✅ Provided strategic recommendations
✅ Included all SQL queries in appendix
✅ Followed SQL formatting best practices
✅ Used complete sentences in report
✅ Created professional PDF-ready report

## Technologies Used

- **SQL** - PostgreSQL dialect
- **Database** - World Bank deforestation data (1990-2016)
- **Export Format** - CSV for results, HTML for final report

## Author

Christopher Aaron O'Hara
Udacity Data Analysis Nanodegree

## License

This project is part of the Udacity Data Analysis curriculum.

---

*Data Source: World Bank - Forest Area and Land Area Statistics (1990-2016)*
