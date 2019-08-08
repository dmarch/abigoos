#-------------------------------------------------------------------------------------------
# plot_depth.R            Plot to summarize max dive depth by species and taxonomic groups
#-------------------------------------------------------------------------------------------

## Load libraries
library(dplyr)
library(ggplot2)
source("R/data_paths.R")


## Import data
df <- read.csv(paste(temp_dir, "spp_list_depth.csv", sep="/"))

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

## Order groups by maximum values of max dive
groups_order <- as.character(depth_sum$group_code[order(depth_sum$max_maxdepth)])

## Figure: violin plot
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
ggsave(p_png, p, width=12, height=10, units="cm", dpi=300)
