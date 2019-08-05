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
# Burger 2001. Diving depths of sharwaters
# Taylor 2008. Maximum dive depths of eight New Zeland Procellariiformes, including Pterodroma species


# Manually update
# Ponganis:
# Eubalaena glacialis: 120 m



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


## Export table as temporary file
write.csv(df, paste(temp_dir, "spp_list_depth.csv", sep="/"), row.names=FALSE)
df <- read.csv(paste(temp_dir, "spp_list_depth.csv", sep="/"))
df <- read.csv(paste("C:/Temp", "spp_list_depth.csv", sep="/"))


#--------------------------------------------------------------------
# 4. Search species without data
#--------------------------------------------------------------------




#--------------------------------------------------------------------
# 5. Combine data
#--------------------------------------------------------------------


## Get max value among the different databases
# df$depth_m <- pmax(df$depth_lower, df$DepthRangeComDeep, df$pen_depth_m, df$hal_depth_m, na.rm=TRUE)
# df$maxdepth_m <- pmax(df$depth_lower, df$pen_maxdepth_m, df$DepthRangeDeep, df$hal_maxdepth_m, df$hos_max_depth_m, na.rm=TRUE)


## select by priority (Hoscheid > Pen > Hal > Sealifebase > IUCN)
## higher priority are incorporated later and overwrite previous data

# For max depth
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

# Halsey
sel <- which(!is.na(df$hal_maxdepth_m))
df$maxdepth_m[sel] <- df$hal_maxdepth_m[sel]
df$maxdepth_source[sel] <- "Halsey et al. 2006"

# Penguiness book
sel <- which(!is.na(df$pen_maxdepth_m))
df$maxdepth_m[sel] <- df$pen_maxdepth_m[sel]
df$maxdepth_source[sel] <- "Penguiness book"

# Hoscheid et al. 2014
sel <- which(!is.na(df$hos_max_depth_m))
df$maxdepth_m[sel] <- df$hos_max_depth_m[sel]
df$maxdepth_source[sel] <- "Hoscheid et al. 2014"






## Correlation between depth sources
# plot(match$pen_depth_m, match$hal_depth_m)
# plot(match$pen_maxdepth_m, match$hal_maxdepth_m)
# plot(match$depth_lower_m, match$pen_depth_m)
# plot(match$depth_lower_m, match$hal_depth_m)
# 




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
plot(depth_levels, prop_depth, type="l")

# proportion at 2000m
# 8 species (6.5%)
prop2000 <- (sum(df$maxdepth_m > 2000)/total_species)*100
prop1000 <- (sum(df$maxdepth_m > 1000)/total_species)*100


##
library(ggplot2)

groups_order <- as.character(depth_sum$group_code[order(depth_sum$max_maxdepth)])

#### Figure: violin plot

p <- ggplot(df, aes(factor(group_code), maxdepth_m)) +
  geom_violin(aes(fill = group_code, colour = group_code), trim = TRUE, scale="width", alpha = I(1 / 3)) +
  geom_jitter(aes(color = group_code), height = 0, width = 0.1, alpha = I(1 / 1.5)) + 
  labs(y = "Maximum dive depth (m)", x = "") +
  scale_y_continuous(trans = 'reverse', limits = c(4000, 0), expand = c(0, 0)) +
  geom_hline(yintercept=c(2000), linetype="dotted") +
  scale_x_discrete(limits=groups_order) +
  theme_bw(base_size = 12, base_family = "") +
  theme(
    legend.position =  "none",
    panel.grid = element_blank(),
    axis.text.y = element_text(margin=unit(c(0.3,0.3,0.3,0.3), "cm")), 
    axis.text.x = element_text(margin=unit(c(0.3,0.3,0.3,0.3), "cm"))
  )
p


# Save as png file
p_png = paste0(fig_dir, "/dive/violin_maxdepth.png")
#ggsave(p_png, p, width=10, height=8, units="cm", dpi=300)
ggsave(p_png, p, width=12, height=10, units="cm", dpi=300)

