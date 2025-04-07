## LEAD PA: Oliver: wants a pivot table. in partner_lead_pa, joins precinct 2020, 2022, 2024 —> table is general_20_22_24
## columns: votes for each party, rows are senate and house district, values in cells are % of votes won by each party
## - vote totals are votes received by statewide candidates; 
## state house, state senate - votes that are summed are votes that are received by statewide candidates and then filter it to only show state house and state senate districts, not candidates

CREATE OR REPLACE TABLE `prod-pipeline-initia-6a1e01ea.partner_lead_pa.general_22_23_24` AS

-- Combine data from multiple election years 
WITH combined_votes AS (
    SELECT 
        year,  
        candidate_district,  
        candidate_office_code, 
        election_type,  
        party_simplified,  
        -- Only include vote totals for statewide candidates
        CASE 
            WHEN candidate_office_code NOT IN ('USS', 'USC', 'STS', 'STG', 'USP') THEN vote_total 
            ELSE 0 
        END AS vote_total,
        COALESCE(yes_vote_total, 0) AS yes_vote_total,  -- Ensure nulls become zero
        COALESCE(no_vote_total, 0) AS no_vote_total
    FROM (
        -- Union all relevant tables and label them by year
        SELECT 2022 AS year, * FROM `prod-pipeline-initia-6a1e01ea.partner_lead_pa.precinct_general_2022`
        UNION ALL
        SELECT 2024 AS year, * FROM `prod-pipeline-initia-6a1e01ea.partner_lead_pa.precinct_general_2024`
        UNION ALL
        SELECT 2023 AS year, * FROM `prod-pipeline-initia-6a1e01ea.partner_lead_pa.precinct_municipal_returns_2023`
    )
),

-- Agg vote totals by year, district, office, election type, and party
aggregated_votes AS (
    SELECT 
        year,
        candidate_district,
        candidate_office_code,
        election_type,
        party_simplified,
        SUM(vote_total) AS total_votes,  -- Total votes per party
        SUM(yes_vote_total) AS total_yes,  -- Total "yes" votes for ballot questions
        SUM(no_vote_total) AS total_no  -- Total "no" votes for ballot questions
    FROM combined_votes
    GROUP BY year, candidate_district, candidate_office_code, election_type, party_simplified
),

-- calculate party share and ballot support
performance AS (
    SELECT 
        year,
        candidate_district,
        candidate_office_code,
        election_type,
        SUM(total_votes) AS total_votes,  -- Total votes across all parties
        -- Calc percentage of Democratic votes
        SUM(CASE WHEN party_simplified = 'DEM' THEN total_votes ELSE 0 END) * 1.0 /
            NULLIF(SUM(total_votes), 0) AS dem_pct,
        -- Cal percentage of Republican votes
        SUM(CASE WHEN party_simplified = 'REP' THEN total_votes ELSE 0 END) * 1.0 /
            NULLIF(SUM(total_votes), 0) AS rep_pct,
        -- Calc percentage of Third-party votes
        SUM(CASE WHEN party_simplified = 'THIRD' THEN total_votes ELSE 0 END) * 1.0 /
            NULLIF(SUM(total_votes), 0) AS ind_pct,
        -- Summarize ballot totals
        SUM(total_yes) AS total_yes,
        SUM(total_no) AS total_no,
        -- Calc percentage support for "yes" on ballot questions
        CASE 
            WHEN SUM(total_yes) + SUM(total_no) > 0 
            THEN SUM(total_yes) * 1.0 / (SUM(total_yes) + SUM(total_no))
            ELSE NULL 
        END AS yes_pct
    FROM aggregated_votes
    GROUP BY year, candidate_district, candidate_office_code, election_type
)

-- format table with proper column order and labels
SELECT 
    year,  -- Election year
    CASE 
        WHEN candidate_office_code = 'STS' THEN 'State Senate'  -- Label for State Senate
        WHEN candidate_office_code = 'STH' THEN 'State House'   -- Label for State House
        ELSE 'Other'  -- Fallback
    END AS chamber,
    candidate_district AS district,  -- Raw district number
    CONCAT(
        CASE 
            WHEN candidate_office_code = 'STS' THEN 'SD-'  -- State Senate district ID prefix
            WHEN candidate_office_code = 'STH' THEN 'HD-'  -- State House district ID prefix
            ELSE 'Other-'
        END,
        candidate_district
    ) AS district_id,
    candidate_office_code,
    election_type,
    total_votes,
    dem_pct,
    rep_pct,
    ind_pct,
    total_yes,
    total_no,
    yes_pct

-- Only include rows for State Senate and State House
FROM performance
WHERE candidate_office_code IN ('STS', 'STH')
ORDER BY year, chamber, candidate_office_code, candidate_district;


### list out columns
SELECT column_name
FROM `prod-pipeline-initia-6a1e01ea.ballotready.INFORMATION_SCHEMA.COLUMNS`
WHERE table_name = 'offices';
