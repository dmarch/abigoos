#---------------------------------------------------------------------------------------
# tbl_overlap_results.R        Generate table with overlap indices per species, region and data source
#---------------------------------------------------------------------------------------

## Load dependencies
library(dplyr)
source("R/data_paths.R")

## Import data
spplist <- read.csv(spp_list_group)  # Import species list
eoo_overlap <- read.csv(paste(overlap_dir, "eoo_overlap.csv", sep="/"))  # overlap metrics for eoo
tel_overlap <- read.csv(paste(overlap_dir, "telemetry_overlap.csv", sep="/"))  # overlap metrics for telemetry

## Add data_type to overlap tables
eoo_overlap$data_type <- "eoo"
tel_overlap$data_type <- "telemetry"

## Combine EOO and telemetry
comb <- rbind(eoo_overlap, tel_overlap)

## Select columns from species list
spplist <- spplist %>%
  dplyr::select(
    group_name,
    scientific_name,
    taxonid)

## Incorporate species name and group
comb <- merge(comb, spplist, by="taxonid")

## Select columns to export
comb <- comb %>%
  dplyr::select(
    group_name,
    scientific_name,
    taxonid,
    region,
    range_km2,
    ov_range,
    ov_coldspot,
    data_type
  )

## Set order by taxonomic group
comb <- arrange(comb, group_name, scientific_name, data_type)

## Metadata
# group_name = "taxonomic group used in this study",
# scientific_name = "scientific name of species",
# taxonid = "taxonomic ID from IUCN API",
# region = "ocean region",
# extent_km2 ="species range, in km2",
# ov_range = "proportion of overlap with coldspots in relation to species range",
# ov_coldspot = "proportion of overlap with coldspots in relation to coldspot surface"
# data_type = "data type: eoo or telemetry"

## Export table (CSV format)
outfile <- paste(tbl_dir, "tbl_overlap_results.csv", sep="/")
write.csv(comb, outfile, row.names=FALSE)
