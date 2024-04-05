#### 1. 載入原始資料與套件 ####

#path
setwd("D:/Mong Chen/240329_ebird to OP")

#package
library(data.table)
library(dplyr)
library(parallel)
library(sf)
library(raster)
library(stringr)

#input files
f_ebd <- "data/ebd_TW_smp_relFeb-2024.txt"
ebd_dt <- fread(f_ebd, quote="", encoding = "UTF-8", colClasses = "character")
adminarealist<-fread("adminarealist.csv",encoding = "UTF-8", colClasses = "character")

#### 2. eBird資料初步清理轉換欄位 ####

ebd_table<-ebd_dt %>% 
  
  #as.data.table
  setDT() %>%
  
  #select
  .[, list(`GLOBAL UNIQUE IDENTIFIER`, `ALL SPECIES REPORTED`, `DURATION MINUTES`,
            `LATITUDE`, `LONGITUDE`, `LOCALITY`, `STATE`,
            `OBSERVATION COUNT`, `OBSERVATION DATE`, `OBSERVER ID`,
            `SCIENTIFIC NAME`, `SAMPLING EVENT IDENTIFIER`, `PROTOCOL TYPE`,
            `EFFORT DISTANCE KM`, `BREEDING CODE`)] %>%
  
  #dwcID
  .[, dwcID := str_extract(`GLOBAL UNIQUE IDENTIFIER`, pattern ="OBS.+")] %>%
  
  
  #taxonomicCoverage
  setnames(., "ALL SPECIES REPORTED", "taxonomicCoverage") %>%
  .[, taxonomicCoverage := ifelse(as.numeric(taxonomicCoverage)==1, "Aves", "")] %>%

  #sampleSizeValue
  setnames(., "DURATION MINUTES", "sampleSizeValue") %>%
  
  #sampleSizeUnit
  .[, sampleSizeUnit := ifelse(sampleSizeValue=="", "", "minutes")] %>%
  
  #decimalLatitude, decimalLongitude, verbatimLocality 
  setnames(.,
           c("LATITUDE", "LONGITUDE", "LOCALITY"),
           c("decimalLatitude", "decimalLongitude", "verbatimLocality")) %>%
  
  #individualCount
  setnames(., "OBSERVATION COUNT", "individualCount") %>%
  #individualCount "X" transform to ""
  .[, individualCount := ifelse(individualCount=="X", "", individualCount)] %>%

  #year, month, day
  .[, year := substring(`OBSERVATION DATE`,1,4)] %>%
  .[, month := substring(`OBSERVATION DATE`,6,7)] %>%
  .[, day := substring(`OBSERVATION DATE`,9,10)] %>%
  
 
  #recordedBy
  setnames(., "OBSERVER ID", "recordedBy") %>%
  
  #originalVernacularName
  setnames(., "SCIENTIFIC NAME", "originalVernacularName") %>%
  
  
  #eventID, samplingProtocol
  
  setnames(.,
           c("SAMPLING EVENT IDENTIFIER", "PROTOCOL TYPE"),
           c("eventID", "samplingProtocol")) %>%
  
  #coordinateUncertaintyInMeters
  setnames(., "EFFORT DISTANCE KM", "coordinateUncertaintyInMeters") %>%
  .[, coordinateUncertaintyInMeters := as.numeric(coordinateUncertaintyInMeters)*1000] %>%
  #1. Behavior Flyover: delete coordinateUncertaintyMeters value
  .[, coordinateUncertaintyInMeters := ifelse(`BREEDING CODE`=="F", "", coordinateUncertaintyInMeters)] %>%
  #2. samplingProtocol Stationary: set coordinateUncertaintyMeters value to 500
  .[, coordinateUncertaintyInMeters := ifelse(samplingProtocol=="Stationary", "500", coordinateUncertaintyInMeters)] %>%
  
  #catalogNumber
  setnames(., "GLOBAL UNIQUE IDENTIFIER", "catalogNumber") %>%
  
  #basisOfRecord: 人為觀測
  .[, basisOfRecord := "人為觀測"] %>%
  
  #license: CC BY
  .[, license := "CC BY"] %>%  
  
  #delete column
  .[, c("OBSERVATION DATE", "BREEDING CODE") := NULL]

#### 3. adminarealist合併 ####

ebd_table<-ebd_table %>% 
  left_join(adminarealist, by=c("STATE")) %>% 
  subset(., select = -c(STATE))

#### 4.抽取Municipality, minimumElevationInMeters欄位資訊 ####

#with location
ebd_loc<- subset(ebd_table, ebd_table$decimalLatitude != "")

ebd_loc <- ebd_loc %>%
  setDT() %>%
  .[, file_ID := rep(1:ceiling(nrow(.)/250000), each=250000, length.out=nrow(.))] %>%
  .[, decimalLongitude := as.numeric(decimalLongitude)] %>%
  .[, decimalLatitude := as.numeric(decimalLatitude)]

ebd_loc_table <- ebd_loc %>% 
  dplyr::select(file_ID, dwcID, decimalLatitude, decimalLongitude) %>% 
  .[!duplicated(.[ , c("dwcID","decimalLatitude", "decimalLongitude")]), ]

ebd_loc_list <-ebd_loc_table %>% split(., .$file_ID)

#catchlocation function
catchlocation <- function(x){
  x %>%
    st_as_sf(coords = c("decimalLongitude", "decimalLatitude"), remove=FALSE) %>% # set coordinates
    st_set_crs(4326) %>%  # table transform to polygon
    st_join(., town, join = st_intersects, left = TRUE, largest=TRUE) %>% 
    st_drop_geometry(.)
}

#parallel
cpu.cores <- detectCores()
cl <- makeCluster(cpu.cores-1)
clusterEvalQ(cl, { # make sure all clusters are ready
  library(tidyverse)
  library(data.table)
  library(sf)
  town <- st_read("polygon/Taiwan_WGS84_land_ocean_final/Taiwan_WGS84_land_ocean_final.shp")
  town<- as(town, "sf")%>%
    st_set_crs(4326)
  sf_use_s2(FALSE)
}
)

system.time(
  ebd_loc_final<- parLapply(cl, ebd_loc_list, catchlocation)%>% 
    do.call(rbind,.)
)
stopCluster(cl)

ebd_loc_final <- ebd_loc_final %>%
  dplyr::select(file_ID, dwcID, decimalLatitude, decimalLongitude, TOWNNAME, COUNTYNAME) %>%
  setDT() %>%
  setnames(., "COUNTYNAME", "county_catch") %>%
  setnames(., "TOWNNAME", "municipality")

# add minimumElevationInMeters
elevation_raster <- raster("polygon/twdtm_asterV3_30m/twdtm_asterV3_30m.tif")

ebd_loc_final<- ebd_loc_final %>%
  setDT(.) %>%
  .[,decimalLongitude := as.numeric(decimalLongitude)] %>%
  .[,decimalLatitude := as.numeric(decimalLatitude)] %>%
  .[, minimumElevationInMeters := extract(elevation_raster, .[,c("decimalLongitude", "decimalLatitude")])] %>%
  subset(., select = -c(file_ID))

colnames(ebd_loc_final)

ebd_loc_final<- ebd_loc_final %>%
  dplyr::select(dwcID, municipality, county_catch, minimumElevationInMeters)

#ebd_loc_result
ebd_loc_result<-merge(ebd_table, ebd_loc_final,  by=c("dwcID"))

ebd_table_final<-ebd_loc_result %>%
  .[, county := as.character(county)] %>%
  .[, county_catch := as.character(county_catch)] %>%
  .[, municipality := as.character(municipality)] %>%
  .[, municipality := ifelse(is.na(municipality), "", municipality)] %>%
  mutate(county_catch = str_replace(county_catch,'臺','台')) 

ebd_table_final<-ebd_table_final %>%
  mutate(municipality = ifelse(county==county_catch, municipality, "")) %>%
  subset(., select = -c(county_catch))

#### 5. 剩餘資料欄位處理 ####

#minimumElevationInMeters: 若coordinateUncertaintyInMeters為空值或大於5000，則minimumElevationInMeters填入空值
ebd_table_final <- ebd_table_final %>%
  setDT() %>%
  .[, minimumElevationInMeters := as.character(minimumElevationInMeters)] %>%
  .[, coordinateUncertaintyInMeters := as.numeric(coordinateUncertaintyInMeters)] %>%
  .[, minimumElevationInMeters := ifelse(!is.na(coordinateUncertaintyInMeters) & coordinateUncertaintyInMeters<5000, minimumElevationInMeters, "")] %>%
  .[, coordinateUncertaintyInMeters := as.character(coordinateUncertaintyInMeters)]

#issue
ebd_table_final<-ebd_table_final %>%
  mutate(issue = case_when(
    municipality != "" &  minimumElevationInMeters != "" ~ "County and Municipality derived from coordinates by TBN; minimumElevationInMeters derived from coordinates by TBN",
    municipality != "" &  minimumElevationInMeters == "" ~ "County and Municipality derived from coordinates by TBN",
    municipality == "" &  minimumElevationInMeters != "" ~ "minimumElevationInMeters derived from coordinates by TBN",
    TRUE ~ ""
  ))

#save file
ebd_split<-ebd_table_final %>% split(., rep(1:ceiling(nrow(.)/250000), each=250000, length.out=nrow(.)))

dir.create("result")

for (i in 1:ceiling(nrow(ebd_table_final)/250000)) {
  table<-setDT(ebd_split[[i]])
  write.csv(table, sprintf("result/ebd_split_%s.csv",i),fileEncoding = "UTF-8",row.names=FALSE)
}
