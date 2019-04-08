#-----------------------------------------------------------------------------
# 01_overlap_telemetry.R      Spatial overlap between Telemetry maps and Argo coldspots
#------------------------------------------------------------------------------
#
# Inputs:
# - Argo coldspots
# - Rasters with presence/absence of per species
#
# Output:
# - Table with overlap indices
#
# Description:
# We assessed the spatial overlap between rasterized species distribution maps
# (i.e., Telemetry maps) and the coldspot regions of the Argo network.
# We use distribution data as presence/absence data.
# For each species, we quantified the spatial overlap between its spatial distribution
# and Argo coldspots using two complementary indices:
# OVcoldspot = S / C
# OVrange = S / R	
# where S is the shared surface between the species range and the coldspot regions,
# C is the surface occupied only by the coldspots,
# and R is the surface used only by the species.
# The first index, OVcoldspot, represents the propotion of coldspots that are covered by the range of a single species.
# The second index, OVrange, indicates the amount of one species range that overlaps with coldspots surfaces,
# and can be understood as an indicator of the specificity of such species to remain within coldspots areas.
# We calculated the spatial overlap indices for the global ocean (90ºS – 90ºN),
# and five sectors of the world oceans limited by the 30th and 60th parallels.


## Load libraries
library(raster)
library(dplyr)
library(data.table)
source("R/data_paths.R")
source("R/utils.R")

## Import data
coldspots <- raster(argo_coldspots)  # Argo coldspots
match <- read.csv(spp_list_group)  # Species list

## Import pinniped profiles
outfile <- paste0(temp_dir, "/meop_profiles.csv")
profdf <- read.csv(outfile)

## List all species with telemetry data
match <- dplyr::select(match, taxonid, scientific_name, group)  # select fields
df_pin <- filter(match, scientific_name %in% unique(profdf$scientific_name))  # Select pinniped species from profiles
df_tur <- filter(match, group == "turtle")  # select all sea turtles
match <- rbind(df_pin, df_tur)  # combine pinnipeds and turtles


## Prepare data
overlap_list <- list()  # create empty list to store the results
ids <- match$taxonid  # select unique IDs

## Calculate overlap between species range and Argo coldspots
for (i in 1:length(ids)){
 
  print(paste("Species", i, "from", length(ids)))
  
  # import EOO raster map
  taxonid <- ids[i]
  pat <- paste0("^", taxonid, ".nc")
  file <- list.files(telemetry_tempdir, recursive=TRUE, pattern=pat, full.names=TRUE)
  r <- raster(file)
  
  # Overlap analysis
  ov <- overlap(a=r, b=coldspots)
  
  # Append results to list
  df <- data.frame(taxonid, ov)
  overlap_list[[i]] <- df
}

## Combine all species
data <- rbindlist(overlap_list)

## Rename variables
names(data)[names(data)=="a_km2"] <- "range_km2"
names(data)[names(data)=="b_km2"] <- "coldspot_km2"
names(data)[names(data)=="overlap_a"] <- "ov_range"
names(data)[names(data)=="overlap_b"] <- "ov_coldspot"

## Export table
outfile <- paste(overlap_dir, "telemetry_overlap.csv", sep="/")
write.csv(data, outfile, row.names=FALSE)