#---------------------------------------------------------------------------------------
# tables.R        Generate output tables
#---------------------------------------------------------------------------------------

# Add shapefile source for EOO. eoo_source


## Load dependencies
library(dplyr)
source("R/data_paths.R")


## Import data
spplist <- read.csv(spp_list_group)  # Import species list
eoo_overlap <- read.csv(paste(overlap_dir, "eoo_overlap.csv", sep="/"))  # overlap metrics for eoo
tel_overlap <- read.csv(paste(overlap_dir, "telemetry_overlap.csv", sep="/"))  # overlap metrics for eoo


## Set data types
# spplist$group <- as.character(spplist$group)
# spplist$shp_type <- as.character(spplist$shp_type)

#-----------------------------------------------------
# 1. Create a reference column with source references
#-----------------------------------------------------

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
#-----------------------------------------------------


#-----------------------------------------------------
# Create sourceTelemetry for turtles and pinnipeds
#-----------------------------------------------------






## Select columns to export
spplist <- spplist %>%
  dplyr::select(
    group,
    scientific_name,
    taxonid,
    category,
    depth_lower,
    Length,
    extent_km2,
    shp_type,
    sourceTelemetry,
    reference
  )

## Change units
spplist$Length <- round(spplist$Length/100,2)  # cm to m 
spplist$overlap_argo <- round(spplist$overlap_argo*100, 3)  # round to 3 decimals
spplist$overlap_sp <- round(spplist$overlap_sp*100, 3)  # round to 3 decimals


# ## Change value types (from number of datasets to presence (1) absence (NA))
# spplist$datasets_hussey <- ifelse(is.na(spplist$datasets_hussey), NA, 1)
# spplist$datasets_lascelles <- ifelse(is.na(spplist$datasets_lascelles), NA, 1)
# spplist$datasets_sequeira <- ifelse(is.na(spplist$datasets_sequeira), NA, 1)
# spplist$datasets_meop <- ifelse(is.na(spplist$datasets_meop), NA, 1)
# spplist$datasets_obis <- ifelse(is.na(spplist$datasets_obis), NA, 1)


## Change value names
spplist$group[spplist$group == "Swimming bird"] <- "Penguin"
spplist$shp_type[spplist$shp_type == "iucn"] <- "IUCN"
spplist$shp_type[spplist$shp_type == "rmu"] <- "SWOT"
spplist$shp_type[spplist$shp_type == "birdlife"] <- "Birdlife"


## Rename variables
names(spplist)[names(spplist)=="taxonid"] <- "taxonID"
names(spplist)[names(spplist)=="scientific_name"] <- "scientificName"
names(spplist)[names(spplist)=="group"] <- "taxonomicGroup"
names(spplist)[names(spplist)=="category"] <- "categoryIUCN"
names(spplist)[names(spplist)=="depth_lower"] <- "depthLower_m"
names(spplist)[names(spplist)=="Length"] <- "length_m"
names(spplist)[names(spplist)=="datasets_hussey"] <- "refHussey2015"
names(spplist)[names(spplist)=="datasets_lascelles"] <- "refLascelles2016"
names(spplist)[names(spplist)=="datasets_sequeira"] <- "refSequeira2018"
names(spplist)[names(spplist)=="datasets_obis"] <- "refSEAMAP2018"
names(spplist)[names(spplist)=="datasets_meop"] <- "refMEOP2018"
names(spplist)[names(spplist)=="shp_type"] <- "sourceEOO"
names(spplist)[names(spplist)=="overlap_argo"] <- "overlapColdspot"
names(spplist)[names(spplist)=="overlap_sp"] <- "overlapRange"


## Set order by taxonomic group
spplist <- arrange(spplist, taxonomicGroup, scientificName)

## Metadata
# taxonomicGroup: taxonomic group used in this study
# scientificName: scientific name of species
# taxonID: taxonomic ID from IUCN API
# class: taxonomic rank
# family: taxonomic rank
# order: taxonomic rank
# categoryIUCN: IUCN category
# depthLower_m: lower depth, in meters. Automatically extracted extracted from IUCN API
# length_m: body length, in meters. Automatically extracted from FishBase (http://fishbase.org/search.php) and SeaLifeBase (https://www.sealifebase.ca/).
# sourceEOO: source of EOO maps used in this study
# reference: reference used to list species

metadata <- list(
  taxonomicGroup = "taxonomic group used in this study",
  scientificName = "scientific name of species",
  taxonID = "taxonomic ID from IUCN API",
  #class = "taxonomic rank",
  #family= "taxonomic rank",
  #order= "taxonomic rank",
  categoryIUCN= "IUCN category",
  depthLower_m= "lower depth, in meters. Automatically extracted extracted from IUCN API",
  length_m= "body length, in meters. Automatically extracted from FishBase (http://fishbase.org/search.php) and SeaLifeBase (https://www.sealifebase.ca/).",
  extent_km2 ="species range, in km2",
  overlapRange ="ratio of spatial overlap between species range and Argo coldspots to total species range, in percentage",
  overlapColdspot ="ratio of spatial overlap between species range and Argo coldspots to total coldspots surface, in percentage",
  sourceEOO = "source of EOO maps used in this study",
  sourceTelemetry = "source of telemetry data",
  reference = "reference used to list species"
)

## Additional fields
# telemetrySource
#"extent_km2";"overlap_argo";"jaccard"

## EXport table (CSV format)
outfile <- paste0(output, "/speciesList/SupplementaryData_SpeciesList.csv")
write.csv(spplist, outfile, row.names=FALSE)

## EXport table (Excel format)
library("xlsx")
outfile <- paste0(output, "/speciesList/SupplementaryData_SpeciesList.xlsx")
# Write the first data set in a new workbook
write.xlsx(spplist, file = outfile, sheetName = "Species List",
           col.names = TRUE, row.names = FALSE, showNA = TRUE, append = FALSE)
# Add a second data set in a new worksheet
meta <- as.data.frame(t(rbind.data.frame(metadata)))
write.xlsx(meta, file = outfile, sheetName="Metadata", 
           col.names = FALSE, row.names = TRUE, append=TRUE)

