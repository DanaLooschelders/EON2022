######################################################
# ips-map: Detection of bark beetle infestation in
# spruce plantations using multispectral drone images
#
# 05 Validation Sampling
# Forest Inventory and Remote Sensing
# University Göttingen
# Dr. Hans Fuchs
# hfuchs@gwdg.de
#######################################################

# set working directory
# adapt to your local directory where the project is stored.
wd = "~/ips-map"
setwd(wd)


######################################################
# Importing libaries
#####################################################

library(sf)
library(stars)
library(raster)
library(dplyr)


#######################################################
# Prepare data
#######################################################
set.seed(123)

# Read the classified vector polygons
ThematicVectorLayer = st_read(dsn="./data/tree_polygons_classified_nn.gpkg")

# Define sampling frame
MaskVectorLayer = st_read(dsn="./data/subset_Extent_buf.gpkg")
SampleSize = 30  
ThematicRast = st_rasterize(ThematicVectorLayer["C_ID"], dx = 0.20, dy =0.20)

spdf = as_Spatial(MaskVectorLayer)
masked = mask(as(ThematicRast, "Raster"),spdf)

# Stratified random sampling with equal allocation for each class
valpoints = sampleStratified(masked, SampleSize, exp=10, na.rm=T, xy=T, sp=1)

ValidationPointLayer = st_as_sf(valpoints)
st_write(ValidationPointLayer, "./data/validation_points.gpkg", driver="GPKG", overwrite_layer=T)

# clear up memory
rm(list = ls())
gc()

