#-------------------------------------------------------------------------------------------------
# link_dive_databases.R            Link species list with Dive Databases
#-------------------------------------------------------------------------------------------------

library(dplyr)


## Import data

# Species list
spp_file <- "D:/temp/sd1_tbl_species_list.csv"
df <- read.csv(spp_file)

# Penguiness book --------------
# Ropert-Coudert Y, Kato A, Robbins A, Humphries GRW (2018) The Penguiness book.
# World Wide Web electronic publication (http://www.penguiness.net), version 3.0, October 2018.
# DOI:10.13140/RG.2.2.32289.66406
penguiness_file <- "D:/temp/all_dive_data.csv"
pen <- read.csv(penguiness_file)

# Halsey et al. 2006 -------------
# A Phylogenetic Analysis of the Allometry of Diving.
# Lewis G. Halsey, Patrick J. Butler, and Tim M. Blackburn
# The American Naturalist 2006 167:2, 276-287 
# Note:
# - Raw file has been manipulated to remove subheaders and blank lines
# - Subspecies removed and aggregated at species level (max depth selected)
halsey_file <- "D:/temp/halsey_2006.txt"
hal <- read.table(halsey_file, sep="\t", header=TRUE, fill = TRUE)



##### Process Penguiness book data

# convert factor to numeric
pen$depth <-as.numeric(as.character(pen$depth))
pen$max.depth <-as.numeric(as.character(pen$max.depth))

# get max depth and max.depth from the records
pen <- pen %>%
  filter(depth.type != "None", depth > 0) %>%
  group_by(latin.name) %>%
  summarize(pen_depth_m = max(depth, na.rm=TRUE),
            pen_maxdepth_m = max(max.depth, na.rm = TRUE))

# if max.depth is smaller than depth, then reassign
pen$dif <- pen$pen_maxdepth_m - pen$pen_depth_m
pen$pen_maxdepth_m[pen$dif < 0] <- pen$pen_depth_m[pen$dif < 0]
pen <- select(pen, -dif)

# join with species list
match <- merge(df, pen, by.x="scientific_name", by.y="latin.name", all.x=TRUE)



##### Process Halsey et al.

# get max depth and max.depth from the records
hal <- hal %>%
  filter(!is.na(Dive.depth..m.))%>%#, !is.na(Maximum.dive.depth..m.)) %>%
  group_by(Latin.name.) %>%
  summarize(hal_depth_m = max(Dive.depth..m., na.rm=TRUE),
            hal_maxdepth_m = max(Maximum.dive.depth..m., na.rm = TRUE))

# if max.depth is smaller than depth, then reassign
hal$dif <- hal$hal_maxdepth_m - hal$hal_depth_m
hal$hal_maxdepth_m[hal$dif < 0] <- hal$hal_depth_m[hal$dif < 0]
hal <- select(hal, -dif)


# join with species list
match <- merge(match, hal, by.x="scientific_name", by.y="Latin.name.", all.x=TRUE)



## Correlation between depth sources
plot(match$pen_depth_m, match$hal_depth_m)
plot(match$pen_maxdepth_m, match$hal_maxdepth_m)
plot(match$depth_lower_m, match$pen_depth_m)
plot(match$depth_lower_m, match$hal_depth_m)


## Get max value among the different databases
match$depth_m <- pmax(match$depth_lower_m, match$pen_depth_m, match$hal_depth_m, na.rm=TRUE)
match$maxdepth_m <- pmax(match$depth_lower_m, match$pen_maxdepth_m, match$hal_maxdepth_m, na.rm=TRUE)




## Filter species with depth data
df <- filter(match, !is.na(depth_m))

##

#### Figure: violin plot
p <- ggplot(df, aes(factor(group_name), maxdepth_m)) +
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

p<-ggplot(data=df, aes(x=reorder(scientific_name, depth_m), y=depth_m, fill=group_name)) +
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
  arrange(group_name, depth_m) %>%
  mutate(scientific_name = factor(scientific_name, levels = scientific_name))

p<-ggplot(data=df2, aes(x=scientific_name, y=depth_m, fill=group_name)) +
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
    color = "lightgray"
  ) + 
  geom_point(aes(color = group_name), size = 3) +
  scale_y_continuous(trans = 'reverse', limits = c(3000, 0), expand = c(0, 0)) +
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





# https://www.r-bloggers.com/bar-plots-and-modern-alternatives/
# https://www.datanovia.com/en/blog/ggplot-examples-best-reference/
