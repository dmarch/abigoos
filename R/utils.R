#------------------------------------------------------------
# utils.R       Suite of custom functions
#------------------------------------------------------------
#
# This script contains a suite of custom functions used by other scripts from
# the current project.
#
# List of fuctions:
#
# 
# bb               Create world bounding box at custom CRS
# binsurf         Calculate surface of binary map on Equal area projection
# oceanArea
# oceanAreaEEZ
# overlap       Overlap between species range (a) and Argo coldspots (b)
# plotraster       Plot raster map
# plotrasterDis     Plot raster map for discrete values
# presence         Calculate presence map from quintile map
# quintile         Calculate quintile map from raster map
# spatialOverlap        Spatial Overlap between gaps of Argo network and species distributions
# unsamp         Calculate unsampled cells
# zonalLatitude         Calculate zonal statistic for raster by latitude



#----------------------------------------------------------------------
# bb             Create world bounding box at custom CRS
#----------------------------------------------------------------------
bb <- function(xmin, xmax, ymin, ymax, crs="+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs"){
  # Arguments
  # xmin        Minimum longitude
  # xmax        Maximum longitude
  # ymin        Minimum latitude
  # ymax        Maximum latitude
  # crs         CRS definition
  # 
  # Details:
  # By default, the bounding box is returned in longlat.
  #
  # Description:
  # This function has been designed to create a bounding box defined by multiple points.
  # Using extent() from raster package only provides 4 points, which is not enough to plot
  # a box using other projections (eg. Mollweide).
  # We then need to create a bounding box with more density of points in order to
  # change its shape with transforming to other projections.


  library(raster)
  library(rgeos)
  library(sp)
  
  # create bounding box with four points and project to mercator
  e <- as(raster::extent(xmin, xmax, ymin, ymax), "SpatialPolygons")
  proj4string(e) <- "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs"
  
  # transform to line and sample new points
  el <- as(e, "SpatialLines")
  len <- gLength(el)
  i <- gInterpolate(el, d=seq(0, len, by=0.5), normalized = FALSE)  # sample points at 0.5 degrees
  
  # reconvert to spatial polygon
  P1 = Polygon(i)
  Ps1 = SpatialPolygons(list(Polygons(list(P1), ID = "a")), proj4string=CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs"))
  
  # reproject
  Ps1.prj <- spTransform(Ps1, crs)
  
  return(Ps1.prj)
}
#----------------------------------------------------------------------

#------------------------------------------------------------------------------
# binsurf         Calculate surface of binary map on Equal area projection
#------------------------------------------------------------------------------
binsurf <- function(r){
  # Arguments
  # r                 Raster of binary data (presence = 1)
  #
  # Description
  # Raster has to be on an equal area projection. See ?area for non-projected.
  #
  # Value
  # Surface in km2
  
  # Calculate number of cells with presence
  ncell <- sum(values(r), na.rm=TRUE) # number of cells
  
  # Calculate surface of one cell (in km2)
  scell <- (res(r)[1] * res(r)[2]) / 1000000
  
  # Calculate overall surface
  surf <- ncell * scell
  return(surf)
}
#------------------------------------------------------------------------------

#-----------------------------------
# oceanArea
#-----------------------------------
oceanArea <- function(ocean_mask, xmin = -180, xmax = 180, ymin = -90, ymax = -90, crs=PROJ){
  
  library(raster)
  source("R/utils.R")
  
  box <- bb(xmin, xmax, ymin, ymax, crs)  # create polygon per region
  m <- rasterize(box, ocean_mask)  # rasterize polygon
  o <- m * ocean_mask  # extract ocean cells from mask
  s <- binsurf(o)  # calculate surface for ocean cells
  return(s)
}
#-----------------------------------

#-----------------------------------
# oceanAreaEEZ
#-----------------------------------
oceanAreaEEZ <- function(ocean_mask, eez, xmin = -180, xmax = 180, ymin = -90, ymax = 90, crs=PROJ, crs.geo=GEO){
  
  library(raster)
  source("R/utils.R")
  
  box <- bb(xmin, xmax, ymin, ymax, crs)  # create polygon per region
  m <- rasterize(box, ocean_mask)  # rasterize polygon
  o <- m * ocean_mask  # extract ocean cells from mask
  
  # overlap with eez
  o_geo <- projectRaster(o, crs=crs.geo, method="ngb")
  a <- area(o_geo)
  area <- o_geo * a
  eezArgo <- extract(area, eez, fun=sum, na.rm=TRUE, sp=TRUE) # calculate the sum of Argo profiles per each EEZ
  coldspot_area_in_ezz <- sum(eezArgo$layer)
  
  return(coldspot_area_in_ezz)
}
#-----------------------------------

#------------------------------------------------------------------------------------
# overlap       Overlap between species range (a) and Argo coldspots (b)
#------------------------------------------------------------------------------------
overlap <- function(a, b){
  # a: Species. Raster layer with value (1) for presence, and (NA) for absence
  # b: Coldspots. Raster layer with value (1) for presence, and (NA) for absence
  
  # Load libraries
  library(raster)
  source("R/utils.R")
  
  # Calculate the intersection of the two rasters, this is given by adding 
  # the binary rasters together -> 2 indicates intersection
  combination <- sum(a, b, na.rm=TRUE)
  intersection <- combination == 2
  union <- combination >= 1
  
  ## Calculate surfaces
  a_km2 <- binsurf(a)   # extent of the species, in km2 [A]
  b_km2 <- binsurf(b)   # extent of the Argo coldspots, in km2 [B]
  intersection_km2 <- binsurf(intersection)  # overlap between species range and Argo gap, in km2 [A∩B]
  union_km2 <- binsurf(union)  # union of species range and Argo gap, in km2 [A∪B]
  
  ## Calculate metrics
  overlap_a <- round(intersection_km2/a_km2, 3)  # proportion of species range overlaped by Argo gap, from 0-1 [A∩B]/A
  overlap_b <- round(intersection_km2/b_km2, 3)  # proportion of Argo gap overlaped by species, from 0-1 [A∩B]/B
  jaccard <- round(intersection_km2/union_km2, 3)  # Jaccard index of overlap. 1 means perfect overlap, 0 no overlap [A∩B]/[A∪B]
  
  ## Prepare output
  out <- data.frame(a_km2, b_km2, intersection_km2, union_km2, overlap_a, overlap_b, jaccard)
  return(out)
}
#------------------------------------------------------------------------------------



#----------------------------------------------------------------------
# plotraster     Plot raster map
#----------------------------------------------------------------------
plotraster <- function(r, land, box, palette = 'Spectral', ggtitle = NULL, 
                       limits = NULL, legendTitle = NULL, legend.position = "right",
                       text = NULL, text.x = NULL, text.y = NULL, text.size = NULL,
                       contour = NULL){
  # r               Raster map
  # land            Land mask
  # box             World box
  # palette         Color palette
  # limits          Set limits to display. Vector with two values.
  # legendTitle     If not null, set legend title
  # ggtitle         If not null, set plot title
  # legend.position Position of legend if legendTitle not null
  # text            If not null, set text
  # contour         Spatial polygon
  #
  # helpful links:
  # https://seethedatablog.wordpress.com/2016/12/26/mapping-cities-some-tweaks-with-ggplot-and-ggrepel/
  # multiplot() http://www.cookbook-r.com/Graphs/Multiple_graphs_on_one_page_(ggplot2)/
  
  
  library(ggplot2)
  
  if (is.null(limits)) limits <- c(min(minValue(r)), max(maxValue(r)))
  
  
  p <- rasterVis::gplot(r) +
    # Add raster layer  
    geom_raster(aes(fill=value)) +
    
    # Set raster palette and legend header
    # scale_fill_distiller(
    #   type = 'seq', palette = 'Spectral',
    #   name = legendTitle, na.value='white') +
    
    scale_fill_distiller(
      type = 'div', palette = palette,
      name = legendTitle, na.value='white',
      limits = limits) +#,
    #breaks= limits, labels=round(limits, 1)) +
    
    # Add projected countries (land)
    geom_polygon(data = land, 
                 aes(long,lat, group = group), 
                 colour = "grey70", fill = "grey70", size = .25) +
    
    # # Add projected bounding box (box)
    geom_polygon(data = box,
                 aes(x = long, y = lat),
                 colour = "grey70", fill = "transparent", size = .25) +
    
    # Set aspect ratio
    # the default, ratio = 1 in coord_fixed ensures that one unit on the x-axis is the same length as one unit on the y-axis
    coord_fixed(ratio = 1) +
    
    # Set empty theme
    theme_void() + # remove the default background, gridlines & default gray color around legend's symbols
    
    # Set them options
    theme(legend.position = legend.position, #"none", "bottom"
          plot.title = element_text(hjust = 0.5),
          plot.margin = grid::unit(c(0,0,0,0), "mm"),
          legend.title=element_text(size=14), 
          legend.text=element_text(size=12))   
  
  # Set title if not null
  if (!is.null(ggtitle))  p <- p + ggtitle(ggtitle)
  
  # Set text if not null
  if (!is.null(text)) p <- p + annotate("text", label = text, x = text.x, y = text.y, size = text.size, colour = "black")
  
  # Plot contour if not null
  if (!is.null(contour)) p <- p + geom_polygon(data = contour,
                                               aes(x = long, y = lat, group = group), colour="black", fill=NA, size = 0.5)
  
  return(p)
  
}
#----------------------------------------------------------------------

#----------------------------------------------------------------------
# plotrasterDis     Plot raster map for discrete values
#----------------------------------------------------------------------
plotrasterDis <- function(r, land, box, palette = 'Spectral', ggtitle = NULL, 
                          colors=NULL, breaks = NULL, labels = NULL,
                          limits = NULL, legendTitle = NULL, legend.position = "right",
                          text = NULL, text.x = NULL, text.y = NULL, text.size = NULL,
                          contour = NULL){
  # r               Raster map
  # land            Land mask
  # box             World box
  # palette         Color palette
  # limits          Set limits to display. Vector with two values.
  # legendTitle     If not null, set legend title
  # ggtitle         If not null, set plot title
  # legend.position Position of legend if legendTitle not null
  # text            If not null, set text
  # contour         Spatial polygon
  #
  # helpful links:
  # https://seethedatablog.wordpress.com/2016/12/26/mapping-cities-some-tweaks-with-ggplot-and-ggrepel/
  # multiplot() http://www.cookbook-r.com/Graphs/Multiple_graphs_on_one_page_(ggplot2)/
  
  
  library(ggplot2)
  
  if (is.null(limits)) limits <- c(min(minValue(r)), max(maxValue(r)))
  
  
  p <- rasterVis::gplot(r) +
    # Add raster layer  
    geom_raster(aes(fill=as.character(value))) +
    
    # Set raster palette and legend header
    # scale_fill_distiller(
    #   type = 'seq', palette = 'Spectral',
    #   name = legendTitle, na.value='white') +
    
    # scale_fill_distiller(
    #   type = 'div', palette = palette,
    #   name = legendTitle, na.value='white',
    #   limits = limits) +#,
    # #breaks= limits, labels=round(limits, 1)) +
  
  scale_fill_manual(values = colors,
                    breaks = breaks,
                    labels = labels,
                    name= legendTitle) +
    
    # Add projected countries (land)
    geom_polygon(data = land, 
                 aes(long,lat, group = group), 
                 colour = "grey70", fill = "grey70", size = .25) +  # change from grey 70 to grey 90
    
    # # Add projected bounding box (box)
    geom_polygon(data = box,
                 aes(x = long, y = lat),
                 colour = "grey70", fill = "transparent", size = .25) +
    
    # Set aspect ratio
    # the default, ratio = 1 in coord_fixed ensures that one unit on the x-axis is the same length as one unit on the y-axis
    coord_fixed(ratio = 1) +
    
    # Set empty theme
    theme_void() + # remove the default background, gridlines & default gray color around legend's symbols
    
    # Set them options
    theme(legend.position = legend.position, #"none", "bottom"
          plot.title = element_text(hjust = 0.5),
          plot.margin = grid::unit(c(0,0,0,0), "mm"),
          legend.title=element_text(size=14), 
          legend.text=element_text(size=12))   
  
  # Set title if not null
  if (!is.null(ggtitle))  p <- p + ggtitle(ggtitle)
  
  # Set text if not null
  if (!is.null(text)) p <- p + annotate("text", label = text, x = text.x, y = text.y, size = text.size, colour = "black")
  
  # Plot contour if not null
  if (!is.null(contour)) p <- p + geom_polygon(data = contour,
                                               aes(x = long, y = lat, group = group), colour="black", fill=NA, size = 0.5)
  
  return(p)
  
}
#----------------------------------------------------------------------


#----------------------------------------------------------------------
# unsamp2         Calculate unsampled cells, but differentiate between undersampled(1) and unsampled(2)
#----------------------------------------------------------------------
unsamp2 <- function(r, mask){
  # Arguments:
  # r             raster of profile densities
  # mask          raster of ocean mask
  #
  # Description:
  # This function calculates and combines undersampled cells with unsampled cells.
  # Undersampled cells are defined as those containing the 20 percentile from the accumulated
  # distribution of number of profiles.
  # Unsampled cells are define as those cells were there were any profile.
  
  ## Extract the undersampled cells (20th percentile)
  q20 <- quantile(r, probs = c(0.20), type=7, na.rm=TRUE, names = FALSE)
  runder <- cut(r, breaks=c(0, q20))  # set q20 cells equal to 1.
  
  ## Extract unsampled cells (no profiles)
  runder[is.na(r)]<-2  # set cells wihtout profiles equal to 2
  runsamp <- runder * mask  # filter out cells that are not ocean
  return(runsamp)
}
#----------------------------------------------------------------------


#----------------------------------------------------------------------
# zonalLatitude         Calculate zonal statistic for raster by latitude
#----------------------------------------------------------------------
zonalLatitude <- function(r, fun="sum"){
  yzone <- init(r, v="y")
  z <- zonal(r, yzone, fun, digits=1, na.rm=TRUE)
}
#----------------------------------------------------------------------
