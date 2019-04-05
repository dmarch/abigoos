#-----------------------------------------------------------------------------
# 02_pinniped_profiles.R      Select and process CTD profiles for pinniped species
#------------------------------------------------------------------------------
# This script extracts the location of CTD profiles from pinniped species.
# The output is a table with the profile information.


## Load libraries
library(raster)
library(maptools)
library(dplyr)
library(lubridate)
library(stringr)
library(ncdf4)
library(data.table)
source("R/data_paths.R")

## Import species list
match <- read.csv(spp_list_group)
match$scientific_name <- as.character(match$scientific_name)

## Import MEOP-CTD tags
names <- read.csv(meop_names, header=TRUE)
names(names) <- c("species", "scientific_name")

## List of nc files
pat <- "prof.nc"
ncfiles <- list.files(meop_db, full.names = TRUE, pattern=pat, recursive=TRUE)
ncfiles <- ncfiles[grepl("^((?!.*interp.*).)*(_prof.nc)", ncfiles, perl=TRUE)] # discard interpolated files
length(ncfiles)  # 1144 file

## Prepare loop for profile data.frame
## For each platform, retrieve the location of each profile
prof_list <- list()
for (i in 1:length(ncfiles)){
  
  print(paste("profile", i, "from", length(ncfiles)))
  
  ## import nc
  ncfile <- ncfiles[i]
  nc <- nc_open(ncfile)
  
  ## get data
  lon <- ncvar_get(nc, varid="LONGITUDE")  #dim[N_PROF]
  lat <- ncvar_get(nc, varid="LATITUDE")  #dim[N_PROF]
  ptt <- ncatt_get(nc, 0, "ptt")$value
  species <- ncatt_get(nc, 0, "species")$value
  tag <- ncatt_get(nc, 0, "smru_platform_code")$value
  
  ## get date
  juld <- ncvar_get(nc, varid="JULD")  #dim[N_PROF]
  refdate <- ncvar_get(nc, varid="REFERENCE_DATE_TIME")  #dim[N_PROF]
  refdate <- as.POSIXct(refdate, format="%Y%m%d%H%M%S", tz="UTC")
  date <- as.POSIXlt(juld*86400, origin=refdate, tz="UTC")
  
  ## create data.frame and bind to profdf
  df <- data.frame(ptt, species, tag, date, lon,lat)
  #profdf <- rbind(profdf, df)
  prof_list[[i]] <- df
  
  ## close nc
  nc_close(nc)
}

## combine lists into data.frame
profdf <- rbindlist(prof_list)

## Add scientific names
profdf <- merge(profdf, names, by="species")

## Select pinniped species with datasets in MEOP-CTD database
pin <- filter(match, group=="pinniped", !is.na(datasets_meop))
profdf <- filter(profdf, scientific_name %in% pin$scientific_name)

## Summarize profile data
length(unique(profdf$ptt))  # 844 PTTs
nrow(profdf)  # 424,541 profiles
min(profdf$date)  # "2004-01-27 UTC"
max(profdf$date)  # "2017-08-21 UTC"

## Three species were not available in the public database of MEOP-CTD.
## Neophoca cinerea, Callorhinus ursinus, Phoca vitulina
## Therefore, the analysis with satellite tracks is conducted with 10 species
na_pin <- filter(pin, !scientific_name %in% profdf$scientific_name)

## Export table
outfile <- paste0(temp_dir, "/meop_profiles.csv")
write.csv(profdf, outfile, row.names=FALSE)