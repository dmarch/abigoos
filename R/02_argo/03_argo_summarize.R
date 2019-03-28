#-------------------------------------------------------------------------------------
# 03_argo_summarize.R      Summarize coldspot surfaces
#-------------------------------------------------------------------------------------
# This script summarizes Argo coldspot surface by latitude, bathymetry, EZZ, and ocean regions



## Load libraries
library(raster)
library(ggplot2)
library(stringr)
library(reshape2)
library(rgdal)
source("R/utils.R")
source("R/data_paths.R")

## Import data
coldspots <- raster(argo_coldspots)
bathy <- raster(temp_bathy)



#------------------------------------------------
# 1. Summarize coldspots latitude
#------------------------------------------------

## Unsampled data
zunsamp <- zonalLatitude(coldspots, fun="sum")

## Transform Mollweide coordinates to geographic
GEO <- "+proj=longlat +ellps=WGS84"
df <- data.frame(x= 0, y = zunsamp[,"zone"])
coordinates(df) = ~x+y
proj4string(df) <- CRS(PROJ)
df.lonlat <- spTransform(df, CRS=CRS(GEO))

## Reasign values
zunsamp[,"zone"] <- coordinates(df.lonlat)[,"y"]
plot(zunsamp, typ="l")

# Export data.frame for plotting
df <- data.frame(latitude = zunsamp[,"zone"], coldspot_surface=zunsamp[,"sum"])
write.csv(df, coldspots_latitude_csv, row.names=FALSE)


#------------------------------------------------
# 2. Summarize coldspots by bathymetry
#------------------------------------------------

## get range  value of bathymetry
bathy <- setMinMax(bathy)
bathy_max <- signif(minValue(bathy), digits=2)
       
## Reclassify bathymetry at 100 m intervals
from <- seq(0, bathy_max+100, by=-100)
to <- seq(-100, bathy_max, by=-100)
becomes <- seq(100, abs(bathy_max), by=100)
rclmat <- matrix(cbind(to, from, becomes), ncol=3, byrow=FALSE)  # switched 'to' and 'from' due to negative values
rclmat <- rbind(c(0,Inf,NA), rclmat)  # include NA for surface values
rc <- reclassify(bathy, rclmat)  # reclassify raster

## Calculate undersampled surface per bathymetric level using zonal statistics
zbathy <- zonal(coldspots, rc, "sum", digits=1, na.rm=TRUE)  # sum surface values (km2) per bathymetric level
plot(zbathy, typ="l")

## Calculate the percentage of surface in shallow water (<200m)
sum(zbathy[1:2, "sum"]) / sum(zbathy[,"sum"])  # 34.2%

# Export data.frame for plotting
df <- data.frame(bathymetry = zbathy[,"zone"], coldspot_surface=zbathy[,"sum"])
write.csv(df, coldspots_bathymetry_csv, row.names=FALSE)


#------------------------------------------------
# 3. Summarize coldspots by EEZ
#------------------------------------------------

