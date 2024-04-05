#### 1. 載入原始資料與套件 ####

#path
setwd("D:/Mong Chen/240329_ebird to OP")

#library
library(data.table)
library(tidyverse)
library(gridExtra)
library(showtext)
showtext_auto() 
font_add("Microsoft_JhengHei", regular = "C:/Windows/Fonts/msjh.ttc")
font_add("Microsoft_JhengHei_bold", regular = "C:/Windows/Fonts/msjhbd.ttc")


#input files
file_name <- list.files("./result/", recursive=TRUE, full.names = TRUE, all.files = TRUE, include.dirs = TRUE, no..= FALSE)

ebd_dt<-lapply(file_name, function(x)
    fread(x, sep = ",", colClasses = "character", encoding= "UTF-8"))%>%
  do.call(rbind, .)

#### plot 1: bar plot of the data numbers by state and county ####

#plot1_data
plot1_data<-ebd_dt[,.N, by=county] %>%
  .[, county := factor(.$county, levels=c("連江縣", "金門縣", "澎湖縣", "台東縣", "花蓮縣", "宜蘭縣",
                                                    "屏東縣", "高雄市", "台南市", "嘉義縣", "嘉義市", "雲林縣",
                                                    "彰化縣", "南投縣", "台中市", "苗栗縣", "新竹縣", "新竹市",
                                                    "桃園市", "新北市", "台北市", "基隆市"))] %>%
  .[, N := round(N/10000, digits=2)] %>%
  setnames(., "N", "count")
  

#plot1-1: state
plot_state<-ggplot(plot1_data, aes(x=county, y=count)) +
  geom_bar(stat="identity", fill="steelblue")+
  xlab("縣市")+
  ylab("資料筆數(萬)")+
  geom_text(aes(label=count), hjust=-0.05, size=5)+
  theme_bw(base_size = 20)+
  theme(
    text = element_text(family = "Microsoft_JhengHei"),
    axis.title = element_text(family = "Microsoft_JhengHei_bold")
  )+ coord_flip()

#plot1_data2
plot1_data2<-ebd_dt[,.N, by=.(county, municipality)] %>%
  .[, N := round(N/1000, digits=1)] %>%
  setnames(., "N", "count") %>%
  filter(municipality != "")

#plot1-2: county
county_ls<-unique(plot1_data2$county)

plot1_data2_ls<-lapply(1:length(county_ls), function(i){
  table<-plot1_data2 %>% .[county==county_ls[i]] %>% setDT()
  return(table)
})



for (i in 1:length(county_ls)) {
  table<-plot1_data2_ls[[i]]
  state<-unique(table$county)
  p<-ggplot(table, aes(x=municipality, y=count)) +
    geom_bar(stat="identity", fill="grey")+
    xlab("鄉鎮區")+
    ylab("資料筆數(千)")+
    scale_y_continuous(breaks=seq(0,400,100),limits=c(0, 400))+
    ggtitle(state)+
    geom_text(aes(label=count), hjust=0, size=3)+
    theme_bw(base_size = 14)+
    theme(
      axis.title.x = element_blank(), axis.title.y = element_blank(),
      legend.position='none',
      text = element_text(family = "Microsoft_JhengHei"),
      plot.title = element_text(family = "Microsoft_JhengHei_bold"),
    )+ coord_flip()
  assign(paste("p", i, sep=""),p)
}

p.all<-grid.arrange(p1, p2, p3, p4, p5, p6, p7, p8, p9, p10,
                    p11, p12, p13, p14, p15, p16, p17, p18, p19, p20,
                    p21, p22, ncol = 6)

p.all2<-grid.arrange(plot_state,p.all, ncol = 2)

dir.create("plot")

ggsave("各縣市eBird資料數量長條圖.jpg",
       plot = p.all2,
       path = "D:/Mong Chen/240329_ebird to OP/plot",
       width = 40,
       height =32,
       dpi = 300)

#### plot 2: histogram plot of the ebd's elevation distribution ####

ebd_dt <- ebd_dt %>% .[, minimumElevationInMeters := as.numeric(minimumElevationInMeters)]

plot_minimumElevationInMeters<-ggplot(ebd_dt, aes(x=minimumElevationInMeters)) + 
  geom_histogram(aes(y=..density..), colour="black", fill="white", bins = 1000)+
  geom_density(alpha=.2, fill="#FF6666")+
  xlab("minimumElevationInMeters")+
  ylab("density")+
  scale_x_continuous(breaks=seq(0,4500,500),limits=c(0, 4500))+
  theme_bw(base_size = 20)

dir.create("table")

#### 3: originalVernacularName vertification list ####

ebd_dt %>% dplyr::select(originalVernacularName) %>%
  mutate(ID = row_number()) %>%
  rename(scientific_name="originalVernacularName") %>%
  fwrite(., "table/scientificname_vertification_list.csv")

#### 4. random table ####

random_ls<-sample(1:nrow(ebd_dt), size = 1000)

random_table<-lapply(1:length(random_ls), function(i){
  return(ebd_dt[random_ls[i],])
}) %>% do.call(rbind, .) %>%
  write.csv(., "table/random_table.csv", fileEncoding = "UTF-8", row.names=FALSE)
