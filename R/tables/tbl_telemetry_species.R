#---------------------------------------------------------------------------------------
# tbl_telemetry_species.R        Generate table with summary per telemetry species
#---------------------------------------------------------------------------------------

## Load dependencies
library(dplyr)
source("R/data_paths.R")


## Import species data
match <- read.csv(spp_list_group)  # Species list

## Import pinniped profiles
outfile <- paste0(temp_dir, "/meop_profiles.csv")
profdf <- read.csv(outfile)

## Import turtle summary
outfile <- paste(temp_dir, "obis_turtle_summary.csv", sep="/")
obis <- read.csv(outfile)

## Import overlap indices for telemetry
tel_overlap <- read.csv(paste(overlap_dir, "telemetry_overlap.csv", sep="/"))  # overlap metrics for telemetry


##### Combine overlap results with species
tel_overlap <- merge(tel_overlap, match, by="taxonid")


## Turtle data
obis <- obis %>%
            mutate(scientific_name = sp_scientific, tags = animals.tagged, observations = total.records) %>%
            dplyr::select(scientific_name, tags, observations)

## Pinniped data
meop <- profdf %>%
  group_by(scientific_name) %>%
  summarize(tags = n_distinct(tag), observations = n())

## Combine turtle and pinniped
tel_sp <- rbind(obis, meop)


# select overlap info
tel_overlap <- tel_overlap %>%
  filter(region == "GO") %>%
  dplyr::select(group_name, scientific_name, range_km2, ov_range, ov_coldspot)


# combine obis and overlap information
telemetry <- merge(tel_sp, tel_overlap, by="scientific_name")

## Set order by taxonomic group
telemetry <- arrange(telemetry, group_name, scientific_name)

## Export table (CSV format)
outfile <- paste(tbl_dir, "tbl_telemetry_species.csv", sep="/")
write.csv(telemetry, outfile, row.names=FALSE)