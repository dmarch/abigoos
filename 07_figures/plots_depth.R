#-------------------------------------------------------------------------------------------
# plot_depth.R            Plot to summarize max dive depth by species and taxonomic groups
#-------------------------------------------------------------------------------------------

## Load libraries
library(dplyr)
library(ggplot2)
source("R/data_paths.R")



## Import data
match <- read.csv("C:/Temp/sd1_tbl_species_list.csv")  # Import species list

## Filter species with depth data
df <- filter(match, !is.na(depth_lower_m))

##

#### Figure: violin plot
p <- ggplot(df, aes(factor(group_name), depth_lower_m)) +
  geom_violin(trim = TRUE, fill = "grey80", colour = "grey70", scale="width") +
  geom_jitter(height = 0, width = 0.1, alpha = I(1 / 1.5), color="dodgerblue3") + 
  theme_bw() + 
  labs(y = "Depth (m)", x = "") +
  ylim(3000, 0) +
  #scale_x_discrete(limits=c("TB", "SR", "PI", "CE", "FB", "PE", "TU", "SI")) +
  theme(legend.position="none",
        panel.grid.major = element_blank(), panel.grid.minor = element_blank())


p<-ggplot(data=df, aes(x=reorder(scientific_name, depth_lower_m), y=depth_lower_m, fill=group_name)) +
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
  
