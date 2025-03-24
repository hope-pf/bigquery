## voterfile
SELECT m.`Indigo voter ID` as stacks_id, i.candidate_id as ballotready_id ,
`VANID` as van_id,
`Date of birth` as dob,
m.`Gender` as gender,
`Ethnicity` as race,
`Registration address` as reg_address,
`Registration city` as reg_city,
`Registration state` as reg_state,
`Registration ZIP code` as reg_zip,
`Mailing address` as mail_address,
`Mailing city` as mail_city,
`Mailing state` as mail_state,
`Mailing ZIP code` as mail_zip,
`Cell phone number` as cell,
`Landline phone number` as landline,
`Party registration` as registered_party,
`Dem partisanship` as dem_partisanship,
`Presidental general turnout` as pres_gen_turnout,
`Harris 2024 support` as harris_support

from `prod-pipeline-initia-6a1e01ea.partner_matches.emerge_matched_032125` m
left join `prod-pipeline-initia-6a1e01ea.matched_ballotready.br_candidacies_matched_indigo` i
on
m.`Indigo voter ID`= i.indigo_voter_id
left join `prod-pipeline-initia-6a1e01ea.stacks_people.voters_modeling` st on m.`Indigo voter ID`
= st.voterbase_id

## BR Officeholders
SELECT m.`Indigo voter ID` as stacks_id, i.candidate_id , office_holder_id, o.state, o.level, o.is_judicial,
o.position_id, o.position_name, o.normalized_position_name, m.`Registration address` as reg_address, m.`Registration city` as reg_city, m.`Registration state` as reg_state,
m.`Registration ZIP code` as reg_zip, m.`Mailing address` as mail_address, m.`Mailing city` as mail_city, m.`Mailing state` as mail_state, m.`Mailing ZIP code` as mail_zip,
m.`Party registration` as registered_party, m.`Dem partisanship` as dem_partisanship, m.`Presidental general turnout` as pres_gen_turnout, m.`Harris 2024 support` as harris_support,
o.start_at, o.end_at
from `prod-pipeline-initia-6a1e01ea.partner_matches.emerge_matched_032125` m
left join `prod-pipeline-initia-6a1e01ea.matched_ballotready.br_candidacies_matched_indigo` i
on
m.`Indigo voter ID`= i.indigo_voter_id
left join `prod-pipeline-initia-6a1e01ea.ballotready_avro.office_holders` o using (candidate_id)
where office_holder_id is not null

## BR Candidates
SELECT m.`Indigo voter ID` as stacks_id, i.candidate_id ,
o.position_id, o.position_name, o.normalized_position_name, o.election_day, o.state, o.level,
o.is_judicial, o.is_primary, o.election_result
from `prod-pipeline-initia-6a1e01ea.partner_matches.emerge_matched_032125` m
left join `prod-pipeline-initia-6a1e01ea.matched_ballotready.br_candidacies_matched_indigo` i
on
m.`Indigo voter ID`= i.indigo_voter_id
left join `prod-pipeline-initia-6a1e01ea.ballotready_avro.candidacies` o using (candidate_id)
where i.candidate_id is not null
