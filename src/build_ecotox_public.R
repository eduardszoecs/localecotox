### ----------------------------------------------------------------------------
### Build a local version of the EPA ECOTOX database  https://cfpub.epa.gov/ecotox/
### Written by Eduard Szöcs
### LICENSE: MIT

# path to downloaded and extracted ecotox database
datadir <- '/Downloads/ecotox_ascii_06_15_2016/' # adapt 

# db server details
require(RPostgreSQL)
DBname <- 'ecotox'
DBhost <- '<yourIP>'   # or localhost)
DBport <- '<yourPort>' # default is 5432
DBuser <- '<yourUsername>'

drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, dbname=DBname, user=DBuser, host=DBhost, port=DBport)


### ----------------------------------------------------------------------------
# Push data to server (core data)
# list all .txt files
files <- list.files(datadir, pattern = "*.txt", full.names = TRUE)
# exlcude the release notes
files <- files[!grepl('release', files)]
# extract the file/table names
names <- gsub(".txt", "", basename(files))
# for every file, read into R and copy to postgresql
for(i in seq_along(files)){
  message("Read File: ", files[i], "\n")
  df <- read.table(files[i], header = TRUE, sep = '|', comment.char = '', 
    quote = '')
  dbWriteTable(con, names[i], value = df, row.names = FALSE)
}

# Add primary keys
dbSendQuery(con, "ALTER TABLE chemical_carriers ADD PRIMARY KEY (carrier_id)")
dbSendQuery(con, "ALTER TABLE dose_response_details ADD PRIMARY KEY (dose_resp_detail_id)")
dbSendQuery(con, "ALTER TABLE dose_response_links ADD PRIMARY KEY (dose_resp_link_id)")
dbSendQuery(con, "ALTER TABLE dose_responses ADD PRIMARY KEY (dose_resp_id)")
dbSendQuery(con, "ALTER TABLE doses ADD PRIMARY KEY (dose_id)")
dbSendQuery(con, "ALTER TABLE media_characteristics ADD PRIMARY KEY (result_id)")
dbSendQuery(con, "ALTER TABLE results ADD PRIMARY KEY (result_id)")
dbSendQuery(con, "ALTER TABLE tests ADD PRIMARY KEY (test_id)")

# add indexes
dbSendQuery(con, "CREATE INDEX idx_chemical_carriers_test_id ON chemical_carriers(test_id)")
dbSendQuery(con, "CREATE INDEX idx_chemical_carriers_cas ON chemical_carriers(cas_number)")
dbSendQuery(con, "CREATE INDEX idx_dose_response_details_dose_resp_id ON dose_response_details(dose_resp_id)")
dbSendQuery(con, "CREATE INDEX idx_dose_response_details_dose_id ON dose_response_details(dose_id)")
dbSendQuery(con, "CREATE INDEX idx_dose_response_links_results_id ON dose_response_links(result_id)")
dbSendQuery(con, "CREATE INDEX idx_dose_response_links_dose_resp ON dose_response_links(dose_resp_id)")
dbSendQuery(con, "CREATE INDEX idx_dose_responses_test_id ON dose_responses(test_id)")
dbSendQuery(con, "CREATE INDEX idx_dose_responses_effect_code ON dose_responses(effect_code)")
dbSendQuery(con, "CREATE INDEX idx_doses_test_id ON doses(test_id)")
dbSendQuery(con, "CREATE INDEX idx_results_endpoint ON results(endpoint)")
dbSendQuery(con, "CREATE INDEX idx_results_test_id ON results(test_id)")
dbSendQuery(con, "CREATE INDEX idx_results_effect ON results(effect)")
dbSendQuery(con, "CREATE INDEX idx_results_conc1_unit ON results(conc1_unit)")
dbSendQuery(con, "CREATE INDEX idx_results_obs_duration_mean ON results(obs_duration_mean)")
dbSendQuery(con, "CREATE INDEX idx_results_obs_duration_unit ON results(obs_duration_unit)")
dbSendQuery(con, "CREATE INDEX idx_results_measurement ON results(measurement)")
dbSendQuery(con, "CREATE INDEX idx_results_response_site ON results(response_site)")
dbSendQuery(con, "CREATE INDEX idx_results_chem_analysis ON results(chem_analysis_method)")
dbSendQuery(con, "CREATE INDEX idx_results_significance_code ON results(significance_code)")
dbSendQuery(con, "CREATE INDEX idx_results_trend ON results(trend)")
dbSendQuery(con, "CREATE INDEX idx_test_cas ON tests(test_cas)")
dbSendQuery(con, "CREATE INDEX idx_test_species_number ON tests(species_number)")
dbSendQuery(con, "CREATE INDEX idx_test_media_type ON tests(media_type)")
dbSendQuery(con, "CREATE INDEX idx_test_location ON tests(test_location)")
dbSendQuery(con, "CREATE INDEX idx_test_type ON tests(test_type)")
dbSendQuery(con, "CREATE INDEX idx_test_study_type ON tests(study_type)")
dbSendQuery(con, "CREATE INDEX idx_test_method ON tests(test_method)")
dbSendQuery(con, "CREATE INDEX idx_test_lifestage ON tests(organism_lifestage)")
dbSendQuery(con, "CREATE INDEX idx_test_gender ON tests(organism_gender)")
dbSendQuery(con, "CREATE INDEX idx_test_source ON tests(organism_source)")
dbSendQuery(con, "CREATE INDEX idx_test_exposure ON tests(exposure_type)")
dbSendQuery(con, "CREATE INDEX idx_test_application_freq_unit ON tests(application_freq_unit)")
dbSendQuery(con, "CREATE INDEX idx_test_application_type ON tests(application_type)")

# move to ecotox schema
dbSendQuery(con, "CREATE SCHEMA ecotox;")
for (i in names) {
  q <- paste0("ALTER TABLE ", i, " SET SCHEMA ecotox")
  dbSendQuery(con, q)
}


### ----------------------------------------------------------------------------
# Push data to server (validation data)
files2 <- list.files(file.path(datadir, "validation"), pattern = "*.txt", 
  full.names = T)
names2 <- gsub(".txt", "", basename(files2))
for(i in seq_along(files2)){
  message("Read File: ", files2[i], "\n")
  df <- read.table(files2[i], header = TRUE, sep = '|', comment.char = '', 
    quote = '')
  dbWriteTable(con, names2[i], value = df, row.names = FALSE)
}

# Add primary keys (some table without PK -> these are just lookup tables)
dbSendQuery(con, "ALTER TABLE chemicals ADD PRIMARY KEY (cas_number)")
dbSendQuery(con, "ALTER TABLE \"references\" ADD PRIMARY KEY (reference_number)")
dbSendQuery(con, "ALTER TABLE species ADD PRIMARY KEY (species_number)")
dbSendQuery(con, "ALTER TABLE species_synonyms ADD PRIMARY KEY (species_number, latin_name)")
dbSendQuery(con, "ALTER TABLE trend_codes ADD PRIMARY KEY (code)")
dbSendQuery(con, "ALTER TABLE application_type_codes ADD PRIMARY KEY (code)")
dbSendQuery(con, "ALTER TABLE application_frequency_codes ADD PRIMARY KEY (code)")
dbSendQuery(con, "ALTER TABLE exposure_type_codes ADD PRIMARY KEY (code)")
dbSendQuery(con, "ALTER TABLE chemical_analysis_codes ADD PRIMARY KEY (code)")
dbSendQuery(con, "ALTER TABLE organism_source_codes ADD PRIMARY KEY (code)")
dbSendQuery(con, "ALTER TABLE gender_codes ADD PRIMARY KEY (code)")
dbSendQuery(con, "ALTER TABLE lifestage_codes ADD PRIMARY KEY (code)")
dbSendQuery(con, "ALTER TABLE response_site_codes ADD PRIMARY KEY (code)")
dbSendQuery(con, "ALTER TABLE measurement_codes ADD PRIMARY KEY (code)")
dbSendQuery(con, "ALTER TABLE effect_codes ADD PRIMARY KEY (code)")
dbSendQuery(con, "ALTER TABLE test_method_codes ADD PRIMARY KEY (code)")
dbSendQuery(con, "ALTER TABLE field_study_type_codes ADD PRIMARY KEY (code)")
dbSendQuery(con, "ALTER TABLE test_type_codes ADD PRIMARY KEY (code)")
dbSendQuery(con, "ALTER TABLE test_location_codes ADD PRIMARY KEY (code)")
dbSendQuery(con, "ALTER TABLE media_type_codes ADD PRIMARY KEY (code)")

# Add indexes
dbSendQuery(con, "CREATE INDEX idx_species_latin ON species(latin_name)")
dbSendQuery(con, "CREATE INDEX idx_species_group ON species(ecotox_group)")
dbSendQuery(con, "CREATE INDEX idx_media_type ON media_type_codes(code)")

# change name and schema of references
dbSendQuery(con, 'ALTER TABLE public.\"references\" RENAME TO refs')
dbSendQuery(con, 'ALTER TABLE public.refs SET SCHEMA ecotox')

# move to ecotox schema
for(i in names2[!names2 %in% 'references']){
  q <- paste0("ALTER TABLE ", i, " SET SCHEMA ecotox")
  dbSendQuery(con, q)
}



### ----------------------------------------------------------------------------
# Push data to server (lookup tables)
# path for lookup-tables
lookuppath <- '/home/edisz/Documents/Uni/Projects/PHD/15localecotoxdatabase/data/conversions/'
files3 <- list.files(lookuppath, pattern = "*.csv$", 
                     full.names = T)
names3 <- gsub(".csv", "", basename(files3))
for(i in seq_along(files3)){
  message("Read File: ", files3[i], "\n")
  df <- read.table(files3[i], header = TRUE, sep = ';')
  dbWriteTable(con, names3[i], value = df, row.names = FALSE)
  dbSendQuery(con, paste0('ALTER TABLE ', names3[i], ' SET SCHEMA ecotox'))
}

# add pk
dbSendQuery(con, "ALTER TABLE ecotox.ecotox_group_convert ADD PRIMARY KEY (ecotox_group)")
dbSendQuery(con, "ALTER TABLE ecotox.unit_convert ADD PRIMARY KEY (unit)")
dbSendQuery(con, "ALTER TABLE aquire.duration_convert ADD PRIMARY KEY (duration, unit)")

# add indexes
dbSendQuery(con, "CREATE INDEX idx_duration_convert_unit ON ecotox.duration_convert(unit)")
dbSendQuery(con, "CREATE INDEX idx_duration_convert_duration ON ecotox.duration_convert(duration)")


### ----------------------------------------------------------------------------
## functions
# Cast text to numeric, if not possible return NULL
dbSendQuery(con, "
CREATE OR REPLACE FUNCTION cast_to_num(text) 
RETURNS numeric AS 
            $$
            begin
            -- Note the double casting to avoid infinite recursion.
            RETURN cast($1::varchar AS numeric);
            exception
            WHEN invalid_text_representation THEN
            RETURN NULL;
            end;
            $$ 
            language plpgsql immutable;
            ")

dbSendQuery(con, "
            CREATE CAST (text as numeric) WITH FUNCTION cast_to_num(text);"
)




### ----------------------------------------------------------------------------
# Maintainance
dbSendQuery(con, 'VACUUM ANALYZE')

dbDisconnect(con)
dbUnloadDriver(drv)
