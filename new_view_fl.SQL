## Make a table showcasing uncontested vs contested seats - FL Example
#sum_number_of_seats: The total number of seats for the given position (summed across all rows).
#total_candidates: The total number of candidates (summed across all rows).
#general_candidates: The number of candidates in the general election (summed across all rows).
#uncontested_seats: The number of uncontested seats for each position, includes primary and general.
#uncontested_general_seats: The number of uncontested seats in the general election.
#total_officeholders: The total number of officeholders for each position.
#vacant_officeholders: The number of vacant officeholders for each position.
#off_cycle_officeholders: The number of off-cycle officeholders for each position.

CREATE OR REPLACE VIEW `prod-pipeline-initia-6a1e01ea.pipeline_partner_data.contest_uncontest_view` AS
WITH candidacy_counts AS (
  SELECT 
    c.state,
    c.position_id,
    COUNT(DISTINCT c.candidacy_id) AS total_candidates,
    SUM(CASE WHEN c.is_primary = FALSE THEN 1 ELSE 0 END) AS general_candidates,
    SUM(CASE WHEN c.is_primary = TRUE THEN 1 ELSE 0 END) AS primary_candidates
  FROM `prod-pipeline-initia-6a1e01ea.pipeline_partner_data.br_candidacies` c
  GROUP BY c.state, c.position_id
),
officeholder_counts AS (
  SELECT 
    oh.state,
    oh.position_id,
    COUNT(DISTINCT oh.office_holder_id) AS total_officeholders,
    SUM(CASE WHEN oh.is_vacant = TRUE THEN 1 ELSE 0 END) AS vacant_officeholders,
    SUM(CASE WHEN oh.is_off_cycle = TRUE THEN 1 ELSE 0 END) AS off_cycle_officeholders
  FROM `prod-pipeline-initia-6a1e01ea.pipeline_partner_data.br_officeholders` oh
  GROUP BY oh.state, oh.position_id
)
SELECT 
  c.state,
  EXTRACT(YEAR FROM c.election_day) AS election_year,
  c.position_name AS position,
  c.position_id AS position_id,
  c.geo_id AS geo_id,
  c.mtfcc AS mtfcc,
  c.level AS level,
  c.normalized_position_name,
  CASE
    WHEN c.mtfcc IN ('600', '610') THEN 'State Legislature'
    WHEN c.mtfcc = '2390' THEN 'School Board'
    WHEN c.is_judicial = TRUE THEN 'Judicial'
    WHEN c.level = 'State' THEN 'Statewide'
    WHEN c.level = 'County' THEN 'County'
    WHEN c.level = 'Federal' THEN 'Federal'
    ELSE 'Local'
  END AS position_type,
  SUM(c.number_of_seats) AS sum_number_of_seats,

  -- Aggregate candidacy counts correctly
  SUM(cc.total_candidates) AS total_candidates,
  SUM(cc.general_candidates) AS general_candidates,

  -- Calculate uncontested seats, ignoring zero candidate values
  COUNT(DISTINCT CASE 
    WHEN cc.total_candidates > 0 AND c.number_of_seats >= cc.total_candidates THEN c.position_id 
  END) AS uncontested_seats,

  -- Calculate uncontested general election seats, also ignoring zero candidate values
  COUNT(DISTINCT CASE 
    WHEN cc.general_candidates > 0 AND c.number_of_seats >= cc.general_candidates THEN c.position_id 
  END) AS uncontested_general_seats,

  -- Aggregate officeholder counts correctly
  SUM(oc.total_officeholders) AS total_officeholders,
  SUM(oc.vacant_officeholders) AS vacant_officeholders,
  SUM(oc.off_cycle_officeholders) AS off_cycle_officeholders
FROM `prod-pipeline-initia-6a1e01ea.pipeline_partner_data.br_candidacies` c
LEFT JOIN candidacy_counts cc
  ON c.state = cc.state AND c.position_id = cc.position_id
LEFT JOIN officeholder_counts oc
  ON c.state = oc.state AND c.position_id = oc.position_id
GROUP BY c.state, election_year, c.position_name, c.position_id, c.geo_id, c.mtfcc, c.level, c.normalized_position_name, c.is_judicial;
