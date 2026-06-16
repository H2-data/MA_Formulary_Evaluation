-- Now that I have all data and metrics, I'll score everything here.
-- First, I'll create the raw scores for claims, beneficiaries, and spending.
-- I'll also create inverted and uninverted options for claims and beneficiaries.

DROP VIEW raw_scores;

CREATE VIEW raw_scores AS
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
    ON l.Brnd_Name = m.Brnd_Name
JOIN benes AS b
    ON l.Brnd_Name = b.Brnd_Name;

SELECT * FROM raw_scores;

-- I have all the raw scores, but the final scores will be calculated with weight for each aspect. 
DROP VIEW final_scores;

CREATE VIEW final_scores AS
SELECT
    *,
    (   
        0.50 * avg_spnd_rank
      + 0.25 * tot_benes_rank
      + 0.25 * tot_clms_rank
    ) AS composite_score
FROM raw_scores;

SELECT * FROM final_scores
ORDER BY avg_spnd_rank;

-- I plan to use the weighted scores, but here, I'll create a view for the unweighted scores just to have on hand.

DROP VIEW final_scores_unw;

CREATE VIEW final_scores_unw AS
SELECT
    *,
    (
        avg_spnd_rank
      + tot_benes_rank
      + tot_clms_rank
    ) / 3 AS composite_score
FROM raw_scores;

SELECT 
	Brnd_Name,
    HCPCS_Cd,
    Outlier_Flag,
    year,
    ROUND(avg_spnd_rank, 2), 
	ROUND(tot_clms_rank, 2),
    ROUND(tot_benes_rank, 2),
    ROUND(composite_score, 2)
FROM final_scores
ORDER BY composite_score DESC
LIMIT 5;

-- Everything looks like it should. Now I just need to connect the database into Power BI.