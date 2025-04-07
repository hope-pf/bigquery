## Make a table showcasing uncontested vs contested seats - FL Example
#sum_number_of_seats: The total number of seats for the given position (summed across all rows).
#total_candidates: The total number of candidates (summed across all rows).
#general_candidates: The number of candidates in the general election (summed across all rows).
#uncontested_seats: The number of uncontested seats for each position, includes primary and general.
#uncontested_general_seats: The number of uncontested seats in the general election.
#total_officeholders: The total number of officeholders for each position.
#vacant_officeholders: The number of vacant officeholders for each position.
#off_cycle_officeholders: The number of off-cycle officeholders for each position.

CREATE OR REPLACE TABLE `proj-tmc-mem-pia.pipeline_ballotready.aggregate_elections` AS

WITH overlaps_cte AS (
  SELECT * 
  FROM `prod-pipeline-initia-6a1e01ea.pipeline_partner_data.house_overlaps` 
  WHERE state = 'FL'
  
  UNION ALL
  
  SELECT * 
  FROM `prod-pipeline-initia-6a1e01ea.pipeline_partner_data.county_overlaps` 
  WHERE state = 'FL'
  
  UNION ALL
  
  SELECT * 
  FROM `prod-pipeline-initia-6a1e01ea.pipeline_partner_data.senate_overlaps` 
  WHERE state = 'FL'
)

SELECT 
  election_results.election_year,
  COALESCE(overlaps_cte.county, 'Unknown') AS district_name,
  election_results.position AS position,
  
  CASE
    WHEN election_results.position LIKE '%State%' THEN 'Statewide'
    WHEN election_results.position LIKE '%House%' THEN 'State House'
    WHEN election_results.position LIKE '%Senate%' THEN 'State Senate'
    WHEN election_results.position LIKE '%City%' THEN 'City'
    WHEN election_results.position LIKE '%Local%' THEN 'Local'
    WHEN election_results.position LIKE '%Judicial%' OR election_results.position LIKE '%Judge%' THEN 'Judicial'
    WHEN election_results.position LIKE '%County%' THEN 'County'
    WHEN election_results.position LIKE '%Federal%' THEN 'Federal'
    WHEN election_results.position LIKE '%Regional%' THEN 'Regional'
    WHEN election_results.position LIKE '%Town%' THEN 'Town'
    WHEN election_results.position LIKE '%Regional%' THEN 'Regional'
    ELSE 'Local'
  END AS geography_level,

  -- Include position_id, geo_id, and mtfcc
  election_results.position_id,
  election_results.geo_id,
  election_results.mtfcc,

  -- Count of total positions
  COUNT(*) AS count_of_positions,

  -- Total contested positions (more candidates than seats)
  SUM(CASE 
        WHEN election_results.total_candidates > election_results.sum_number_of_seats 
        THEN 1 
        ELSE 0 
      END) AS total_contested_positions,

  -- Total uncontested positions (candidates <= seats)
  SUM(CASE 
        WHEN election_results.total_candidates <= election_results.sum_number_of_seats 
        THEN 1 
        ELSE 0 
      END) AS total_uncontested_positions,

  -- Total uncontested general seats
  SUM(CASE 
        WHEN election_results.total_candidates <= election_results.sum_number_of_seats 
        THEN election_results.sum_number_of_seats
        ELSE 0 
      END) AS total_uncontested_general_seats,

  -- Candidate and officeholder aggregates
  SUM(election_results.total_candidates) AS total_candidates,
  SUM(election_results.general_candidates) AS total_candidates_general,
  SUM(election_results.sum_number_of_seats) AS total_num_of_seats_available,
  SUM(election_results.total_officeholders) AS total_officeholders,
  SUM(election_results.vacant_officeholders) AS vacant_officeholders,
  SUM(election_results.off_cycle_officeholders) AS off_cycle_officeholders

FROM `prod-pipeline-initia-6a1e01ea.pipeline_partner_data.contest_uncontest_view` election_results

LEFT JOIN overlaps_cte 
  ON election_results.position_id = overlaps_cte.position_id 

GROUP BY 
  election_results.election_year,
  district_name,
  election_results.position,
  election_results.position_type,
  geography_level,
  election_results.position_id,
  election_results.geo_id,
  election_results.mtfcc

ORDER BY election_year, district_name, position;
