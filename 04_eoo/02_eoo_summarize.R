#------------------------------------------------------------------------------------------
# 02_eoo_summarize.R       Summarize rasterized EOO maps at the taxonomic group level
#------------------------------------------------------------------------------------------
#
# This script summarizes the number of species per taxonomic group.
# The number of species for each taxon were then normalized by rescaling from zero to one,
# and averaged across taxa by cell for all taxa.
#
# Input:
# - Species list with link to shapefiles
# - Ocean mask
# - It also requires having created the raster map for each species
#
# Output:
# - Single raster map per taxonomic group (output product)


## Load libraries
library(raster)
source("R/data_paths.R")

## Import species list
match <- read.csv(spp_list_group)

## Import ocean mask
mask <- raster(temp_mask)


#---------------------------------------------------------------------------
# 1. Aggregate number of species by taxonomic group
#---------------------------------------------------------------------------

## Loop over each class
class <- unique(match$group)

for (k in 1:length(class)){ 
  
  # select species from each group
  kmatch <- match[match$group %in% class[k],]
  
  # list files within class
  ids <- kmatch$taxonid
  rfiles <- c()
  for (f in 1:length(ids)){
    pat <- paste0("^", ids[f], ".nc")
    file <- list.files(eoo_tempdir, recursive=TRUE, pattern=pat, full.names=TRUE)
    rfiles <- c(rfiles, file)
  }
  
  # Create a stack with all files
  s <- stack(rfiles)
  
  ## Calculate number of species per cell
  sum_grd <- sum(s, na.rm=TRUE)
  sum_grd[sum_grd == 0] <- NA
  
  ## Overlap with ocean mask
  sum_grd <- sum_grd * mask
  
  # save raster with species distribution per class
  outfile <- paste0(eoo_dir, "/", class[k], ".nc")
  writeRaster(sum_grd, filename=outfile,  format="CDF", overwrite=TRUE)
}