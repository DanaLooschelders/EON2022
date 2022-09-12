###### tags: `2nd Joined Field Course EarthObservationNetwork`, `12.-16.09.2022`, `Waldhaus Oderbrück`, Forest Inventory and Remote Sensing, University  Göttingen, 
Dr. Hans Fuchs, hfuchs@gwdg.de

# Bark_Beetle_UAS: Detection of bark beetle infestation in spruce plantations using multispectral drone images


## Background
Since 2019 a bark beetle (*Ips typographus*) outbreak  in Harz mountains induce large economic and ecological problems in spruce forests. Large area changes call for adapting current forest management and monitoring systems.

In a pilot project of the Chair of Forest Inventory and Remote sensing, University Göttingen, drone flights were conducted in the forest district Clausthal, state forest lower saxony. Image data were acquired on 10.05.2022 using RGB and multispectral sensors (s.Tab. 1). Digital ortho photo mosaics were produced and provided as a WebGIS (Fuchs, Nölke und Magdon (2022), http://wwwuser.gwdg.de/~hfuchs/altenau/). 

Table 1. Spectral resolution of the multispectral sensor RedEdge-MX (Micasense).

| Bandno.   | Spektral range  | Wavelenght [nm]|
| -------- | --------    | -------- |
|1         | Blue        | 475      |
|2         | Green       | 566      |
|3         | Red         | 668      |
|4         | RedEdge     | 717      |
|5         | Near IR     | 842      |


Following resarch questions should be answered:

1. Are multipsectral drone images suited to detect bark beetle attacks?
2. Can an automated object-based image analysis(OBIA) distinguish different stages of tree dieback? 

## Objectives
* Know main steps of an OBIA process workflow.
* Selecting training data for a supervised classification.
* Extracting features for classifying image segments.
* Application of deep and shallow neural networks.
* Creating validation points based on stratified random sampling with equal allocation. 
* Apply stratified estimators for accuracy and bias adjusted area proportions.


## Prerequisites

* Windows10 64bit: R and RStudio Installation
http://wiki.awf.forst.uni-goettingen.de/wiki/index.php/R_installation

## Exercise
Download folder *Bark_Beetle_UAS* in the gitup repository EON2022 to a local folder. Open the Rscripts in subfolder */src* with RStudio.
Send code to the R-Terminal line by line.

### 01 Data Preparation
Tutorial data are downloaded from cloud storage.
Raster data are read and visualized as single and multiband files.

Histograms and image statistics inform on data type and range. 

Remove transparency channel No = 6 for subsequent analyses.

Resampling aggregates pixel size from 9cm to 18cm reducing data size by factor 4.


### 02. Image Enhancement
Marx (2010) proposes spectral indices sensitive to changes of chlorophyll content beside the original 5 bands: 

* RedEdge NDVI
* Green NDVI
* RATIO
* Chlorophyl Green Model
* Clorophyll RedEdge Model. 

Results are saved together with the original bands as an image stack of 10 bands. 



### 03 **Feature extraction**

In OBIA we look not only at instances on pixel level but also on spatial neighborhoods which are built by image regions or segments. Spatial context is favourable especially for high spatial resolution sensor data.

The OBIA work flow starts with a segmentation which divides the image into regions. Here we use the result of a deep learning instance based segmentation using a 2D multispectral ortho photo as input. The model is parametrized by a large amount of training data (Freudenberg et al. 2022).

For each segment we calculate simple descriptive statistical measures (mean, standard deviation) using all pixel values inside a segment. 

### **Excursus: Selecting training data**
Training data are non-statistically selected on basis of image segements with describing features. Polygons are selected and labeled on screen. As reference source a false color composite of the ortho photo mosaic is interpreted.
Following classes are defined: (s. Marx, 2010):

| C_ID     | Attribute   | Properties |Color code       |
| -------- | ---------| ------------- |---------------
| 1     | Healthy      | Spruce needles green an vital | #4d4dff |
| 2     | Infested    | Spruce needles green and reduced vitality | #fbd931 |
| 3     | Red         | Spruce needles red brown, with or without defoliation, dying or dead | #ed0808 |
| 4     | Broadleaf  |                   | #80ff00  |

Training data may be selected in QGIS:

* Load the drone ortho photo *UAS_image.tif* and display a false color composite RGB = 4,2,3
* Load the segmentation result with extracted attributes as vector file ```tpolygons.gpkg``` into the map canvas.
* Change symbology of polygons from "Solid" to "No Brush", stroke color = white.
* Add an additional column "*C_ID*" to the polygon attribute table.
* Select polygons of a vitality class and insert the class code in column *"C_ID"*. For each class choose the same sample size (minimum 25).
* Select all labeled polygons and save them in a new vector file.
   * Export > Save selected features as ...
*  Drag and drop the legend *legend.csv* into the Layers window. Join attribute tables of the layer *train_polygons.gpkg* and *legend.csv* on the common field *"C_ID"*.

These work steps may be skipped using an already prepared file:

```train_polygons.gpkg```

### **04 Feature selection, training and classifikation**

We apply classical methods of machine learning. 

In the process of feature extraction we reduce the number of features and  using recursive backward selection of the ensemble classifier random forest. 

Reduction and selection of best suited variables or variable groups lead to more robust models that may be better generalized on new data.

An additional classifier is a shallow neural network with 8 input nodes,  one hidden layer with 3 nodes und 4 output nodes.

![](https://pad.gwdg.de/uploads/1668293f-4a8f-48f5-831b-845af31e964a.png)

Finally the classication model is applied on all image segments.

### **05 Validation Sampling**

The resulting thematic map is imperfect and provides only a generalized model. The map information is (only) useful for a user if the map quality is known. A statistically rigorous evaluation of the map quality should be viewed as an essential part of any remote sensing project. 

We create a point validation file using stratified random sampling with equal allocation.

We collect validation data by visual interpretation of a false color composite of the ortho photo mosaic. Vitality classes are assigned to the validation point location. Add a new column *C_ID* to the attribute table and enter the class code. 

### **06 Stratified Validation**

We build error matrices and calculate accuracies using naive and stratified estimators.
Then, we may adjust the bias of area proportions.

## Task
1. Analyze the vitality of spruce trees after bark beetle attacks using a shallow neural network.

2. Display the result as a thematic map using the proposed color table (Tab. 1) with the ortho photo mosaic as background.

3. Save the Map display as PNG:

* Project > Import/Export > Export Map as Image ...

4. Compare the accuracies of random forest and a shallow neural network.


### **References**

Freudenberg, M., Magdon, P. and N.Nölke (2022): 
Individual tree crown delineation in high-resolution remote sensing images based on U-Net. Neural Computing and Applications. https://doi.org/10.1007/s00521-022-07640-4

Fuchs, H., Nölke, N. und P. Magdon, (2022): Drohnenbefliegung des Forstrevieres Altenau im Forstamt Clausthal-Zellerfeld am 10.5.2022. Url: http://wwwuser.gwdg.de/~hfuchs/altenau/

Marx, A. (2010): Erkennung von Borkenkäferbefall in Fichtenreinbeständen mit multi-temporalen RapidEye-Satellitenbildern und Datamining-Techniken. PFG 2010/4,S. 243 – 252.

Olofsson, P., Foody, G. M., Herold, M., Stehman, S.V., Woodcock, C. E. and Wulder, M. A. (2014): Good practices for estimating area and assessing accuracy of land change. Remote Sensing of Environment,Volume 148, 2014, ISSN 0034-4257, http://dx.doi.org/10.1016/j.rse.2014.02.015

Ortmann, A. 2017: Stratified sampling tool for area estimation. https://github.com/openforis/accuracy-assessment

Stehman, S.V., Foody G.M. (2019): Key issues in rigorous accuracy assessment of land cover products, Remote Sensing of Environment,Volume 231,2019,111199,ISSN 0034-4257, https://doi.org/10.1016/j.rse.2019.05.018

