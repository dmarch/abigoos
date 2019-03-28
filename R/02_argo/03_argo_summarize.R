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
library(geosphere)
library(dplyr)
library(data.table)
source("R/utils.R")
source("R/data_paths.R")

## Import data
coldspots <- raster(argo_coldspots)
bathy <- raster(temp_bathy)
mask <- raster(temp_mask)

## Import EEZ
eez <- readOGR(eez_dir, eez_shp)






#------------------------------------------------
# 1. Summarize coldspots latitude
#------------------------------------------------

## Unsampled data
zunsamp <- zonalLatitude(coldspots, fun="sum")

## Transform Mollweide coordinates to geographic
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

## Transform coldspots to lonlat
## EEZ maps does not reproject well to Mollweide due to boundary issues
coldspots_geo <- projectRaster(coldspots, crs=GEO, method="ngb")

## Dissagregate EEZ polygons
eez_dis <- disaggregate(eez) # (281 => 1821 elements)

# recalculate area for each new polygon
eez_dis$Area_km2_new <- areaPolygon(eez_dis)/1000000  # convert from area in square meters to square km

## Calculate area of Argo undersampled
a <- area(coldspots_geo)
area <- coldspots_geo * a
area_geo <- sum(values(area), na.rm=TRUE)  # 67,999,148
area_moll <- binsurf(coldspots)  # 69,760,000

# extract potential surface area per EEZ
eezArgo <- extract(area, eez_dis, fun=sum, na.rm=TRUE, sp=TRUE) # calculate the sum of Argo profiles per each EEZ
names(eezArgo)[names(eezArgo) == "layer"] <- "coldspot_km2"

# group data by country
df <- data.frame(eezArgo)
country <- df %>%
  group_by (Sovereign1) %>% #ISO_Ter1, Sovereign1
  summarise (coldspot_km2=sum(coldspot_km2), area_km2=sum(Area_km2_new))

# calculate proportions and accumulated sums
country$coldspot_proportion <- country$coldspot_km2/country$area_km2
country$overall_proportion <- (country$coldspot_km2/sum(country$coldspot_km2))*100
country <- arrange(country, desc(overall_proportion))
country$cumprop <- cumsum(country$overall_proportion)

## Export table
write.csv(country, coldspots_eez_csv, row.names=FALSE)


#------------------------------------------------
# 4. Summarize coldspots per ocean regions
#------------------------------------------------

## Prepare data.frame
reg_no <- list(name="northern ocean", xmin = -180, xmax = 180, ymin = 30, ymax = 60)
reg_to <- list(name="tropical ocean", xmin = -180, xmax = 180, ymin = -30, ymax = 30)
reg_so <- list(name="southern ocean", xmin = -180, xmax = 180, ymin = -60, ymax = -30)
reg_ao <- list(name="artic ocean", xmin = -180, xmax = 180, ymin = 60, ymax = 90)
reg_ato <- list(name="antarctic ocean", xmin = -180, xmax = 180, ymin = -90, ymax = -60)
reg_go <- list(name="global ocean", xmin = -180, xmax = 180, ymin = -90, ymax = 90)
reg <- list(reg_no, reg_to, reg_so, reg_ao, reg_ato, reg_go)
ocean_regions <- rbindlist(reg)

## Calculate overal ocean area per ocean regions
## It uses the ocean mask created previously
for (i in 1:nrow(ocean_regions)){
  ocean_regions$ocean_area_km2[i] <- oceanArea(ocean_mask = mask, 
                                           xmin = ocean_regions$xmin[i], xmax = ocean_regions$xmax[i],
                                           ymin = ocean_regions$ymin[i], ymax = ocean_regions$ymax[i],
                                           crs=PROJ)
}


## Calculate coldspots area per ocean regions
for (i in 1:nrow(ocean_regions)){
  ocean_regions$coldspot_area_km2[i] <- oceanArea(ocean_mask = coldspots,
                                               xmin = ocean_regions$xmin[i], xmax = ocean_regions$xmax[i],
                                               ymin = ocean_regions$ymin[i], ymax = ocean_regions$ymax[i],
                                               crs=PROJ)
}


## Calculate coldspots area within EEZ per ocean regions
for (i in 1:nrow(ocean_regions)){
  ocean_regions$coldspot_eez_km2[i] <- oceanAreaEEZ(ocean_mask = coldspots, eez = eez_dis,
                                                  xmin = ocean_regions$xmin[i], xmax = ocean_regions$xmax[i],
                                                  ymin = ocean_regions$ymin[i], ymax = ocean_regions$ymax[i],
                                                  crs=PROJ, crs.geo=GEO)
}

## Calculate percetage of coldspots area within EEZ per ocean regions
ocean_regions$coldspot_eez_percent <- (ocean_regions$coldspot_eez_km2 / ocean_regions$coldspot_area_km2) * 100

## Export table
write.csv(ocean_regions, coldspots_summary_csv, row.names=FALSE)

