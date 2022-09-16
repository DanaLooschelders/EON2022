## Johannes Löw
## EON Workshop 2022, Harz


library(raster)
library(ggplot2)
library(sf)
library(dplyr)
library(pracma)
library(Rlibeemd)
library(bfast)
library(xts)
library(tidyr)


setwd("D:/Harz_Kurs_S1_data/")

s1_mask <- shapefile("Harz_BBX_fixed.shp")
s1_mask <- spTransform(s1_mask, "EPSG:32633")
clausthal <- st_read("AOIs_harz_FoA_Claustahl.gpkg")
clausthal_sp <- as_Spatial(st_transform(clausthal, "EPSG:32633"))

s1_type <- "INT"

l_feats <- list("VH", "VV")

lapply(l_feats, function(s1_feat){
  ##load data
  s1_fp <- list.files(path= paste0(s1_type,"/" ,s1_feat), pattern = "*.tif$", full.names = T)
  
  master_s1 <- raster(s1_fp[[1]])
  
  s1_reproj <-list.files(path= paste0(s1_type,"/" ,s1_feat), pattern = "*_reproj.tif$", full.names = T)
  
  test <- stack(append(s1_fp[[1]], s1_reproj))
  test_masked <- terra::crop(test, s1_mask)
  test_mean <- calc(test_masked, function(x){max(x)-min(x)})
  
  plot(test_mean)
  ##extract dates from filename
  layernames <- names(test)
  if(s1_type == "COH"){
    dates <- sapply(layernames, function(n){
      date_str <- substr(n, 23, 30)
      my_date <- http://hil-mx-21.hawk.de:32224/?dmVyPTEuMDAxJiYwYTFkN2ZmZDNmNDUwYzRlNT02MzI0MkQwMl83Mzg3NV8zMDA3XzEmJmE4YjM0Yzk0ZmZkMzVlMz0xMjMzJiZ1cmw9YXMlMkVEYXRl(date_str, "%Y%m%d")
      return(as.character(my_date))
    })
  }else{
    dates <- sapply(layernames, function(n){
      date_str <- substr(n, 24, 31)
      my_date <- base::as.Date(date_str, "%Y%m%d")
      return(as.character(my_date))
    })
  }
  dates <- base::as.Date(unname(dates))
  ## extract median time series from AOI and smooth it
  s1_claus_bk <- terra::extract(test_masked, subset(clausthal_sp, Gebiet == "Buchenkopf"), fun= median)
  s1_claus_bk_wt <- pracma::whittaker(array(s1_claus_bk), lambda = 5)
  
  tmp_df_zoo <- data.frame(date= dates, value= s1_claus_bk_wt)
  tmp_zoo <- read.zoo(tmp_df_zoo)
  ##linear interpolation of ts
  tmp_ipol <- na.approx(tmp_zoo, xout = seq(start(tmp_zoo), end(tmp_zoo), "day"))
  df_out <- data.frame(date_idx= index(tmp_ipol), value= tmp_ipol)
  df_out$date <- http://hil-mx-21.hawk.de:32224/?dmVyPTEuMDAxJiYxODBiMjA5NzFhNTAxZDRhNT02MzI0MkQwMl83Mzg3NV8zMDA3XzEmJmFjMDAxODY3ZmY5MjBmNT0xMjMzJiZ1cmw9c2VxJTJFRGF0ZQ==(dates[1], dates[length(dates)], "day")
  ##get extrema from ts
  extr <- extrema(tmp_ipol)
  ## drop artifical extrema at start & end of ts
  my_min_sub <- t(as.data.frame(extr$minima[-c(1, nrow(extr$minima)),]))
  count_min <- nrow(my_min_sub)
  my_max_sub <- t(as.data.frame(extr$maxima[-c(1, nrow(extr$maxima)),]))
  count_max <- nrow(my_max_sub)
  
  my_max_sub <- data.frame(my_max_sub, type= rep("max", nrow(my_max_sub)))
  my_min_sub <- data.frame(my_min_sub, type= rep("min", nrow(my_min_sub)))
  
  colnames(my_max_sub) <- c("time", "value", "extremum")
  colnames(my_min_sub) <- c("time", "value", "extremum")
  
  df_extr <- data.frame(rbind(my_max_sub, my_min_sub))
  df_extr$time <- df_extr$time+1
  df_extr <- data.frame(df_extr, date= df_out$date[df_extr$time])
  ## create ts object for bfast
  tmp_xts <- xts(df_out$value, http://hil-mx-21.hawk.de:32224/?dmVyPTEuMDAxJiYwNDFjMzVkYzJjMWYwYjU2ND02MzI0MkQwMl83Mzg3NV8zMDA3XzEmJjZkNzE0Y2Q0OWI2MzZlOT0xMjMzJiZ1cmw9b3JkZXIlMkVieQ== = df_out$date_idx)
  tmp_ts <- ts(as.numeric(tmp_xts), frequency= 1)
  
  bf <- bfast::bfast(tmp_ts, season= "none", max.iter = 3)
  
  bf_pos <- bf$output[[1]]$bp.Vt$breakpoints
  bf_dates <- df_out$date[bf_pos]
  
  bp_df <- data.frame(date= bf_dates, vline= "break point")
  bp_df$bp_id <- seq(1, nrow(bp_df))
  
  
  ##plot results
  ggplot2::ggplot()+
    geom_line(data = df_out, mapping=aes(x= date, y= value))+
    geom_point(data= df_extr, mapping = aes(x=date, y=value, color= extremum), size=4)+
    geom_vline(data= bp_df, aes(xintercept=date, linetype= vline), size= 1.2,color= "darkgreen")
})