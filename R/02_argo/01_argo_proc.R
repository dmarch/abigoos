#-----------------------------------------------------------------------------
# argo_proc.R  Process and rasterize Argo profile index
#------------------------------------------------------------------------------
#
# Description:
# This script processes the Argo profile directory and generates yearly maps
# of the Argo distribution.
# First, data is filtered by longitude and latitude ranges. We also exclude profiles
# without data.
# Second, profiles are rasterized on a yearly basis using a global grid of 100 x 100 km.
# We use an equal area projection (Mollweide) for further analysis.
# Third, plots are genearted to visualize the distributions.
# Finally, the coefficient of variation is calculated to assess dispersion between years
#
# Inputs:
# - Profile directory file of the Argo Global Data Assembly Center
# - Raster ocean masks for processing
# - Vectorial land mask for plots
#
# Outputs:
# - argo.nc: argo count of profiles per year
#------------------------------------------------------------------------------


#--------------------------------------------
# 1. Load libraries and set paths
#--------------------------------------------

## Load libraries
library(raster)
library(lubridate)
library(dplyr)
library(ncdf4)
library(rgdal)
library(ggplot2)
source("R/utils.R")
source("R/data_paths.R")


## Set years to process
years <- 2005:2016


#--------------------------------------------
# 2. Import data
#--------------------------------------------

## Import Argo profile directory file
data <- read.table(argoindex, skip=8, sep=",", dec=".", header=TRUE)
data$time <- parse_date_time(data$date, "YmdHMS", tz = "UTC")  # Date_time convention is : YYYYMMDDHHMISS (see Argo Manual)

## Import ocean mask
mask <- raster(temp_mask)


#--------------------------------------------
# 3. Inspect database (only exploratory, can be skipped)
#--------------------------------------------

## Profiles
nrow(data)  # 1856912 profiles
min(data$time, na.rm=TRUE)  # "1997-07-28 20:26:20 UTC"
max(data$time, na.rm=TRUE)  # "2017-11-19 12:01:00 UTC"

## Extract instrument information and count number of instruments
data$instr <- gsub(".*[/]([^.]+)[/]([^.]+)[/].*", "\\1", data$file)
data$source <- gsub("[/].*", "\\1", data$file)
length(unique(data$instr)) # 13385
length(unique(paste0(data$source,data$instr)))  # 13385


#---------------------------------------------
# 4. Filter data
#---------------------------------------------

## Filter data by year
data$year <- year(data$time)  # create variable year
data <- filter(data, year %in% years)

## Filter data by longitude and latitude
data  <- filter(data, !is.na(date),       # filter out profiles without time
                longitude >= (-180) & longitude <= 180,  # filter out profiles with wrong longitudes
                latitude >= (-90) & latitude <= 90)  # filter out profiles with wrong latitudes


#---------------------------------------------
# 5. Create raster count maps on a yearly basis
#---------------------------------------------

# Prepare empty stack
argo <- stack()  # create stack

# Loop to create a raster for each year
for (i in 1:length(years)){
  
  print(paste("Processing year", i, "from", length(years)))
  
  # filter data per year
  subdata <- dplyr::filter(data, year == years[i])
  
  # transform coordinates to mollweide
  coordinates(subdata) <- ~ longitude + latitude
  proj4string(subdata) <- CRS("+proj=longlat +ellps=WGS84")
  subdata <- spTransform(subdata, CRSobj = PROJ)
  
  ## rasterize profiles
  xy <- coordinates(subdata)
  irargo <- rasterize(xy, mask, fun="count")
  argo <- stack(argo, irargo)
}

# set names and time for each raster
names(argo) <- as.character(years)
argo <- setZ (argo, years)

# check that total number of profiles is the same as original
nrow(data) == sum(values(argo), na.rm=TRUE)

# output file
writeRaster(argo, filename=argo_count, format="CDF", overwrite=TRUE)