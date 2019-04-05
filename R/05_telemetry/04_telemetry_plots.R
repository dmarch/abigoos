#------------------------------------------------------------------------------------------
# 03_telemetry_plots.R       Plots Telemetry observations
#------------------------------------------------------------------------------------------


## Load libraries
library(raster)
library(rgdal)
library(ggplot2)
source("R/utils.R")
source("R/data_paths.R")

## Create world bounding box in Mollweide
box <- bb(xmin = -180, xmax = 180, ymin = -90, ymax = 90, crs=PROJ)

## Import data
land.prj <- readOGR(temp_dir, temp_land)  # landmask

turtle_dens <- paste0(temp_dir, "/", "obisTurtlesDens.grd")
chelo <- raster(turtle_dens)

#-------------------------------------------------------------------------
# Fig 1. Density maps of sea turtle telemetry number of records
#-------------------------------------------------------------------------
# Plot of number of species per taxa.

# Create plot
p <- plotraster(r = log10(chelo), land = land.prj, box = box,
                legendTitle = expression(log[10]~(records / km^2)))

# Save as png file
p_png <- paste(fig_dir,"telemetry","turtle_telemetry_density.png", sep="/")
ggsave(p_png, p, width=25, height=14, units="cm", dpi=300)
