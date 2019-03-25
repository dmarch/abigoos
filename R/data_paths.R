#----------------------------------------------------------------
# data_paths.R   Define paths to datasets
#----------------------------------------------------------------
# This file provide the paths to raw datasets and generated products
# Note that default are Windows file paths. Adapt them to your OS accordingly.


# Set projections ----------------------------------------------------------

PROJ <- "+proj=moll +ellps=WGS84"  # Project projection, Mollweide


# Set main directories ----------------------------------------------------

## Set absolute paths of the three main data folders
raw_dir <- "E:/abigoosv2/data/raw"  # raw data folder
temp_dir <- "E:/abigoosv2/data/temp"  # temporary data folder
out_dir <- "E:/abigoosv2/data/out" # output data folder


# Raw data ----------------------------------------------------------------

# Note: Make sure all raw data is stored using the same folder structure, or modify accordingly

# Bathymetry
# The GEBCO 2014 Grid, version 20150318, www.gebco.net.
gebco_nc <- paste(raw_dir, "bathymetry/GEBCO_2014_2D.nc", sep="/")

# Land mask
# Land polygons using the 1:50 vector map from Natural Earth (www.naturalearthdata.com), 
ne_shp <- paste(raw_dir, "landmask/ne_10m_land.shp", sep="/")




# Output data ----------------------------------------------------------------

## Set relative paths of the output folders
study_area_dir <- paste(out_dir, "study_area", sep="/")
argo_dir <- paste(out_dir, "argo", sep="/")
species_dir <- paste(out_dir, "species", sep="/")
distribution_ranges_dir <- paste(out_dir, "distribution_ranges", sep="/")
telemetry_dir <- paste(out_dir, "telemetry", sep="/")
overlap_dir <- paste(out_dir, "overlap", sep="/")
telemetry_dir <- paste(out_dir, "telemetry", sep="/")





