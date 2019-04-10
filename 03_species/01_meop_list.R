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
names <- read.csv(meop_names, header=TRUE)

#---------------------------------------------
# Add scientific names
#---------------------------------------------

names(names) <- c("species", "scientific_name")
tags <- merge(tags, names, by="species")


#---------------------------------------------
# Summarize data per species
#---------------------------------------------

## Count number of species per group
spp <- tags %>%
  group_by(scientific_name) %>%
  summarise(n = n())

## Export table
write.csv(spp, meopfile, row.names=FALSE)
