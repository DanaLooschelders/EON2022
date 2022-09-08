rm(list=ls())
library(raster)
library(viridis)
library(bfast)

setwd("/home/hanna/Documents/Lehre/Kurse/2022_Sose/ExkursionHarz/timeseries_Modis/")
dat <- stack("Modis_crop.tif")

dat <- crop(dat,c(721812,743068,5743189,5764888))
dat <- dat*0.00000001

#########################################################
#Spatial trend analysis
#########################################################
#install.packages("greenbrown", repos="http://R-Forge.R-project.org")
library(greenbrown)

trend <- TrendRaster(dat, start = c(2003, 1), 
                     freq = 23, method="STM")
plot(trend)

spplot(trend$SlopeSEG1,main="SlopeSEG1")


### Only look at significant trends:
mask <- trend$SlopeSEG1
mask[trend$PvalSEG1>0.05] <- NA
masked_trend <- mask(trend$SlopeSEG1,mask)
spplot(masked_trend)
mapview(masked_trend)

writeRaster(masked_trend, filename = "trend.tif",overwrite=TRUE)

#########################################################
#Inspect single pixel location
#########################################################
#1) Pixel with highest negative trend:
mostnegchange <- dat[which(values(masked_trend)==min(values(masked_trend),na.rm=T))]
datats <- ts(as.vector(mostnegchange),frequency=23,start=c(2003,1))
ts_bf <- bfast(datats,season="harmonic",max.iter = 1)
plot(ts_bf)


### or use greenbrown for it
plot(TrendSTM(datats,breaks=0))


