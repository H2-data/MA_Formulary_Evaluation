-- Active: 1780043201174@@127.0.0.1@3306@medidrugs
-- Now that I have all data and metrics, I'll score everything here.
-- First, I'll create the raw scores for claims, beneficiaries, and spending.
-- I'll also create inverted and uninverted options for claims and beneficiaries.

DROP VIEW v_raw_scores;

CREATE VIEW v_raw_scores AS
SELECT
    l.Brnd_Name,
    l.HCPCS_Cd,
    l.MedicationID,
    l.Outlier_Flag,
    l.year,
    PERCENT_RANK() OVER(PARTITION BY l.year ORDER BY m.Avg_Spndng_Per_Dsg_Unt) AS avg_spnd_rank,
    1 - PERCENT_RANK() OVER(PARTITION BY l.year ORDER BY b.Tot_Clms) AS tot_clms_rank,
    1 - PERCENT_RANK() OVER(PARTITION BY l.year ORDER BY b.Tot_Benes) AS tot_benes_rank,
    PERCENT_RANK() OVER(PARTITION BY l.year ORDER BY b.Tot_Clms) AS tot_clms_true,
    PERCENT_RANK() OVER(PARTITION BY l.year ORDER BY b.Tot_Benes) AS tot_benes_true
FROM lookup AS l
JOIN meds AS m
    ON l.MedicationID = m.MedicationID
JOIN benes AS b
    ON l.MedicationID = b.MedicationID;

-- Sanity Check
SELECT
    m.Brnd_Name, 
    m.Avg_Spndng_Per_Dsg_Unt,
    v.avg_spnd_rank
FROM meds AS m
JOIN v_raw_scores AS v
    ON m.MedicationID = v.MedicationID
WHERE m.year = 2023;

-- The top 8 2023 medications in order of least to greatest for 
-- the raw average spending scores and the raw average spending are the same.

DROP VIEW v_raw_growth_scores;

CREATE VIEW v_raw_growth_scores AS
SELECT
    g1.Brnd_Name,
    PERCENT_RANK() OVER(ORDER BY g1.pct_change) AS growth_21_22_rank,
    PERCENT_RANK() OVER(ORDER BY g2.pct_change) AS growth_22_23_rank
FROM v_growth_21_22 AS g1
JOIN v_growth_22_23 AS g2
    ON g1.Brnd_Name = g2.Brnd_Name;

SELECT
    *
FROM v_raw_growth_scores
ORDER BY growth_22_23_rank DESC;



-- I have all the raw scores, but the final scores will be calculated with weight for each aspect. 

DROP VIEW v_final_scores;

-- There should be no problem if I join on Brnd_Name.
-- Yes, there are duplicate brand names, one for each year, but the table provides the same result for each year.
-- The values that are actually affected by year aren't being joined, they're alrady in 1 table split by the index (HCPCS_Cd)

CREATE VIEW v_final_scores AS
SELECT
    r.Brnd_Name,
    r.year,
    r.avg_spnd_rank,
    r.Outlier_Flag,
    r.tot_benes_rank,
    r.tot_benes_true,
    r.tot_clms_rank,
    r.tot_clms_true,
    g.growth_21_22_rank,
    g.growth_22_23_rank,
    (   
        0.45 * r.avg_spnd_rank
      + 0.20 * r.tot_benes_rank
      + 0.20 * r.tot_clms_rank
      + 0.10 * g.growth_22_23_rank
      + 0.05 * g.growth_21_22_rank
    ) AS composite_score
FROM v_raw_scores AS r
JOIN v_raw_growth_scores AS g
    ON r.Brnd_Name = g.Brnd_Name;

-- Sanity Check: To ensure the code is working as it should with no silent debugs, I will check the following for 3 random meds:
-- 1. Each medication has the same growth rate in it's growth rate columns for each year.
-- 2. I will do manual composite score mathmatics on the scoring numbers to ensure it matches the final composite score.
-- Since all scores have already been checked for accuracy, this should be sufficient for production. 

SELECT
    *
FROM v_final_scores
WHERE Brnd_Name IN ('Alimta*', 'Acetaminophen (J0131)', 'Gelsyn-3');

-- I will also check for fanning by ensuring no medication appears more than 5 times, as the dataset only spans from 2019-2023.
-- If all is well, each medication should appear with a scoring for each year.
SELECT
    Brnd_Name,
    COUNT(Brnd_Name)
FROM v_final_scores
GROUP BY Brnd_Name
HAVING COUNT(Brnd_Name) > 5;

-- I plan to use the weighted scores, but here, I'll create a view for the unweighted scores just to have on hand.

DROP VIEW v_final_scores_unw;

CREATE VIEW v_final_scores_unw AS
SELECT
    r.Brnd_Name,
    r.year,
    r.avg_spnd_rank,
    r.HCPCS_Cd,
    r.Outlier_Flag,
    r.tot_benes_rank,
    r.tot_benes_true,
    r.tot_clms_rank,
    r.tot_clms_true,
    (   
        r.avg_spnd_rank
        + r.tot_benes_rank
        + r.tot_clms_rank
        + g.growth_22_23_rank
        + g.growth_21_22_rank
    ) / 5 AS composite_score_unw
FROM v_raw_scores AS r
JOIN v_raw_growth_scores AS g
    ON r.Brnd_Name = g.Brnd_Name;

-- I'll repeat the same sanity checks for the unweighted scores.

SELECT
    *
FROM v_final_scores_unw
WHERE Brnd_Name IN ('Alimta*', 'Acetaminophen (J0131)', 'Gelsyn-3');
SELECT
    Brnd_Name,
    COUNT(Brnd_Name)
FROM v_final_scores_unw
GROUP BY Brnd_Name
HAVING COUNT(Brnd_Name) > 5;

SELECT 
	Brnd_Name,
    year,
    ROUND(composite_score, 2) as Composite_Score
FROM v_final_scores
WHERE year = 2023
ORDER BY composite_score DESC;

-- Everything looks like it should. Now I just need to connect the database into Power BI.