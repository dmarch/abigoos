#------------------------------------------------------------------------------------------
# 02_eoo_summarize.R       Summarize rasterized EOO maps at the taxonomic group level
#------------------------------------------------------------------------------------------
#
# This script summarizes the number of species per taxonomic group.
# The number of species for each taxon were then normalized by rescaling from zero to one,
# and averaged across taxa by cell for all taxa.


## Load libraries
library(raster)
source("R/data_paths.R")

## Import species list
match <- read.csv(spp_list_group)

## Import ocean mask
mask <- raster(temp_mask)


## Count number of species per cell for each taxonomic group
class <- unique(match$group)  # get group classes

for (i in 1:length(class)){
  
  print(i)
  
  ## Import grd files
  grdfile <- list.files(temp_dir, pattern=paste0(class[i], ".grd"), full.names=TRUE)
  grd <- stack(grdfile)
  
  ## Calculate number of species per cell
  sum_grd <- sum(grd, na.rm=TRUE)
  sum_grd[sum_grd == 0] <- NA
  
  ## Overlap with ocean mask
  sum_grd <- sum_grd * mask
  
  ## Export map as output product
  outfile <- paste0(eoo_dir, "/",class[i], ".nc")
  writeRaster(sum_grd, filename=outfile, format="CDF", overwrite=TRUE)
}

