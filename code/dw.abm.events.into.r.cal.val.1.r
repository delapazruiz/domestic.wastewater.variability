# Calibration and Validation

options(scipen = 999)
#library(rJava)
#library(RNetLogo)
library(lubridate)
library(ggplot2)
library(dplyr)
library(hrbrthemes)
library(highfrequency)
library(xts)
library(reshape2)
library(stringr)
library(purrr)
library(dygraphs)
library(tidyr)
library(readr)
library(tibble)
library(RcppRoll)


#Before running Netlogo calibration-validation file
#Make sure you have at least 20 GB of free RAM to rung the simulation

#Modify C:\Program Files\NetLogo 6.1.1\app\NetLogo.cfg
#[JVMOptions]
# there may be one or more lines, leave them unchanged
# Modify this line: -Xmx1024m to 20024m

# Required files to run dw.sms.abm.snt.2020.nlogo in Netlogo
# Remove old files and create new ones every time before running Netlogo

# file.remove("results/calibration.snt/manholes.snt.cal1.csv")
# file.remove("results/calibration.snt/dwpee.snt.cal1.csv")
# file.remove("results/calibration.snt/dwpoo.snt.cal1.csv")
# file.remove("results/calibration.snt/dwshower.snt.cal1.csv")
# file.remove("results/calibration.snt/dwkitchensink.snt.cal1.csv")
# file.remove("results/calibration.snt/dwwmachine.snt.cal1.csv")
# file.remove("results/calibration.snt/dwwashbasin.snt.cal1.csv")
# 
# file.create("results/calibration.snt/manholes.snt.cal1.csv")
# file.create("results/calibration.snt/dwpee.snt.cal1.csv")
# file.create("results/calibration.snt/dwpoo.snt.cal1.csv")
# file.create("results/calibration.snt/dwshower.snt.cal1.csv")
# file.create("results/calibration.snt/dwkitchensink.snt.cal1.csv")
# file.create("results/calibration.snt/dwwmachine.snt.cal1.csv")
# file.create("results/calibration.snt/dwwashbasin.snt.cal1.csv")


#Load SMS-ABM Netlogo outcomes ----
manholes.snt <- read_csv(
  "results/calibration.snt/manholes.snt.cal1.csv",
  col_names = c(
    "ind.id","date.time","day.n","event.typ","manhole.id","wwp.id","seed","run","exp"))

pee.snt <- read_csv(
  "results/calibration.snt/dwpee.snt.cal1.csv",
  col_names = c(
    "ind.id","date.time","day.n","event.typ","CVEGEO","wwp.id","seed","run","exp"))

poo.snt <- read_csv(
  "results/calibration.snt/dwpoo.snt.cal1.csv",
  col_names = c(
    "ind.id","date.time","day.n","event.typ","CVEGEO","wwp.id","seed","run","exp"))

kitchen.snt <- read_csv(
  "results/calibration.snt/dwkitchensink.snt.cal1.csv",
  col_names = c(
    "ind.id","date.time","day.n","event.typ","CVEGEO","wwp.id","seed","run","exp"))

shower.snt <- read_csv(
  "results/calibration.snt/dwshower.snt.cal1.csv",
  col_names = c(
    "ind.id","date.time","day.n","event.typ","CVEGEO","wwp.id","seed","run","exp"))

washingmachine.snt <- read_csv(
  "results/calibration.snt/dwwmachine.snt.cal1.csv",
  col_names = c(
    "ind.id","date.time","day.n","event.typ","CVEGEO","wwp.id","seed","run","exp"))

washbasin.snt <- read_csv(
  "results/calibration.snt/dwwashbasin.snt.cal1.csv",
  col_names = c(
    "ind.id","date.time","day.n","event.typ","CVEGEO","wwp.id","seed","run","exp"))

#Cehcking for duplicates
# manholes.snt[duplicated(manholes.snt),]
# pee.snt[duplicated(pee.snt),]
# poo.snt[duplicated(poo.snt),]
# kitchen.snt[duplicated(kitchen.snt),]
# shower.snt[duplicated(shower.snt),]
# washingmachine.snt[duplicated(washingmachine.snt),]
# washbasin.snt[duplicated(washbasin.snt),]

#Checking sensitivity analysis variables
manholes.snt$run %>% unique()
manholes.snt$exp %>% unique()
manholes.snt$seed %>% unique()
manholes.snt$manhole.id %>% unique()

#Datetime format for time-series data analysis
manholes.snt$date.time <- parse_date_time(
  manholes.snt$date.time, orders = c("%Y-%m-%d %H:%M:%S"))

pee.snt$date.time <- parse_date_time(
  pee.snt$date.time, orders = c("%Y-%m-%d %H:%M"))

poo.snt$date.time <- parse_date_time(
  poo.snt$date.time, orders = c("%Y-%m-%d %H:%M"))

kitchen.snt$date.time <- parse_date_time(
  kitchen.snt$date.time, orders = c("%Y-%m-%d %H:%M"))

shower.snt$date.time <- parse_date_time(
  shower.snt$date.time, orders = c("%Y-%m-%d %H:%M"))

washingmachine.snt$date.time <- parse_date_time(
  washingmachine.snt$date.time, orders = c("%Y-%m-%d %H:%M"))

washbasin.snt$date.time <- parse_date_time(
  washbasin.snt$date.time, orders = c("%Y-%m-%d %H:%M"))

#Define validation hours
dt.val <- tibble(
  start = c(
  '2022:03:19 07:45',
  '2022:03:20 07:45',
  '2022:03:21 07:45',
  '2022:03:22 07:45',
  '2022:03:23 07:45'),
  end =c(
    '2022:03:19 16:15',
    '2022:03:20 16:15',
    '2022:03:21 16:15',
    '2022:03:22 16:15',
    '2022:03:23 16:15')
    )

#Set date time hours
dt.val$start <- parse_date_time(
  dt.val$start, orders = c("%Y-%m-%d %H:%M"))

dt.val$end <- parse_date_time(
  dt.val$end, orders = c("%Y-%m-%d %H:%M"))

dt.val

#Filter validation hours
#Selcting Monday for sensitivity analysis
filter.val.range <- function(
    var.df = manholes.snt,
    dt.val = dt.val,
    name.out = 'manholes.snt'
) {
  # d1<- var.df %>%
  #   .[.$date.time >= dt.val[1,1] & .$date.time <= dt.val[1,2], ]
  # 
  # d2<- var.df %>%
  # .[.$date.time >= dt.val[2,1] & .$date.time <= dt.val[2,2], ]

  d3<- var.df %>%
    .[.$date.time >= dt.val[3,1] & .$date.time <= dt.val[3,2], ]

  d4<- var.df %>%
    .[.$date.time >= dt.val[4,1] & .$date.time <= dt.val[4,2], ]

  d5<- var.df %>%
  .[.$date.time >= dt.val[5,1] & .$date.time <= dt.val[5,2], ]

  d1.5<- rbind(d3,d4,d5) #d1,d2,

  assign(name.out,d1.5,
         envir = globalenv())
}

filter.val.range(var.df = manholes.snt,
                 dt.val = dt.val,
                 name.out = 'manholes.snt')

filter.val.range(var.df = pee.snt,
                 dt.val = dt.val,
                 name.out = 'pee.snt')

filter.val.range(var.df = poo.snt,
                 dt.val = dt.val,
                 name.out = 'poo.snt')

filter.val.range(var.df = kitchen.snt,
                 dt.val = dt.val,
                 name.out = 'kitchen.snt')

filter.val.range(var.df = shower.snt,
                 dt.val = dt.val,
                 name.out = 'shower.snt')

filter.val.range(var.df = washingmachine.snt,
                 dt.val = dt.val,
                 name.out = 'washingmachine.snt')

filter.val.range(var.df = washbasin.snt,
                 dt.val = dt.val,
                 name.out = 'washbasin.snt')


# manholes.snt %>% .$date.time %>% lubridate::hour(.) %>% unique()
# pee.snt %>% .$date.time %>% lubridate::hour(.) %>% unique()
# poo.snt %>% .$date.time %>% lubridate::hour(.) %>% unique()
# kitchen.snt %>% .$date.time %>% lubridate::hour(.) %>% unique()
# shower.snt %>% .$date.time %>% lubridate::hour(.) %>% unique()
# washingmachine.snt%>% .$date.time %>% lubridate::hour(.) %>% unique()
# washbasin.snt%>% .$date.time %>% lubridate::hour(.) %>% unique()

# Load SMS agents with ind.id ----
indiv_mipfp.id <- read_csv(
  "data/sms.agent.snt.csv",
  col_names = c("Sex","Age","Go_School","Go_Work",
                "Escolar_grade","Escolar_level","CVEGEO",
                "ind.id",'wwtp.conex'))

# Filter inhabitants connected to WWTP
indiv_mipfp.id<- indiv_mipfp.id %>% filter(wwtp.conex == 'y')
# head(indiv_mipfp.id)
# str(indiv_mipfp.id)

#Remove wwtp.conex column
indiv_mipfp.id <- indiv_mipfp.id %>% 
  .[,!(colnames(.) %in% c("wwtp.conex"))]

# Parametrization: (inner_join)DW.events & sms.agents ----

#Merge events & agents 
manholes.snt <- inner_join(manholes.snt, indiv_mipfp.id, by = "ind.id")
pee.snt <- inner_join(pee.snt, indiv_mipfp.id, by = "ind.id")
poo.snt <- inner_join(poo.snt, indiv_mipfp.id, by = "ind.id")
kitchen.snt <- inner_join(kitchen.snt, indiv_mipfp.id, by = "ind.id")
shower.snt <- inner_join(shower.snt, indiv_mipfp.id, by = "ind.id")
#washingmachine.snt <- inner_join(washingmachine.snt, indiv_mipfp.id, by = "ind.id")
washbasin.snt <- inner_join(washbasin.snt, indiv_mipfp.id, by = "ind.id")
blocks.snt<- rbind(pee.snt,poo.snt,kitchen.snt,
                   shower.snt,washingmachine.snt,washbasin.snt)

# DF inputs to execute parametrization
blocks.snt
manholes.snt

remove(
  pee.snt,
  poo.snt,
  kitchen.snt,
  shower.snt,
  washingmachine.snt,
  washbasin.snt)

#Define tag version base on temporal execution of parametrization
ver.tim <- Sys.time() %>% gsub(":",".",.) %>% 
  gsub("-","",.)%>% gsub(" ",".",.)

#Execute parametrization
source("code/dw.pollutant.loads.by.events.global.snt.calibration.r")

#remove un-used var
remove(dt.val,blocks.snt,manholes.snt,indiv_mipfp.id)

# Results from DW parametrization
# blocks.snt.pol
# manholes.snt.pol
# 
# summary(blocks.snt.pol)
# summary(manholes.snt.pol)
# 
# manholes.snt.pol %>% .$date.time %>% lubridate::hour(.) %>% unique()
# blocks.snt.pol %>% .$date.time %>% lubridate::hour(.) %>% unique()

#> Fun: var.SPT resolutions DW- COD.TSS.VOL   <------------------------------ =================================

dw.var.spt.resol.processing.plots <- function(
    tem.res.in.min.int = 12,
    mh.loc.pol = manholes.snt.pol,
    #wwtp.loc.pol = wwtp.snt.pol,
    #blo.loc.pol = blocks.snt.pol,
    date.1.str = "2022-03-19",
    date.2.str = "2022-03-20",
    date.3.str = "2022-03-21",
    date.4.str = "2022-03-22",
    date.5.str = "2022-03-23",
    #blo.out.res.loc.df = 'blo.out.12min.snt.df',
    mh.out.res.loc.df = 'name'
    #wwtp.out.res.loc.df = 'wwtp.out.12min.snt.df',
    #wwtp.mh.blo.out.res.loc.plot = 'wwtp.mh.blo.out.12min.snt.plot'
){
  
  
  
  # Manholes  ------------------------------
  
  mh.loc.pol.min <- mh.loc.pol
  mh.loc.pol.min$date.time <- align.time(as.POSIXct(mh.loc.pol.min$date.time), tem.res.in.min.int * 60)
  
  
  #Pollutants concentration applies mean values in a time window
  #This applies when the concentration from two events is combined:Target question
  dw.manholes.minute.cod <- aggregate(cod.mgl ~
                                        format(as.POSIXct(mh.loc.pol.min$date.time), "%Y-%m-%d %H:%M")+ 
                                        mh.loc.pol.min$manhole.id,
                                      data= mh.loc.pol.min,
                                      FUN = mean)%>% as_tibble()
  
  dw.manholes.minute.tss <- aggregate(tss.mgl ~
                                        format(as.POSIXct(mh.loc.pol.min$date.time), "%Y-%m-%d %H:%M")+ 
                                        mh.loc.pol.min$manhole.id,
                                      data= mh.loc.pol.min,
                                      FUN = mean)%>% as_tibble()
  
  #Liters apply the sum of the values in a time window
  #This applies when the total amount of DW production is the target
  dw.manholes.minute.lts <- aggregate(lts.vol ~ 
                                        format(as.POSIXct(mh.loc.pol.min$date.time), "%Y-%m-%d %H:%M")+ 
                                        mh.loc.pol.min$manhole.id,
                                      data= mh.loc.pol.min,
                                      FUN = 'sum')%>% as_tibble()
  
  # dw.manholes.minute.cod.min <- aggregate(cod.mgl ~
  #                                           format(as.POSIXct(mh.loc.pol.min$date.time), "%Y-%m-%d %H:%M")+ 
  #                                           mh.loc.pol.min$manhole.id,
  #                                         data= mh.loc.pol.min,
  #                                         FUN = roll_min)%>% as_tibble()
  # 
  # dw.manholes.minute.tss.min <- aggregate(tss.mgl ~
  #                                           format(as.POSIXct(mh.loc.pol.min$date.time), "%Y-%m-%d %H:%M")+ 
  #                                           mh.loc.pol.min$manhole.id,
  #                                         data= mh.loc.pol.min,
  #                                         FUN = roll_min)%>% as_tibble()
  # 
  # dw.manholes.minute.cod.max <- aggregate(cod.mgl ~
  #                                           format(as.POSIXct(mh.loc.pol.min$date.time), "%Y-%m-%d %H:%M")+ 
  #                                           mh.loc.pol.min$manhole.id,
  #                                         data= mh.loc.pol.min,
  #                                         FUN = roll_max)%>% as_tibble()
  # 
  # dw.manholes.minute.tss.max <- aggregate(tss.mgl ~
  #                                           format(as.POSIXct(mh.loc.pol.min$date.time), "%Y-%m-%d %H:%M")+ 
  #                                           mh.loc.pol.min$manhole.id,
  #                                         data= mh.loc.pol.min,
  #                                         FUN = roll_max)%>% as_tibble()
  
  #Merged COD TSS LTS by space-time
  mh.out.res.name.df <- inner_join(dw.manholes.minute.cod,dw.manholes.minute.tss)
  mh.out.res.name.df <- inner_join(mh.out.res.name.df,dw.manholes.minute.lts)
  
  # mh.out.res.name.df.mix <- cbind(dw.manholes.minute.cod.min,dw.manholes.minute.cod.max)
  # mh.out.res.name.df.mix <- cbind(mh.out.res.name.df.mix,dw.manholes.minute.tss.min)
  # mh.out.res.name.df.mix <- cbind(mh.out.res.name.df.mix,dw.manholes.minute.tss.max)

  
  colnames(mh.out.res.name.df) <-c("date.time","manhole.id","cod.mgl","tss.mgl","lts.vol")
   mh.out.res.name.df$date.time <- parse_date_time(mh.out.res.name.df$date.time, orders = c("%Y-%m-%d %H:%M"))
  
  
  # colnames(mh.out.res.name.df.mix) <-c(
  #   "date.time","manhole.id","cod.mgl.min","cod.mgl.max","tss.mgl.min","tss.mgl.max")
  # mh.out.res.name.df.mix$date.time <- parse_date_time(
  #   mh.out.res.name.df.mix$date.time, orders = c("%Y-%m-%d %H:%M")) 
  
  remove(
    mh.loc.pol.min,
    dw.manholes.minute.cod,
    dw.manholes.minute.tss,
    dw.manholes.minute.lts
  )
  
  
  
  #Saving results
  # 
  # assign(blo.out.res.loc.df, blo.out.res.name.df,
  #        envir = globalenv())
  
  assign(mh.out.res.loc.df,mh.out.res.name.df,
         envir = globalenv())
  

}

#> Fun: Max, SPT resolutions DW- COD.TSS.VOL   <------------------------------ =================================

max.dw.var.spt.resol.processing.plots <- function(
    tem.res.in.min.int = 12,
    mh.loc.pol = manholes.snt.pol,
    #wwtp.loc.pol = wwtp.snt.pol,
    #blo.loc.pol = blocks.snt.pol,
    date.1.str = "2022-03-19",
    date.2.str = "2022-03-20",
    date.3.str = "2022-03-21",
    date.4.str = "2022-03-22",
    date.5.str = "2022-03-23",
    #blo.out.res.loc.df = 'blo.out.12min.snt.df',
    mh.out.res.loc.df = 'name'
    #wwtp.out.res.loc.df = 'wwtp.out.12min.snt.df',
    #wwtp.mh.blo.out.res.loc.plot = 'wwtp.mh.blo.out.12min.snt.plot'
){
  # Manholes  ------------------------------
  
  mh.loc.pol.min <- mh.loc.pol
  #mh.loc.pol.min$date.time <- align.time(as.POSIXct(mh.loc.pol.min$date.time), tem.res.in.min.int * 60)
  
  #Pollutants concentration applies mean values in a time window
  #This applies when the concentration from two events is combined:Target question
  dw.manholes.minute.cod <- aggregate(cod.mgl ~
                                        format(as.POSIXct(mh.loc.pol.min$date.time), "%Y-%m-%d %H:%M")+ 
                                        mh.loc.pol.min$manhole.id,
                                      data= mh.loc.pol.min,
                                      FUN = max)%>% as_tibble()
  
  dw.manholes.minute.tss <- aggregate(tss.mgl ~
                                        format(as.POSIXct(mh.loc.pol.min$date.time), "%Y-%m-%d %H:%M")+ 
                                        mh.loc.pol.min$manhole.id,
                                      data= mh.loc.pol.min,
                                      FUN = max)%>% as_tibble()
  
  #Liters apply the sum of the values in a time window
  #This applies when the total amount of DW production is the target
  dw.manholes.minute.lts <- aggregate(lts.vol ~ 
                                        format(as.POSIXct(mh.loc.pol.min$date.time), "%Y-%m-%d %H:%M")+ 
                                        mh.loc.pol.min$manhole.id,
                                      data= mh.loc.pol.min,
                                      FUN = max)%>% as_tibble()
  
  #Merged COD TSS LTS by space-time
  mh.out.res.name.df <- inner_join(dw.manholes.minute.cod,dw.manholes.minute.tss)
  mh.out.res.name.df <- inner_join(mh.out.res.name.df,dw.manholes.minute.lts)
  
  colnames(mh.out.res.name.df) <-c("date.time","manhole.id","cod.mgl","tss.mgl","lts.vol")
  mh.out.res.name.df$date.time <- parse_date_time(mh.out.res.name.df$date.time, orders = c("%Y-%m-%d %H:%M"))
  
  remove(
    mh.loc.pol.min,
    dw.manholes.minute.cod,
    dw.manholes.minute.tss,
    dw.manholes.minute.lts
  )

  assign(mh.out.res.loc.df,mh.out.res.name.df,
         envir = globalenv())
  
  
}

#> Fun: Min, SPT resolutions DW- COD.TSS.VOL   <------------------------------ =================================

min.dw.var.spt.resol.processing.plots <- function(
    tem.res.in.min.int = 12,
    mh.loc.pol = manholes.snt.pol,
    #wwtp.loc.pol = wwtp.snt.pol,
    #blo.loc.pol = blocks.snt.pol,
    date.1.str = "2022-03-19",
    date.2.str = "2022-03-20",
    date.3.str = "2022-03-21",
    date.4.str = "2022-03-22",
    date.5.str = "2022-03-23",
    #blo.out.res.loc.df = 'blo.out.12min.snt.df',
    mh.out.res.loc.df = 'name'
    #wwtp.out.res.loc.df = 'wwtp.out.12min.snt.df',
    #wwtp.mh.blo.out.res.loc.plot = 'wwtp.mh.blo.out.12min.snt.plot'
){
  # Manholes  ------------------------------
  
  mh.loc.pol.min <- mh.loc.pol
  #mh.loc.pol.min$date.time <- align.time(as.POSIXct(mh.loc.pol.min$date.time), tem.res.in.min.int * 60)
  
  
  #Pollutants concentration applies mean values in a time window
  #This applies when the concentration from two events is combined:Target question
  dw.manholes.minute.cod <- aggregate(cod.mgl ~
                                        format(as.POSIXct(mh.loc.pol.min$date.time), "%Y-%m-%d %H:%M")+ 
                                        mh.loc.pol.min$manhole.id,
                                      data= mh.loc.pol.min,
                                      FUN = min)%>% as_tibble()
  
  dw.manholes.minute.tss <- aggregate(tss.mgl ~
                                        format(as.POSIXct(mh.loc.pol.min$date.time), "%Y-%m-%d %H:%M")+ 
                                        mh.loc.pol.min$manhole.id,
                                      data= mh.loc.pol.min,
                                      FUN = min)%>% as_tibble()
  
  #Liters apply the sum of the values in a time window
  #This applies when the total amount of DW production is the target
  dw.manholes.minute.lts <- aggregate(lts.vol ~ 
                                        format(as.POSIXct(mh.loc.pol.min$date.time), "%Y-%m-%d %H:%M")+ 
                                        mh.loc.pol.min$manhole.id,
                                      data= mh.loc.pol.min,
                                      FUN = min)%>% as_tibble()

  
  #Merged COD TSS LTS by space-time
  mh.out.res.name.df <- inner_join(dw.manholes.minute.cod,dw.manholes.minute.tss)
  mh.out.res.name.df <- inner_join(mh.out.res.name.df,dw.manholes.minute.lts)
  
  colnames(mh.out.res.name.df) <-c("date.time","manhole.id","cod.mgl","tss.mgl","lts.vol")
  mh.out.res.name.df$date.time <- parse_date_time(mh.out.res.name.df$date.time, orders = c("%Y-%m-%d %H:%M"))
  
  remove(
    mh.loc.pol.min,
    dw.manholes.minute.cod,
    dw.manholes.minute.tss,
    dw.manholes.minute.lts
  )
  
  #Saving results
  assign(mh.out.res.loc.df,mh.out.res.name.df,
         envir = globalenv())

}

#> Avg. T.res:x5 DW- COD.TSS.VOL   <------------------------------ =================================

#> Minutes (6 min) DW- COD.TSS.VOL
dw.var.spt.resol.processing.plots(
  tem.res.in.min.int = 6,
  mh.loc.pol = manholes.snt.pol,
  mh.out.res.loc.df = 'mh.out.06min.snt.df',
  date.1.str = "2022-03-19",
  date.2.str = "2022-03-20",
  date.3.str = "2022-03-21",
  date.4.str = "2022-03-22",
  date.5.str = "2022-03-23"
  #blo.out.res.loc.df = 'blo.out.06min.snt.df',
  #wwtp.loc.pol = wwtp.snt.pol,
  #blo.loc.pol = blocks.snt.pol,
  #wwtp.out.res.loc.df = 'wwtp.out.06min.snt.df',
  #wwtp.mh.blo.out.res.loc.plot = 'wwtp.mh.blo.out.06min.snt.plot'
)

#htmltools::browsable(htmltools::tagList(wwtp.mh.blo.out.06min.snt.plot))

#> Minutes (12 min) DW- COD.TSS.VOL
dw.var.spt.resol.processing.plots(
  tem.res.in.min.int = 12,
  mh.loc.pol = manholes.snt.pol,
  date.1.str = "2022-03-19",
  date.2.str = "2022-03-20",
  date.3.str = "2022-03-21",
  date.4.str = "2022-03-22",
  date.5.str = "2022-03-23",
  mh.out.res.loc.df = 'mh.out.12min.snt.df'
  #wwtp.loc.pol = wwtp.snt.pol,
  #blo.loc.pol = blocks.snt.pol,
  #blo.out.res.loc.df = 'blo.out.12min.snt.df',
  #wwtp.out.res.loc.df = 'wwtp.out.12min.snt.df',
  #wwtp.mh.blo.out.res.loc.plot = 'wwtp.mh.blo.out.12min.snt.plot'
)

#htmltools::browsable(htmltools::tagList(wwtp.mh.blo.out.12min.snt.plot))

#> Minutes (30 min) DW- COD.TSS.VOL
dw.var.spt.resol.processing.plots(
  tem.res.in.min.int = 30,
  mh.loc.pol = manholes.snt.pol,
  date.1.str = "2022-03-19",
  date.2.str = "2022-03-20",
  date.3.str = "2022-03-21",
  date.4.str = "2022-03-22",
  date.5.str = "2022-03-23",
  mh.out.res.loc.df = 'mh.out.30min.snt.df'
  #blo.out.res.loc.df = 'blo.out.30min.snt.df',
  #wwtp.loc.pol = wwtp.snt.pol,
  #blo.loc.pol = blocks.snt.pol,
  #wwtp.out.res.loc.df = 'wwtp.out.30min.snt.df',
  #wwtp.mh.blo.out.res.loc.plot = 'wwtp.mh.blo.out.30min.snt.plot'
)

#htmltools::browsable(htmltools::tagList(wwtp.mh.blo.out.30min.snt.plot))

#> Minutes (1 hr) DW- COD.TSS.VOL
dw.var.spt.resol.processing.plots(
  tem.res.in.min.int = 60,
  mh.loc.pol = manholes.snt.pol,
  date.1.str = "2022-03-19",
  date.2.str = "2022-03-20",
  date.3.str = "2022-03-21",
  date.4.str = "2022-03-22",
  date.5.str = "2022-03-23",
  mh.out.res.loc.df = 'mh.out.60min.snt.df'
  #blo.out.res.loc.df = 'blo.out.60min.snt.df',
  #wwtp.loc.pol = wwtp.snt.pol,
  #blo.loc.pol = blocks.snt.pol,
  #wwtp.out.res.loc.df = 'wwtp.out.60min.snt.df',
  #wwtp.mh.blo.out.res.loc.plot = 'wwtp.mh.blo.out.60min.snt.plot'
)

#htmltools::browsable(htmltools::tagList(wwtp.mh.blo.out.60min.snt.plot))

#> Minutes (3 hrs) DW- COD.TSS.VOL
dw.var.spt.resol.processing.plots(
  tem.res.in.min.int = 180,
  mh.loc.pol = manholes.snt.pol,
  date.1.str = "2022-03-19",
  date.2.str = "2022-03-20",
  date.3.str = "2022-03-21",
  date.4.str = "2022-03-22",
  date.5.str = "2022-03-23",
  mh.out.res.loc.df = 'mh.out.180min.snt.df'
  #blo.out.res.loc.df = 'blo.out.180min.snt.df',
  #wwtp.loc.pol = wwtp.snt.pol,
  #blo.loc.pol = blocks.snt.pol,
  #wwtp.out.res.loc.df = 'wwtp.out.180min.snt.df',
  #wwtp.mh.blo.out.res.loc.plot = 'wwtp.mh.blo.out.180min.snt.plot'
)

#htmltools::browsable(htmltools::tagList(wwtp.mh.blo.out.180min.snt.plot))


#> Max-Min T.res:x5 DW- COD.TSS.VOL   <------------------------------ =================================
# Individual.70.sim. Min(6,12,30,60,180) DW- COD.TSS.VOL
#Individual simulations to extract MAX & MIN

# 06 min max-min
mh.runs.f.06 <- function(
    data = manholes.snt.pol
){
  mh.runs.06 <- manholes.snt.pol %>%
    group_by(run)%>%
    group_map(
      ~ dw.var.spt.resol.processing.plots(
        .,tem.res.in.min.int = 6))%>%
    bind_rows()
  
  mh.runs.06.max <-mh.runs.06%>% 
    max.dw.var.spt.resol.processing.plots(
      .,tem.res.in.min.int = 6)
  
  mh.runs.06.min <-mh.runs.06%>% 
    min.dw.var.spt.resol.processing.plots(
      .,tem.res.in.min.int = 6)
  
  #Proper col names for plotting
  mh.runs.06.max <- rename(
    mh.runs.06.max, cod.mx=cod.mgl,tss.mx=tss.mgl,lts.mx=lts.vol)
  
  mh.runs.06.min <- rename(
    mh.runs.06.min, cod.mn=cod.mgl,tss.mn=tss.mgl,lts.mn=lts.vol)
  
  #Join DF
  mh.runs.06.all <- right_join(
    mh.runs.06.max,mh.runs.06.min) %>% as_tibble()
  
  mh.runs.06.all <- right_join(
    mh.runs.06.all, mh.out.06min.snt.df)%>% as_tibble()
  
  
  assign('mh.runs.06.all',mh.runs.06.all,envir = globalenv())
}

mh.runs.f.06(manholes.snt.pol)

# mh.06.cod.plt
# mh.06.tss.plt
# mh.runs.06.all
# 
# remove(mh.06.cod.plt,mh.06.tss.plt,mh.runs.06.all,name)

# 12 min max-min
mh.runs.f.12 <- function(
    data = manholes.snt.pol
){
  mh.runs.12 <- manholes.snt.pol %>%
    group_by(run)%>%
    group_map(
      ~ dw.var.spt.resol.processing.plots(
        .,tem.res.in.min.int = 12))%>%
    bind_rows()
  
  mh.runs.12.max <-mh.runs.12%>% 
    max.dw.var.spt.resol.processing.plots(
      .,tem.res.in.min.int = 12)
  
  mh.runs.12.min <-mh.runs.12%>% 
    min.dw.var.spt.resol.processing.plots(
      .,tem.res.in.min.int = 12)
  
  #Proper col names for plotting
  mh.runs.12.max <- rename(
    mh.runs.12.max, cod.mx=cod.mgl,tss.mx=tss.mgl,lts.mx=lts.vol)
  
  mh.runs.12.min <- rename(
    mh.runs.12.min, cod.mn=cod.mgl,tss.mn=tss.mgl,lts.mn=lts.vol)
  
  #Join DF
  mh.runs.12.all <- right_join(
    mh.runs.12.max,mh.runs.12.min) %>% as_tibble()
  
  mh.runs.12.all <- right_join(
    mh.runs.12.all, mh.out.12min.snt.df)%>% as_tibble()
  
  
  assign('mh.runs.12.all',mh.runs.12.all,envir = globalenv())
}

mh.runs.f.12(manholes.snt.pol)

# mh.12.cod.plt
# mh.12.tss.plt
# mh.runs.12.all
# 
# remove(mh.12.cod.plt,mh.12.tss.plt,mh.runs.12.all,name)

# 30 min max-min
mh.runs.f.30 <- function(
    data = manholes.snt.pol
){
  mh.runs.30 <- manholes.snt.pol %>%
    group_by(run)%>%
    group_map(
      ~ dw.var.spt.resol.processing.plots(
        .,tem.res.in.min.int = 30))%>%
    bind_rows()
  
  mh.runs.30.max <-mh.runs.30%>% 
    max.dw.var.spt.resol.processing.plots(
      .,tem.res.in.min.int = 30)
  
  mh.runs.30.min <-mh.runs.30%>% 
    min.dw.var.spt.resol.processing.plots(
      .,tem.res.in.min.int = 30)
  
  #Proper col names for plotting
  mh.runs.30.max <- rename(
    mh.runs.30.max, cod.mx=cod.mgl,tss.mx=tss.mgl,lts.mx=lts.vol)
  
  mh.runs.30.min <- rename(
    mh.runs.30.min, cod.mn=cod.mgl,tss.mn=tss.mgl,lts.mn=lts.vol)
  
  #Join DF
  mh.runs.30.all <- right_join(
    mh.runs.30.max,mh.runs.30.min) %>% as_tibble()
  
  mh.runs.30.all <- right_join(
    mh.runs.30.all, mh.out.30min.snt.df)%>% as_tibble()
  
  
  assign('mh.runs.30.all',mh.runs.30.all,envir = globalenv())
}

mh.runs.f.30(manholes.snt.pol)

# mh.30.cod.plt
# mh.30.tss.plt
# mh.runs.30.all
# 
# remove(mh.30.cod.plt,mh.30.tss.plt,mh.runs.30.all,name)

# 60 min max-min
mh.runs.f.60 <- function(
    data = manholes.snt.pol
){
  mh.runs.60 <- manholes.snt.pol %>%
    group_by(run)%>%
    group_map(
      ~ dw.var.spt.resol.processing.plots(
        .,tem.res.in.min.int = 60))%>%
    bind_rows()
  
  mh.runs.60.max <-mh.runs.60%>% 
    max.dw.var.spt.resol.processing.plots(
      .,tem.res.in.min.int = 60)
  
  mh.runs.60.min <-mh.runs.60%>% 
    min.dw.var.spt.resol.processing.plots(
      .,tem.res.in.min.int = 60)
  
  #Proper col names for plotting
  mh.runs.60.max <- rename(
    mh.runs.60.max, cod.mx=cod.mgl,tss.mx=tss.mgl,lts.mx=lts.vol)
  
  mh.runs.60.min <- rename(
    mh.runs.60.min, cod.mn=cod.mgl,tss.mn=tss.mgl,lts.mn=lts.vol)
  
  #Join DF
  mh.runs.60.all <- right_join(
    mh.runs.60.max,mh.runs.60.min) %>% as_tibble()
  
  mh.runs.60.all <- right_join(
    mh.runs.60.all, mh.out.60min.snt.df)%>% as_tibble()
  
  
  assign('mh.runs.60.all',mh.runs.60.all,envir = globalenv())
}

mh.runs.f.60(manholes.snt.pol)

# mh.60.cod.plt
# mh.60.tss.plt
# mh.runs.60.all
# 
# remove(mh.60.cod.plt,mh.60.tss.plt,mh.runs.60.all,name)

# 180 min max-min

mh.runs.f.180 <- function(
    data = manholes.snt.pol
){
  mh.runs.180 <- manholes.snt.pol %>%
    group_by(run)%>%
    group_map(
      ~ dw.var.spt.resol.processing.plots(
        .,tem.res.in.min.int = 180))%>%
    bind_rows()
  
  mh.runs.180.max <-mh.runs.180%>% 
    max.dw.var.spt.resol.processing.plots(
      .,tem.res.in.min.int = 180)
  
  mh.runs.180.min <-mh.runs.180%>% 
    min.dw.var.spt.resol.processing.plots(
      .,tem.res.in.min.int = 180)
  
  #Proper col names for plotting
  mh.runs.180.max <- rename(
    mh.runs.180.max, cod.mx=cod.mgl,tss.mx=tss.mgl,lts.mx=lts.vol)
  
  mh.runs.180.min <- rename(
    mh.runs.180.min, cod.mn=cod.mgl,tss.mn=tss.mgl,lts.mn=lts.vol)
  
  #Join DF
  mh.runs.180.all <- right_join(
    mh.runs.180.max,mh.runs.180.min) %>% as_tibble()
  
  mh.runs.180.all <- right_join(
    mh.runs.180.all, mh.out.180min.snt.df)%>% as_tibble()
  
  
  assign('mh.runs.180.all',mh.runs.180.all,envir = globalenv())
}

mh.runs.f.180(manholes.snt.pol)

# mh.180.cod.plt
# mh.180.tss.plt
# mh.runs.180.all
# 
# remove(mh.180.cod.plt,mh.180.tss.plt,mh.runs.180.all,name)

# Exporting Avg.70.sim results ----

#Checking results
# mh.out.06min.snt.df %>% .$date.time %>% lubridate::hour(.) %>% unique()
# mh.out.12min.snt.df %>% .$date.time %>% lubridate::hour(.) %>% unique()
# mh.out.30min.snt.df %>% .$date.time %>% lubridate::hour(.) %>% unique()
# mh.out.60min.snt.df %>% .$date.time %>% lubridate::hour(.) %>% unique()
# mh.out.180min.snt.df %>% .$date.time %>% lubridate::hour(.) %>% unique()

#Adding max an min to final results

mh.out.06min.snt.df <- mh.runs.06.all
mh.out.12min.snt.df <- mh.runs.12.all
mh.out.30min.snt.df <- mh.runs.30.all
mh.out.60min.snt.df <- mh.runs.60.all
mh.out.180min.snt.df <- mh.runs.180.all

#Files for processing model validation
write_csv(mh.out.06min.snt.df,'results/calibration.snt/mh.out.06min.snt.df.csv')
write_csv(mh.out.12min.snt.df,'results/calibration.snt/mh.out.12min.snt.df.csv')
write_csv(mh.out.30min.snt.df,'results/calibration.snt/mh.out.30min.snt.df.csv')
write_csv(mh.out.60min.snt.df,'results/calibration.snt/mh.out.60min.snt.df.csv')
write_csv(mh.out.180min.snt.df,'results/calibration.snt/mh.out.180min.snt.df.csv')

#Removing unused variables for validation after exporting files
#Keep ver.tim variable
remove(
       mh.runs.06.all,
       mh.runs.12.all,
       mh.runs.30.all,
       mh.runs.60.all,
       mh.runs.180.all,
       blocks.snt.pol,
       manholes.snt.pol,
       filter.val.range,
       dw.var.spt.resol.processing.plots,
       name,
       max.dw.var.spt.resol.processing.plots,
       min.dw.var.spt.resol.processing.plots,
       mh.runs.f.06,
       mh.runs.f.12,
       mh.runs.f.30,
       mh.runs.f.60,
       mh.runs.f.180
       # mh.out.06min.snt.df,
       # mh.out.12min.snt.df,
       # mh.out.30min.snt.df,
       # mh.out.60min.snt.df,
       # mh.out.180min.snt.df,
       )

#clean memory
gc()

#Execute validation: correlation tables
#source("code/dw.abm.validation.snt.cal.val.1.R")












