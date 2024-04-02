# ebird_data_to_TBN

### eBird對應TBN填入資料欄位

| TBN 欄位名稱 | eBird 原始欄位名稱 | 類別 | 說明 |  達爾文核心集參考術語(terms) |
|---|---|---|---|---|
|occurrenceUUID||文字|TBN觀測紀錄UUID，為字串，RFC 4122，需含斷字符號共36個字元，例: "dfed457f-622c-41c9-8f21-4aab087c15f0"||
|externalID||文字|系統自動內部編碼，格式為dwc[dataset id].[eBirdID]，例:"dwc.1729967.OBS887376268"||
|dwcID|global_unique_identifier|文字|擷取eBird資料集global_unique_identifier中"OBS+數字編號9~10位"字串，並填入於dwcID。例:"OBS887376268"。|[occurrenceID](	http://rs.tdwg.org/dwc/terms/occurrenceID)|
|catalogNumber||文字|新增欄位，將原始global_unique_identifier文字存於catalogNumber欄位中。例:"URN:CornellLabOfOrnithology:EBIRD:OBS887376268"。|[catalogNumber](http://rs.tdwg.org/dwc/terms/catalogNumber)|
|decimalLatitude|latitude|數值|原始eBird資料集經緯度座標系統為WGS84(4326)，取其原始值直接填入。|[decimalLatitude](	http://rs.tdwg.org/dwc/terms/decimalLatitude)|
|decimalLongitude|longitude|數值|原始eBird資料集經緯度座標系統為WGS84(4326)，取其原始值直接填入。|[decimalLongitude](http://rs.tdwg.org/dwc/terms/decimalLongitude)|
|coordinateUncertaintyInMeters|effort_distance_km|數值|1. 若原始eBird資料集protocol_type欄位為"Traveling"，取原始值並將公里轉換為以公尺為單位之值填入; 2. 若原始eBird資料集protocol_type欄位為"Stationary"，則填入500; 3. 若原始eBird資料集breedind_code 欄位為"flyover"，則不予填入。|[coordinateUncertaintyInMeters](http://rs.tdwg.org/dwc/terms/coordinateUncertaintyInMeters)|
|minimumElevationInMeters||數值|由latitude及longitude計算之衍生欄位，使用美國國家航空暨太空總署(National Aeronautics and Space Administration, NASA)「臺灣30米數值地形模型資料(DEM)第三版」圖層（原始資料來源：[ASTER GDEM V3](https://asterweb.jpl.nasa.gov/gdem.asp?fbclid=IwAR1TdjOyhS-fNUav-CQHQdMz4Ad7GkqGY5ZY2Lq_CqpFNZ5c6ogS0DxI-aY)），根據經緯度座標抓取最低海拔欄位資料。此外，若coordinateUncertaintyInMeters為空值，或該數值大於5000，則此欄位不予填入。|[minimumElevationInMeters](	http://rs.tdwg.org/dwc/terms/minimumElevationInMeters)|
|county|state|文字|使用eBird資料集原始值。|[county](	http://rs.tdwg.org/dwc/terms/county)|
|municipality||文字|由latitude及longitude計算之衍生欄位，使用政府資料開放平台「臺灣縣市和鄉鎮區界線圖層」（原始資料來源：[直轄市、縣市界線](https://data.gov.tw/dataset/32158)、[鄉鎮市區界線](https://data.gov.tw/dataset/32157)），與海洋保育署「海洋行政區範圍圖層」（原始資料來源:[海洋保育地理資訊圖台](https://iocean.oca.gov.tw/iOceanMap/map.aspx)）進行套疊，再根據經緯度座標抓取鄉鎮區資料。此外，若使用圖層獲取行政區縣市與原始eBird資料集縣市紀錄不同，則保留原eBird資料集縣市資訊，並且此欄位不予填入。|[municipality](http://rs.tdwg.org/dwc/terms/municipality)|
|verbatimLocality|locality|文字|使用eBird資料集原始值。|[verbatimLocality](http://rs.tdwg.org/dwc/terms/verbatimLocality)|
|year|observation_date|數值|於observation_date字串YYYY-MM-DD中擷取西元年份|[year](http://rs.tdwg.org/dwc/terms/year)|
|month|observation_date|數值|於observation_date字串YYYY-MM-DD中擷取月份|[month](http://rs.tdwg.org/dwc/terms/month)|
|day|observation_date|數值|於observation_date字串YYYY-MM-DD中擷取日期|[day](http://rs.tdwg.org/dwc/terms/day)|
|originalVernacularName|scientific_name|文字|原始eBird Taxonomy對應分類群學名。|[scientificName](	http://rs.tdwg.org/dwc/terms/scientificName)|
|basisOfRecord||文字|eBird台灣資料觀測方式皆為"人為觀測"。|[basisOfRecord](http://rs.tdwg.org/dwc/terms/basisOfRecord)|
|individualCount|observation_count|文字|取其原始值直接填入；若為文字"X"，則轉換為空值。根據原eBird資料集說明，"X"代表無計數，僅記錄該物種有出現。|[individualCount](	http://rs.tdwg.org/dwc/terms/individualCount)|
|recordedBy|observer_id|文字|使用eBird資料集原始值。|[recordedBy](http://rs.tdwg.org/dwc/terms/recordedBy)|
|sampleSizeValue|duration_minutes|數值|取duration_minutes（調查持續時間(分鐘)）原始值填入。|[sampleSizeValue](http://rs.tdwg.org/dwc/terms/sampleSizeValue)|
|sampleSizeUnit||文字|新增sampleSizeUnit欄位，若duration_minutes不為空值，sampleSizeUnit填入"minutes"。|[sampleSizeUnit](http://rs.tdwg.org/dwc/terms/sampleSizeUnit)|
|samplingProtocol|protocol_type|文字|使用eBird資料集原始值。|[samplingProtocol](http://rs.tdwg.org/dwc/terms/samplingProtocol)|
|eventID|sampling_event_identifier|文字|使用eBird資料集原始值。|[eventID](http://rs.tdwg.org/dwc/terms/eventID)|
|taxonomicCoverage|all_species_reported|文字|於eBird原始欄位中為布林值，若為1，填入 "Aves"; 若為0，填入空值(NULL)。|[Organism](	http://rs.tdwg.org/dwc/terms/Organism)|
| license ||文字|eBird台灣以"CC BY"做為資料授權。|[accessRights](http://purl.org/dc/terms/accessRights)|
|issue||文字|若相對應municipality和minimumElevationInMeters欄位不為空值，則分別填入"County and Municipality derived from coordinates by TBN"，與"minimumElevationInMeters derived from coordinates by TBN"。||

### Script 240401_eBird_to_op_transformation_code.R 細節說明

#### 1. 載入原始資料與套件
  * 建立相對路徑
  * 載入所需套件
  * 載入eBird原始資料集 (txt)

#### 2. eBird資料初步清理轉換欄位
* 篩選清理與轉換資料所需eBird欄位
* 根據上表[「eBird對應TBN填入資料欄位」](https://github.com/TBNworkGroup/eBird_data_to_OP/blob/main/README.md#ebird%E5%B0%8D%E6%87%89tbn%E5%A1%AB%E5%85%A5%E8%B3%87%E6%96%99%E6%AC%84%E4%BD%8D)重新命名與轉換欄位
* `individualCount` 欄位 "X" 資料轉為空值
* 若`Breedind code` 為 flyover，`coordinateUncertaintyInMeters`數值刪除
* 若`samplingProtocol` 為 Stationary，`coordinateUncertaintyInMeters`填入500


#### 3. 使用[adminarealist.csv]對照表獲取county欄位資訊
* 與[adminarealist.csv]()合併，獲得county欄位

#### 4.  抽取Municipality, minimumElevationInMeters欄位資訊
1. 使用 [Taiwan_WGS84_land_ocean_final]() 圖層抓取行政區欄位資料
  * 篩選 `dwcID`,`decimalLatitude`, `decimalLongitude` 三個欄位並另外新增資料集 `ebd_loc_table`
  * 使用`catchlocation` function 抓取座標的行政區，並執行平行運算
  * 若由座標抓去的縣市，與資料原縣市不符，則保留原縣市並且行政區填入空值

2. 使用 [twdtm_asterV3_30m.tif]() 圖層抓取最低海拔欄位資料
  * 分割篩選並另存成 `elevation_catch_table` 資料集，包含欄位: `dwcID`, `decimalLatitude`,`decimalLongitude`
  * 使用 QGIS "Point sampling tool" 抓取最低海拔欄位和另存檔案
  * 讀取和合併檔案 `elevation.data`

#### 5. 剩餘資料欄位處理
  * `minimumElevationInMeters`: 1. 只有`coordinateUncertaintyInMeters`資訊才填入; 2. 數值須小於5000公尺時，才會填入數值
  * `issue`: TBN自行新增的縣市和海拔要加註: "County and Municipality derived from coordinates by TBN" ; "minimumElevationInMeters derived from coordinates by TBN"
  * 分割和儲存最後檔案
