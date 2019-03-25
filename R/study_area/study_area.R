#---------------------------------------------------------------------------------
# study_area.R   Process GEBCO data and generate ocean mask
#---------------------------------------------------------------------------------
# Author: David March
#
# Description:
# - Resamples global 30 arc-second interval grid into 1 x 1 degree
# - Excludes cells with <10% ocean area 
# - Excludes Caspian Sea
# - Transform to Mollweide
# - Calculate ocean surface for further analyses
#
# Inputs:
# - GEBCO bathymetry
# - Natural Earth landmask
#
# Outputs:
# This script derives: bathymetry at 1d, ocean mask at 1d, landmask in Mollweide
#---------------------------------------------------------------------------------


## Set script parameters
exclude_area <- 0.10 # Exclude cells containing <10% ocean area

## Set paths for generated files
temp_bathy <- paste(temp_dir,"bathy_1d_moll.nc", sep="/")
temp_mask <- paste(temp_dir,"mask_1d_moll.nc", sep="/")
temp_land <- "land_moll"

## Load libraries
library(raster)
library(maptools)
library(rgdal)
source("R/utils.R")
source("R/data_paths.R")

## Import data
gebco <- raster(gebco_nc)
land <- readShapePoly(ne_shp)
proj4string(land) <- CRS("+init=epsg:4326")

## Create a ocean mask
om <- reclassify(gebco, c(-Inf, 0, 1, 0, Inf, NA))  # negative values are ocean cells
gebco_mask <- gebco * om

## Aggregate data at 1 x 1 d
om_1d <- aggregate(om, fact=120, fun=sum)  # sum the number of cells defined as ocean
gebco_1d <-  aggregate(gebco_mask, fact=120, fun=mean) # average bathymetry values at resampled resolution

## Exclude cells containing <10% ocean area (1400 from 14000)
ncells <- maxValue(om_1d) * exclude_area
om_1d_rec <- reclassify(om_1d, c(-Inf, ncells, NA, ncells, Inf, 1))

## Exclude cells on land (eg. helps to remove lakes)
rland <- rasterize(land, om_1d, getCover=TRUE)  # fraction of each grid covered by land
ncells <-  maxValue(rland) * (1-exclude_area)
rland_rec <- reclassify(rland, c(-Inf, ncells, 1, ncells, Inf, NA))  # select cells with <10% land

## Combine ocean and landmask
mask <- om_1d_rec * rland_rec

## Exclude Caspian Sea
ec <- extent(c(45, 56, 35, 49))+5
cells <- cellsFromExtent(mask, ec)
mask[cells] <- NA   # plot(ec,add=TRUE)

## Apply mask to bathymetry
gebco_1d <- gebco_1d * mask

## Transform datasets to Mollweide
gebco_1d.prj <- projectRaster(gebco_1d, crs=PROJ, res=c(100000, 100000), method="bilinear")
mask.prj <- projectRaster(mask, crs=PROJ, res=c(100000, 100000), method="ngb")
land.prj <- spTransform(land, CRSobj = PROJ)  # Tranform data to Mollweide

## Export temporary products
writeRaster(gebco_1d.prj, temp_bathy, format="CDF", overwrite=TRUE)  # bathymetry
writeRaster(mask.prj, temp_mask, format="CDF", overwrite=TRUE)  # ocean mask
writeOGR(land.prj, temp_dir, temp_land, driver="ESRI Shapefile", overwrite_layer=TRUE)  # land reprojected

#writeRaster(gebco_1d, paste(temp_dir,"bathy_1d_lonlat.nc", sep="/"), format="CDF", overwrite=TRUE)
#writeRaster(mask, paste0(study_area_dir,"GEBCO_mask_1d_lonlat.nc"), format="CDF", overwrite=TRUE)
## Calculate surface of the ocean layer
#binsurf(mask.prj) # 374,450,000 km2
