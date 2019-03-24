#----------------------------------------------------------------
# data_paths.R   Define paths to datasets
#----------------------------------------------------------------
# This file provide the paths to raw datasets and generated products
# Note that default are Windows file paths. Adapt them to your OS accordingly.


## Set absolute paths of the three main data folders
raw_dir <- "E:/abigoosv2/data/raw"  # raw data folder
temp_dir <- "E:/abigoosv2/data/temp"  # temporary data folder
out_dir <- "E:/abigoosv2/data/out" # output data folder

## Set relative paths of the raw datasets



## Data folder
hd <- "H:/data/"

# Raw data ----------------------------------------------------------------

## Project data


## External data


# * Bathymetry
# * Argo profiles from GDAC
# * MEOP-CTD database
# * OBIS-SEAMAP
# * IUCN spatial data
# * Birdlife
# * SWOT
# * SeaVox Salt and Fresh Water Body Gazetter (v16 2015)
# * Land mask, Natural Earth



# External data ----------------

# gebco bathymetry
gebconc <- paste0(hd, "gebco/RN-4015_1510486680263/GEBCO_2014_2D.nc")

# natural earth land mask
neshp <- paste0(hd, "natural_earth/ne_10m_land/ne_10m_land.shp")