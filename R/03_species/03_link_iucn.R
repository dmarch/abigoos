#------------------------------------------------------------------------------------------
# 03_link_iucn.R       Link species list with IUCN API
#------------------------------------------------------------------------------------------
#
# This script combines the species list with IUCN database to incorporate taxonomic information
# and additional information about each species.


## Load libraries
library("rredlist")  # Use the IUCN API
library(dplyr)
source("R/data_paths.R")


## Import data
data <- read.csv(spp_list_refs)

## Create empty data.frame
taxonomy <- data.frame(taxonid = NA, scientific_name = data$scientific_name, synonim = NA,
                       class = NA, family = NA, order = NA, category = NA,
                       marine_system = NA, eoo_km2 = NA,
                       depth_upper =NA, depth_lower = NA,
                       elevation_upper =NA, elevation_lower = NA)
taxonomy$scientific_name <- as.character(taxonomy$scientific_name)


# For each species[i] search taxonomic information
# If there is no info, search for synomins
# If there is info or synonim, extract taxonomic groups and IUCN category
for (i in 1:nrow(taxonomy)){
  print(i)
  
  # search taxonomic information
  rl <- rl_search(taxonomy$scientific_name[i], key = key)
  
  # if there are no results
  if(is.null(rl$result) | length(rl$result)==0){
    
    # check for synonims
    s <- rl_synonyms(taxonomy$scientific_name[i], key = key)
    
    # if no results, next name
    if(is.null(s$result) | length(s$result)==0) next
    
    # if results, then search taxonomic informqtion
    syn <- s$result$accepted_name[1]
    taxonomy$synonim[i] <- syn
    rl <- rl_search(syn, key = key)
    if(is.null(rl$result) | length(rl$result)==0) next
  }
  
  # extract taxonomic information
  taxonomy$taxonid[i] <- rl$result$taxonid
  taxonomy$class[i] <- rl$result$class
  taxonomy$family[i] <- rl$result$family
  taxonomy$order[i] <- rl$result$order
  taxonomy$category[i] <- rl$result$category
  
  # extract additional information
  taxonomy$marine_system[i] <- rl$result$marine_system
  taxonomy$eoo_km2[i] <- rl$result$eoo_km2
  taxonomy$depth_lower[i] <- rl$result$depth_lower
  taxonomy$depth_upper[i] <- rl$result$depth_upper
  taxonomy$elevation_lower[i] <- rl$result$elevation_lower
  taxonomy$elevation_upper[i] <- rl$result$elevation_upper
}

# Replace subspecies
taxonomy$synonim[taxonomy$synonim == "Pusa hispida ssp. botnica"] <- "Pusa hispida"

# Merge with species list
data <- merge(data, taxonomy, by="scientific_name")

# Remove species not matchin with IUCN (n=3)
data <- filter(data, !is.na(taxonid))

# Remove duplicates with same taxonid (due to generation of synonim names)
data <- filter(data, !duplicated(data$taxonid))

# Remove non-marine species
data <- filter(data, marine_system == TRUE)  # returns 201 spp

## Export table as temporary file
write.csv(data, spp_list_refs_iucn, row.names=FALSE)
