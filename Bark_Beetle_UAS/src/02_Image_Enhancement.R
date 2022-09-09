######################################################
# ips-map: Detection of bark beetle infestation in
# spruce plantations using multispectral drone images
#
# 02 Image Enhancement
# Forest Inventory and Remote Sensing
# University Göttingen
# Dr. Hans Fuchs
# hfuchs@gwdg.de
#######################################################

# set working directory
# adapt to your local directory where the project is stored.
wd = "~/ips-map"
setwd(wd)

#######################################################
# References
# Marx, A. (2010): Erkennung von Borkenkaeferbefall 
# in Fichtenreinbestaenden mit multi-temporalen RapidEye 
# Satellitenbildern und Datamining-Techniken. PFG 2010/4, 243-252
#######################################################


#######################################################
# Importing libraries
#######################################################

library(raster)
library(rgdal)
library(RStoolbox)
library(mapview)


#######################################################
# Defining spectral index functions (s. Marx 2010)
#######################################################

RENDVI = function(re,nir){
  # Function to calculate the RedeEdge Normalized Vegetation Index (RENDVI)
  rendvi = (nir-re)/(nir+re)
  names(rendvi) = 'RENDVI'
  return(rendvi)
}

GNDVI = function(green,re){
  # Function to calculate the Green Normalized Vegetation Index (GNDVI)
  gndvi  = (re-green)/(re+green)
  names(gndvi) = 'GNDVI'
  return(gndvi)
}

RATIO = function(gndvi,rendvi){
  # Function to calculate the Ratio of vegetation indexes
  ratio = rendvi/gndvi
  names(ratio) = 'RATIO'
  return(ratio)
}

CGM = function(green,nir){
  # Function to calculate the Chlorophyll Green Model index
  cgm = (nir/green)-1
  names(cgm) = 'CGM'
  return(cgm)
}

CREM = function(re,nir){
  # Function to calculate the Chlorophyll RedEdge Model index
  crem = (nir/re) -1
  names(crem) = 'CREM'
  return(crem)
}

#######################################################
# Calculating spectral Indices
#######################################################

# Read the resampled multiband file with 5 bands as a brick 
UAS_image = raster::brick("./data/UAS_image.tif")
names(UAS_image) = c('blue','green','red','re','nir')
UAS_image
NAvalue(UAS_image) = 65535

# Calculate spectral indexes
rendvi = RENDVI(re=UAS_image$re,nir=UAS_image$nir)
gndvi = GNDVI(green=UAS_image$green,re=UAS_image$re)
ratio = RATIO(gndvi=gndvi,rendvi=rendvi)
cgm = CGM(green=UAS_image$green,nir=UAS_image$nir)
crem = CREM(re=UAS_image$re,nir=UAS_image$nir)

# Check results with interactive map
mapview(rendvi,legend=T)


#######################################################
# Create a new layer stack with all bands and export GTIFF
#######################################################

uas_vi = raster::stack(list(UAS_image,rendvi,gndvi,ratio,cgm,crem))
raster::writeRaster(uas_vi,
                    file='./data/UAS_VI.tif',
                    overwrite=T,progress='text')

# clear up memory
rm(list = ls())
gc()

