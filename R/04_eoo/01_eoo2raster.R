#------------------------------------------------------------------------------------------
# 01_eoo2raster.R       Rasterize extent of occurrence (EOO) maps
#------------------------------------------------------------------------------------------
#
# This script rasterizes extent of occurrence (EOO) maps per each of the identified species.
# We consider extent areas, and for species with separate subpopulation EOO maps,
# we combined all subpopulations to create a single global population.
# Once rasterized, we transform to Mollweide projection to conduct further analysis.
# The output of this script is a multiband raster in ".grd" format for each taxonomic group.
# Every layer of the raster represent one species, which has been labeled with the taxonid
# gathered from the IUCN API.


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

## Loop to rasterize EOO maps
class <- unique(match$group)

for (k in 1:length(class)){  # Loop for each taxonomic group
  
  print(paste("Processing group:", class[k]))
  
  # select species for next step
  # kmatch <- dplyr::filter(match, sp_class == class[k])
  kmatch <- match[match$group %in% class[k],]
  rclass <- stack()  # create stack
  
  # select shapefiles
  shps <- unique(kmatch$shp)
  
  for (i in 1:length(shps)){  # Loop for each shapefile (i.e. 1 taxonomic group can be related to >1 shapefile)
    
    shape_name <- as.character(shps[i])
    
    # Open shapefile
    ishpfile <- list.files(raw_dir, pattern=shape_name, recursive=TRUE, full.names=TRUE)[1]
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
    
    # Get number of species for that shapefile
    imatch <- filter(kmatch, shp == shape_name)
    
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
      
      # add to stack
      rclass <- stack(rclass, rpols)
    } # END LOOP: species
  } # END LOOP: shapefiles
  
  
  ## Reproject to Equal-Area projection (Mollweide)
  rclass.prj <-  projectRaster(from = rclass, to = mask)

  # save raster with species distribution per class
  outfile <- paste0(temp_dir, "/",class[k], ".grd")
  writeRaster(rclass.prj, filename=outfile, bandorder='BIL', overwrite=TRUE)
} # END LOOP: class