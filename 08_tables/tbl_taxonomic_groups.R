#---------------------------------------------------------------------------------------
# tbl_taxonomic_groups.R        Generate table with summary per taxonomic groups
#---------------------------------------------------------------------------------------

## Load dependencies
library(dplyr)
source("R/data_paths.R")

## Import species data
match <- read.csv(spp_list_group)  # Species list

## Import overlap indices for telemetry
eoo_overlap <- read.csv(paste(overlap_dir, "eoo_overlap.csv", sep="/"))  # overlap metrics for telemetry

## Filter EOO overlap results at global level
eoo_overlap <- filter(eoo_overlap, region == "GO")

## Combine species list and overlap results
spp <- merge(match, eoo_overlap, by="taxonid")

## Summaryze data
df <- spp %>%
  group_by (group_name) %>% #ISO_Ter1, Sovereign1
  summarise (
    # no. species
    n = n(),
    # exntent
    meanExtent_km2 = mean(range_km2, na.rm=TRUE),
    sdExtent_km2 = sd(range_km2, na.rm=TRUE),
    nExtent = sum(!is.na(range_km2)),
    # length
    meanLength_m = mean(Length/100, na.rm=TRUE),
    sdLength_m = sd(Length/100, na.rm=TRUE),
    nLength = sum(!is.na(Length/100)),
    # depth
    meanDepth = mean(depth_lower, na.rm=TRUE),
    sdDepth = sd(depth_lower, na.rm=TRUE),
    nDepth = sum(!is.na(depth_lower)),
    ## overlap coldspots
    meanOVcoldspot = mean(ov_coldspot, na.rm=TRUE),
    sdOVcoldspot = sd(ov_coldspot, na.rm=TRUE),
    nOVcoldspot = sum(!is.na(ov_coldspot)),
    ## overlap range
    meanOVrange = mean(ov_range, na.rm=TRUE),
    sdOVrange = sd(ov_range, na.rm=TRUE),
    nOVrange = sum(!is.na(ov_range))
    )

## Export table (CSV format)
outfile <- paste(tbl_dir, "tbl_taxonomic_group.csv", sep="/")
write.csv(df, outfile, row.names=FALSE)
