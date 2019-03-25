#-----------------------------------------------------------------------------
# argo_plots.R  Plots and tables from Argo analysis
#------------------------------------------------------------------------------


## Load libraries
library(raster)
library(ggplot2)
library(stringr)
source("R/utils.R")
source("R/data_paths.R")

## Create world bounding box in Mollweide
box <- bb(xmin = -180, xmax = 180, ymin = -90, ymax = 90, crs=PROJ)

## Import data
land.prj <- readOGR(temp_dir, temp_land)  # landmask
mask <- raster(temp_mask) # oceanmask
argo <- stack(argo_count) # argo counts per year


#------------------------------------------------
# Plot 1: Argo density for the 2005-2016 period
#------------------------------------------------

# Calculate density (profiles / km2)
argoSum <- sum(argo, na.rm=TRUE)
argoSum[argoSum==0]<-NA
argoSum <- argoSum * mask
argoDens <- argoSum / ((res(argoSum)[1]/1000)*(res(argoSum)[2]/1000))

# Create plot
p <- plotraster(r = log10(argoDens), land = land.prj, box = box,
                legendTitle = expression(log[10]~(profiles / km^2)))

# Save as png file
p_png <- paste(fig_dir,"argo","argo_map_all.png", sep="/")
ggsave(p_png, p, width=25, height=14, units="cm", dpi=300)


#------------------------------------------------
# Plot 2: Argo density on a yealy basis
#------------------------------------------------

# Calculate density (profiles / km2)
argoDensY <- argo / ((res(argo)[1]/1000)*(res(argo)[2]/1000))  # divide by km2
years <- as.numeric(str_extract(names(argoDensY), "\\d{4}"))

# Fix legend limits
vmin <- log10(min(minValue(argoDensY)))
vmax <- log10(max(maxValue(argoDensY)))
b <- c(vmin, vmax)  

## Loop for each year
for (i in 1:nlayers(argoDensY)){
  
  print(paste("plot", i, "from", nlayers(argoDensY)))
  
  ## Extract raster
  r <- subset(argoDensY,i)
  year <- years[i]
  
  ## Make plot
  p <- plotraster(r = log10(r), land = land.prj, box = box, limits =  b,
                  legend.position = "bottom",
                  text = year, text.x = 7000000, text.y = 5000000, text.size = 15,
                  legendTitle = expression(log[10]~(profiles / km^2)))
  
  # Save as png file
  p_png <- paste0(fig_dir,"/argo/","argo_map_",year, ".png")
  ggsave(p_png, p, width=25, height=14, units="cm", dpi=300)
}


#------------------------------------------------
# Plot 3: Coefficient of Variation
#------------------------------------------------

## set NA values to 0
fun <- function(x) { x[is.na(x)] <- 0; return(x)} 
argo0 <- calc(argoDensY, fun)

## remove land cells using a ocean mask
argom <- argo0 * mask

## calculate coefficient of variation (CV)
u <- mean(argom, na.rm=TRUE)
s <- calc(argom, fun=sd, na.rm=TRUE)
cv <- s/u

# Create plot
p <- plotraster(r = cv, land = land.prj, box = box,
                legendTitle = "CV")

# Save as png file
p_png <- paste(fig_dir,"argo","cv_argo.png", sep="/")
ggsave(p_png, p, width=25, height=14, units="cm", dpi=300)


#------------------------------------------------
# Plot 4: Gap persistence
#------------------------------------------------



#------------------------------------------------
# Plot 5: Coldspots
#------------------------------------------------


