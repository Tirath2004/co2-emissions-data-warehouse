# CO₂ Emissions Data Warehouse & Analytics Platform

An end-to-end data storage and analytics solution that consolidates global CO₂ emissions data into a queryable, trustworthy data warehouse — covering data integration, dimensional modeling, ETL, reporting, dashboarding, and a relational-vs-graph database comparison.

## Overview

Global CO₂ emissions data is scattered across sources with inconsistent formats, country codes, and structures. This project builds a proof-of-concept data warehouse that consolidates it into a single, reliable source analysts can query with confidence — then layers reporting, visualization, and an alternative graph-database model on top.

**Data sources:**
- Our World in Data — CO₂ / GHG emissions dataset
- World Bank — country classification metadata

**Scale:** ~14,700 country-year records, 200+ countries, 1750–2024, joined on ISO country code.

## Architecture

The warehouse uses a dimensional star schema in SQL Server:

- **`Fact_Emissions`** — CO2 totals, energy consumption, GHG emissions, population, GDP
- **`DimCountry`** — ISO code, country name, region, sub-region, income level, geographic group
- **`DimTime`** — year, quarter, month, decade, year type
- **`DimEnergy_Type`** — energy type, category, fuel group
- **`DimIndicator`** — indicator name, category, unit

See the schema diagram in the repo for the full table relationships.

## ETL Pipeline (SSIS)

`Integration Project.slnx`

A fully repeatable pipeline: **staging → dimension load → fact load.**

The core challenge was country-matching logic — reconciling two independently maintained country lists (emissions data vs. World Bank metadata) without duplicating or silently dropping records. The pipeline:

1. Loads raw CSV data (OWID emissions, World Bank metadata) into staging tables
2. Runs a lookup transformation matching incoming countries against `DimCountry`
3. Routes 207 existing countries down the standard update path
4. Routes 11 new/unmatched countries down a separate insert path
5. Loads the reconciled dimension, then the fact table

This ensures the fact table never orphans a record against a missing or mismatched country key.

## Reports (SSRS)

Four parameterised reports:

| Report | File | Description |
|---|---|---|
| Top 20 Emitters | `Top 20 by Total Emissions report.rdl` | Ranked table of the highest cumulative-emitting countries |
| Emissions by Region | `Emissions by Region.rdl` | Aggregated totals grouped by World Bank region |
| Emissions by Decade | `Global Emissions by Decade.rdl` | Global totals rolled up by decade, 1750–present |
| Emissions Trend by Country | `Emissions Trend by Country.rdl` | Year-by-year trend for a selected country, with a live filter parameter |

## Dashboard (Tableau)

`Global Co2 Emissions Dashboard.twbx`

An interactive dashboard combining four linked visualizations:

- **Global Emissions Trend** — 250+ year line chart of total emissions
- **Global CO2 Emissions by Country (Yearly)** — choropleth map with a year slider
- **Top 20 Emitting Countries** — horizontal bar chart
- **CO2 Emissions by Region Over Time** — stacked area chart of regional share

## Relational vs. Graph Comparison (Neo4j)

- `B9DA111_Appendix_C_SQL_Comparison_Queries.sql`
- `B9DA111_Appendix_C_Neo4j_Queries.cql`
- `B9DA111_Neo4j_Import_EmissionsData.csv`

The same dataset was loaded into Neo4j to compare query patterns against SQL Server across seven equivalent query pairs.

**Findings:**
- For flat aggregations (totals, rankings, group-bys), SQL Server was as concise as Cypher and often faster.
- For relationship-style questions, graph pulled ahead clearly. A shortest-path query connecting two countries through shared regions took one line of Cypher, versus a recursive SQL query that was significantly more complex to write and maintain.

## Repo Structure

```
├── Emissions by Region.rdl
├── Emissions Trend by Country.rdl
├── Global Emissions by Decade.rdl
├── Top 20 by Total Emissions report.rdl
├── Integration Project.slnx
├── Global Co2 Emissions Dashboard.twbx
├── EmissionsData.csv
├── B9DA111_Appendix_C_Neo4j_Queries.cql
├── B9DA111_Appendix_C_SQL_Comparison_Queries.sql
├── B9DA111_Neo4j_Import_EmissionsData.csv
└── Screenshot 2026-07-27 013430.png   (star schema diagram)
```

## Skills Demonstrated

SQL Server · SSIS · SSRS · Tableau · Neo4j · Cypher · Dimensional Modeling · ETL Development · Data Integration · Data Visualization
