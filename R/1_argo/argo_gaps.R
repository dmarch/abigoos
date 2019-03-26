#------------------------------------------------------------------------------
# argo_gaps.R       Analyse gap regions from profile density maps
#------------------------------------------------------------------------------
#
# Description:
# This script calculates sampling gaps, considering both unsampled and undersampled cells
#
# Inputs:
# - Argo counts
# - Raster ocean masks for processing
#
# Outputs:
# - argo_gaps.nc: argo gaps per year
# - argo_gap_persistence.nc: frequency of gaps
#------------------------------------------------------------------------------


## Load libraries
library(raster)
library(lubridate)
library(dplyr)
library(rgdal)
library(maptools)
source("R/utils.R")
source("R/data_paths.R")


#--------------------------------------------
# 1. Import data
#--------------------------------------------

mask <- raster(temp_mask) # oceanmask
argo <- stack(argo_count) # argo counts per year


#--------------------------------------------------------
# 2. Calculate undersampled regions for Argo
#--------------------------------------------------------
# Differentiate between undersampled(1) and unsampled(2)

## Calculate undersampled cells
unders.argo <- stack()
for (i in 1:nlayers(argo)){
  r <- subset(argo,i)
  iunsamp <- unsamp2(r, mask)
  unders.argo <- stack(unders.argo, iunsamp)
}

## Set dates
years <- as.numeric(str_extract(names(argo), "\\d{4}"))
unders.argo <- setZ(unders.argo, years)

## Save yearly undersampled maps in netcdf
writeRaster(unders.argo, filename=argo_gaps, format="CDF", overwrite=TRUE)


#--------------------------------------------------------
# 3. Calculate Persistence of gaps areas 
#--------------------------------------------------------

## combine unsampled and undersampled
gaps <- unders.argo/unders.argo

## Calculate how many time one cell has been considered undersampled from yearly maps
persistence <- sum(gaps, na.rm=TRUE) / nlayers(gaps)
persistence <- persistence * mask

## Save gap persistence map in netcdf
writeRaster(persistence, filename=argo_gap_persistence, format="CDF", overwrite=TRUE)


#--------------------------------------------------------
# 4. Calculate coldspots
#--------------------------------------------------------

## Select cells with a gap persistence >80%
## Note: this is not the 80% of the distribution
pers80 <- reclassify(persistence, c(-Inf, 0.8, NA, 0.8, Inf, 1))  # create a ocean mask

## Convert raster to polygons
pol <- rasterToPolygons(pers80, na.rm=TRUE, dissolve=TRUE)

## split into single polygons
poldis <- disaggregate(pol)

## calculate areas (in km2)
poldis$Area_km2 <- area(poldis)/1000000  # convert from area in square meters to square km

## Retain spatial coherent hotspots larger than 25 square degrees
polsel <- poldis[poldis$Area_km2 > (100*100*25),]
eliminated_cells <- 1 - (sum(polsel$Area_km2) / sum(poldis$Area_km2))  # 23.8% cells removed

## Backtransform to raster
## Note: check that you use a version of raster package >2.8-14
## previous version had issues when rasterizing polygon holes.
rpolsel <- rasterize(polsel, persistence)  # rasterize
rpolsel <- rpolsel/rpolsel  # set value to 1

## Summary data
binsurf(rpolsel)  # 70,370,000
(binsurf(rpolsel) / binsurf(mask)) * 100  # coldspots represents a 18.8%

## Save coldspots map
writeRaster(rpolsel, filename=argo_coldspots, format="CDF", overwrite=TRUE)  # nc
writePolyShape(polsel, argo_coldspots_shp)  # shapefile