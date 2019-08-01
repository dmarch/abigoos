#----------------------------------------------------------------
# data_paths.R   Define paths to datasets
#----------------------------------------------------------------
# This file provide the paths to raw datasets and generated products
# Note that default are Windows file paths. Adapt them to your OS accordingly.


# Set projections ----------------------------------------------------------

PROJ <- "+proj=moll +ellps=WGS84"  # Project projection, Mollweide
GEO <- "+proj=longlat +ellps=WGS84"

# Set main directories ----------------------------------------------------

## Set absolute paths of the three main data folders
main_path <- "D:/abigoosv2/"
raw_dir <- paste0(main_path, "data/raw")  # raw data folder
temp_dir <- paste0(main_path, "data/temp") # temporary data folder
out_dir <- paste0(main_path, "data/out") # output data folder
fig_dir <- paste0(main_path, "fig") # output data folder for figures
tbl_dir <- paste0(main_path, "tbl") # output data folder for tables
auth_dir <- paste0(main_path, "auth") # api keys

# Set auth credentials ----------------------------------------------------
library(jsonlite)
keyfile = paste(auth_dir, "iucn.json", sep="/")  # IUCN API token
key = fromJSON(keyfile)$key


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

# EEZ
# Exclusive Economic Zones (EEZ) from Marine Regions (http://www.marineregions.org).
eez_dir <-  paste(raw_dir, "World_EEZ_v9_20161021_LR", sep="/")
eez_shp <- "eez_lr"

# Ocean regions correspond to the "The SeaVoX Salt and Fresh Water Body Gazetteer" (v16 2015) that was extracted from marineregions.org
seavox_dir <-  paste(raw_dir, "SeaVoX_sea_areas_polygons_v16", sep="/")
seavox_shp <- "SeaVoX_v16_2015"

# Species lists
husseyfile <- paste(raw_dir, "species_lists", "Satellite List Locations and Species Info.tsv", sep="/")
sequeirafile <- paste(raw_dir, "species_lists", "sequeira.csv", sep="/")
lascellesfile <- paste(raw_dir, "species_lists", "Lascelles_2016_ddi12411-sup-0002-appendixs2.csv", sep="/")
obisfile <- paste(raw_dir, "species_lists", "download_from_obis_seamap_5a8f4b4646cfa_.csv", sep="/")  # downloaded 23/02/2018

# Distribution ranges
iucn_shp <- paste(raw_dir, "distribution_ranges", "iucn", sep="/")
birdlife_shp <- paste(raw_dir, "distribution_ranges", "birdlife", sep="/")
swot_shp <- paste(raw_dir, "distribution_ranges", "swot_rmu_21071", sep="/")


# MEOP
meop_db <- paste(raw_dir, "telemetry/MEOP-CTD_2017-11-11", sep="/")
meop_tags <- paste(raw_dir, "telemetry/MEOP-CTD_2017-11-11/info_tags.csv", sep="/")
meop_names <- paste(raw_dir, "species_lists", "meopNames2scientificNames.csv", sep="/")

# OBIS-SEAMAP
# Those file is the result of the following query:
# Taxon: Chelonioidea or each species
# Data type: Telemetry
# Layer: Summary
# Resolution: 0.1 x 0.1 degrees
# Access date: 16 May 2017 & 16 Nov 2017
chelo <- paste(raw_dir,
               "telemetry/obis_seamap",
               "01deg/obis_seamap_custom_591ad4865c69e_20170516_63302_dist_sp_01deg_csv.csv",
               sep="/")
cc <- paste(raw_dir,
            "telemetry/obis_seamap",
            "cc/obis_seamap_custom_5a0dd16545a0a_20171116_125843_dist_sp_01deg_csv.csv",
            sep="/")
cm <- paste(raw_dir,
            "telemetry/obis_seamap",
            "cm/obis_seamap_custom_5a0dd3740bb7e_20171116_130610_dist_sp_01deg_csv.csv",
            sep="/")
dc <- paste(raw_dir,
            "telemetry/obis_seamap",
            "dc/obis_seamap_custom_5a0dd40beedf1_20171116_130855_dist_sp_01deg_csv.csv",
            sep="/")
ei <- paste(raw_dir,
            "telemetry/obis_seamap",
            "ei/obis_seamap_custom_5a0dd21fe2020_20171116_130206_dist_sp_01deg_csv.csv",
            sep="/")
lk <- paste(raw_dir,
            "telemetry/obis_seamap",
            "lk/obis_seamap_custom_5a0dd2ce7f73b_20171116_130347_dist_sp_01deg_csv.csv",
            sep="/")
lo <- paste(raw_dir,
            "telemetry/obis_seamap",
            "lo/obis_seamap_custom_5a0dd325cbbdc_20171116_130449_dist_sp_01deg_csv.csv",
            sep="/")
nd <- paste(raw_dir,
            "telemetry/obis_seamap",
            "nd/obis_seamap_custom_5a0dd3bcadd90_20171116_130730_dist_sp_01deg_csv.csv",
            sep="/")


# This file is the result of the following query:
# Taxon: Chelonioidea
# Data type: Telemetry
# Access date: 11 November 2017
seamap.turtle <- paste(raw_dir,
            "telemetry/obis_seamap",
            "animals_tagged_20171116/download_from_obis_seamap_5a0d7694efe66_.csv",
            sep="/")




### Do not edit from here ###

# Temporary data ----------------------------------------------------------------

# study area
temp_bathy <- paste(temp_dir,"bathy_1d_moll.nc", sep="/")
temp_mask <- paste(temp_dir,"mask_1d_moll.nc", sep="/")
temp_land <- "land_moll"

# argo
argo_coldspots_shp <- paste(temp_dir, "argo_coldspots", sep="/")
coldspots_latitude_csv <- paste(temp_dir, "coldspots_latitude.csv", sep="/")
coldspots_bathymetry_csv <- paste(temp_dir, "coldspots_bathymetry.csv", sep="/")

# species lists
meopfile <- paste(temp_dir, "meopSpeciesList.csv", sep="/")  # See meop_species.R
spp_list_refs <- paste(temp_dir, "spp_list_refs.csv", sep="/")
spp_list_refs_iucn <- paste(temp_dir, "spp_list_refs_iucn.csv", sep="/")
spp_list_refs_iucn_fishbase <- paste(temp_dir, "spp_list_refs_iucn_fishbase.csv", sep="/")
spp_list_refs_iucn_fishbase_eoo <- paste(temp_dir, "spp_list_refs_iucn_fishbase_eoo.csv", sep="/")
spp_list_group <- paste(temp_dir, "spp_list_group.csv", sep="/")

# rasterized maps
eoo_tempdir <- paste(temp_dir, "eoo", sep="/")
telemetry_tempdir <- paste(temp_dir, "telemetry", sep="/")




# Output data ----------------------------------------------------------------

## Set relative paths of the output folders
study_area_dir <- paste(out_dir, "study_area", sep="/")
argo_dir <- paste(out_dir, "argo", sep="/")
species_dir <- paste(out_dir, "species", sep="/")
eoo_dir <- paste(out_dir, "eoo", sep="/")
telemetry_dir <- paste(out_dir, "telemetry", sep="/")
overlap_dir <- paste(out_dir, "overlap", sep="/")

## Set paths for generated files

# argo
argo_count <- paste(argo_dir, "argo_count.nc", sep="/")
argo_gaps <- paste(argo_dir, "argo_gaps.nc", sep="/")
argo_gap_persistence <- paste(argo_dir, "argo_gap_persistence.nc", sep="/")
argo_coldspots <- paste(argo_dir, "argo_coldspots.nc", sep="/")
coldspots_summary_csv <- paste(argo_dir, "coldspots_summary.csv", sep="/")
coldspots_eez_csv <- paste(argo_dir, "coldspots_eez.csv", sep="/")
