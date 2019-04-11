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

## Import sea turtle density of number of records
turtle_dens <- paste0(telemetry_tempdir, "/", "turtle_dens.nc")
chelo <- raster(turtle_dens)

## Import pinnipeds density of number of profiles
pin_dens <- paste0(telemetry_tempdir, "/", "pinniped_dens.nc")
pin <- raster(pin_dens)


#-------------------------------------------------------------------------
# Fig 1. Density maps of sea turtle telemetry number of records
#-------------------------------------------------------------------------

# Create plot
p <- plotraster(r = log10(chelo), land = land.prj, box = box, legend.position="bottom",
                legendTitle = expression(log[10]~(observations / km^2)))

# Save as png file
p_png <- paste(fig_dir,"telemetry","turtle_telemetry_density.png", sep="/")
ggsave(p_png, p, width=25, height=14, units="cm", dpi=300)


#-------------------------------------------------------------------------
# Fig 2. Density maps of pinniped telemetry number of profiles
#-------------------------------------------------------------------------

# Create plot
p <- plotraster(r = log10(pin), land = land.prj, box = box,
                legendTitle = expression(log[10]~(profiles / km^2)))

# Save as png file
p_png <- paste(fig_dir,"telemetry","pinniped_telemetry_density.png", sep="/")
ggsave(p_png, p, width=25, height=14, units="cm", dpi=300)
