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
# 4. Search species without data
#--------------------------------------------------------------------




#--------------------------------------------------------------------
# 5. Combine data
#--------------------------------------------------------------------


## Get max value among the different databases
df$depth_m <- pmax(df$depth_lower, df$DepthRangeComDeep, df$pen_depth_m, df$hal_depth_m, na.rm=TRUE)
df$maxdepth_m <- pmax(df$depth_lower, df$pen_maxdepth_m, df$hal_maxdepth_m, df$hos_max_depth_m, na.rm=TRUE)


## select by priority (Hoscheid > Pen > Hal > Sealifebase > IUCN)









## Correlation between depth sources
# plot(match$pen_depth_m, match$hal_depth_m)
# plot(match$pen_maxdepth_m, match$hal_maxdepth_m)
# plot(match$depth_lower_m, match$pen_depth_m)
# plot(match$depth_lower_m, match$hal_depth_m)
# 




## Filter species with depth data
df <- filter(df, !is.na(depth_m))

##
library(ggplot2)
library(ggpubr)

#### Figure: violin plot
p <- ggplot(df, aes(factor(group_code), maxdepth_m)) +
  geom_violin(trim = TRUE, fill = "grey80", colour = "grey70", scale="width") +
  geom_jitter(height = 0, width = 0.1, alpha = I(1 / 1.5), color="dodgerblue3") + 
  theme_bw() + 
  labs(y = "Depth (m)", x = "") +
  ylim(3000, 0) +
  geom_hline(yintercept=c(1000, 2000), linetype="dotted") +
  #scale_x_discrete(limits=c("TB", "SR", "PI", "CE", "FB", "PE", "TU", "SI")) +
  theme(legend.position="none",
        panel.grid.major = element_blank(), panel.grid.minor = element_blank())
p

p<-ggplot(data=df, aes(x=reorder(scientific_name, depth_m), y=depth_m, fill=group_code)) +
  geom_bar(stat="identity") + 
  scale_y_continuous(trans = 'reverse', limits = c(3000, 0), expand = c(0, 0)) +
  labs(y = "Maximum dive depth (m)", x = "") +
  scale_fill_brewer(palette = "Set2") +
  geom_hline(yintercept=c(1000, 2000), linetype="dotted") +
  theme_bw(base_size = 12, base_family = "") +
  theme(
    legend.position="right",
    panel.grid = element_blank(),
    axis.text.x = element_blank(),
    axis.ticks.x=element_blank(),
    axis.text.y = element_text(margin=unit(c(0.3,0.3,0.3,0.3), "cm"))
  )
p  


df2 <- df %>%
  arrange(group_code, depth_m) %>%
  mutate(scientific_name = factor(scientific_name, levels = scientific_name))

p<-ggplot(data=df2, aes(x=scientific_name, y=depth_m, fill=group_code)) +
  geom_bar(position="dodge", stat="identity") + 
  scale_y_continuous(trans = 'reverse', limits = c(3000, 0), expand = c(0, 0)) +
  labs(y = "Maximum dive depth (m)", x = "") +
  scale_fill_brewer(palette = "Set2") +
  geom_hline(yintercept=c(1000, 2000), linetype="dotted") +
  theme_bw(base_size = 12, base_family = "") +
  theme(
    legend.position="right",
    panel.grid = element_blank(),
    axis.text.x = element_blank(),
    axis.ticks.x=element_blank(),
    axis.text.y = element_text(margin=unit(c(0.3,0.3,0.3,0.3), "cm"))
  )
p 



# lollipop chart
ggplot(df2, aes(x = scientific_name, y = depth_m)) +
  geom_segment(
    aes(x = scientific_name, xend = scientific_name, y = 0, yend = depth_m), 
    color = "lightgray", size = 2) + 
  #geom_point(aes(colour = group_code), size = 4) +
  #geom_point(shape = 21, colour = "black", fill = group_code, size = 4, stroke = 0.5) +
  geom_point(aes(fill = group_code), size = 4, shape=21) +
  scale_y_continuous(trans = 'reverse', limits = c(2000, 0), expand = c(0, 0)) +
  labs(y = "Maximum dive depth (m)", x = "") +
  scale_color_brewer(palette = "Set2") +
  geom_hline(yintercept=c(1000, 2000), linetype="dotted") +
  theme_bw(base_size = 12, base_family = "") +
  theme(
    legend.position="right",
    panel.grid = element_blank(),
    axis.text.x = element_blank(),
    axis.ticks.x=element_blank(),
    axis.text.y = element_text(margin=unit(c(0.3,0.3,0.3,0.3), "cm"))
  )



ggdotchart(df2, x = "scientific_name", y = "depth_m",
           color = "group_code",                         # Color by groups
           #palette = c("#00AFBB", "#E7B800", "#FC4E07"), # Custom color palette
           #sorting = "group_code",                        # Sort value in descending order
           add = "segments",                             # Add segments from y = 0 to dots
           ggtheme = theme_pubr()                        # ggplot2 theme
)


ggdotchart(dfm, x = "name", y = "mpg_z",
           color = "cyl",                                # Color by groups
           palette = c("#00AFBB", "#E7B800", "#FC4E07"), # Custom color palette
           sorting = "descending",                       # Sort value in descending order
           add = "segments",                             # Add segments from y = 0 to dots
           add.params = list(color = "lightgray", size = 2), # Change segment color and size
           group = "cyl",                                # Order by groups
           dot.size = 6,                                 # Large dot size
           label = round(dfm$mpg_z,1),                        # Add mpg values as dot labels
           font.label = list(color = "white", size = 9, 
                             vjust = 0.5),               # Adjust label parameters
           ggtheme = theme_pubr()                        # ggplot2 theme
)+
  geom_hline(yintercept = 0, linetype = 2, color = "lightgray")

# https://www.r-bloggers.com/bar-plots-and-modern-alternatives/
# https://www.datanovia.com/en/blog/ggplot-examples-best-reference/
