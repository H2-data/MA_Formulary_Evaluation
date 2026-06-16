-- Active: 1780043201174@@127.0.0.1@3306@medidrugs

-- Here, I want to take a look at the growth metrics for 2021 to 2022 and 2022 to 2023.
DROP VIEW v_growth_22_23;

CREATE VIEW v_growth_22_23 AS
SELECT
  l.Brnd_Name,
  SUM(CASE WHEN l.year = 2022 THEN m.Avg_Spndng_Per_Dsg_Unt END) AS Avg_Spndng_Per_DU_2022,
  SUM(CASE WHEN l.year = 2023 THEN m.Avg_Spndng_Per_Dsg_Unt END) AS Avg_Spndng_Per_DU_2023,
  (
      SUM(CASE WHEN l.year = 2023 THEN m.Avg_Spndng_Per_Dsg_Unt END)
    - SUM(CASE WHEN l.year = 2022 THEN m.Avg_Spndng_Per_Dsg_Unt END)
  ) / SUM(CASE WHEN l.year = 2022 THEN m.Avg_Spndng_Per_Dsg_Unt END) AS pct_change
FROM lookup AS l
JOIN meds AS m
  ON l.Brnd_Name = m.Brnd_Name
GROUP BY Brnd_Name;

SELECT * FROM v_growth_22_23
ORDER BY pct_change DESC;

-- Repeat the above process fo 2021 and 2022.

DROP VIEW change_21_22;

CREATE VIEW change_21_22 AS
SELECT
    Brnd_Name,
    MAX(CASE WHEN year = 2021 THEN Avg_Spndng_Per_Dsg_Unt END) AS Avg_Spndng_Per_DU_2021,
    MAX(CASE WHEN year = 2022 THEN Avg_Spndng_Per_Dsg_Unt END) AS Avg_Spndng_Per_DU_2022,
    MAX(Outlier_Flag) AS Outlier_Flag,
    (
        MAX(CASE WHEN year = 2022 THEN Avg_Spndng_Per_Dsg_Unt END)
      - MAX(CASE WHEN year = 2021 THEN Avg_Spndng_Per_Dsg_Unt END)
    ) / NULLIF(MAX(CASE WHEN year = 2021 THEN Avg_Spndng_Per_Dsg_Unt END), 0) AS pct_change
FROM medidrugs
GROUP BY Brnd_Name;

SELECT * FROM change_21_22
LIMIT 10;

-- Based on my findings, it appears that growth isn't as reliable a measure as I thought.
-- It will not be factored into scoring.