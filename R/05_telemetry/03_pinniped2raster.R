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

## Prepare pre-processing table
match <- dplyr::select(match, taxonid, scientific_name)
df <- filter(match, scientific_name %in% unique(profdf$scientific_name))

## Rasterize MEOP data per species
pinniped <- stack()  # create stack

for (i in 1:nrow(df)){
  
  ispp <- df$scientific_name[i]
  ispid <- as.character(df$taxonid[i])
  print(ispp)
  
  ## Subset data
  data <- filter(profdf, scientific_name == ispp)
  
  ## Convert to spatial class
  coordinates(data) <- ~lon+lat
  proj4string(data) <- CRS("+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0")
  
  # transform coordinates to mollweide
  data <- spTransform(data, CRSobj = PROJ)
  
  ## rasterize distribution data
  rdata <- rasterize(coordinates(data), mask, fun = "count") # count number of profiles
  rdata[rdata==0]<-NA
  
  ## filter out land cells
  rdata <- rdata * mask
  
  ## convert to binary
  rdata <- rdata/rdata
  
  ## save into stack
  names(rdata) <- ispid
  pinniped <- stack(pinniped, rdata)
}

# save raster with telemetry presence data per species
outfile <- paste0(temp_dir, "/", "meopPinniped.grd")
writeRaster(pinniped, filename=outfile, bandorder='BIL', overwrite=TRUE)



#--------------------------------------------------------
# 2. Calculate density of profiles per km2 for all spp
#--------------------------------------------------------


## Use complete dataset
data <- profdf

## Convert to spatial class
coordinates(data) <- ~lon+lat
proj4string(data) <- CRS("+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0")

# transform coordinates to mollweide
data <- spTransform(data, CRSobj = PROJ)

## rasterize distribution data
rdata <- rasterize(coordinates(data), mask, fun = "count") # count number of profiles
rdata[rdata==0]<-NA

## filter out land cells
rdata <- rdata * mask

## Calculate density: number of profiles per km2
rdata  <- rdata  / ((res(rdata )[1]/1000)*(res(rdata )[2]/1000))  # divide by km2

# save raster with telemetry density observations
outfile <- paste0(temp_dir, "/", "meopPinDens.grd")
writeRaster(rdata, filename=outfile, bandorder='BIL', overwrite=TRUE)
