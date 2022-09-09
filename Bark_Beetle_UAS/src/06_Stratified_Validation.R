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
# References
#####################################################

# Stephen V. Stehman, Giles M. Foody: Key issues in rigorous accuracy assessment of land cover products,
# Remote Sensing of Environment,Volume 231,2019,111199,ISSN 0034-4257, https://doi.org/10.1016/j.rse.2019.05.018
#
# Olofsson, P., Foody, G. M., Herold, M., Stehman, S.V., Woodcock, C. E. and Wulder, M. A.: 
# Good practices for estimating area and assessing accuracy of land change. 
# Remote Sensing of Environment,Volume 148, 2014, ISSN 0034-4257, http://dx.doi.org/10.1016/j.rse.2014.02.015
#
# Antonia Ortmann, 2017: Stratified sampling tool for area estimation. https://github.com/openforis/accuracy-assessment


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

ConfidenceInterval = 95
alpha = (100 - ConfidenceInterval)/100

# Read the classified vector polygons
ThematicVectorLayer = st_read(dsn="./data/tree_polygons_classified_nn.gpkg")
ReferenceField = "ref"
MapField = ""

# Define sampling frame
MaskVectorLayer = st_read(dsn="./data/subset_Extent_buf.gpkg")

ThematicRast = st_rasterize(ThematicVectorLayer["C_ID"], dx = 0.20, dy =0.20)

spdf = as_Spatial(MaskVectorLayer)
masked = mask(as(ThematicRast, "Raster"),spdf)

# Read the validation points with ground truth classes in column "ref"
ValidationPointLayer = st_read(dsn="./data/validation_points_interpreted.gpkg")


accuracy.stratified<-function(cm, area, alpha, classnames) {
  #convert both data frames and vectors to matrices
  cmx = as.matrix(cm)
  #try to convert a vector to a square matrix
  if (ncol(cmx) == 1)
     cmx = matrix(cmx, byrow=TRUE, nrow=sqrt(nrow(cmx)))
   nr<-nrow(cmx); nc<-ncol(cmx)
   if (nr != nc)
  { print("Error: matrix is not square"); break }
 
  #Naive accuracies
  n = sum(cmx)
  naive.oa = sum(diag(cmx))/n * 100 # naive overall accuracy
  naive.ua = round(as.vector(diag(cmx) / rowSums(cmx) * 100),1) # naive user's accuracy 
  Wk.prop = round(Wk * 100, 1)
  naive.pa = round(as.vector(diag(cmx) / colSums(cmx) *100),1) # naive producer's accuracy
  
  n.k = as.vector(colSums(cmx)) # sample column totals
  nk. = as.vector(rowSums(cmx)) # sample row totals

  cmdf = as.data.frame(cbind(cmx, nk., naive.ua, Wk.prop))
  np = as.data.frame(rbind(n.k, naive.pa))
  colnames(np) = classnames
  errorma.naive = bind_rows(cmdf, np)
  errorma.naive["n.k","nk."] = sum(nk.)

  print("-----------------------------------------")
  p1 = sprintf("Naive overall accuracy: %.1f", round(naive.oa,1))
  p2 = sprintf("Sample n: %1.0f", round(n,1))
  print(p1)
  print(p2)
  print("Naive error matrix in terms of sample counts, rows= Map, columns= Reference") # Table 4 in Stehman and Foody 2019
  print(errorma.naive)
  print("-----------------------------------------")


  #Calculate the area proportions
  proportions = function(cm, Wi){
  propma<-matrix(nrow=nrow(cm),ncol=ncol(cm))
    for (i in 1:ncol(cm)){
      propma[,i]=(cm[,i]/rowSums(cm))*Wi
    }
  return(propma)
  }

  propma = proportions(cmx,Wk)
  colnames(propma) = rownames(propma)<-colnames(cmx)
  propma[is.nan(propma)] = 0 # for classes with nk. = 0

  # Stratified random accuracies (adapted code from Antonia Ortmann)
  oa.strat = sum(diag(propma)) # overall accuracy (Eq. 13 in Stehman and Foody 2019)
  ua.strat = diag(propma) / rowSums(propma) # user's accuracy (Eq. 14 in Stehman and Foody 2019)
  pa.strat = diag(propma) / colSums(propma) # producer's accuracy (Eq. 15 in Stehman and Foody 2019)

  # Stratified random variance
  oav.strat = sum(Wk^2 * ua.strat * (1 - ua.strat) / (nk. - 1), na.rm=T)  # variance of overall accuracy (Eq. 16 in Stehman and Foody 2019)
  uav.strat = ua.strat * (1 - ua.strat) / (rowSums(cmx) - 1) # variance of user's accuracy (Eq. 17 in Stehman and Foody 2019)

  # Variance of producer's accuracy (Eq. 18 in Stehman and Foody 2019)
  N.j = array(0, dim=length(classnames))
  aftersumsign = array(0, dim=length(classnames))
  for(cj in 1:length(classnames)) {
    N.j[cj] = sum(maparea$count / nk. * cmx[, cj], na.rm=T)
    aftersumsign[cj] = sum(maparea$count[-cj]^2 * cmx[-cj, cj] / nk.[-cj] * ( 1 - cmx[-cj, cj] / nk.[-cj]) / (nk.[-cj] - 1), na.rm = T)
    }
  pav.strat = 1/N.j^2 * ( 
    maparea$count^2 * (1-pa.strat)^2 * ua.strat * (1-ua.strat) / (nk.-1) + 
      pa.strat^2 * aftersumsign
  ) 
  pav.strat[is.nan(pav.strat)] = 0

  # Estimate area                                 
  # proportional area estimation
  propAreaEst = colSums(propma) # proportion of area (Eq. 19 in Stehman and Foody 2019)
  AreaEst = propAreaEst * sum(maparea$area.ha) # estimated area
  # standard errors of the area estimation (Eq. 20 in Stehman and Foody 2019)
  propAreaEst.v = array(0, dim=length(classnames))
  for (cj in 1:length(classnames)) {
  propAreaEst.v[cj] = sum((Wk * propma[, cj] - propma[, cj] ^ 2) / ( rowSums(cmx) - 1))
  }
  propAreaEst.v[is.na(propAreaEst.v)] = 0

  # prepare stratified error matrix
  oa.prop = round(oa.strat * 100, 1) # Overall_accuracy 
  oa.se = round(sqrt(oav.strat) *100,1) # Overall accuracy standard error
  oaul = oa.prop+(qnorm(1-(alpha/2))*(sqrt(oav.strat))*100) # Upper limit of the overall accuracies based on the confidence level of 1-Alpha
  oall = oa.prop-(qnorm(1-(alpha/2))*(sqrt(oav.strat))*100) # Lower limit of the overall accuracies based on the confidence level of 1-Alpha
  area.prop = round(rowSums(propma) * 100,1) # area proportion based on pixel counting
  ua.prop = round((ua.strat * 100), 1) # User's accucary for each class
  ua.se = round(sqrt(uav.strat) *100,1) # Standard error of User's accucary for each class 
  pa.prop = round((pa.strat * 100), 1) # Producer accucary for each class after adjusting area bias
  pa.se = round(sqrt(pav.strat) *100,1) # Standard error for the weighted Producer accucary for each class after adjusting area bias

  errorma.strat = as.data.frame(cbind(round(propma * 100,1),area.prop, ua.prop, ua.se, nk.))
  totalArea.prop = round(propAreaEst * 100, 1) # Error adjusted map proportion for each class
  totalArea.se = round(sqrt(propAreaEst.v) * 100, 1) # Standard error for the error adjusted map proportions.
  npp = as.data.frame(rbind(totalArea.prop, totalArea.se, pa.prop, pa.se, n.k))
  errorma.strat = bind_rows(errorma.strat,npp)
  print("")
  print("")
  print("-----------------------------------------")
  p3 = sprintf("Estimated (stratified random) overall accuracy is %.1f", oa.prop)
  p4 = sprintf("with a standard error of %.1f", oa.se)
  p5 = sprintf("which would yield a %1.0f percent confidence intervall of %.1f to %.1f",ConfidenceInterval, oaul, oall)
  print(p3)
  print(p4)
  print(p5)
  print("Estimated error matrix based on stratified random sampling with equal allocation, rows= Map, columns= Reference") # Table 5 in Stehman and Foody 2019
  print(errorma.strat)
  print("-----------------------------------------")
  print("")
  print("")
 
  # prepare overall accuracies for output
  overall  = as.data.frame(rbind(n, oa.prop, oa.se, oaul, oall, ConfidenceInterval))
  row.names(overall) = c("sample n","overall accuracy","overall accuracy standard error","o.a.upper limit","o.a.lower limit", "confidence interval %")
  colnames(overall) = c("stratified_adjusted")
  
  # prepare area estimates for output:  ToDo
  # area_stat = cbind(maparea, propAreaEst, AreaEst)


  # returning results
  output = list(overall, errorma.naive, errorma.strat)
  names(output) = c("accuracy", "naive_error_matrix","stratified_error_matrix")
  print("-----------------------------------------")
  return(output)
}


#---------------------------------------------------------------------
#Count pixel map area

  r1 = masked
  names(r1) = "map"
  pixelarea = prod(res(r1))/10000   # pixel area in ha

#  if(length(NoDataValue)) {              ToDo  NA handling still not yet implemented
#    NAvalue(r1) = as.integer(NoDataValue)
# }

  print("Counting class pixels ...")
  if(length(MaskVectorLayer)) {
        dfr <- raster::extract(r1, MaskVectorLayer, df=T, na.rm=TRUE)
        str(dfr)
        maparea = as.data.frame(table(dfr$map, useNA="no"))
        } else {
            maparea = as.data.frame(freq(r1, useNA="no"))
            }

  colnames(maparea) = c("class","count")
  maparea$class = as.integer(maparea$class)
  A.tot = sum(maparea$count)
  maparea$Wi = round(maparea$count / A.tot, 5)
  maparea$area.ha = round(maparea$count * pixelarea, 0)
  A.tot.ha = sum(maparea$count) * pixelarea

  maparea
  classnames = as.character(maparea$class)
  classnames
  Wk = as.vector(maparea$Wi)
  Wk

#----------------------------------------------------------------------------
#Extract pixel value from thematic map layer

  if(MapField != ""){
                conTable = table(ValidationPointLayer[[MapField]],ValidationPointLayer[[ReferenceField]])
                } else {
                val = raster::extract(r1, ValidationPointLayer, sp=T)
                conTable = table(val@data[,"map"],val@data[,ReferenceField])
                }

  cm = as.matrix(conTable)
  rownames(cm) = classnames
  colnames(cm) = classnames

  results = accuracy.stratified(cm, Wk, alpha, classnames)
  results

# clear up memory
rm(list = ls())
gc()


