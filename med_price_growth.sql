-- Active: 1780043201174@@127.0.0.1@3306@medidrugs

-- Here, I want to take a look at the growth metrics for 2021 to 2022 and 2022 to 2023.
DROP VIEW v_growth_22_23;

CREATE VIEW v_growth_22_23 AS
SELECT
  l.Brnd_Name,
  SUM(CASE WHEN l.year = 2022 THEN m.Avg_Spndng_Per_Dsg_Unt END) AS Avg_Spndng_Per_DU_2022,
  SUM(CASE WHEN l.year = 2023 THEN m.Avg_Spndng_Per_Dsg_Unt END) AS Avg_Spndng_Per_DU_2023,
  (SUM(CASE WHEN l.year = 2023 THEN m.Avg_Spndng_Per_Dsg_Unt END) - 
  (SUM(CASE WHEN l.year = 2022 THEN m.Avg_Spndng_Per_Dsg_Unt END))) / 
  SUM(CASE WHEN l.year = 2022 THEN m.Avg_Spndng_Per_Dsg_Unt END) * 100 AS pct_change
FROM lookup AS l
JOIN meds AS m
  ON l.HCPCS_Cd = m.HCPCS_Cd
GROUP BY Brnd_Name;

SELECT 
  Brnd_Name,
  Avg_Spndng_Per_DU_2022,
  Avg_Spndng_Per_DU_2023,
  ROUND(pct_change, 2)
FROM v_growth_22_23
WHERE Avg_Spndng_Per_DU_2022 > 10
ORDER BY pct_change DESC;

-- Repeat the above process fo 2021 and 2022.

DROP VIEW v_growth_21_22;

CREATE VIEW v_growth_21_22 AS
SELECT
  l.Brnd_Name,
  SUM(CASE WHEN l.year = 2021 THEN m.Avg_Spndng_Per_Dsg_Unt END) AS Avg_Spndng_Per_DU_2022,
  SUM(CASE WHEN l.year = 2022 THEN m.Avg_Spndng_Per_Dsg_Unt END) AS Avg_Spndng_Per_DU_2023,
  (SUM(CASE WHEN l.year = 2022 THEN m.Avg_Spndng_Per_Dsg_Unt END) - 
  (SUM(CASE WHEN l.year = 2021 THEN m.Avg_Spndng_Per_Dsg_Unt END))) / 
  SUM(CASE WHEN l.year = 2021 THEN m.Avg_Spndng_Per_Dsg_Unt END) * 100 AS pct_change
FROM lookup AS l
JOIN meds AS m
  ON l.HCPCS_Cd = m.HCPCS_Cd
GROUP BY Brnd_Name;

SELECT 
  Brnd_Name,
  Avg_Spndng_Per_DU_2022,
  Avg_Spndng_Per_DU_2023,
  ROUND(pct_change, 2)
FROM v_growth_21_22
WHERE Avg_Spndng_Per_DU_2023 > 10
ORDER BY pct_change DESC;