#---------------------------------------------------------------------
# 05_link_eoo.R         Link species list with distribution ranges shapefiles
#---------------------------------------------------------------------
#
# We used extent of occurrence maps (EOO) from the International Union for Conservation
# of Nature (IUCN). EOO maps for seabirds (i.e. flying birds and penguins) and turtles
# were available separately from Bird Life International and the State of the
# World’s Sea Turtles mapping application, respectively.


## Load libraries
library(dplyr)
library(foreign)
source("R/data_paths.R")

## Import data
data <- read.csv(spp_list_refs_iucn_fishbase)


#-------------------------------------------
# 1. Link with IUCN shapefiles
#-------------------------------------------

## Set the name of IUCN shapefiles
chond <- "CHONDRICHTHYES"    
mamma <- "MARINE_MAMMALS"    
tunas <- "TUNAS_BILLFISHES"
repti <- "REPTILES" 
iucn_shp <- list(chond, mamma, tunas, repti)

## Read species across all shapefiles from IUCN
iucn <- data.frame()
for (i in 1:length(iucn_shp)){
  
  # Locate shapfile for taxonomic group
  idbfile <- paste0(iucn_shp[[i]], ".dbf")
  idbfile <- list.files(raw_dir, pattern=idbfile, recursive=TRUE, full.names=TRUE)
  ishp <- paste0(iucn_shp[[i]], ".shp")
  
  # Read attribute table and add the name of the shapefile
  idbf <- read.dbf(idbfile)
  idbf$shp <- ishp
  idbf$shp_type <- "iucn"
  iucn <- rbind(iucn, idbf)
}

## Prepare unique list of spp and shapefiles
iucnSel <- dplyr::select(iucn, id_no, shp, shp_type)
iucnSel <- iucnSel[-which(duplicated(iucnSel$id_no)),]

## match with iucn dat
match <- merge(data, iucnSel, by.x="taxonid", by.y="id_no", all.x=TRUE)


#-------------------------------------------
# 2. Link with RMU - Turtles
#-------------------------------------------

### Re-assign shapefiles manually (RMU for turtles)
match$shp[match$scientific_name == "Caretta caretta"] <- "CC_RMU_20101013.shp"
match$shp[match$scientific_name == "Chelonia mydas"] <- "CM_RMU_20101013.shp"
match$shp[match$scientific_name == "Dermochelys coriacea"] <- "DC_RMU_20110429.shp"
match$shp[match$scientific_name == "Eretmochelys imbricata"] <- "EI_RMU_20101013.shp"
match$shp[match$scientific_name == "Lepidochelys kempii"] <- "LK_RMU_20101013.shp"
match$shp[match$scientific_name == "Lepidochelys olivacea"] <- "LO_RMU_20101013.shp"
match$shp[match$scientific_name == "Natator depressus"] <- "ND_RMU_20101013.shp"

### Change shapefile source
match$shp_type[match$scientific_name == "Caretta caretta"] <- "rmu"
match$shp_type[match$scientific_name == "Chelonia mydas"] <- "rmu"
match$shp_type[match$scientific_name == "Dermochelys coriacea"] <- "rmu"
match$shp_type[match$scientific_name == "Eretmochelys imbricata"] <- "rmu"
match$shp_type[match$scientific_name == "Lepidochelys kempii"] <- "rmu"
match$shp_type[match$scientific_name == "Lepidochelys olivacea"] <- "rmu"
match$shp_type[match$scientific_name == "Natator depressus"] <- "rmu"



#-------------------------------------------
# 3. Link with Birdlife - Seabirds
#-------------------------------------------

# A previous step is to create the shapefile of EOO from the Geodatabase
# We first create a QUERY string to filter the species from our list.
# Following lines provide the string to use in ArcMap to subset the geodatabase.
# Database is found on "D:/data/EOO/birdlife/BOTW/BOTW.gdb"
# Code to prepare query for the geodatabase of Birdlife (not run):
#
# bird <- filter(data, sp_class == "bird")
# query <- paste0("SCINAME = '", bird$scientific_name, "' OR")
# cat(query, file="bird_query.txt")
#
# In ArcMap: Open geodatabase table 'All Species' > Go to properties
# > Go to Definition Query tab > Paste text from the txt (without last 'OR') 
# Export data as shapefile (BOTW_telemetry.shp)

## Add birds
birds <- "BOTW_telemetry"
idbfile <- paste0(birds, ".dbf")
idbfile <- list.files(raw_dir, pattern=idbfile, recursive=TRUE, full.names=TRUE)
ishp <- paste0(birds, ".shp")
birdlife<- read.dbf(idbfile)

# select which bird species from match are in birdlife
# for those, add the shapefile name and shapefile type
#birdsel <- which(match$scientific_name %in% birdlife$SCINAME)
birdsel <- which(match$taxonid %in% birdlife$SISID)
match$shp[birdsel] <- ishp
match$shp_type[birdsel] <- "birdlife"


#-------------------------------------------
# 4. Prepare species list
#-------------------------------------------

## Filter out species without distribution range maps
match <- filter(match, !is.na(shp))

## Export table as temporary file
write.csv(match, spp_list_refs_iucn_fishbase_eoo, row.names=FALSE)
