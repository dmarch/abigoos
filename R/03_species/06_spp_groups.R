#---------------------------------------------------------------------
# 06_spp_groups.R       Define taxonomic groups
#---------------------------------------------------------------------


## Load libraries
library(dplyr)
library(data.table)
source("R/data_paths.R")

## Import data
data <- read.csv(spp_list_refs_iucn_fishbase_eoo)


#------------------------------------------------------
# Generate taxonomic groups used in this study
#------------------------------------------------------

## Birds (flyings vs penguins)
data$group[data$class == "AVES"] <- "flying_bird"
data$group[data$family == "SPHENISCIDAE"] <- "penguin"  # penguins

## Marine mammals (pinnipeds as semiaquatic, cetaceans & sirenians as aquatics)
data$group[data$order == "CARNIVORA"] <- "pinniped"  
data$group[data$order == "CETARTIODACTYLA"] <- "cetacean"  
data$group[data$order == "SIRENIA"] <- "sirenian"  

## Reptiles (turtles, crocodiles)
data$group[data$order == "TESTUDINES"] <- "turtle"

## Elasmobranchs (sharks, rays)
data$group[data$class == "CHONDRICHTHYES"] <- "shark_ray"  

# Tunna and billfishes: Species from the family Istiophoridae, Scombridae and Xiphiidae.
data$family <- as.character(data$family)
data$group[data$family %in% c("ISTIOPHORIDAE","SCOMBRIDAE", "XIPHIIDAE")] <- "tuna_billfish"

# Remove non-matching (n=1)
data <- filter(data, !is.na(group))


#------------------------------------------------------
# Generate corresponde table for taxonomic groups
#------------------------------------------------------

# Group codes and names are further used for plotting
FB <- list (group = "flying_bird", group_code = "FB", group_name = "Flying bird")
PE <- list (group = "penguin", group_code = "PE", group_name = "Penguin")
PI <- list (group = "pinniped", group_code = "PI", group_name = "Pinniped")
CE <- list (group = "cetacean", group_code = "CE", group_name = "Cetaceans")
SI <- list (group = "sirenian", group_code = "SI", group_name = "Sirenian")
TU <- list (group = "turtle", group_code = "TU", group_name = "Turtle")
SR <- list (group = "shark_ray", group_code = "SR", group_name = "Shark and ray")
TB <- list (group = "tuna_billfish", group_code = "TB", group_name = "Tuna and billfish")

## Combine lists
group_list <- list(FB, PE, PI, CE, SI, TU, SR, TB)
group <- rbindlist(group_list)

## Match with species list
match <- merge(data, group, by="group", all.x=TRUE)

## Count number of species per group
groups <- match %>%
  group_by(group) %>%
  summarise(n = n())

## Export table as temporary file
write.csv(match, spp_list_group, row.names=FALSE)
