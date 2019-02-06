#----------------------------------------------------------------
# data_paths.R   Define paths to datasets
#----------------------------------------------------------------
# Date: 2018/11/13
# Author: David March
# Project: Tortugas oceanografas
#----------------------------------------------------------------


## Data folder
hd <- "H:/data/"


# External data ----------------

# gebco bathymetry
gebconc <- paste0(hd, "gebco/RN-4015_1510486680263/GEBCO_2014_2D.nc")

# natural earth land mask
neshp <- paste0(hd, "natural_earth/ne_10m_land/ne_10m_land.shp")