rm(list=ls())

remotes::install_github("fdetsch/MODIS")
library(MODIS)

#EarthdataLogin() # urs.earthdata.nasa.gov download MODIS data from LP DAAC

lap = "/home/hanna/Documents/Data/MODIS/"
MODISoptions(lap, outDirPath = file.path(lap, "PROCESSED")
             , MODISserverOrder = c("LPDAAC", "LAADS"), quiet = TRUE)

### download data
getHdf("MOD13Q1",begin = "2003.01.01", end = "2022.09.06",
       tileH = 18, tileV = 3)

### process data (extract NDVI only)
runGdal(job="NDVI_Germany","MOD13Q1",begin = "2003.01.01", end = "2022.09.06",
        tileH = 18, tileV = 3
        , SDSstring = "100000000000")
