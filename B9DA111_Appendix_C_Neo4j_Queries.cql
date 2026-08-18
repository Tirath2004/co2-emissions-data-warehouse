// ===========================================================================
//  B9DA111 - Assessment ONE - Task 5
//  Graph database in Neo4j (Cypher / CQL)  -  AS ACTUALLY BUILT
//  Instance: EmissionsGraph   |   Import file: EmissionsData.csv
//  (EmissionsData.csv columns, 0-indexed:
//     0 country, 1 region, 2 iso_code, 3 year, 4 decade, 5 co2)
// ===========================================================================
//  GRAPH MODEL
//  -----------------------------------------------------------------------
//  (:Country {iso_code, name})
//  (:Region  {name})
//  (:YearlyEmission {year, decade, co2})
//
//  (:Country)-[:IN_REGION]->(:Region)
//  (:Country)-[:HAS_EMISSION]->(:YearlyEmission)
//
//  Loaded totals: 215 Country nodes, 8 Region nodes,
//                 23,408 YearlyEmission nodes / HAS_EMISSION relationships.
// ===========================================================================


// ---------------------------------------------------------------------------
// STEP 0 :  Constraints (run once) - keep Country/Region unique & fast to match
// ---------------------------------------------------------------------------
CREATE CONSTRAINT country_iso IF NOT EXISTS FOR (c:Country) REQUIRE c.iso_code IS UNIQUE;
CREATE CONSTRAINT region_name IF NOT EXISTS FOR (r:Region)  REQUIRE r.name    IS UNIQUE;


// ---------------------------------------------------------------------------
// STEP 1 :  Load Country + Region nodes and the IN_REGION relationship
//           (place EmissionsData.csv in the Neo4j 'import' folder first)
// ---------------------------------------------------------------------------
LOAD CSV FROM 'file:///EmissionsData.csv' AS row
CALL {
  WITH row
  WITH row WHERE row[2] IS NOT NULL AND trim(row[2]) <> ''
  MERGE (c:Country {iso_code: row[2]})
    ON CREATE SET c.name = row[0]
  MERGE (r:Region {name: row[1]})
  MERGE (c)-[:IN_REGION]->(r)
} IN TRANSACTIONS OF 1000 ROWS;


// ---------------------------------------------------------------------------
// STEP 2 :  Load YearlyEmission nodes and the HAS_EMISSION relationship
// ---------------------------------------------------------------------------
LOAD CSV FROM 'file:///EmissionsData.csv' AS row
CALL {
  WITH row
  WITH row WHERE row[2] IS NOT NULL AND row[3] IS NOT NULL AND row[5] IS NOT NULL
  MATCH (c:Country {iso_code: row[2]})
  CREATE (e:YearlyEmission {year: toInteger(row[3]), decade: toInteger(row[4]), co2: toFloat(row[5])})
  CREATE (c)-[:HAS_EMISSION]->(e)
} IN TRANSACTIONS OF 1000 ROWS;


// ---------------------------------------------------------------------------
// Sanity checks after loading
// ---------------------------------------------------------------------------
MATCH (c:Country)       RETURN count(c) AS Countries;        // -> 215
MATCH (e:YearlyEmission) RETURN count(e) AS EmissionRows;    // -> 23,408



// ###########################################################################
// #  SEVEN COMPARISON QUERIES  (each has a SQL twin in                       #
// #  SQL_Neo4j_Comparison_Queries.sql - screenshot both for the report)      #
// ###########################################################################


// ===========================================================================
// QUERY 1 : Total CO2 by Region  (aggregation over a traversal)
// ===========================================================================
MATCH (c:Country)-[:IN_REGION]->(r:Region),
      (c)-[:HAS_EMISSION]->(e:YearlyEmission)
RETURN r.name AS Region, sum(e.co2) AS Total
ORDER BY Total DESC;
// Europe & Central Asia 595,030 | North America 470,541 | East Asia & Pacific 462,574 ...


// ===========================================================================
// QUERY 2 : Top 20 emitting countries of all time
// ===========================================================================
MATCH (c:Country)-[:HAS_EMISSION]->(e:YearlyEmission)
RETURN c.name AS Country, sum(e.co2) AS Total
ORDER BY Total DESC
LIMIT 20;
// United States 434,866 | China 285,087 | Russia 122,808 ... (matches SSRS report)


// ===========================================================================
// QUERY 3 : Global CO2 by decade
// ===========================================================================
MATCH (:Country)-[:HAS_EMISSION]->(e:YearlyEmission)
RETURN e.decade AS Decade, sum(e.co2) AS Total
ORDER BY Decade;


// ===========================================================================
// QUERY 4 : Emissions trend for one country over time (United States)
// ===========================================================================
MATCH (c:Country {name:'United States'})-[:HAS_EMISSION]->(e:YearlyEmission)
RETURN e.year AS Year, e.co2 AS CO2
ORDER BY Year;


// ===========================================================================
// QUERY 5 : Total CO2 for a single country (India)
// ===========================================================================
MATCH (c:Country {name:'India'})-[:HAS_EMISSION]->(e:YearlyEmission)
RETURN sum(e.co2) AS Total_CO2;   // -> 66,072


// ===========================================================================
// QUERY 6 : *** GRAPH-NATIVE *** shortest path between two countries
//   Germany and France are connected through their shared Region node.
//   Returns a path (view it in the graph tab). Swapping in two countries in
//   different regions (e.g. India / China) returns no path - a useful
//   "these are not connected in our graph" finding in itself.
// ===========================================================================
MATCH p = shortestPath( (a:Country {name:'Germany'})-[*..6]-(b:Country {name:'France'}) )
RETURN p;


// ===========================================================================
// QUERY 7 : Regional peers - other countries sharing a country's region
//   One short traversal through the shared :Region node.
// ===========================================================================
MATCH (:Country {name:'Germany'})-[:IN_REGION]->(r:Region)<-[:IN_REGION]-(c2:Country)
RETURN c2.name AS RelatedCountry
ORDER BY RelatedCountry;


// ---------------------------------------------------------------------------
//  OPTIONAL data-quality note: a few source rows carry the literal text
//  "NULL" as their region, producing a small "NULL" Region node. Filter with
//  WHERE r.name <> 'NULL' if you want to exclude it from Query 1.
// ---------------------------------------------------------------------------


// ===========================================================================
//  RESET (use with care during testing)
// ===========================================================================
// MATCH (n) DETACH DELETE n;
