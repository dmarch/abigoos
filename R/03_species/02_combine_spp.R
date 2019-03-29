#--------------------------------------------------------------------------------
# 02_combine_spp.R       Generate a list of satellite tracked marine vertebrates
#--------------------------------------------------------------------------------
#
# Generate a list of satellite tracked marine vertebrates
# The main sources to create the list are:
# Hussey et al. 2015
# Sequeira et al. 2017
# Lascelles et al. 2017
# OBIS-SEAMAP
# MEOP-CTD

## Load libraries
library(dplyr)
library(readr)
source("R/data_paths.R")

## Import species lists
hussey <- read_tsv(husseyfile)  # Data from Hussey et al. 823 locations
sequeira <- read.csv(sequeirafile, sep=";", dec=",")  # Data extracted from Sequeira et al. 2018. 49 spp.
lascelles <- read.csv(lascellesfile) # Data from Lascelles et al 2017. 61 spp. We have incorporated scientific names manually.
obis <- read.csv(obisfile)  # Data from OBIS-SEAMAP. 41 species
meop <- read.csv(meopfile)

## Harmonize variable and values names
## Create column to summarize the number of datasets for each species
names(hussey)[names(hussey)=="Species Name"] <- "scientific_name"
names(obis)[names(obis)=="num_datasets"] <- "datasets_obis"
names(meop)[names(meop)=="n"] <- "datasets_meop"
names(sequeira)[names(sequeira)=="num_datasets"] <- "datasets_sequeira"
names(lascelles)[names(lascelles)=="No..sites.resulting"] <- "datasets_lascelles"
lascelles <- lascelles[-nrow(lascelles),]  # remove last row with totals

## Standardize data type classes (factor 2 character)
sequeira$scientific_name <- as.character(sequeira$scientific_name)
obis$scientific_name <- as.character(obis$scientific_name)
lascelles$scientific_name <- as.character(lascelles$scientific_name)
meop$scientific_name <- as.character(meop$scientific_name)


## Get list of unique species and select common variables

# Hussey list
hussey <- hussey %>%
  group_by(scientific_name) %>%
  summarise(datasets_hussey = n())

# MEOP list
meop <- dplyr::select(meop, scientific_name, datasets_meop)
meop <- dplyr::filter(meop, !is.na(scientific_name))

# Others
obis <- dplyr::select(obis, scientific_name, datasets_obis)  # OBIS list
lascelles <- dplyr::select(lascelles, scientific_name, datasets_lascelles)  # Lascelles
sequeira <- dplyr::select(sequeira, scientific_name, datasets_sequeira)  # Sequeira


## Combine lists
join1 <- full_join(hussey, obis, by=c("scientific_name" = "scientific_name"))  # Add OBIS
join2 <- full_join(join1, lascelles, by=c("scientific_name" = "scientific_name")) # Add Lascelles
join3 <- full_join(join2, sequeira, by=c("scientific_name" = "scientific_name")) # Add Sequeira
data <- full_join(join3, meop, by=c("scientific_name" = "scientific_name"))  # Add MEOP


##### Check species names and filter out subspecies

# Lower to upper case
data$scientific_name[data$scientific_name == "delphinus delphis"] <- "Delphinus delphis"
data$scientific_name[data$scientific_name == "lagenorhynchus acutus"] <- "Lagenorhynchus acutus"

# Correct names
data$scientific_name[data$scientific_name == "Acipenser oxyrinchus oxyrinchus"] <- "Acipenser oxyrinchus"
data$scientific_name[data$scientific_name == "Masturusálanceolatus"] <- "Masturus lanceolatus"
data$scientific_name[data$scientific_name == "Salmo salar L."] <- "Salmo salar"

# Correct synonims not found in IUCN
data$scientific_name[data$scientific_name == "Phoca sibirica"] <- "Pusa sibirica"
data$scientific_name[data$scientific_name == "Manta alredii"] <- "Manta alfredi"

# Remove wrong names
data <- filter(data, scientific_name != "Natator depressa")  # Keep Natator depressus instead
data <- filter(data, scientific_name != "Ardenna griseus")  

# remove genus names
data <- filter(data, !scientific_name %in% "Arctocephalus sp")

# Remove subspecies
subspp <- c("Odobenus rosmarus divergens", "Odobenus rosmarus rosmarus",
            "Phoca vitulina richardii", "Trichechus manatus manatus",
            "Thunnus thynnus orientalis", "Arctocephalus pusillus doriferus")
data <- filter(data, !scientific_name %in% subspp)  # Keep Natator depressus instead
# returns 208 spp

## Export table as temporary file
write.csv(data, spp_list_refs, row.names=FALSE)
