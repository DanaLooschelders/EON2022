######################################################
# ips-map: Detection of bark beetle infestation in
# spruce plantations using multispectral drone images
#
# 04 Feature Selection, Training, Classification
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

library(devtools)
library(sf)
library(doParallel)
library(skimr)
library(caret)
library(randomForest)
library(MLmetrics)
library(reshape)
library(dplyr)


#import the plot function for neural network architectures
source_url('https://gist.githubusercontent.com/fawda123/7471137/raw/466c1474d0a505ff044412703516c34f1a4684a5/nnet_plot_update.r')

# Adapt to number of cores available on your laptop
registerDoParallel(cores = 16)

#######################################################
# Prepare data
#######################################################

# Read the prepared training data
TrainLayer = st_read(dsn="./data/train_polygons.gpkg")
ClassField = 'C_ID'
ColorField = 'hexcolor'

TrainLayer[[ClassField]] = as.factor(TrainLayer[[ClassField]])
TrainLayer = dplyr::arrange(TrainLayer, TrainLayer[[ClassField]])
colores = c(unique(TrainLayer[[ColorField]]))
print("Class Hexcolor codes")
colores

FeatureNames = colnames(TrainLayer)[-c(1,22:25)]
FeatureNames

#Plot training data
plot(TrainLayer[ClassField], main="Spatial distribution of Training areas", pal=colores, key.pos = 1, axes = T)

# convert sf object to data.frame
train = st_drop_geometry(TrainLayer)

# Plot data types and ranges of variables
# different data ranges need to be scaled and centered! 
skim(train)


#######################################################
#Feature Selection and Training Phase
#######################################################

x = train[, FeatureNames]
head(x)
y = train[, ClassField]
head(y)

featurePlot(x = x, 
            y = y, 
            plot = "box",
            main = "Training data",
            strip=strip.custom(par.strip.text=list(cex=.7)),
            scales = list(x = list(relation="free"), 
                          y = list(relation="free")))

# calculate pairwise correlation for removing 
# redundant information and reducing number of variables
correlationMatrix = cor(x)
print(correlationMatrix)

# identify highly correlated variables defining a cut off
hc = findCorrelation(correlationMatrix, cutoff=0.95)
hc= sort(hc)
hc
#Remove highly correlated variables
x = x[, -c(hc)]
head(x)

# Randomforest algorithm parameters for recursive feature selection
# with repeated k-fold cross validation where k = 5
set.seed(1234567)
subsets <- c(1:18)

ctrl <- rfeControl(functions = rfFuncs,
                   method = "repeatedcv",
                   repeats = 10,
                   verbose = TRUE)

rfe_model = rfe(x=x, y=y,
                 sizes = subsets,
                 preProcess=c("center","scale"),
                 rfeControl = ctrl)

rfe_model
predictors(rfe_model)
c(predictors(rfe_model))


trellis.par.set(caretTheme())
plot(rfe_model, type = c("g", "o"), main="Training")


#######################################################
# Training Phase
#######################################################

#Train and Tune a shallow neural network with selected features
train <- subset(train, select = c(predictors(rfe_model), ClassField))
head(train)

levels(train$C_ID) <- make.names(levels(factor(train$C_ID)))
grid <- expand.grid(.decay = c(1.6,1.5,1.4,1.3,1.2,1.1,1.0,0.9,0.8,0.7,0.6,0.5,0.4,0.3,0.2,0.1), .size = c(3,4,5,6,7,8,9,10,11,12))

numFolds <- trainControl(method = 'cv', 
                         number = 10,
                         classProbs = TRUE,
                         verboseIter = TRUE,
                         summaryFunction = multiClassSummary)

model_nn <- train(C_ID~., data=train,
              method = 'nnet',
              preProcess = c('center', 'scale'),
              trControl = numFolds,
              maxit=1000,
              tuneGrid=grid)


model_nn
plot(model_nn)
plot.nnet(model_nn)
c(predictors(model_nn$finalModel))

#######################################################
# Classification Phase
#######################################################

# Read all tree segments
tree_poly = st_read(dsn="./data/tpolygons.gpkg")
tree_poly[["id"]] = 1:nrow(tree_poly)

# Predict classes based on randomforest
tree_poly_rfe = st_drop_geometry(tree_poly)
tree_poly_pred = predict(rfe_model, tree_poly_rfe)
tree_poly_pred[["id"]] = 1:nrow(tree_poly_pred)
rfe_pred = left_join(tree_poly, tree_poly_pred)
rfe_pred[["C_ID"]] = as.integer(rfe_pred$pred)
st_write(rfe_pred, "./data/tree_polygons_classified_rfe.gpkg", driver="GPKG", overwrite_layer=T)

# Predict classes based on shallow neural network
tree_poly_nn = subset(tree_poly, select = c(predictors(model_nn$finalModel)))
tree_poly_nn
tree_poly_nn$predicted = NA
tree_poly_nn$predicted = predict(model_nn, tree_poly_nn)
head(tree_poly_nn$predicted)

tree_poly_nn$C_ID = NA
tree_poly_nn[which(tree_poly_nn$predicted == "X1"),c("C_ID")] <- 1
tree_poly_nn[which(tree_poly_nn$predicted == "X2"),c("C_ID")] <- 2
tree_poly_nn[which(tree_poly_nn$predicted == "X3"),c("C_ID")] <- 3
tree_poly_nn[which(tree_poly_nn$predicted == "X4"),c("C_ID")] <- 4

tree_poly_nn$C_ID<- as.integer(tree_poly_nn$C_ID)
st_write(tree_poly_nn, "./data/tree_polygons_classified_nn.gpkg", driver="GPKG", overwrite_layer=T)

# clear up memory
rm(list = ls())
gc()


