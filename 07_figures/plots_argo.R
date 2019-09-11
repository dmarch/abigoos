#-----------------------------------------------------------------------------
# argo_plots.R  Plots and tables from Argo analysis
#------------------------------------------------------------------------------


## Load libraries
library(raster)
library(ggplot2)
library(stringr)
library(reshape2)
library(maptools)
library(rgdal)
source("R/utils.R")
source("R/data_paths.R")

## Create world bounding box in Mollweide
box <- bb(xmin = -180, xmax = 180, ymin = -90, ymax = 90, crs=PROJ)

## Import data
land.prj <- readOGR(temp_dir, temp_land)  # landmask
mask <- raster(temp_mask) # oceanmask
argo <- stack(argo_count) # argo counts per year
unders.argo <- stack(argo_gaps)
persistence <- raster(argo_gap_persistence)
coldspots <- raster(argo_coldspots)
coldspots_shp <- readShapePoly(argo_coldspots_shp)

## Set years to process
years <- 2005:2016

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
p_png <- paste(fig_dir,"argo","argo_density_all.png", sep="/")
ggsave(p_png, p, width=25, height=14, units="cm", dpi=300)


#------------------------------------------------
# Plot 2: Argo density on a yealy basis
#------------------------------------------------

# Calculate density (profiles / km2)
argoDensY <- argo / ((res(argo)[1]/1000)*(res(argo)[2]/1000))  # divide by km2

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
  p_png <- paste0(fig_dir,"/argo/","argo_density_",year, ".png")
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
# Plot 4: Surface of sampling gaps by type
#------------------------------------------------

## Calculate % of surface  by unsampled and undersampled.
df <- data.frame(year=years, unsampled=NA, undersampled=NA)

## Loop for each year
for (i in 1:nlayers(unders.argo)){

  ## Extract raster
  r <- subset(unders.argo,i)

  ## Get number of cells by type
  df$undersampled[i] <- table(values(r))[1]
  df$unsampled[i] <- table(values(r))[2]
}

## Calculate the sum between unsampled and undersampled
df$gap <- rowSums(df[,c(2,3)])

## Temporal plot
dfm <- melt(df, id.vars="year", measure.vars=c("unsampled", "undersampled"))

## stacked area plot better represents proportion and total gaps surface
ylab <- expression(Argo~surface~gap~(x10^4~km^2))
fill <- c("#40b8d0", "#b2d183")
p <- ggplot(dfm, aes(x = year, y = value, fill = variable)) + 
  geom_area(aes(fill=variable), position = position_stack(reverse = T))+ 
  scale_x_continuous(breaks=seq(2005,2016,1), expand = c(0, 0)) +
  scale_y_continuous(expand = c(0, 0)) +
  scale_fill_manual(values=fill, labels=c("Un-sampled", "Under-sampled")) +
  labs(x = "Year", y = ylab) +
  theme_bw() + 
  theme(legend.position = c(0.8, 0.2), legend.title=element_blank(),
        plot.margin = margin(0.5, 0.5, 0.5, 0.5, "cm"),
      legend.background = element_rect(color = "black", fill = "white", size = 0.2, linetype = "solid"),
      panel.grid.major = element_blank(), panel.grid.minor = element_blank())

# Save as png file
p_png <- paste(fig_dir,"argo","unsamp_undersamp_area.png", sep="/")
ggsave(p_png, p, width=15, height=10, units="cm", dpi=300)



#------------------------------------------------
# Plot 5: Map of sampling gaps
#------------------------------------------------

unders.argo <- setZ (unders.argo, years)

## Loop for each year
for (i in 1:nlayers(unders.argo)){

  ## Extract raster
  r <- subset(unders.argo,i)
  year <- getZ(unders.argo)[i]
  
  ## Make plot
  p <- plotrasterDis(r = r, land = land.prj, box = box,
                     colors = c("1" = "#b2d183", "2" = "#40b8d0"),
                     labels = c("Under-sampled", "Un-sampled"),
                     text = year, text.x = 7000000, text.y = 5000000, text.size = 15,
                     breaks = 1:2,
                     legendTitle = "Gap cells", legend.position = "none")
  
  
  p <- p + geom_polygon(data = land.prj, 
                        aes(long,lat, group = group), 
                        colour = "grey10", fill = "transparent", size = .25) 
  
  # Save as png file
  p_png <- paste0(fig_dir,"/argo/","argo_gaps_",year, ".png")
  ggsave(p_png, p, width=25, height=14, units="cm", dpi=300)
}



#------------------------------------------------
# Plot 6: Gap persistence
#------------------------------------------------

# Reclassify raster to discrete class
m <- c(-Inf,0.2,1, 0.2,0.4,2, 0.4,0.6,3, 0.6,0.8,4, 0.8,Inf,5)
pers <- reclassify(persistence, m) 
pers <- pers * mask

# Create plot
# Note: change colors for land mask from utils.R
p <- plotrasterDis(r = pers, land = land.prj, box = box,
                   colors = c("1" = "#eff3ff", "2" = "#bdd7e7", "3" = "#6baed6", "4" = "#3182bd", "5" = "#08519c"),
                   labels = c("0-20%", "20-40%", "40-60%", "60-80%", "80-100%"),
                   breaks = 1:5,
                   legendTitle = "Gap persistence")

p <- p + geom_polygon(data = land.prj, 
                      aes(long,lat, group = group), 
                      colour = "grey10", fill = "transparent", size = .25) 

# Save as png file
p_png <- paste(fig_dir,"argo","gap_persistency.png", sep="/")
ggsave(p_png, p, width=25, height=14, units="cm", dpi=300)



#------------------------------------------------
# Plot 7: Coldspots
#------------------------------------------------

# set output file and open device
p_png <- paste(fig_dir,"argo","coldspot.png", sep="/")
png(p_png , width=25, height=14, units="cm", res=300)

# plot
plot(coldspots, col=c("#4393c3") , axes=FALSE, box=FALSE, legend=FALSE)
plot(coldspots_shp, col= "transparent", border= "grey40", lwd=0.01, add=TRUE) #border=NA
plot(land.prj, col= "grey80", border= "grey40", lwd=0.01, add=TRUE) #border=NA
plot(box, border= "grey70", add=TRUE)

# close device
dev.off()


#------------------------------------------------
# Plot 8: Coldspots per latitude
#------------------------------------------------

df <- read.csv(coldspots_latitude_csv)
dfm <- melt(df, id.vars="latitude", measure.vars=c("coldspot_surface"))
colour <- c("red")

ylab = expression(Coldspot~surface~(x10^4~km^2))

p <- ggplot(dfm, aes(x = latitude, y = value, colour = variable)) +
  geom_line(size=1) + 
  scale_x_continuous(limits=c(-90,90), breaks=seq(-90,90,30)) +
  scale_y_continuous(breaks=seq(0,180,20)) +
  scale_colour_manual(values=colour, labels=c("Unsamp")) +
  labs(x = "Latitude", y = ylab) +
  theme_bw() + 
  theme(legend.position="none",
        panel.grid.major = element_blank(), panel.grid.minor = element_blank())

# Save as png file
p_png <- paste(fig_dir,"argo","coldspot_by_latitude.png", sep="/")
ggsave(p_png, p, width=13, height=7, units="cm", dpi=300)





#------------------------------------------------
# Plot 9: Coldspots per bathymetry
#------------------------------------------------

df <- read.csv(coldspots_bathymetry_csv)

dfm <- melt(df, id.vars="bathymetry", measure.vars=c("coldspot_surface"))
colour <- c("red")

ylab = expression(Coldspot~surface~(x10^4~km^2))

p <- ggplot(dfm, aes(x = bathymetry, y = value, colour = variable)) +
  geom_line(size=1) + 
  scale_x_continuous(limits=c(0,7200), breaks=seq(0,7200,1000)) +
  scale_y_continuous(breaks=seq(0,3000,500)) +
  scale_colour_manual(values=colour, labels=c("Unsamp")) +
  labs(x = "Bathymetry (m)", y = ylab) +
  theme_bw() + 
  theme(legend.position="none",
        panel.grid.major = element_blank(), panel.grid.minor = element_blank())

# Save as png file
p_png <- paste(fig_dir,"argo","coldspot_by_bathymetry.png", sep="/")
ggsave(p_png, p, width=13, height=7, units="cm", dpi=300)

