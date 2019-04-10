#---------------------------------------------------------------------------------------
# tbl_ezz_top15.R        Generate top 15 EEZs by coldspot surface
#---------------------------------------------------------------------------------------

## Load dependencies
library(dplyr)
source("R/data_paths.R")

## Import coldspot estimates by EEZ
eez <- read.csv(coldspots_eez_csv)

## Select and rename columns
eez <- eez %>%
  mutate(eez = Sovereign1, eez_km2 = area_km2, coldspot_percent = overall_proportion) %>%
  dplyr::select(eez, coldspot_km2, coldspot_percent, eez_km2)

## Estimate total
total <- colSums(eez[,2:4])
total <- data.frame(t(total))
total$eez <- "All EEZ"

## Select top 15
eez <- eez[1:15,]

## combine top 15 with total
df <- rbind(eez, total)

## Export table (CSV format)
outfile <- paste(tbl_dir, "tbl_eez_top15.csv", sep="/")
write.csv(df, outfile, row.names=FALSE)
