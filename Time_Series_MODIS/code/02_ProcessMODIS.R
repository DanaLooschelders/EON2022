rm(list=ls())
library(raster)
library(viridis)
library(mapview)

# Path to the Processed MODIS data:
setwd("/home/hanna/Documents/Data/MODIS/PROCESSED/NDVI_Germany/")
outpath <- "/home/hanna/Documents/Lehre/Kurse/2022_Sose/ExkursionHarz/timeseries_Modis/"

# Load all MODIS data:
dat <- stack(list.files())

# crop to area of interest:
dat <- raster::crop(dat,c(690676,796816,5708670,5782856))


mapview(dat[[1]])
#save cropped data so that there is no need anymore to handle the full dataset
writeRaster(dat,paste0(outpath,"/Modis_crop.tif"))

# Visualize a single MODIS scene (note: unit is NDVI*0.0001):
spplot(dat[[1]]* 0.0001,col.regions=viridis(100))
spplot(dat[[1:10]])


#######
dat <- stack(list.files())
dat_final <- crop(dat[[1]],c(690676,796816,5708670,5782856))
for (i in 2:nlayers(dat)){
  dat1 <- raster::crop(dat[[i]],c(690676,796816,5708670,5782856))
 dat_final <- stack(dat_final,dat1)
 print(i)
}
writeRaster(dat_final,paste0(outpath,"/Modis_crop.tif"))

