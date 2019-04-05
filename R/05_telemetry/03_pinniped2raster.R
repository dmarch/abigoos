#-------------------------------------------------------------------
# 03_pinniped2raster.R
#-------------------------------------------------------------------


## Load libraries
library(raster)
library(maptools)
library(dplyr)
source("R/data_paths.R")

## Import species list
match <- read.csv(spp_list_group)
match$scientific_name <- as.character(match$scientific_name)

## Import ocean mask
mask <- raster(temp_mask)

## Import pinniped profiles
outfile <- paste0(temp_dir, "/meop_profiles.csv")
profdf <- read.csv(outfile)


## Create raster in longlat to use as base for rasterization
r <- raster(xmn=-180, xmx=180, ymn=-90, ymx=90, crs=CRS("+proj=longlat +ellps=WGS84"),
            resolution=c(1, 1), vals=NA)






#--------------------------------------------------------
# 1. Rasterize presence of telemetry records per species
#--------------------------------------------------------
