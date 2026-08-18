/* ===========================================================================
   B9DA111 - Assessment ONE - Task 5
   RELATIONAL (SQL Server / EmissionsDW) counterparts of the seven Cypher
   queries in  Neo4j_Emissions_Graph_FINAL.cql  (same numbering).
   Run in SSMS and screenshot each result beside the matching Neo4j output.
   =========================================================================== */
USE EmissionsDW;
GO

/* QUERY 1 : Total CO2 by Region -------------------------------------------- */
SELECT c.Region, SUM(f.CO2_Emissions_Total) AS Total
FROM fact.Fact_Emissions f
JOIN dim.DimCountry c ON f.CountryKey = c.CountryKey
WHERE f.CO2_Emissions_Total IS NOT NULL
  AND f.EnergyKey = -1 AND f.IndicatorKey = -1
  AND c.Region IS NOT NULL
GROUP BY c.Region
ORDER BY Total DESC;


/* QUERY 2 : Top 20 emitting countries -------------------------------------- */
SELECT TOP 20 c.Country_Name AS Country, SUM(f.CO2_Emissions_Total) AS Total
FROM fact.Fact_Emissions f
JOIN dim.DimCountry c ON f.CountryKey = c.CountryKey
WHERE f.CO2_Emissions_Total IS NOT NULL
  AND f.EnergyKey = -1 AND f.IndicatorKey = -1
GROUP BY c.Country_Name
ORDER BY Total DESC;


/* QUERY 3 : Global CO2 by decade ------------------------------------------- */
SELECT t.Decade, SUM(f.CO2_Emissions_Total) AS Total
FROM fact.Fact_Emissions f
JOIN dim.DimTime t ON f.TimeKey = t.TimeKey
WHERE f.CO2_Emissions_Total IS NOT NULL
  AND f.EnergyKey = -1 AND f.IndicatorKey = -1
GROUP BY t.Decade
ORDER BY t.Decade;


/* QUERY 4 : United States trend over time ---------------------------------- */
SELECT t.Year, f.CO2_Emissions_Total AS CO2
FROM fact.Fact_Emissions f
JOIN dim.DimCountry c ON f.CountryKey = c.CountryKey
JOIN dim.DimTime    t ON f.TimeKey    = t.TimeKey
WHERE c.Country_Name = 'United States'
  AND f.EnergyKey = -1 AND f.IndicatorKey = -1
  AND f.CO2_Emissions_Total IS NOT NULL
ORDER BY t.Year;


/* QUERY 5 : Total CO2 for India -------------------------------------------- */
SELECT SUM(f.CO2_Emissions_Total) AS Total_CO2
FROM fact.Fact_Emissions f
JOIN dim.DimCountry c ON f.CountryKey = c.CountryKey
WHERE c.Country_Name = 'India'
  AND f.EnergyKey = -1 AND f.IndicatorKey = -1;


/* QUERY 6 : "Path" between two countries -----------------------------------
   Relational has no native shortest-path. The nearest equivalent is asking
   whether two countries share a region (a one-hop connection). Multi-hop
   paths would need recursive CTEs - which is exactly the point of the
   comparison: what is one line in Cypher is awkward or impossible in SQL. */
SELECT CASE WHEN a.Region = b.Region THEN 'Connected via region: ' + a.Region
            ELSE 'Not connected (different regions)' END AS Relationship
FROM dim.DimCountry a, dim.DimCountry b
WHERE a.Country_Name = 'Germany' AND b.Country_Name = 'France';


/* QUERY 7 : Regional peers of a country ------------------------------------ */
SELECT peer.Country_Name AS RelatedCountry
FROM dim.DimCountry ire
JOIN dim.DimCountry peer
      ON peer.Region = ire.Region
     AND peer.CountryKey <> ire.CountryKey
WHERE ire.Country_Name = 'Germany'
ORDER BY peer.Country_Name;
