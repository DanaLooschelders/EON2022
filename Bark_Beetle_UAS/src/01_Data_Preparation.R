#######################################################
# Bark_Beetle_UAS: Detection of bark beetle infestation in
# spruce plantations using multispectral drone images
#
# 01 Data Preparation
# Forest Inventory and Remote Sensing
# University Göttingen
# Dr. Hans Fuchs
# hfuchs@gwdg.de
#######################################################

# set working directory
# adapt to your local directory where the project is stored.
wd = "~/Bark_Beetle_UAS"
setwd(wd)

#######################################################
# Installing packages
#######################################################

if (!require("raster")) install.packages("raster")
if (!require("rgdal")) install.packages("rgdal")
if (!require("RStoolbox")) install.packages("RStoolbox")
if (!require("mapviev")) install.packages("mapview")
if (!require("skimr")) install.packages("skimr")
if (!require("devtools")) install.packages("devtools")
if (!require("randomForest")) install.packages("randomForest")
if (!require("MLmetrics")) install.packages("MLmetrics")
if (!require("reshape")) install.packages("reshape")
if (!require("stars")) install.packages("stars")

#######################################################
# Importing libraries
#######################################################

library(raster)
library(rgdal)

#######################################################
# Download and quality check of multiband UAS ortho image
#######################################################

tf = tempfile()
url = "https://owncloud.gwdg.de/index.php/s/IBMuTMMnsAkDs1R/download"

# on Windows use:
download.file(url, tf, method = 'wininet', mode = 'wb')

# on other OS use:
# download.file(url, tf,mode = 'wb')

files = unzip( tf , exdir = "./data" )
# here are your files:
files

UAS_image_blue_band1 = raster("./data/subset_RedEdge_Mission.tif", band = 1)

# create a grayscale color palette to use for the image.
grayscale_colors = gray.colors(100,            # number of different color levels 
                                start = 0.0,    # how black (0) to go
                                end = 1.0,      # how white (1) to go
                                gamma = 2.2,    # correction between how a digital 
                                # camera sees the world and how human eyes see it
                                alpha = NULL)   #Null=colors are not transparent

# Plot band 1
plot(UAS_image_blue_band1, 
     col=grayscale_colors, 
     axes=FALSE,
     main="UAS Image Blue Band 1 Altenau")

# view attributes
UAS_image_blue_band1

# min and max values
minValue(UAS_image_blue_band1)
maxValue(UAS_image_blue_band1)

# Use stack function to read in all bands of a multiband file
UAS_image = stack("./data/subset_RedEdge_Mission.tif")

# view attributes of stack object
UAS_image

# view attributes of raster
UAS_image@layers

# view attributes for first band
UAS_image[[1]]

# view histogram of all 6 bands
hist(UAS_image, maxpixels=ncell(UAS_image))

# plot all 6 bands separately
plot(UAS_image, col=grayscale_colors)

# remove transparency band = 6 from stack
UAS_image = dropLayer(UAS_image, 6)
nlayers(UAS_image)

# Standard true color composite
plotRGB(UAS_image,
        r = 3, g = 2, b = 1, 
        scale=800,
        stretch = "lin")

# Standard false color composite
plotRGB(UAS_image,
        r = 5, g = 3, b = 2, 
        scale=800,
        stretch = "lin")

# False color composite with rededge
plotRGB(UAS_image,
        r = 4, g = 2, b = 3, 
        scale=800,
        stretch = "lin")

#######################################################
# Reducing data size by resampling from 9cm to 18cm 
# pixel size and saving as GTiff
#######################################################

UAS_image = aggregate(UAS_image,2)
raster::writeRaster(UAS_image, file='./data/UAS_image.tif',overwrite=T,progress='text')

# clear up memory
rm(list = ls())
gc()

