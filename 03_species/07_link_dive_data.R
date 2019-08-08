#-------------------------------------------------------------------------------------------------
# 07_link_dive_data.R            Link species list with Dive Databases
#-------------------------------------------------------------------------------------------------
# We combine differnet dive depth databases in order to assess the potential distribution of vertical
# profiles collected by animal-borne instruments.
# We use the IUCN API to get a taxonid for scientific names and perform a better match, even with synonims.
# 
# We combine data from multiple sources:
# IUCN (see 03_link_iucn.R)
# Fishbase and Sealifebase API (see 04_link_fishbase.R)
# Ropert-Coudert Y, Kato A, Robbins A, Humphries GRW (2018) The Penguiness book.
# Halsey et al. 2006. A Phylogenetic Analysis of the Allometry of Diving. The American Naturalist 2006 167:2, 276-287 
# Hoscheid et al. 2014. Why we mind sea turtles' underwater business: A review on the study of diving behavior.
# Ponganis et al. 2015. Diving Physiology of Marine Mammals and Seabirds. Cambridge
# Any reference for sharks a fishes?
# Burger 2001. Diving depths of shearwaters
# Taylor 2008. Maximum dive depths of eight New Zeland Procellariiformes, including Pterodroma species



library(dplyr)
source("R/utils.R")
source("R/data_paths.R")

#--------------------------------------------------------------------
# 1. Import species data
#--------------------------------------------------------------------

# Species list
df <- read.csv(spp_list_group)

# select fields for dive
df <- df %>% select(group, group_code, taxonid, scientific_name, depth_upper, depth_lower,
          DepthRangeDeep, DepthRangeComShallow, DepthRangeComDeep)
#--------------------------------------------------------------------


#--------------------------------------------------------------------
# 2. Integrate Penguiness book
#--------------------------------------------------------------------
# Ropert-Coudert Y, Kato A, Robbins A, Humphries GRW (2018) The Penguiness book.
# World Wide Web electronic publication (http://www.penguiness.net), version 3.0, October 2018.
# DOI:10.13140/RG.2.2.32289.66406

# Import database
penguiness_file <- paste(raw_dir, "species_lists/all_dive_data.csv", sep="/")
pen <- read.csv(penguiness_file)

# convert factor to numeric
pen$depth <-as.numeric(as.character(pen$depth))
pen$max.depth <-as.numeric(as.character(pen$max.depth))
pen$latin.name <- as.character(pen$latin.name)

# set depth 0 to NA
pen$depth[pen$depth == 0] <- NA
pen$max.depth[pen$max.depth == 0] <- NA

# get max depth and max.depth from the records
pen <- pen %>%
  dplyr::filter(!is.na(depth) | !is.na(max.depth)) %>%
  dplyr::group_by(latin.name) %>%
  dplyr::summarize(pen_depth_m = max(depth, na.rm=TRUE),
            pen_maxdepth_m = max(max.depth, na.rm = TRUE))

# Set Inf values to NA
pen$pen_depth_m[is.infinite(pen$pen_depth_m)] <- NA
pen$pen_maxdepth_m[is.infinite(pen$pen_maxdepth_m)] <- NA

# if max.depth is smaller than depth, then reassign
pen$dif <- pen$pen_maxdepth_m - pen$pen_depth_m
pen$pen_maxdepth_m[which((pen$dif < 0)=="TRUE")] <- pen$pen_depth_m[which((pen$dif < 0)=="TRUE")]

# get taxon id
pen$taxonid <- getTaxonId(as.character(pen$latin.name), key)
pen <- select(pen, -dif, -latin.name)

# join with species list
df <- merge(df, pen, by="taxonid", all.x=TRUE)



#--------------------------------------------------------------------
# 2. Integrate Halsey et al. 2006
#--------------------------------------------------------------------
# A Phylogenetic Analysis of the Allometry of Diving.
# Lewis G. Halsey, Patrick J. Butler, and Tim M. Blackburn
# The American Naturalist 2006 167:2, 276-287 
# Note:
# - Raw file has been manipulated to remove subheaders and blank lines
# - Subspecies removed and aggregated at species level (max depth selected)

# Import database
halsey_file <- paste(raw_dir, "species_lists/halsey_2006.csv", sep="/")
hal <- read.csv(halsey_file)

# filter out register where dive depth OR max dive depth are missing
hal <- filter(hal, !is.na(dive_depth_m) | !is.na(max_dive_depth_m))

# check that max dive depth is lager than dive depth. If not, reassing
hal$dif <- hal$max_dive_depth_m - hal$dive_depth_m
hal$max_dive_depth_m[which((hal$dif < 0)=="TRUE")] <- hal$dive_depth_m[which((hal$dif < 0)=="TRUE")]

# get max depth and max.depth from the records
hal <- hal %>%
  dplyr::group_by(latin_name) %>%
  dplyr::summarize(hal_depth_m = max(dive_depth_m, na.rm=TRUE),
            hal_maxdepth_m = max(max_dive_depth_m, na.rm = TRUE))

# Set Inf values to NA
hal$hal_depth_m[is.infinite(hal$hal_depth_m)] <- NA
hal$hal_maxdepth_m[is.infinite(hal$hal_maxdepth_m)] <- NA

# get taxon id
hal$taxonid <- getTaxonId(as.character(hal$latin_name), key)
hal <- select(hal, -latin_name)

# join with species list
df <- merge(df, hal, by="taxonid", all.x=TRUE)


#--------------------------------------------------------------------
# 3. Integrate Hoscheid et al. 2014. 
#--------------------------------------------------------------------

# import data
# Extracted from Table 2 of the paper
hos_file <- paste(raw_dir, "species_lists/hoscheid_2014.csv", sep="/")
hos <- read.csv(hos_file)

# rename depth variable
hos$hos_max_depth_m <- hos$max_depth_m

# get taxon id
hos$taxonid <- getTaxonId(as.character(hos$species), key)
hos <- select(hos, -species, -source, -max_depth_m)

# join with species list
df <- merge(df, hos, by="taxonid", all.x=TRUE)


#--------------------------------------------------------------------
# 4. Integrate Ponganis et al. 2015. 
#--------------------------------------------------------------------
# Ponganis et al. 2015. Diving Physiology of Marine Mammals and Seabirds. Cambridge

# import data
# Data on dive max depth (m) from Tables 1.1 to 1.10 have been digitized into a CSV file
# Species names corrected for: Eumetopias jubatus, Megaptera novaeangliae, Procellaria aequinoctialis
# Arctocephalus pusillus subspecies have been merged at species level, selecting max depth.
pon_file <- paste(raw_dir, "species_lists/ponganis_2015.csv", sep="/")
pon <- read.csv(pon_file)

# filter species without diving depth
pon <- filter(pon, !is.na(depth_max_m))

# rename depth variable
pon$pon_max_depth_m <- pon$depth_max_m

# get taxon id
pon$taxonid <- getTaxonId(as.character(pon$species), key)
pon <- select(pon, -species, -group, -depth_max_m)

# join with species list
df <- merge(df, pon, by="taxonid", all.x=TRUE)



#--------------------------------------------------------------------
# 5. Combine data
#--------------------------------------------------------------------

# Some species are shared between sources. We define a priority for selecting
# records based on publication year (eg. Penguiness book is the most recent database)
# and specificity of the source (eg. Hoscheid 2014 is focused on marine turtles).
# select by priority (Hoscheid > Penguiness book > Ponganis 2015 > Halsey 2006 > IUCN > Sealifebase)

# Create max depth and max depth source
df$maxdepth_m <- NA
df$maxdepth_source <- NA

# Sealifebase
sel <- which(!is.na(df$DepthRangeDeep))
df$maxdepth_m[sel] <- df$DepthRangeDeep[sel]
df$maxdepth_source[sel] <- "Sealifebase"

# IUCN
sel <- which(!is.na(df$depth_lower))
df$maxdepth_m[sel] <- df$depth_lower[sel]
df$maxdepth_source[sel] <- "IUCN"

# Halsey et al. 2006
sel <- which(!is.na(df$hal_maxdepth_m))
df$maxdepth_m[sel] <- df$hal_maxdepth_m[sel]
df$maxdepth_source[sel] <- "Halsey et al. 2006"

# Ponganis (2015)
sel <- which(!is.na(df$pon_max_depth_m))
df$maxdepth_m[sel] <- df$pon_max_depth_m[sel]
df$maxdepth_source[sel] <- "Ponganis 2015"

# Penguiness book (2018)
sel <- which(!is.na(df$pen_maxdepth_m))
df$maxdepth_m[sel] <- df$pen_maxdepth_m[sel]
df$maxdepth_source[sel] <- "Penguiness book"

# Hoscheid (2014)
sel <- which(!is.na(df$hos_max_depth_m))
df$maxdepth_m[sel] <- df$hos_max_depth_m[sel]
df$maxdepth_source[sel] <- "Hoscheid et al. 2014"



#--------------------------------------------------------------------
# 6. Export table
#--------------------------------------------------------------------

## Export table as temporary file
write.csv(df, paste(temp_dir, "spp_list_depth.csv", sep="/"), row.names=FALSE)
df <- read.csv(paste(temp_dir, "spp_list_depth.csv", sep="/"))





#--------------------------------------------------------------------
# 6. Summarize data
#--------------------------------------------------------------------



## Filter species with depth data
df <- filter(df, !is.na(maxdepth_m))

## Summarize results
depth_sum <- df %>% 
  group_by(group_code) %>%
  summarize(n = n(),
            avg_maxdepth = mean(maxdepth_m),
            sd_maxdepth = sd(maxdepth_m),
            med_maxdetph = median(maxdepth_m),
            min_maxdepth = min(maxdepth_m),
            max_maxdepth = max(maxdepth_m)
            )

## Calculate proportion of species within multiple depth levels.
depth_levels <- seq(from = 10, to = 4000, by=10)
total_species <- nrow(df)
prop_depth <- NULL
for (i in 1:length(depth_levels)){
  prop <- sum(df$maxdepth_m > depth_levels[i])/total_species
  prop_depth <- c(prop_depth, prop)
}
depth_df <- data.frame(depth_levels, prop_depth)
plot(prop_depth*100, depth_levels, type="l", xlab="Proportion of species (%, n = 122)", ylab = "Maximum dive depth (m)", ylim = c(4000, 0))


# proportion at 2000m
# 8 species (6.5%)
prop2000 <- (sum(df$maxdepth_m > 2000)/total_species)*100
prop1000 <- (sum(df$maxdepth_m > 1000)/total_species)*100


