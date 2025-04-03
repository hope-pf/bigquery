SELECT * FROM `prod-pipeline-initia-6a1e01ea.pipeline_partner_data.county_overlaps` 
where state = 'MI'
and extract (year from election_day) = 2025
order by county
