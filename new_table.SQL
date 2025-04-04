### this table is for LEAD PA, Oliver wants an end result of a pivot table, showing vote totals for everything except USP, STS, STH
## LEAD PA:
## Oliver: wants a pivot table. in partner_lead_pa, joins precinct 2020, 2022, 2024 —> table is general_20_22_24
## drop table, recreate is as general_22_23_24;  union, select from 2022, 2023, 2024
##congress national, % for dem / gop; sum of votes for dems statewide candidates divided by all votes, grouped by legislative district; put the years in as rows
## don’t model it off of general_22_23_24.
## imagine: columns: votes for each party, rows are senate and house district, values in cells are % of votes won by each party
## each candidate has vote_total, make a cute for votes won by what candidate; DEM - case when candidate_party is DEM/REP/IND
## we want: where candidate_office_code not in (USP, STS, STH) 

CREATE TABLE `prod-pipeline-initia-6a1e01ea.partner_lead_pa.general_22_23_24` AS
WITH combined_votes AS (
    SELECT 
        year,
        candidate_district,
        candidate_office_code,
        election_type,
        party_simplified,
        SUM(vote_total) AS total_votes,
        SUM(COALESCE(yes_vote_total, 0)) AS total_yes, 
        SUM(COALESCE(no_vote_total, 0)) AS total_no  
    FROM (
        SELECT 2022 AS year, * FROM `prod-pipeline-initia-6a1e01ea.partner_lead_pa.precinct_general_2022`
        UNION ALL
        SELECT 2024 AS year, * FROM `prod-pipeline-initia-6a1e01ea.partner_lead_pa.precinct_general_2024`
        UNION ALL
        SELECT 2023 AS year, * FROM `prod-pipeline-initia-6a1e01ea.partner_lead_pa.precinct_municipal_returns_2023`
    )
    WHERE candidate_office_code NOT IN ('USP')  
    GROUP BY year, candidate_district, candidate_office_code, election_type, party_simplified
),
performance AS (
    SELECT 
        year,
        candidate_district,
        candidate_office_code,
        election_type,
        SUM(total_votes) AS total_votes,
        SUM(CASE WHEN party_simplified = 'DEM' THEN total_votes ELSE 0 END) * 1.0 /
        NULLIF(SUM(total_votes), 0) AS dem_pct,
        SUM(CASE WHEN party_simplified = 'REP' THEN total_votes ELSE 0 END) * 1.0 /
        NULLIF(SUM(total_votes), 0) AS rep_pct,
        SUM(CASE WHEN party_simplified = 'THIRD' THEN total_votes ELSE 0 END) * 1.0 /
        NULLIF(SUM(total_votes), 0) AS ind_pct,
        SUM(total_yes) AS total_yes,
        SUM(total_no) AS total_no,
        CASE 
            WHEN SUM(total_yes) + SUM(total_no) > 0 
            THEN SUM(total_yes) * 1.0 / (SUM(total_yes) + SUM(total_no)) 
            ELSE NULL 
        END AS yes_pct  
    FROM combined_votes
    GROUP BY year, candidate_district, candidate_office_code, election_type
)
SELECT 
    year,
    candidate_district AS district,
    candidate_office_code,
    election_type,
    total_votes,
    dem_pct,
    rep_pct,
    ind_pct,
    total_yes,
    total_no,
    yes_pct,
    CASE 
        WHEN candidate_office_code = 'STS' THEN 'State Senate'
        WHEN candidate_office_code = 'STH' THEN 'State House'
        ELSE 'Other'
    END AS chamber,
    CONCAT(
        CASE 
            WHEN candidate_office_code = 'STS' THEN 'SD-' 
            WHEN candidate_office_code = 'STH' THEN 'HD-' 
            ELSE 'Other-'
        END,
        candidate_district
    ) AS district_id
FROM performance
ORDER BY year, candidate_district, election_type;

### list out columns
SELECT column_name
FROM `prod-pipeline-initia-6a1e01ea.ballotready.INFORMATION_SCHEMA.COLUMNS`
WHERE table_name = 'offices';
