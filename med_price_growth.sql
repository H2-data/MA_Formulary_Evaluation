-- Active: 1780043201174@@127.0.0.1@3306@medidrugs

-- Here, I want to take a look at the growth metrics for 2021 to 2022 and 2022 to 2023.
DROP VIEW v_growth_22_23;

CREATE VIEW v_growth_22_23 AS
WITH cte_growth_22_23 AS (
SELECT
	l.Brnd_Name,
	SUM(CASE WHEN m.YEAR = 2022 THEN m.Avg_Spndng_Per_Dsg_Unt END) AS val_2022,
	SUM(CASE WHEN m.YEAR = 2023 THEN m.Avg_Spndng_Per_Dsg_Unt END) AS val_2023
FROM meds AS m
JOIN lookup AS l
	ON m.MedicationID = l.MedicationID
GROUP BY l.Brnd_Name
)
SELECT
  Brnd_Name,
  val_2022,
  val_2023,
  (val_2023 - val_2022) / val_2022 * 100 AS pct_change
FROM cte_growth_22_23;

SELECT 
	COUNT(*) 
FROM v_growth_22_23 
WHERE pct_change IS NULL;

-- Approximately 10% of medications are missing partial growth data for 2022-2023.
-- Because of this, growth has a low composite score contribution.

-- Deaggregrated Sanity Check
SELECT
	l.Brnd_Name,
	m.Avg_Spndng_Per_Dsg_Unt
FROM meds AS m
JOIN lookup AS l
	ON m.MedicationID = l.MedicationID
WHERE l.Brnd_Name = 'Zemdri' AND m.YEAR IN ('2022', '2023');

-- The calculation in the query matches the manual calculation on the deaggregated data.

-- Repeat the above process fo 2021 and 2022.

DROP VIEW v_growth_21_22;

CREATE VIEW v_growth_21_22 AS
WITH cte_growth_21_22 AS (
SELECT
	l.Brnd_Name,
	SUM(CASE WHEN m.YEAR = 2021 THEN m.Avg_Spndng_Per_Dsg_Unt END) AS val_2021,
	SUM(CASE WHEN m.YEAR = 2022 THEN m.Avg_Spndng_Per_Dsg_Unt END) AS val_2022
FROM meds AS m
JOIN lookup AS l
	ON m.MedicationID = l.MedicationID
GROUP BY l.Brnd_Name
)
SELECT
  Brnd_Name,
  val_2021,
  val_2022,
  (val_2022 - val_2021) / val_2021 * 100 AS pct_change
FROM cte_growth_21_22;

SELECT 
	COUNT(*) 
FROM v_growth_21_22 
WHERE pct_change IS NULL;

-- Approximately 16% of medications are missing partial growth data for 2021-2022
-- Because of this, growth has a low composite score contribution.

-- Deaggregrated Sanity Check
SELECT
	l.Brnd_Name,
	m.Avg_Spndng_Per_Dsg_Unt
FROM meds AS m
JOIN lookup AS l
	ON m.MedicationID = l.MedicationID
WHERE l.Brnd_Name = 'Eovist' AND m.YEAR IN ('2021', '2022');

-- The calculation in the query matches the manual calculation on the deaggregated data.
