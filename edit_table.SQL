`update `prod-pipeline-initia-6a1e01ea.partner_lead_pa.precinct_municipal_returns_2023`
set party_simplified =
(case when candidate_party_code = 'REP' then 'REP'
when candidate_party_code = 'DEM' then 'DEM'
else 'THIRD'
end)`
