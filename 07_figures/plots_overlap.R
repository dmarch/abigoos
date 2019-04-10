#------------------------------------------------------------------------------------------
# 03_overlap_plot.R       Plots results of overlap analysis
#------------------------------------------------------------------------------------------
#

## Load libraries
library(raster)
library(rgdal)
library(ggplot2)
library(RColorBrewer)
library(dplyr)
source("R/utils.R")
source("R/data_paths.R")

## Create world bounding box in Mollweide
box <- bb(xmin = -180, xmax = 180, ymin = -90, ymax = 90, crs=PROJ)

## Import data
land.prj <- readOGR(temp_dir, temp_land)  # landmask
coldspots <- raster(argo_coldspots)  # Argo coldspots
match <- read.csv(spp_list_group)  # Import species list
turtle_tel <- raster(paste0(telemetry_tempdir, "/", "turtle_dens.nc"))  # turtle telemetry map
turtle_eoo <- raster(paste0(eoo_dir, "/", "turtle", ".nc"))  # turtle eoo map
pin_tel <- raster(paste0(telemetry_tempdir, "/", "pinniped_dens.nc"))  # pinniped telemetry map
pin_eoo <- raster(paste0(telemetry_tempdir, "/", "pinniped_subset", ".nc"))  # pinniped eoo map
eoo_overlap <- read.csv(paste(overlap_dir, "eoo_overlap.csv", sep="/"))  # overlap metrics for eoo
tel_overlap <- read.csv(paste(overlap_dir, "telemetry_overlap.csv", sep="/"))  # overlap metrics for eoo


#---------------------------------------------------------------------------
# Fig 1. Overlap between gaps of the Argo network and EOO maps. (taxonomic group)
#---------------------------------------------------------------------------
# Use num. of species (normalized)

## Loop over each class
class <- unique(match$group)

for (i in 1:length(class)){
  
  print(i)
  
  # Import nc files
  ncfile <- list.files(eoo_dir, pattern=paste0(class[i], ".nc"), full.names=TRUE)
  nc <- raster(ncfile)
  
  ## Normalize number of species from zero to one
  nc <- setMinMax(nc)
  norm <- (nc - minValue(nc)) / (maxValue(nc) - minValue(nc))
  if (minValue(nc) == maxValue(nc)) norm <- nc
  
  ## Mask with coldspots
  ov <- norm * coldspots  # Mask for Argo undersampled areas
  
  ## Plot and save
  redpal <- brewer.pal(9,"Reds")
  p_png = paste0(fig_dir, "/overlap/", class[i],".png")

  png(p_png , width=25, height=14, units="cm", res=300)
  plot(coldspots, col="#6baed6", axes=FALSE, box=FALSE, legend=FALSE)
  plot(ov, col=redpal, add=TRUE, legend=FALSE)
  plot(land.prj, col= "grey80", border= "grey40", lwd=0.01, add=TRUE) #border=NA
  plot(box, border= "grey70", add=TRUE)
  # addRasterLegend(ov, direction="horizontal",
  #                 location = c(-18040096, 0, -12979952, -10979952),
  #                 ramp=redpal,
  #                 side = 1, locs=c(0,1),
  #                 title = "prova")
  dev.off()
}

#---------------------------------------------------------------------------
# Fig 2. Overlap between gaps of the Argo network and telemetry maps. (sea turtles)
#---------------------------------------------------------------------------
# Use combination between EOO and Telemetry

## Transform to presence/absence and intersect with coldspots
tel_pres <- (turtle_tel/turtle_tel) * coldspots
eoo_pres <- (turtle_eoo/turtle_eoo) * coldspots

## Combine the three layers
comb <- sum(coldspots, tel_pres, eoo_pres, na.rm=TRUE)
comb[comb==0] <- NA

## Plot and save
p_png = paste0(fig_dir, "/overlap/", "compare_turtle_eoo_tel.png")
png(p_png , width=25, height=14, units="cm", res=300)
plot(comb, col=c("#6baed6","#fcae91","#a50f15") , axes=FALSE, box=FALSE, legend=FALSE)
plot(land.prj, col= "grey80", border= "grey40", lwd=0.01, add=TRUE) #border=NA
plot(box, border= "grey70", add=TRUE)
legend(comb)
dev.off()
  
  
#---------------------------------------------------------------------------
# Fig 3. Overlap between gaps of the Argo network and telemetry maps. (sea turtles)
#---------------------------------------------------------------------------
# Use combination between EOO and Telemetry
# Need to generate the map of EOO for the same species!!!


## Transform to presence/absence and intersect with coldspots
tel_pres <- (pin_tel/pin_tel) * coldspots
eoo_pres <- (pin_eoo/pin_eoo) * coldspots

## Combine the three layers
comb <- sum(coldspots, tel_pres, eoo_pres, na.rm=TRUE)
comb[comb==0] <- NA

## Plot and save
p_png = paste0(fig_dir, "/overlap/", "compare_pinniped_eoo_tel.png")
png(p_png , width=25, height=14, units="cm", res=300)
plot(comb, col=c("#6baed6","#fcae91","#a50f15") , axes=FALSE, box=FALSE, legend=FALSE)
plot(land.prj, col= "grey80", border= "grey40", lwd=0.01, add=TRUE) #border=NA
plot(box, border= "grey70", add=TRUE)
legend(comb)
dev.off()


#---------------------------------------------------------------------------
# Fig 4. Violin plots
#---------------------------------------------------------------------------
# Violin plots detailing the spatial overlap between the gap of the Argo network
# and animal-borne platforms species by taxonomic group and region

## Combine with species list
match_sel <- dplyr::select(match, taxonid, group, scientific_name, group_code)
eoo_overlap <- merge(eoo_overlap, match_sel, by="taxonid")

## Subset data by region
regions <- unique(eoo_overlap$region)

for (i in 1:length(regions)){
  reg <- regions[i]
  sub <- filter(eoo_overlap, region == reg)
  
  #### Figure: violin plot
  p <- ggplot(sub, aes(factor(group_code), ov_coldspot)) +
    geom_violin(trim = TRUE, fill = "grey80", colour = "grey70", scale="width") +
    geom_jitter(height = 0, width = 0.1, alpha = I(1 / 1.5), color="dodgerblue3") + 
    theme_bw() + 
    labs(y = expression(italic(OV[coldspot])), x = "") +
    ylim(0, 1) +
    scale_x_discrete(limits=c("TB", "SR", "PI", "CE", "FB", "PE", "TU", "SI")) +
    theme(legend.position="none",
          panel.grid.major = element_blank(), panel.grid.minor = element_blank())
  
  # Save as png file
  p_png = paste0(fig_dir, "/overlap/violin_coldspot_", reg,".png")
  ggsave(p_png, p, width=10, height=8, units="cm", dpi=300)
}


#---------------------------------------------------------------------------
# Fig 5a-b.
#---------------------------------------------------------------------------
# Relationship between species range size and overlap indices:
# (a) percentage of coldspots overlapped by species ranges,
# (b) percentage of species ranges overlapped by coldspots

## Filter overlap results for the Global Ocean only
eoo_overlap_GO <- filter(eoo_overlap, region == "GO")


#### Figure: Species range size vs. ovRange
p <- ggplot(eoo_overlap_GO, aes(log10(range_km2), ov_range)) +
  geom_jitter(size=2, alpha = I(1 / 1.5), color="dodgerblue3") + 
  labs(x = expression(Range~size~km^2~(log[10])), y = expression(italic(OV[range]))) +
  ylim(0, 1) +
  theme_bw() + 
  theme(legend.position="none",
        panel.grid.major = element_blank(), panel.grid.minor = element_blank())

# Save as png file
p_png = paste0(fig_dir, "/overlap/range_vs_ovRange.png")
ggsave(p_png, p, width=10, height=9, units="cm", dpi=300)


#### Figure: Species range size vs. ovColdspot
p <- ggplot(eoo_overlap_GO, aes(log10(range_km2), ov_coldspot)) +
  geom_jitter(size=2, alpha = I(1 / 1.5), color="dodgerblue3") + 
  labs(x = expression(Range~size~km^2~(log[10])), y = expression(italic(OV[coldspot]))) +
  ylim(0, 1) +
  theme_bw() + 
  theme(legend.position="none",
        panel.grid.major = element_blank(), panel.grid.minor = element_blank())

# Save as png file
p_png = paste0(fig_dir, "/overlap/range_vs_ovColdspot.png")
ggsave(p_png, p, width=10, height=9, units="cm", dpi=300)




#---------------------------------------------------------------------------
# Fig 6.
#---------------------------------------------------------------------------
# Comparison between overlap indices and data sources (telemetry and EOO ranges) for turtles and pinnipeds. 

## Filter overlap results for the Global Ocean only
eoo_overlap_GO <- filter(eoo_overlap, region == "GO")
tel_overlap_GO <- filter(tel_overlap, region == "GO")

## Combine EOO and telemetry overlap results for common species
dat <- right_join(eoo_overlap_GO, tel_overlap_GO, by=c("taxonid"))

## Combine with species information
match_sel <- select(match, taxonid, group, scientific_name, group_code, group_name)
dat <- merge(dat, match_sel, by="taxonid")


#### Figure: Compare OVcoldspot
p <- ggplot(dat, aes(ov_coldspot.x, ov_coldspot.y, colour = group_name)) +
  geom_jitter(size=3, alpha = I(1 / 1.5)) + 
  labs(x = expression(italic(OV[coldspot])~(EOO)), y = expression(italic(OV[coldspot])~(Telemetry))) +
  xlim(0, 0.5) + ylim(0, 0.5) +
  scale_color_manual(values = c("darkgoldenrod1", "aquamarine4"))+
  theme_bw() + 
  theme(legend.position = c(0.2, 0.8), legend.title=element_blank(),
        legend.background = element_rect(color = "black", fill = "white", size = 0.2, linetype = "solid"),
        panel.grid.major = element_blank(), panel.grid.minor = element_blank())

# Save as png file
p_png = paste0(fig_dir, "/overlap/compare_ovColdspot.png")
ggsave(p_png, p, width=10, height=9, units="cm", dpi=300)


#### Figure: Compare OVrange
p <- ggplot(dat, aes(ov_range.x, ov_range.y, colour = group_name)) +
  geom_jitter(size=3, alpha = I(1 / 1.5)) + 
  labs(x = expression(italic(OV[range])~(EOO)), y = expression(italic(OV[range])~(Telemetry))) +
  xlim(0, 1) + ylim(0, 1) +
  scale_color_manual(values = c("darkgoldenrod1", "aquamarine4"))+
  theme_bw() + 
  theme(legend.position = c(0.2, 0.8), legend.title=element_blank(),
        legend.background = element_rect(color = "black", fill = "white", size = 0.2, linetype = "solid"),
        panel.grid.major = element_blank(), panel.grid.minor = element_blank())

# Save as png file
p_png = paste0(fig_dir, "/overlap/compare_ovRange.png")
ggsave(p_png, p, width=10, height=9, units="cm", dpi=300)
