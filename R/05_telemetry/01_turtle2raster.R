#-----------------------------------------------------------------------------
# 01_turtle2raster.R  Process and rasterize sea turtle telemetry records from OBIS-SEAMAP
#------------------------------------------------------------------------------
# Description:
# This script processes gridded summary data from OBIS-SEAMAP
# In particular, it makes the following steps:
# 1. Import original data at 0.1 x 0.1 resolution
# 2. Filter out cells on land
# 3. Rasterize data (records & animals) into desired resolution and projection
# 4. Export maps
#
# Requirements:
# The input for this script is a CSV file downloaded from OBIS-SEAMAP containing
# gridded summary data of telemetry data. To generate such file, follow these steps:
# 1. Select your species or group of species of interest with the Browse tool
# 2. Select Telemetry in Data Type
# 3. In layer selection, select "Summary" and chose your desired resolution
# 3. Use "Download" button and store the CSV in your path.
#
# Inputs:
# - OBIS-SEAMAP csv files for each species and all species
# - Raster ocean masks for processing
#
#
# Outputs:
# - Raster with presence/absence of telemetry observations per species
# - Single band raster with density of telemetry obbservations for all sea turtle species


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

## Create raster in longlat to use as base for rasterization
r <- raster(xmn=-180, xmx=180, ymn=-90, ymx=90, crs=CRS("+proj=longlat +ellps=WGS84"),
            resolution=c(1, 1), vals=NA)


#--------------------------------------------------------
# 1. Rasterize presence of telemetry records per species
#--------------------------------------------------------

## Prepare pre-processing table
## Table with taxonid, scientific names, OBIS variable (num_records)
df <- data.frame(taxa = rep(c("cc", "cm", "dc", "ei", "lk", "lo", "nd"), each=1),
                 scientific_name = rep(c("Caretta caretta", "Chelonia mydas", "Dermochelys coriacea", "Eretmochelys imbricata", "Lepidochelys kempii", "Lepidochelys olivacea", "Natator depressus"), each=1),
                 var = rep(c("num_records"), 7))
match <- dplyr::select(match, taxonid, scientific_name)
df <- merge(df, match, by="scientific_name")

## Rasterize OBIS-SEAMAP data per species
turtle <- stack()  # create stack

for (i in 1:nrow(df)){
  
  taxa <- as.character(df$taxa[i])
  var <- as.character(df$var[i])
  print(paste(taxa, var))
  ispid <- as.character(df$taxonid[i])
  
  ## Import data
  file <- eval(parse(text = taxa))
  data <- read.csv(file)
  
  ## Convert to spatial class
  coordinates(data) <- ~longitude+latitude
  proj4string(data) <- CRS("+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0")
  
  # transform coordinates to mollweide
  data <- spTransform(data, CRSobj = PROJ)
  
  ## rasterize distribution data
  rdata <- rasterize(data, mask, field = var, fun = "sum") # num_animals, num_records
  rdata[rdata==0]<-NA
  
  ## filter out land cells
  rdata <- rdata * mask
  
  ## convert to binary
  rdata <- rdata/rdata
  
  ## save into stack
  names(rdata) <- ispid
  turtle <- stack(turtle, rdata)
}

# save raster with telemetry presence data per species
outfile <- paste0(temp_dir, "/", "obisTurtles.grd")
writeRaster(turtle, filename=outfile, bandorder='BIL', overwrite=TRUE)


#--------------------------------------------------------
# 2. Calculate density of records per km2 for all spp
#--------------------------------------------------------

## Import data
file <- eval(parse(text = "chelo"))
data <- read.csv(file)

## Convert to spatial class
coordinates(data) <- ~longitude+latitude
proj4string(data) <- CRS("+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0")

# transform coordinates to mollweide
data <- spTransform(data, CRSobj = PROJ)

## rasterize distribution data
rdata <- rasterize(data, mask, field = var, fun = "sum") # num_animals, num_records
rdata[rdata==0]<-NA

## filter out land cells
chelo <- rdata * mask

## Calculate density: number of records per km2
chelo <- chelo / ((res(chelo)[1]/1000)*(res(chelo)[2]/1000))  # divide by km2

# save raster with telemetry density observations
outfile <- paste0(temp_dir, "/", "obisTurtlesDens.grd")
writeRaster(chelo, filename=outfile, bandorder='BIL', overwrite=TRUE)