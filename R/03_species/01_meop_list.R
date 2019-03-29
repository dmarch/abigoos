#------------------------------------------------------------------------------
# 01_meop_list.R        Generate species list from MEOP
#------------------------------------------------------------------------------
#
# This script provides a match between scientific names and
# the species names used in the MEOP-CTD database.
#
# Inputs:
# - tag information file from MEOP-CTD
#
# Outputs:
# - temporary table in csv with the species name and number of tags.

## Load libraries
library(dplyr)
source("R/data_paths.R")

## Import MEOP-CTD tags
tags <- read.csv(meop_tags, header=TRUE)

#---------------------------------------------
# Add scientific names, manually
#---------------------------------------------
tags$scientific_name <- NA
tags$scientific_name[tags$species == "Weddell seal"] <- "Leptonychotes weddellii"
tags$scientific_name[tags$species == "Weddel seal"] <- "Leptonychotes weddellii"
tags$scientific_name[tags$species == "Southern ellie"] <- "Mirounga leonina"
tags$scientific_name[tags$species == "S ellie"] <- "Mirounga leonina"
tags$scientific_name[tags$species == "Hooded seal"] <- "Cystophora cristata"
tags$scientific_name[tags$species == "Blueback hood"] <- "Cystophora cristata"
tags$scientific_name[tags$species == "Bluebacks"] <- "Cystophora cristata"
tags$scientific_name[tags$species == "Hoods"] <- "Cystophora cristata"
tags$scientific_name[tags$species == "Hoods greenland"] <- "Cystophora cristata"
tags$scientific_name[tags$species == "Bearded seal"] <- "Erignathus barbatus"
tags$scientific_name[tags$species == "Grey seals"] <- "Halichoerus grypus"
tags$scientific_name[tags$species == "Sable Grey"] <- "Halichoerus grypus"
tags$scientific_name[tags$species == "Grey"] <- "Halichoerus grypus"
tags$scientific_name[tags$species == "Hg"] <- "Halichoerus grypus"
tags$scientific_name[tags$species == "Harps"] <- "Pagophilus groenlandicus"
tags$scientific_name[tags$species == "Ringed seal"] <- "Pusa hispida"
tags$scientific_name[tags$species == "Fur seal"] <- "Arctocephalus sp"
tags$scientific_name[tags$species == "Northern ellie"] <- "Mirounga angustirostris"
tags$scientific_name[tags$species == "Leopard seal"] <- "Hydrurga leptonyx"
tags$scientific_name[tags$species == "California sea lion"] <- "Zalophus californianus"
tags$scientific_name[tags$species == "Green turtle"] <- "Chelonia mydas"
tags$scientific_name[tags$species == "Crabeater seal"] <- "Lobodon carcinophaga"
tags$scientific_name[tags$species == "Sea lion"] <- "Neophoca cinerea"
tags$scientific_name[tags$species == "Pv"] <- "Phoca vitulina"
tags$scientific_name[tags$species == "Northern fur seal"] <- "Callorhinus ursinus"
tags$scientific_name[tags$species == "Bowhead"] <- "Balaena mysticetus"

#---------------------------------------------
# Summarize data per species
#---------------------------------------------

## Count number of species per group
spp <- tags %>%
  group_by(scientific_name) %>%
  summarise(n = n())

## Export table
write.csv(spp, meopfile, row.names=FALSE)
