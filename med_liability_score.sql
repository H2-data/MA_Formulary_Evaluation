-- Now that I have all data and metrics, I'll score everything here.
-- First, I'll create the raw scores for claims, beneficiaries, and spending.
-- I'll also create inverted and uninverted options for claims and beneficiaries.

DROP VIEW v_raw_scores;

CREATE VIEW v_raw_scores AS
SELECT
    l.Brnd_Name,
    l.HCPCS_Cd,
    l.Outlier_Flag,
    l.year,
    PERCENT_RANK() OVER(PARTITION BY l.year ORDER BY m.Avg_Spndng_Per_Dsg_Unt) AS avg_spnd_rank,
    1 - PERCENT_RANK() OVER(PARTITION BY l.year ORDER BY b.Tot_Clms) AS tot_clms_rank,
    1 - PERCENT_RANK() OVER(PARTITION BY l.year ORDER BY b.Tot_Benes) AS tot_benes_rank,
    PERCENT_RANK() OVER(PARTITION BY l.year ORDER BY b.Tot_Clms) AS tot_clms_true,
    PERCENT_RANK() OVER(PARTITION BY l.year ORDER BY b.Tot_Benes) AS tot_benes_true
FROM lookup AS l
JOIN meds AS m
    ON l.HCPCS_Cd = m.HCPCS_Cd
JOIN benes AS b
    ON l.HCPCS_Cd = b.HCPCS_Cd;

SELECT * FROM v_raw_scores;

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
-- Yes, there are duplicate brand names, one for each year, but the table Im provides the same result for each year.
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

SELECT
    *
FROM v_final_scores
ORDER BY composite_score DESC;

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

SELECT
    *
FROM v_final_scores_unw
ORDER BY composite_score_unw DESC;

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