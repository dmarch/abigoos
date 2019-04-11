#------------------------------------------------------------------------------------------
# 03_eoo_plots.R       Plots EOO maps
#------------------------------------------------------------------------------------------
#
# This script generates overview plots at the taxonomic group level.


## Load libraries
library(raster)
library(rgdal)
library(ggplot2)
library(Hmisc)
library(data.table)
source("R/utils.R")
source("R/data_paths.R")

## Create world bounding box in Mollweide
box <- bb(xmin = -180, xmax = 180, ymin = -90, ymax = 90, crs=PROJ)

## Import data
land.prj <- readOGR(temp_dir, temp_land)  # landmask

## Import species list
match <- read.csv(spp_list_group)
class <- unique(match$group)  # get group classes


#-------------------------------------------------------------------------
# Fig 1. Density maps of species subject to telemetry by taxonomic group.
#-------------------------------------------------------------------------
# Plot of number of species per taxa.
# Normalized from 0 to 1 in order to use the same color palette
range_list <- list()
for (i in 1:length(class)){
  
  print(i)
  
  # Import nc files
  ncfile <- list.files(eoo_dir, pattern=paste0(class[i], ".nc"), full.names=TRUE)
  nc <- raster(ncfile)
  
  # Get min and max values per class
  nc <- setMinMax(nc)
  lim = data.frame(class=class[i], min=minValue(nc), max=maxValue(nc))
  range_list[[i]] <- lim
  
  # Plot
  p <- plotraster(r = nc, land = land.prj, box = box, legendTitle = "")
  
  # Save as png file
  p_png = paste0(fig_dir, "/eoo/", class[i],".png")
  ggsave(p_png, p, width=25, height=14, units="cm", dpi=300)
}
range <- rbindlist(range_list)
write.csv(range, paste0(fig_dir, "/eoo/", "ranges_per_taxa.csv"), row.names=FALSE)

#-------------------------------------------------------------------------
# Fig 2. Density maps of species subject to telemetry (all taxa)
#-------------------------------------------------------------------------
# The number of species for each taxon were then normalized by rescaling from zero to one,
# and averaged across taxa by cell for all taxa.

rnorm <- stack()  # create stack

## Normalize number of species per taxa
for (i in 1:length(class)){
  
  print(i)
  
  # Import nc files
  ncfile <- list.files(eoo_dir, pattern=paste0(class[i], ".nc"), full.names=TRUE)
  nc <- raster(ncfile)
  
  ## Normalize from zero to one
  nc <- setMinMax(nc)
  norm <- (nc - minValue(nc)) / (maxValue(nc) - minValue(nc))
  if (minValue(nc) == maxValue(nc)) norm <- nc  # this exception applies for sirenians with max values = 1
  rnorm <- stack(rnorm, norm)
}

## Average across taxa
allnorm <- mean(rnorm, na.rm=TRUE)

## Plot
legend <- paste0("All taxa\n(normalized)\n")
p <- plotraster(r = allnorm, land = land.prj, box = box, lim=c(0,1), legendTitle = legend, legend.position = "bottom")

# Save as png file
p_png = paste0(fig_dir, "/eoo/", "alltaxa_normalized",".png")
ggsave(p_png, p, width=25, height=14, units="cm", dpi=300)
