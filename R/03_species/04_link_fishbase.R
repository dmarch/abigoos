#------------------------------------------------------------------------------------------
# 04_link_fishbase.R       Link species list with Fishbase and Sealifebase API
#------------------------------------------------------------------------------------------
#
# This script combines the species list with online databases to incorporate
# additional information about each species.
# It requires runnung first the script for linking IUCN in order to get the taxonomic groups


## Load libraries
library(rfishbase)
library(dplyr)
library(data.table)
source("R/data_paths.R")

## Import data
data <- read.csv(spp_list_refs_iucn)

## Loop for each species
data_list <- list()  # create empty list
for (i in 1:nrow(data)){ #nrow(data)
  
  print(i)
  
  ## Get scientific name and class
  isp <- as.character(data$scientific_name[i])  # species name
  iclass <- as.character(data$class[i])  # class name

  ## Add exceptions for certain species
  ## species() returns error instead of empty data for certain species. Omit them manually.
  if(isp %in% c("Cystophora cristata")) next
  
  ## Set API and species table depending on the class name
  if (iclass %in% c("ACTINOPTERYGII", "CHONDRICHTHYES")){
    api = "https://fishbase.ropensci.org"
    spbase = fishbase
  }  else {
    api = "https://fishbase.ropensci.org/sealifebase"
    spbase = sealifebase
  }
  
  # Extract data from API
  idf <- species(isp, server=api,
                 fields=c("DemersPelag","DepthRangeShallow", "DepthRangeDeep", "DepthRangeComShallow", "DepthRangeComDeep", "Length", "CommonLength", "LTypeComM", "Weight"))
  
  # If no data is retrieved...
  if(length(idf) == 0){
    
    # ...search for synomyns
    syn <- synonyms(isp)
    if(length(syn) == 0) next
    
    # And try again to extract data from API
    spsyn <- species_list(SpecCode = syn$SpecCode) 
    idf <- species(spsyn, fields=c("DemersPelag","DepthRangeShallow", "DepthRangeDeep", "DepthRangeComShallow", "DepthRangeComDeep", "Length", "CommonLength", "LTypeComM", "Weight"))
  }
  
  # Store extracted data into data_list object
  idf$scientific_name <- isp
  data_list[[i]] <- idf
}

## Combine dataasets
fishbase_data <- rbindlist(data_list)  # combine lists
cdata <- full_join(data, fishbase_data, by=c("scientific_name" = "scientific_name")) # join with species list

## Export table as temporary file
write.csv(cdata, spp_list_refs_iucn_fishbase, row.names=FALSE)
