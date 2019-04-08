#------------------------------------------------------------------------------------------
# 01_eoo2raster.R       Rasterize extent of occurrence (EOO) maps
#------------------------------------------------------------------------------------------
#
# This script rasterizes extent of occurrence (EOO) maps per each of the identified species.
# We consider extent areas, and for species with separate subpopulation EOO maps,
# we combined all subpopulations to create a single global population.
# Once rasterized, we transform to Mollweide projection to conduct further analysis.
# The output of this script is a raster in ".nc" format for each species.
# Every layer of the raster represent one species, which has been labeled with the taxonid
# gathered from the IUCN API.
#
# Input:
# - Species list with link to shapefiles
#
# Output:
# - Single raster map per species (temp product)
# - Single raster map per taxonomic group (output product)


## Load libraries
library(raster)
library(maptools)
library(dplyr)
source("R/data_paths.R")

## Import species list
match <- read.csv(spp_list_group)

## Import ocean mask
mask <- raster(temp_mask)

## Create raster in longlat to use as base for rasterization
r <- raster(xmn=-180, xmx=180, ymn=-90, ymx=90, crs=CRS("+proj=longlat +ellps=WGS84"),
            resolution=c(1, 1), vals=NA)

#---------------------------------------------------------------------------
# 1. Rasterize at species level
#---------------------------------------------------------------------------

## Loop over each shapefile
## It avois openning large shapefiles on multiple ocassions, which results in faster processing
shps <- unique(match$shp)

for (i in 1:length(shps)){  # Loop for each shapefile
  
  shape_name <- as.character(shps[i])
  print(paste("Processing", shape_name))
  
  # Open shapefile
  ishpfile <- list.files(c(iucn_shp, birdlife_shp, swot_shp), pattern=shape_name, recursive=TRUE, full.names=TRUE)[1]
  ishp <- readShapePoly(ishpfile)
  
  # Select Extant polygons
  if (shape_name  %in% c("MARINE_MAMMALS.shp", "CHONDRICHTHYES.shp", "TUNAS_BILLFISHES.shp")){
    sel <- which(ishp$presence == 1)  # only keep Extant areas (see Metadata for codes)
    ishp <- ishp[sel,]
  }
  
  if (shape_name  == "BOTW_telemetry.shp"){
    sel <- which(ishp$PRESENCE == 1)  # only keep Extant areas (see Metadata for codes)
    ishp <- ishp[sel,]
  }
  
  # Get the species from the selected shapefile
  imatch <- filter(match, shp == shape_name)
  
  for (j in 1:nrow(imatch)){  # Loop for each species of the shapefile
    
    print(paste("Processing species", j, "from", nrow(imatch)))
    
    # select polygons for species (j)
    itaxonid <- imatch$taxonid[j]
    
    if (imatch$shp_type[j] == "rmu"){
      pols <- ishp
    }
    
    if (imatch$shp_type[j] == "iucn"){
      iFID <- which(ishp@data$id_no %in% itaxonid)
      pols <- ishp[iFID,]
    }
    
    if (imatch$shp_type[j] == "birdlife"){
      iFID <- which(ishp@data$SISID %in% itaxonid)
      pols <- ishp[iFID,]
    }
    
    # rasterize polygons
    rpols <- rasterize(pols, r)
    rpols <- rpols/rpols
    names(rpols) <- itaxonid
    
    ## Reproject to Equal-Area projection (Mollweide)
    rpols.prj <-  projectRaster(from = rpols, to = mask)
    
    # save raster with species distribution per class
    outfile <- paste0(eoo_tempdir, "/", itaxonid, ".nc")
    writeRaster(rpols.prj, filename=outfile,  format="CDF", overwrite=TRUE)
    
  } # END LOOP: species
} # END LOOP: shapefiles