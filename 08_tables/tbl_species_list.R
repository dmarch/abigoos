#---------------------------------------------------------------------------------------
# tbl_species_list.R        Generate species list table
#---------------------------------------------------------------------------------------

## Load dependencies
library(dplyr)
source("R/data_paths.R")


## Import data
spplist <- read.csv(spp_list_group)  # Import species list
eoo_overlap <- read.csv(paste(overlap_dir, "eoo_overlap.csv", sep="/"))  # overlap metrics for eoo


## Create a reference column with source references

# Reference 1
ref1 <- which(!is.na(spplist$datasets_hussey))
spplist$reference[ref1] <- "Hussey et al. 2015"

# Reference 2
ref2 <- which(!is.na(spplist$datasets_sequeira))
ref.na <- which(is.na(spplist$reference))
spplist$reference[ref2[ref2 %in% ref.na]] <- "Sequeira et al. 2017"
spplist$reference[ref2[!ref2 %in% ref.na]] <- paste(spplist$reference[ref2[!ref2 %in% ref.na]],"Sequeira et al. 2017", sep=", ")

# Reference 3
ref3 <- which(!is.na(spplist$datasets_lascelles))
ref.na <- which(is.na(spplist$reference))
spplist$reference[ref3[ref3 %in% ref.na]] <- "Lascelles et al. 2017"
spplist$reference[ref3[!ref3 %in% ref.na]] <- paste(spplist$reference[ref3[!ref3 %in% ref.na]],"Lascelles et al. 2017", sep=", ")

# Reference 4
ref4 <- which(!is.na(spplist$datasets_obis))
ref.na <- which(is.na(spplist$reference))
spplist$reference[ref4[ref4 %in% ref.na]] <- "OBIS-SEAMAP"
spplist$reference[ref4[!ref4 %in% ref.na]] <- paste(spplist$reference[ref4[!ref4 %in% ref.na]],"OBIS-SEAMAP", sep=", ")

# Reference 5
ref5 <- which(!is.na(spplist$datasets_meop))
ref.na <- which(is.na(spplist$reference))
spplist$reference[ref5[ref5 %in% ref.na]] <- "MEOP"
spplist$reference[ref5[!ref5 %in% ref.na]] <- paste(spplist$reference[ref5[!ref5 %in% ref.na]],"MEOP", sep=", ")


## Incorporate estimated extent (in km2) from EOO maps at global level
eoo <- eoo_overlap %>%
          filter(region == "GO") %>%
          dplyr::select(taxonid, range_km2) 
spplist <- merge(spplist, eoo, by="taxonid")


## Select columns to export
spplist <- spplist %>%
  dplyr::select(
    group_name,
    scientific_name,
    taxonid,
    category,
    depth_lower,
    Length,
    range_km2,
    shp_type,
    reference
  )


## Change name of EOO sources
spplist$shp_type <- as.character(spplist$shp_type)
spplist$shp_type[spplist$shp_type == "iucn"] <- "IUCN"
spplist$shp_type[spplist$shp_type == "rmu"] <- "SWOT"
spplist$shp_type[spplist$shp_type == "birdlife"] <- "Birdlife"


## Change units
spplist$Length <- round(spplist$Length/100,2)  # cm to m 


## Rename variables
names(spplist)[names(spplist)=="depth_lower"] <- "depth_lower_m"
names(spplist)[names(spplist)=="Length"] <- "length_m"
names(spplist)[names(spplist)=="shp_type"] <- "eoo_source"


## Set order by taxonomic group
spplist <- arrange(spplist, group_name, scientific_name)

## Metadata
# group_name = "taxonomic group used in this study",
# scientific_name = "scientific name of species",
# taxonid = "taxonomic ID from IUCN API",
# category = "IUCN category",
# depth_lower_m = "lower depth, in meters. Automatically extracted extracted from IUCN API",
# length_m= "body length, in meters. Automatically extracted from FishBase (http://fishbase.org/search.php) and SeaLifeBase (https://www.sealifebase.ca/).",
# extent_km2 ="species range, in km2",
# eoo_source = "source of EOO maps used in this study",
# reference = "reference used to list species"


## Export table (CSV format)
outfile <- paste(tbl_dir, "tbl_species_list.csv", sep="/")
write.csv(spplist, outfile, row.names=FALSE)