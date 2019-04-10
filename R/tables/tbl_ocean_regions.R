#---------------------------------------------------------------------------------------
# tbl_ocean_regions.R        Summarize coldspots and overlap by ocean regions
#---------------------------------------------------------------------------------------

## Load dependencies
library(dplyr)
source("R/data_paths.R")

## Import species data
#match <- read.csv(spp_list_group)  # Species list

## Import overlap indices for telemetry
eoo_overlap <- read.csv(paste(overlap_dir, "eoo_overlap.csv", sep="/"))  # overlap metrics for telemetry

## Import coldspot summary
coldspot_summary <- read.csv(coldspots_summary_csv)


### Overlap indices

## Filter out combinations of species and region not available
eoo_overlap <- filter(eoo_overlap, range_km2 > 0)

## Summarize overlap data by region
df <- eoo_overlap %>%
  group_by(region) %>%
  summarize(no_species = sum(!is.na(ov_coldspot)),
            ov_coldspot_mean = mean(ov_coldspot, na.rm=TRUE),
            ov_coldspot_sd = sd(ov_coldspot, na.rm=TRUE),
            ov_range_mean = mean(ov_range, na.rm=TRUE),
            ov_range_sd = sd(ov_range, na.rm=TRUE)
            )

### Combine with Argo coldspots
coldspot_summary$region <- c("NO", "TO", "SO", "AO", "ATO", "GO")
coldspot <- dplyr::select(coldspot_summary, region, ocean_area_km2, coldspot_area_km2,
                          coldspot_eez_percent)

comb <- merge(coldspot, df, by="region")


## Export table (CSV format)
outfile <- paste(tbl_dir, "tbl_ocean_regions.csv", sep="/")
write.csv(comb, outfile, row.names=FALSE)