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
fig_dir <- "E:/abigoosv2/fig" # output data folder

# Raw data ----------------------------------------------------------------

# Note: Make sure all raw data is stored using the same folder structure, or modify accordingly

# Bathymetry
# The GEBCO 2014 Grid, version 20150318, www.gebco.net.
gebco_nc <- paste(raw_dir, "bathymetry/GEBCO_2014_2D.nc", sep="/")

# Land mask
# Land polygons using the 1:50 vector map from Natural Earth (www.naturalearthdata.com), 
ne_shp <- paste(raw_dir, "landmask/ne_10m_land.shp", sep="/")

# Profile directory of Argo floats.
# Argo (2000). Argo float data and metadata from Global Data Assembly Centre (Argo GDAC). SEANOE. http://doi.org/10.17882/42182.
# - Last accessed 2017/11/19
# - ftp://ftp.ifremer.fr/ifremer/argo/etc/argo_profile_detailled_index.txt.gz
argoindex <- paste(raw_dir, "argo/argo_profile_detailled_index.txt", sep="/")



# Output data ----------------------------------------------------------------

## Set relative paths of the output folders
study_area_dir <- paste(out_dir, "study_area", sep="/")
argo_dir <- paste(out_dir, "argo", sep="/")
species_dir <- paste(out_dir, "species", sep="/")
distribution_ranges_dir <- paste(out_dir, "distribution_ranges", sep="/")
telemetry_dir <- paste(out_dir, "telemetry", sep="/")
overlap_dir <- paste(out_dir, "overlap", sep="/")
telemetry_dir <- paste(out_dir, "telemetry", sep="/")

## Set paths for generated files

# study area
temp_bathy <- paste(temp_dir,"bathy_1d_moll.nc", sep="/")
temp_mask <- paste(temp_dir,"mask_1d_moll.nc", sep="/")
temp_land <- "land_moll"

# argo
argo_count <- paste(argo_dir, "argo_count.nc", sep="/")
argo_gaps <- paste(argo_dir, "argo_gaps.nc", sep="/")
argo_gap_persistence <- paste(argo_dir, "argo_gap_persistence.nc", sep="/")
argo_coldspots <- paste(argo_dir, "argo_coldspots.nc", sep="/")
argo_coldspots_shp <- paste(temp_dir, "argo_coldspots", sep="/")

