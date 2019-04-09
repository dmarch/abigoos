#-----------------------------------------------------------------------------------
# 01_turtle_obis.R   Summaryze telemetry data from OBIS-SEAMAP
#-----------------------------------------------------------------------------------
# 1. Summarize telemetry data
# Compare with Jeffers

## Load libraries
library(dplyr)
library(lubridate)
library(rgdal)
source("R/data_paths.R")


## Import data
df <- read.csv(seamap.turtle)  # OBIS-SEAMAP tagging info for each individual
mask <- raster(temp_mask)  # Import ocean mask
seavox <- readOGR(seavox_dir, seavox_shp)  # Ocean regions

#-------------------------------------
# 1. Summarize telemetry data
#-------------------------------------

## calculate new variable: tracking period (in days)
df$date_min <- parse_date_time(df$date_min, "Ymd HMS")
df$date_max <- parse_date_time(df$date_max, "Ymd HMS")
df$period <- as.numeric(round(difftime(df$date_max, df$date_min, units = "days")))

## Summarize data per species
out <- df %>%
  group_by(sp_scientific) %>%
  summarise(animals.tagged=n(),  # number of tagged animals
            total.records = sum(num_records, na.rm=TRUE),  # total number of records
            avg.records = mean(num_records, na.rm=TRUE),  # average number of records
            median.records = median(num_records, na.rm=TRUE),  # median number of records
            sd.records = sd(num_records, na.rm=TRUE),  # sd number of records
            total.travel_km = sum(travel_km, na.rm=TRUE),  # total distance travelled
            avg.travel_km = mean(travel_km, na.rm=TRUE),  # average distance travelled
            median.travel_km = median(travel_km, na.rm=TRUE),  # median distance travelled
            sd.travel_km = sd(travel_km, na.rm=TRUE),  # sd distance travelled
            total.period = sum(period, na.rm=TRUE),  # total period
            avg.period = mean(period, na.rm=TRUE),  # average period
            median.period = median(period, na.rm=TRUE),  # median period
            sd.period = sd(period, na.rm=TRUE))  # sd period

# calculate percentages
out$animals.tagged.percent <- round(out$animals.tagged/sum(out$animals.tagged)*100, digits=1)
out$total.records.percent <- round(out$total.records/sum(out$total.records)*100, digits=1)

# add species short codes
out$sp_code <- c("Cc", "Cm", "Dc", "Ei", "Lk", "Lo", "Nd")

## Export result
#write.table(out, "C:/data/goosturtles/output/seaturtle/animals_summary.csv", sep=";", dec=",", row.names=FALSE)


#-------------------------------------
# 2. Summarize data by ocean region
#-------------------------------------

## Substract land polygons
seavox <-  seavox[-grep("MAINLAND", seavox$REGION),]  # remove mainland regions
# levels(ocean$REGION)
# [1] "ARCTIC OCEAN"                             
# [2] "ASIAN MAINLAND"                           
# [3] "ATLANTIC OCEAN"                           
# [4] "BALTIC SEA"                               
# [5] "EUROPEAN MAINLAND"                        
# [6] "INDIAN OCEAN"                             
# [7] "MEDITERRANEAN REGION"                     
# [8] "NORTH AMERICA MAINLAND"                   
# [9] "PACIFIC OCEAN"                            
# [10] "SOUTH CHINA AND EASTERN ARCHIPELAGIC SEAS"
# [11] "SOUTHERN OCEAN"

## Create raster in longlat to use as base for rasterization
r <- raster(xmn=-180, xmx=180, ymn=-90, ymx=90, crs=CRS("+proj=longlat +ellps=WGS84"),
            resolution=c(1, 1), vals=NA)

## Rasterize seavox
rseavox <- rasterize(seavox, r, field="REGION")

## Overlap bounding box of each individual with the rasterized version of ocean regions
## Returns a data.frame with the number of overlapped cells with each ocean region.
data <- NULL
for (i in 1:nrow(df)){
  
  print(i)
  
  ## create bounding boxes (multipolygon data frame, geometry with species)
  xmin <- df$lon_min[i]
  xmax <- df$lon_max[i]
  ymin <- df$lat_min[i]
  ymax <- df$lat_max[i]
  if (xmin == xmax | ymin == ymax) next
  e <- extent(xmin, xmax, ymin, ymax)
  
  ## Overlap with regions
  ov <- extract(rseavox, e)
  
  ## Calculate degree of overlap with ocean regions
  f <- factor(ov, levels=unique(rseavox))
  d <- data.frame(id=df$numeric_id[i], sp_scientific=df$sp_scientific[i], table(f))
  
  ## Convert to data.frame and append to data.frame with all tags
  dc <- dcast(d, id + sp_scientific ~f)
  data <- rbind(data, dc)
}
data$rowsum <- rowSums(data[,c(3:10)])  # calculate the total number of overlapped cells

## Calculate number  of tagged animals per region
## Consider presence in one region if at least one cell overlaps in that area
data[,c(3:10)][data[,c(3:10)]>0]<-1
percentage_per_region <- (colSums(data[,c(3:10)])/(nrow(data)-length(which(data$rowsum==0))))*100


#-------------------------------------
# 3. Compare OBIS data with Jeffers & Godley 2015
#-------------------------------------

df <- select(out, sp=sp_code, seamap=animals.tagged.percent)

# Add data from Jeffers & Godley (Figure 2a)
# Numbers here are extracted from the Figure
# Note that the order between species is different
df$papers <- c(35, 25, 18, 7, 5, 6.5, 1)  # papers are shaded bars
df$survey <- c(28, 24, 16, 13, 8, 10, 4)  # surveys are unshaded bars

# Plot results
dfm <- melt(df,id.vars = 1)  # prepare table

p <- ggplot(data=dfm, aes(x = sp, y = value, fill = variable)) +
  geom_bar(stat="identity", position=position_dodge())+
  scale_fill_manual(values = c("#c2a5cf", "#a6dba0", "#008837"))+
  xlab("")+
  ylab("Tagged animals (%)")+
  ylim(0, 55) +
  theme_bw() + 
  theme(legend.position = "none", legend.title=element_blank(),
        legend.background = element_rect(color = "white", fill = "white", size = 0.2, linetype = "solid"),
        panel.grid.major = element_blank(), panel.grid.minor = element_blank())

# Save as png file
p_png <- paste(fig_dir,"telemetry","jeffers_species.png", sep="/")
ggsave(p_png, p, width=10, height=9, units="cm", dpi=300)


#---------------------------------------------------
# Compare % of tracking per ocean region
#---------------------------------------------------

ocean <- c("Atl.", "Pac.", "Med.", "Ind.")
papers <- c(49, 25, 12, 10)  # papers are shaded bars
survey <- c(41, 30, 15, 12) 
seamap <- c(percentage_per_region["3"], percentage_per_region["9"],
            percentage_per_region["7"], percentage_per_region["6"])  # see values from ocean_regions_bbox
# 1           3           4           6           7 
# 0.00000000 52.60115607  0.10509721 21.17708881 11.45559643 
# 9          10          11 
# 25.32842880  5.72779821  0.05254861 
# [1] "ARCTIC OCEAN"                             
# [2] "ASIAN MAINLAND"                           
# [3] "ATLANTIC OCEAN"                           
# [4] "BALTIC SEA"                               
# [5] "EUROPEAN MAINLAND"                        
# [6] "INDIAN OCEAN"                             
# [7] "MEDITERRANEAN REGION"                     
# [8] "NORTH AMERICA MAINLAND"                   
# [9] "PACIFIC OCEAN"                            
# [10] "SOUTH CHINA AND EASTERN ARCHIPELAGIC SEAS"
# [11] "SOUTHERN OCEAN"

df <- data.frame(ocean, seamap, papers, survey)

# Plot results
dfm <- melt(df,id.vars = 1)  # prepare table

p <- ggplot(data=dfm, aes(x = ocean, y = value, fill = variable)) +
  geom_bar(stat="identity", position=position_dodge())+
  scale_fill_manual(values = c("#c2a5cf", "#a6dba0", "#008837"))+
  xlab("")+
  ylab("Proportion of tracking (%)")+
  ylim(0, 55) +
  theme_bw() + 
  theme(legend.position = c(0.8, 0.8), legend.title=element_blank(),
        legend.background = element_rect(color = "white", fill = "white", size = 0.2, linetype = "solid"),
        panel.grid.major = element_blank(), panel.grid.minor = element_blank())

# Save as png file
p_png <- paste(fig_dir,"telemetry","jeffers_ocean.png", sep="/")
ggsave(p_png, p, width=10, height=9, units="cm", dpi=300)
