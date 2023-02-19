# Script for evaluating DW modeling results

# Requirements
library(dplyr)
library(purrr)
library(dygraphs)
library(xts)
library(tidyr)
library(stringr)
library(lubridate)
library(readr)
library(BayesFactor)
library(ggstatsplot)
library(here)
library(ggplot2)
library(statsExpressions)
library(correlation)

### >>> NO CALIBRATED <<< ----

#Importing multiple spt resolutions from DW SMS-ABM ------------------------------

mh.out.06min.snt.df <- read_csv('results/calibration.snt/no.cal.mh.out.06min.snt.df.csv')
mh.out.12min.snt.df <- read_csv('results/calibration.snt/no.cal.mh.out.12min.snt.df.csv')
mh.out.30min.snt.df <- read_csv('results/calibration.snt/no.cal.mh.out.30min.snt.df.csv')
mh.out.60min.snt.df <- read_csv('results/calibration.snt/no.cal.mh.out.60min.snt.df.csv')
mh.out.180min.snt.df <- read_csv('results/calibration.snt/no.cal.mh.out.180min.snt.df.csv')

#manhole.id 460 is the inflow of wwtp

mh.out.06min.snt.df$manhole.id[mh.out.06min.snt.df$manhole.id == 460] <- 'wwtp'
mh.out.12min.snt.df$manhole.id[mh.out.12min.snt.df$manhole.id == 460] <- 'wwtp'
mh.out.30min.snt.df$manhole.id[mh.out.30min.snt.df$manhole.id == 460] <- 'wwtp'
mh.out.60min.snt.df$manhole.id[mh.out.60min.snt.df$manhole.id == 460] <- 'wwtp'
mh.out.180min.snt.df$manhole.id[mh.out.180min.snt.df$manhole.id == 460] <- 'wwtp'

mh.out.06min.snt.df$manhole.id %>% unique()
mh.out.12min.snt.df$manhole.id %>% unique()
mh.out.30min.snt.df$manhole.id %>% unique()
mh.out.60min.snt.df$manhole.id %>% unique()
mh.out.180min.snt.df$manhole.id %>% unique()

# variable mh and wwtp simulations
sim.mh.wwtp.06min.snt <-  mh.out.06min.snt.df
sim.mh.wwtp.12min.snt <-  mh.out.12min.snt.df
sim.mh.wwtp.30min.snt <-  mh.out.30min.snt.df
sim.mh.wwtp.60min.snt <-  mh.out.60min.snt.df
sim.mh.wwtp.180min.snt <- mh.out.180min.snt.df
#sim.mh.wwtp.180min.snt$date.time<-sim.mh.wwtp.180min.snt$date.time +3600

#Fieldwork validation data DW- COD.TSS.BOD ----------------------

#> 6 min DW- COD.TSS.BOD
fwmh.stn.val.06min <- read_csv("data/fwmh.stn.val.csv") %>% as_tibble()
fwmh.stn.val.06min <- rename(fwmh.stn.val.06min, date.time=rdate)
fwmh.stn.val.06min <- rename(fwmh.stn.val.06min, manhole.id=PTAR)
fwmh.stn.val.06min <- rename(fwmh.stn.val.06min, ob.cod.mgl=DQO)
fwmh.stn.val.06min <- rename(fwmh.stn.val.06min, ob.bod.mgl=DBO)
fwmh.stn.val.06min <- rename(fwmh.stn.val.06min, ob.tss.mgl=TSS)
fwmh.stn.val.06min <- rename(fwmh.stn.val.06min, ob.no3.mgl=NO3)
fwmh.stn.val.06min <- rename(fwmh.stn.val.06min, id=...1)

fwmh.stn.val.06min$date.time <- as.POSIXct(
  fwmh.stn.val.06min$date.time, format="%d/%m/%Y %H:%M")

# manholes_id's nodes for SMS-ABM model validation ----

# fwmh.stn.val$PTAR == snt.mhole1  ~  mh.out.snt.df$manhole_id == 39
# fwmh.stn.val$PTAR == snt.mhole2 ~   mh.out.snt.df$manhole_id == 258

fwmh.stn.val.06min<- fwmh.stn.val.06min %>%
  mutate(manhole.id = replace(manhole.id, manhole.id== "snt.in", 'wwtp'),
         manhole.id = replace(manhole.id, manhole.id== "snt.mhole1", 39),
         manhole.id = replace(manhole.id, manhole.id== "snt.mhole2", 258)
  )

#fwmh.stn.val.06min %>% head()

#>  Fun: validation.SPT resolutions DW- COD.TSS.BOD
dwfw.var.spt.resol.processing <- function(
    tem.res.in.min.int = 12,
    mh.loc.pol = fwmh.stn.val.06min,
    date.1.str = "2022-03-19",
    date.2.str = "2022-03-20",
    date.3.str = "2022-03-21",
    date.4.str = "2022-03-22",
    date.5.str = "2022-03-23",
    mh.out.res.loc.df = 'fwmh.stn.val.12min.df',
    mh.out.res.loc.plot = 'fwmh.stn.val.12min.plot'
){
  
  # Manholes  
  
  mh.loc.pol.min <- mh.loc.pol
  mh.loc.pol.min$date.time <- align.time(as.POSIXct(mh.loc.pol.min$date.time), tem.res.in.min.int * 60)
  
  
  #Pollutants concentration applies mean values in a time window
  #This applies when the concentration from two events is combined:Target question
  dw.manholes.minute.cod <- aggregate(ob.cod.mgl ~
                                        format(as.POSIXct(mh.loc.pol.min$date.time), "%Y-%m-%d %H:%M")+ 
                                        mh.loc.pol.min$manhole.id,
                                      data= mh.loc.pol.min,
                                      FUN = mean)%>% as_tibble()
  
  dw.manholes.minute.tss <- aggregate(ob.tss.mgl ~
                                        format(as.POSIXct(mh.loc.pol.min$date.time), "%Y-%m-%d %H:%M")+ 
                                        mh.loc.pol.min$manhole.id,
                                      data= mh.loc.pol.min,
                                      FUN = mean)%>% as_tibble()
  
  #Liters apply the sum of the values in a time window
  #This applies when the total amount of DW production is the target
  dw.manholes.minute.bod <- aggregate(ob.bod.mgl ~ 
                                        format(as.POSIXct(mh.loc.pol.min$date.time), "%Y-%m-%d %H:%M")+ 
                                        mh.loc.pol.min$manhole.id,
                                      data= mh.loc.pol.min,
                                      FUN = 'mean')%>% as_tibble()
  
  #Merged COD TSS LTS by space-time
  mh.out.res.name.df <- inner_join(dw.manholes.minute.cod,dw.manholes.minute.tss)
  mh.out.res.name.df <- inner_join(mh.out.res.name.df,dw.manholes.minute.bod)
  
  colnames(mh.out.res.name.df) <-c("date.time","manhole.id","ob.cod.mgl","ob.tss.mgl","ob.bod.mgl")
  mh.out.res.name.df$date.time <- parse_date_time(mh.out.res.name.df$date.time, orders = c("%Y-%m-%d %H:%M"))
  
  
  # Plotting all results
  
  # mh.out.res.name.plot <- c(
  #   dwplot.list.manhole.1,dwplot.list.manhole.2,dwplot.list.manhole.3,
  #   dwplot.list.manhole.4,dwplot.list.manhole.5)
  
  #Saving results
  assign(mh.out.res.loc.df,mh.out.res.name.df,
         envir = globalenv())
  
  # assign(mh.out.res.loc.plot,mh.out.res.name.plot,
  #        envir = globalenv())
  
  #Plotting
  #htmltools::browsable(htmltools::tagList(mh.out.res.name.plot))
  
}

#> FW 06 min DW- COD.TSS.BOD validation
dwfw.var.spt.resol.processing(
  tem.res.in.min.int = 06,
  mh.loc.pol = fwmh.stn.val.06min,
  date.1.str = "2022-03-19",
  date.2.str = "2022-03-20",
  date.3.str = "2022-03-21",
  date.4.str = "2022-03-22",
  date.5.str = "2022-03-23",
  mh.out.res.loc.df = 'fwmh.stn.val.06min.df',
  mh.out.res.loc.plot = 'fwmh.stn.val.06min.plot')

#htmltools::browsable(htmltools::tagList(fwmh.stn.val.06min.plot))


#> FW 12 min DW- COD.TSS.BOD validation
dwfw.var.spt.resol.processing(
  tem.res.in.min.int = 12,
  mh.loc.pol = fwmh.stn.val.06min,
  date.1.str = "2022-03-19",
  date.2.str = "2022-03-20",
  date.3.str = "2022-03-21",
  date.4.str = "2022-03-22",
  date.5.str = "2022-03-23",
  mh.out.res.loc.df = 'fwmh.stn.val.12min.df',
  mh.out.res.loc.plot = 'fwmh.stn.val.12min.plot')

#htmltools::browsable(htmltools::tagList(fwmh.stn.val.12min.plot))

#> FW 30 min DW- COD.TSS.BOD validation
dwfw.var.spt.resol.processing(
  tem.res.in.min.int = 30,
  mh.loc.pol = fwmh.stn.val.06min,
  date.1.str = "2022-03-19",
  date.2.str = "2022-03-20",
  date.3.str = "2022-03-21",
  date.4.str = "2022-03-22",
  date.5.str = "2022-03-23",
  mh.out.res.loc.df = 'fwmh.stn.val.30min.df',
  mh.out.res.loc.plot = 'fwmh.stn.val.30min.plot')

#htmltools::browsable(htmltools::tagList(fwmh.stn.val.30min.plot))

#> FW 60 min DW- COD.TSS.BOD validation
dwfw.var.spt.resol.processing(
  tem.res.in.min.int = 60,
  mh.loc.pol = fwmh.stn.val.06min,
  date.1.str = "2022-03-19",
  date.2.str = "2022-03-20",
  date.3.str = "2022-03-21",
  date.4.str = "2022-03-22",
  date.5.str = "2022-03-23",
  mh.out.res.loc.df = 'fwmh.stn.val.60min.df',
  mh.out.res.loc.plot = 'fwmh.stn.val.60min.plot')

#htmltools::browsable(htmltools::tagList(fwmh.stn.val.60min.plot))

#> FW 180 min DW- COD.TSS.BOD validation
dwfw.var.spt.resol.processing(
  tem.res.in.min.int = 180,
  mh.loc.pol = fwmh.stn.val.06min,
  date.1.str = "2022-03-19",
  date.2.str = "2022-03-20",
  date.3.str = "2022-03-21",
  date.4.str = "2022-03-22",
  date.5.str = "2022-03-23",
  mh.out.res.loc.df = 'fwmh.stn.val.180min.df',
  mh.out.res.loc.plot = 'fwmh.stn.val.180min.plot')
  #fwmh.stn.val.180min.df$date.time<-fwmh.stn.val.180min.df$date.time -3600

#htmltools::browsable(htmltools::tagList(fwmh.stn.val.180min.plot))

#  > Intersection: Obs v.s. Sim <------------------------ ================

no.cal.obs.sim.stn.06min <- inner_join(
  fwmh.stn.val.06min.df,sim.mh.wwtp.06min.snt) %>% as_tibble()

no.cal.obs.sim.stn.12min <- inner_join(
  fwmh.stn.val.12min.df,sim.mh.wwtp.12min.snt) %>% as_tibble()

no.cal.obs.sim.stn.30min <- inner_join(
  fwmh.stn.val.30min.df,sim.mh.wwtp.30min.snt) %>% as_tibble()

no.cal.obs.sim.stn.60min <- inner_join(
  fwmh.stn.val.60min.df,sim.mh.wwtp.60min.snt) %>% as_tibble()

no.cal.obs.sim.stn.180min <- inner_join(
  fwmh.stn.val.180min.df,sim.mh.wwtp.180min.snt) %>% as_tibble()

#Clean unused variables and save memory
# rm(list=ls()[! ls() %in% c(
#   "no.cal.obs.sim.stn.06min",
#   "no.cal.obs.sim.stn.12min",
#   "no.cal.obs.sim.stn.180min",
#   "no.cal.obs.sim.stn.30min",
#   "no.cal.obs.sim.stn.60min",
#   "ver.tim"
# )])

#clean memory
#gc()

# > Performance CORRELATIONS: sim v.s. obs <------------------------ ================

#Define calib-validation hours
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

#Tuesday- as calibration & Monday as validation
no.cal.obs.sim.stn.06min %>%
  filter(between(date.time, dt.val[4,1], dt.val[4,2])) %>%
  .$date.time%>%wday(label=TRUE)

no.cal.obs.sim.stn.06min %>%
  filter(between(date.time, dt.val[3,1], dt.val[3,2])) %>%
  mutate(.,cal.day = wday(.$date.time,label=TRUE)) %>% .[,c('cal.day')]

no.cal.obs.sim.stn.06min %>%
  filter(between(date.time, dt.val[4,1], dt.val[4,2])) %>%
  mutate(.,cal.day = wday(.$date.time,label=TRUE)) %>% .[,c('cal.day')]

no.cal.obs.sim.stn.06min %>%
  filter(between(date.time, dt.val[5,1], dt.val[5,2])) %>%
  mutate(.,cal.day = wday(.$date.time,label=TRUE)) %>% .[,c('cal.day')]

#Correlation for specific spatio-temporal resolutions

#For calibration day
cal.dw.corr.whole <- function(
    tem.res = 60,
    obs.sim.loc.t.resol= no.cal.obs.sim.stn.60min,
    mh.id = 258,
    sim.pollutat= "cod.mgl",
    obs.pollutat= "ob.cod.mgl")
{
  x<- tibble(ver.tm = {{ver.tim}},
             res.min = tem.res,
             manhole.id =mh.id)
  
  #Tuesday-Calibration day
  a <- obs.sim.loc.t.resol %>%
    filter(between(date.time, dt.val[4,1], dt.val[4,2]))%>%
    filter(manhole.id == mh.id) %>%
    correlation(select =c(obs.pollutat,sim.pollutat)) %>% 
    as_tibble()%>% rename(., r.cal.T=r)
  
  as_tibble(cbind(x,a))
}

#For validation day 1
vald1.dw.corr.whole <- function(
    tem.res = 60,
    obs.sim.loc.t.resol= no.cal.obs.sim.stn.60min,
    mh.id = 258,
    sim.pollutat= "cod.mgl",
    obs.pollutat= "ob.cod.mgl")
{
  x<- tibble(ver.tm = {{ver.tim}},
             res.min = tem.res,
             manhole.id =mh.id)
  
  #Monday-Validation day
  b <- obs.sim.loc.t.resol %>%
    filter(between(date.time, dt.val[3,1], dt.val[3,2]))%>%
    filter(manhole.id == mh.id) %>%
    correlation(select =c(obs.pollutat,sim.pollutat)) %>%
    as_tibble() %>% rename(., r.val.M=r)
  
  as_tibble(cbind(x,b))
}


#Table of correlation to all spatiotemporal combinations

#For calibration day
no.cal.tbl.sim.corr.cal.T<- function(
    dw.corr.tbl = paste('corr.tbl.cal.T',{{ver.tim}})){
  
  z<-rbind(
    as_tibble(cal.dw.corr.whole(180,no.cal.obs.sim.stn.180min,'wwtp',"cod.mgl","ob.cod.mgl")),
    as_tibble(cal.dw.corr.whole(60,no.cal.obs.sim.stn.60min,'wwtp',"cod.mgl","ob.cod.mgl")),
    as_tibble(cal.dw.corr.whole(30,no.cal.obs.sim.stn.30min,'wwtp',"cod.mgl","ob.cod.mgl")),
    as_tibble(cal.dw.corr.whole(12,no.cal.obs.sim.stn.12min,'wwtp',"cod.mgl","ob.cod.mgl")),
    as_tibble(cal.dw.corr.whole(06,no.cal.obs.sim.stn.06min,'wwtp',"cod.mgl","ob.cod.mgl"))
  )
  
  x<-rbind(
    as_tibble(cal.dw.corr.whole(180,no.cal.obs.sim.stn.180min,258,"cod.mgl","ob.cod.mgl")),
    as_tibble(cal.dw.corr.whole(60,no.cal.obs.sim.stn.60min,258,"cod.mgl","ob.cod.mgl")),
    as_tibble(cal.dw.corr.whole(30,no.cal.obs.sim.stn.30min,258,"cod.mgl","ob.cod.mgl")),
    as_tibble(cal.dw.corr.whole(12,no.cal.obs.sim.stn.12min,258,"cod.mgl","ob.cod.mgl")),
    as_tibble(cal.dw.corr.whole(06,no.cal.obs.sim.stn.06min,258,"cod.mgl","ob.cod.mgl"))
  )
  
  c<-rbind(
    as_tibble(cal.dw.corr.whole(180,no.cal.obs.sim.stn.180min,39,"cod.mgl","ob.cod.mgl")),
    as_tibble(cal.dw.corr.whole(60,no.cal.obs.sim.stn.30min,39,"cod.mgl","ob.cod.mgl")),
    as_tibble(cal.dw.corr.whole(30,no.cal.obs.sim.stn.30min,39,"cod.mgl","ob.cod.mgl")),
    as_tibble(cal.dw.corr.whole(12,no.cal.obs.sim.stn.12min,39,"cod.mgl","ob.cod.mgl")),
    as_tibble(cal.dw.corr.whole(06,no.cal.obs.sim.stn.06min,39,"cod.mgl","ob.cod.mgl"))
  )
  
  v<-rbind(
    as_tibble(cal.dw.corr.whole(180,no.cal.obs.sim.stn.180min,'wwtp',"tss.mgl","ob.tss.mgl")),
    as_tibble(cal.dw.corr.whole(60,no.cal.obs.sim.stn.60min,'wwtp',"tss.mgl","ob.tss.mgl")),
    as_tibble(cal.dw.corr.whole(30,no.cal.obs.sim.stn.30min,'wwtp',"tss.mgl","ob.tss.mgl")),
    as_tibble(cal.dw.corr.whole(12,no.cal.obs.sim.stn.12min,'wwtp',"tss.mgl","ob.tss.mgl")),
    as_tibble(cal.dw.corr.whole(06,no.cal.obs.sim.stn.06min,'wwtp',"tss.mgl","ob.tss.mgl"))
  )
  
  b<-rbind(
    as_tibble(cal.dw.corr.whole(180,no.cal.obs.sim.stn.180min,258,"tss.mgl","ob.tss.mgl")),
    as_tibble(cal.dw.corr.whole(60,no.cal.obs.sim.stn.60min,258,"tss.mgl","ob.tss.mgl")),
    as_tibble(cal.dw.corr.whole(30,no.cal.obs.sim.stn.30min,258,"tss.mgl","ob.tss.mgl")),
    as_tibble(cal.dw.corr.whole(12,no.cal.obs.sim.stn.12min,258,"tss.mgl","ob.tss.mgl")),
    as_tibble(cal.dw.corr.whole(06,no.cal.obs.sim.stn.06min,258,"tss.mgl","ob.tss.mgl"))
  )
  
  n<-rbind(
    as_tibble(cal.dw.corr.whole(180,no.cal.obs.sim.stn.180min,39,"tss.mgl","ob.tss.mgl")),
    as_tibble(cal.dw.corr.whole(60,no.cal.obs.sim.stn.60min,39,"tss.mgl","ob.tss.mgl")),
    as_tibble(cal.dw.corr.whole(30,no.cal.obs.sim.stn.30min,39,"tss.mgl","ob.tss.mgl")),
    as_tibble(cal.dw.corr.whole(12,no.cal.obs.sim.stn.12min,39,"tss.mgl","ob.tss.mgl")),
    as_tibble(cal.dw.corr.whole(06,no.cal.obs.sim.stn.06min,39,"tss.mgl","ob.tss.mgl"))
  )
  
  dw.results <- as_tibble(rbind(z,x,c,v,b,n))
  
  #Adding to environment
  assign(dw.corr.tbl,dw.results,envir = globalenv())
  #Storing at folder
  #write_csv(dw.results,paste('results/calibration.snt/',{{ver.tim}},'.corr.tbl.cal.T.csv', sep=""))
  #Show results in console
  dw.results
  
}

#For validation day 1
no.cal.tbl.sim.corr.val.d1<- function(
    dw.corr.tbl = paste('corr.tbl.cal.M',{{ver.tim}})){
  
  z<-rbind(
    as_tibble(vald1.dw.corr.whole(180,no.cal.obs.sim.stn.180min,'wwtp',"cod.mgl","ob.cod.mgl")),
    as_tibble(vald1.dw.corr.whole(60,no.cal.obs.sim.stn.60min,'wwtp',"cod.mgl","ob.cod.mgl")),
    as_tibble(vald1.dw.corr.whole(30,no.cal.obs.sim.stn.30min,'wwtp',"cod.mgl","ob.cod.mgl")),
    as_tibble(vald1.dw.corr.whole(12,no.cal.obs.sim.stn.12min,'wwtp',"cod.mgl","ob.cod.mgl")),
    as_tibble(vald1.dw.corr.whole(06,no.cal.obs.sim.stn.06min,'wwtp',"cod.mgl","ob.cod.mgl"))
  )
  
  x<-rbind(
    as_tibble(vald1.dw.corr.whole(180,no.cal.obs.sim.stn.180min,258,"cod.mgl","ob.cod.mgl")),
    as_tibble(vald1.dw.corr.whole(60,no.cal.obs.sim.stn.60min,258,"cod.mgl","ob.cod.mgl")),
    as_tibble(vald1.dw.corr.whole(30,no.cal.obs.sim.stn.30min,258,"cod.mgl","ob.cod.mgl")),
    as_tibble(vald1.dw.corr.whole(12,no.cal.obs.sim.stn.12min,258,"cod.mgl","ob.cod.mgl")),
    as_tibble(vald1.dw.corr.whole(06,no.cal.obs.sim.stn.06min,258,"cod.mgl","ob.cod.mgl"))
  )
  
  c<-rbind(
    as_tibble(vald1.dw.corr.whole(180,no.cal.obs.sim.stn.180min,39,"cod.mgl","ob.cod.mgl")),
    as_tibble(vald1.dw.corr.whole(60,no.cal.obs.sim.stn.30min,39,"cod.mgl","ob.cod.mgl")),
    as_tibble(vald1.dw.corr.whole(30,no.cal.obs.sim.stn.30min,39,"cod.mgl","ob.cod.mgl")),
    as_tibble(vald1.dw.corr.whole(12,no.cal.obs.sim.stn.12min,39,"cod.mgl","ob.cod.mgl")),
    as_tibble(vald1.dw.corr.whole(06,no.cal.obs.sim.stn.06min,39,"cod.mgl","ob.cod.mgl"))
  )
  
  v<-rbind(
    as_tibble(vald1.dw.corr.whole(180,no.cal.obs.sim.stn.180min,'wwtp',"tss.mgl","ob.tss.mgl")),
    as_tibble(vald1.dw.corr.whole(60,no.cal.obs.sim.stn.60min,'wwtp',"tss.mgl","ob.tss.mgl")),
    as_tibble(vald1.dw.corr.whole(30,no.cal.obs.sim.stn.30min,'wwtp',"tss.mgl","ob.tss.mgl")),
    as_tibble(vald1.dw.corr.whole(12,no.cal.obs.sim.stn.12min,'wwtp',"tss.mgl","ob.tss.mgl")),
    as_tibble(vald1.dw.corr.whole(06,no.cal.obs.sim.stn.06min,'wwtp',"tss.mgl","ob.tss.mgl"))
  )
  
  b<-rbind(
    as_tibble(vald1.dw.corr.whole(180,no.cal.obs.sim.stn.180min,258,"tss.mgl","ob.tss.mgl")),
    as_tibble(vald1.dw.corr.whole(60,no.cal.obs.sim.stn.60min,258,"tss.mgl","ob.tss.mgl")),
    as_tibble(vald1.dw.corr.whole(30,no.cal.obs.sim.stn.30min,258,"tss.mgl","ob.tss.mgl")),
    as_tibble(vald1.dw.corr.whole(12,no.cal.obs.sim.stn.12min,258,"tss.mgl","ob.tss.mgl")),
    as_tibble(vald1.dw.corr.whole(06,no.cal.obs.sim.stn.06min,258,"tss.mgl","ob.tss.mgl"))
  )
  
  n<-rbind(
    as_tibble(vald1.dw.corr.whole(180,no.cal.obs.sim.stn.180min,39,"tss.mgl","ob.tss.mgl")),
    as_tibble(vald1.dw.corr.whole(60,no.cal.obs.sim.stn.60min,39,"tss.mgl","ob.tss.mgl")),
    as_tibble(vald1.dw.corr.whole(30,no.cal.obs.sim.stn.30min,39,"tss.mgl","ob.tss.mgl")),
    as_tibble(vald1.dw.corr.whole(12,no.cal.obs.sim.stn.12min,39,"tss.mgl","ob.tss.mgl")),
    as_tibble(vald1.dw.corr.whole(06,no.cal.obs.sim.stn.06min,39,"tss.mgl","ob.tss.mgl"))
  )
  
  dw.results <- as_tibble(rbind(z,x,c,v,b,n))
  
  #Adding to environment
  assign(dw.corr.tbl,dw.results,envir = globalenv())
  #Storing at folder
  #write_csv(dw.results,paste('results/calibration.snt/',{{ver.tim}},'.corr.tbl.val.d1.csv', sep=""))
  #Show results in console
  dw.results
  
}

#Obtain table of correlations and and store its temporal version

#For calibration day = Tuesday
no.cal.tbl.sim.corr.cal.T(paste('corr.tbl.cal.d0',{{ver.tim}}))

#For validation day 1
no.cal.tbl.sim.corr.val.d1(paste('corr.tbl.val.d1',{{ver.tim}}))


# # #  > Patterns validation: sim v.s. obs <------------------------ ================

# Scatterplots correlations 5.days groupby_manhole.id ----

#Define plot fun and export png plots
poll.corr.plot.databy.mhole <- function(
    data = no.cal.obs.sim.stn.06min,
    tem.res.str = 'Resolution:06 min.',
    obs.pollut = ob.cod.mgl,
    sim.pollut = cod.mgl,
    plot.name = paste({{ver.tim}},'cor.obs.stn.06min.png')){
  
  set.seed(123)
  
  no.cal.obs.sim.stn.temp.resl.plot <- grouped_ggscatterstats(
    data             = dplyr::filter({{data}},
                                     manhole.id %in% c("wwtp","258","39")),
    x                = {{obs.pollut}},
    y                = {{sim.pollut}},
    grouping.var     = manhole.id,
    annotation.args  = list(title = "Assesing DW simulation: Correlation  Obs v.s. Sim",
                            paste(tem.res.str)),
    plotgrid.args    = list(nrow = 1, ncol = 3),
    ggtheme          = ggplot2::theme_light(),
    ggplot.component = list(
      ggplot2::scale_y_continuous(
        breaks = seq(0, 3600, 250),
        limits = (c(0, 3600))),
      ggplot2::scale_x_continuous(
        breaks = seq(0, 3600, 250),
        limits = (c(0, 3600))),
      theme(axis.text.x = element_text(angle = 90))
    ),
    xfill            = 'chocolate4', ## fill for marginals on the x-axis
    yfill            = 'chocolate'## fill for marginals on the y-axis
  )
  
  # ggsave(
  #   filename = here::here("img", "sim.vs.obs","calibration", plot.name),
  #   plot = no.cal.obs.sim.stn.temp.resl.plot,
  #   width = 24,
  #   height = 8,
  #   device = "png")
  
  #Adding to environment
  assign('no.cal.obs.sim.stn.temp.resl.plot',no.cal.obs.sim.stn.temp.resl.plot,envir = globalenv())
  
}

#  > dygraphs TS sim v.s. obs manholes <------------------------ ================

# Indv.mh.id + Max.Min + Obs.Val plotting functions----

#COD WWTP
dwts.dygraph.manhole.cod <- function(
    data,t.date, poll.sim, poll.obs, poll.sim.ch, poll.obs.ch){
  
  data %>%
    filter(manhole.id == 'wwtp')%>%
    select(date.time, manhole.id, 
           {{poll.sim}}, {{poll.obs}},
           cod.mn,cod.mx)%>%
    filter(str_detect(date.time,t.date))%>%
    pivot_wider(names_from = manhole.id,
                values_from = c({{poll.sim.ch}},{{poll.obs.ch}},
                                cod.mx,cod.mn))%>%
    xts(.,.$date.time)%>%
    dygraph(main = paste (wday(t.date,label = TRUE,abbr = FALSE),
                          "Pollutant ",
                          {{poll.sim.ch}},
                          sep=" - "),
            group = t.date)%>%
    dyOptions(drawPoints = TRUE, useDataTimezone = TRUE,
              pointSize = 2)%>%
    dyHighlight(highlightSeriesOpts = list(strokeWidth = 3),
                highlightSeriesBackgroundAlpha = 0.2) %>%
    dyAxis("y", label = "Concentration in mg/l") %>%
    dySeries("cod.mgl_wwtp", color = "#543005")%>%
    dySeries("ob.cod.mgl_wwtp", color = "#003c30")%>%
    dySeries("cod.mx_wwtp", color = "#e41a1c")%>%
    dySeries("cod.mn_wwtp", color = "#377eb8")
}


#TSS WWTP
dwts.dygraph.manhole.tss <- function(
    data,t.date, poll.sim, poll.obs, poll.sim.ch, poll.obs.ch){
  
  data %>%
    filter(manhole.id == 'wwtp')%>%
    select(date.time, manhole.id, 
           {{poll.sim}}, {{poll.obs}},
           tss.mn,tss.mx)%>%
    filter(str_detect(date.time,t.date))%>%
    pivot_wider(names_from = manhole.id,
                values_from = c({{poll.sim.ch}},{{poll.obs.ch}},
                                tss.mx,tss.mn))%>%
    xts(.,.$date.time)%>%
    dygraph(main = paste (wday(t.date,label = TRUE,abbr = FALSE),
                          "Pollutant ",
                          {{poll.sim.ch}},
                          sep=" - "),
            group = t.date)%>%
    dyOptions(drawPoints = TRUE, useDataTimezone = TRUE,
              pointSize = 2)%>%
    dyHighlight(highlightSeriesOpts = list(strokeWidth = 3),
                highlightSeriesBackgroundAlpha = 0.2) %>%
    dyAxis("y", label = "Concentration in mg/l") %>%
    dySeries("tss.mgl_wwtp", color = "#7f3b08")%>%
    dySeries("ob.tss.mgl_wwtp", color = "#2d004b")%>%
    dySeries("tss.mx_wwtp", color = "#e41a1c")%>%
    dySeries("tss.mn_wwtp", color = "#377eb8")
}



# run any COD dygraphs (mh.Obs.Val.Max.Min)----
val.days.snt <- c("2022-03-21") #Validation day 1
val.days.snt <- c("2022-03-22") #Calibration day 0

# #COD 06 min
# val.days.snt %>%
#   map(dwts.dygraph.manhole.cod,
#       data = no.cal.obs.sim.stn.06min,
#       poll.sim = cod.mgl,
#       poll.obs = ob.cod.mgl,
#       poll.sim.ch = 'cod.mgl',
#       poll.obs.ch= 'ob.cod.mgl')%>%
#   as.list() -> dwplot.list.1.mh
# 
# #htmltools::browsable(htmltools::tagList(dwplot.list.1.mh))
# 
# #COD 60 min
# val.days.snt %>%
#   map(dwts.dygraph.manhole.cod,
#       data = no.cal.obs.sim.stn.60min,
#       poll.sim = cod.mgl,
#       poll.obs = ob.cod.mgl,
#       poll.sim.ch = 'cod.mgl',
#       poll.obs.ch= 'ob.cod.mgl')%>%
#   as.list() -> dwplot.list.2.mh
# 
# #htmltools::browsable(htmltools::tagList(dwplot.list.2.mh))
# 
# #COD 180 min
# val.days.snt %>%
#   map(dwts.dygraph.manhole.cod,
#       data = no.cal.obs.sim.stn.180min,
#       poll.sim = cod.mgl,
#       poll.obs = ob.cod.mgl,
#       poll.sim.ch = 'cod.mgl',
#       poll.obs.ch= 'ob.cod.mgl')%>%
#   as.list() -> dwplot.list.3.mh

#htmltools::browsable(htmltools::tagList(dwplot.list.3.mh))

# run any TSS dygraphs (mh.Obs.Val.Max.Min)----

# #TSS 06 min
# val.days.snt %>%
#   map(dwts.dygraph.manhole.tss,
#       data = no.cal.obs.sim.stn.06min,
#       poll.sim = tss.mgl,
#       poll.obs = ob.tss.mgl,
#       poll.sim.ch = 'tss.mgl',
#       poll.obs.ch= 'ob.tss.mgl')%>%
#   as.list() -> dwplot.list.4.mh
# 
# #htmltools::browsable(htmltools::tagList(dwplot.list.4.mh))
# 
# #TSS 60 min
# val.days.snt %>%
#   map(dwts.dygraph.manhole.tss,
#       data = no.cal.obs.sim.stn.60min,
#       poll.sim = tss.mgl,
#       poll.obs = ob.tss.mgl,
#       poll.sim.ch = 'tss.mgl',
#       poll.obs.ch= 'ob.tss.mgl')%>%
#   as.list() -> dwplot.list.5.mh
# 
# #htmltools::browsable(htmltools::tagList(dwplot.list.5.mh))
# 
# #TSS 180 min
# val.days.snt %>%
#   map(dwts.dygraph.manhole.tss,
#       data = no.cal.obs.sim.stn.180min,
#       poll.sim = tss.mgl,
#       poll.obs = ob.tss.mgl,
#       poll.sim.ch = 'tss.mgl',
#       poll.obs.ch= 'ob.tss.mgl')%>%
#   as.list() -> dwplot.list.6.mh
# 
# #htmltools::browsable(htmltools::tagList(dwplot.list.6.mh))


#Plotting all

# htmltools::browsable(htmltools::tagList(
#   dwplot.list.1.mh,dwplot.list.2.mh,dwplot.list.3.mh,
#   dwplot.list.4.mh,dwplot.list.5.mh,dwplot.list.6.mh
# ))


### >>> CALIBRATED <<< ----


#Importing multiple spt resolutions from DW SMS-ABM ------------------------------

mh.out.06min.snt.df <- read_csv('results/calibration.snt/mh.out.06min.snt.df.csv')
mh.out.12min.snt.df <- read_csv('results/calibration.snt/mh.out.12min.snt.df.csv')
mh.out.30min.snt.df <- read_csv('results/calibration.snt/mh.out.30min.snt.df.csv')
mh.out.60min.snt.df <- read_csv('results/calibration.snt/mh.out.60min.snt.df.csv')
mh.out.180min.snt.df <- read_csv('results/calibration.snt/mh.out.180min.snt.df.csv')

#manhole.id 460 is the inflow of wwtp

mh.out.06min.snt.df$manhole.id[mh.out.06min.snt.df$manhole.id == 460] <- 'wwtp'
mh.out.12min.snt.df$manhole.id[mh.out.12min.snt.df$manhole.id == 460] <- 'wwtp'
mh.out.30min.snt.df$manhole.id[mh.out.30min.snt.df$manhole.id == 460] <- 'wwtp'
mh.out.60min.snt.df$manhole.id[mh.out.60min.snt.df$manhole.id == 460] <- 'wwtp'
mh.out.180min.snt.df$manhole.id[mh.out.180min.snt.df$manhole.id == 460] <- 'wwtp'

mh.out.06min.snt.df$manhole.id %>% unique()
mh.out.12min.snt.df$manhole.id %>% unique()
mh.out.30min.snt.df$manhole.id %>% unique()
mh.out.60min.snt.df$manhole.id %>% unique()
mh.out.180min.snt.df$manhole.id %>% unique()

# variable mh and wwtp simulations
sim.mh.wwtp.06min.snt <-  mh.out.06min.snt.df
sim.mh.wwtp.12min.snt <-  mh.out.12min.snt.df
sim.mh.wwtp.30min.snt <-  mh.out.30min.snt.df
sim.mh.wwtp.60min.snt <-  mh.out.60min.snt.df
sim.mh.wwtp.180min.snt <- mh.out.180min.snt.df
#sim.mh.wwtp.180min.snt$date.time<-sim.mh.wwtp.180min.snt$date.time +3600

#Fieldwork validation data DW- COD.TSS.BOD ----------------------

#> 6 min DW- COD.TSS.BOD
fwmh.stn.val.06min <- read_csv("data/fwmh.stn.val.csv") %>% as_tibble()
fwmh.stn.val.06min <- rename(fwmh.stn.val.06min, date.time=rdate)
fwmh.stn.val.06min <- rename(fwmh.stn.val.06min, manhole.id=PTAR)
fwmh.stn.val.06min <- rename(fwmh.stn.val.06min, ob.cod.mgl=DQO)
fwmh.stn.val.06min <- rename(fwmh.stn.val.06min, ob.bod.mgl=DBO)
fwmh.stn.val.06min <- rename(fwmh.stn.val.06min, ob.tss.mgl=TSS)
fwmh.stn.val.06min <- rename(fwmh.stn.val.06min, ob.no3.mgl=NO3)
fwmh.stn.val.06min <- rename(fwmh.stn.val.06min, id=...1)

fwmh.stn.val.06min$date.time <- as.POSIXct(
  fwmh.stn.val.06min$date.time, format="%d/%m/%Y %H:%M")

# manholes_id's nodes for SMS-ABM model validation ----

# fwmh.stn.val$PTAR == snt.mhole1  ~  mh.out.snt.df$manhole_id == 39
# fwmh.stn.val$PTAR == snt.mhole2 ~   mh.out.snt.df$manhole_id == 258

fwmh.stn.val.06min<- fwmh.stn.val.06min %>%
  mutate(manhole.id = replace(manhole.id, manhole.id== "snt.in", 'wwtp'),
         manhole.id = replace(manhole.id, manhole.id== "snt.mhole1", 39),
         manhole.id = replace(manhole.id, manhole.id== "snt.mhole2", 258)
  )

#fwmh.stn.val.06min %>% head()

#>  Fun: validation.SPT resolutions DW- COD.TSS.BOD
dwfw.var.spt.resol.processing <- function(
    tem.res.in.min.int = 12,
    mh.loc.pol = fwmh.stn.val.06min,
    date.1.str = "2022-03-19",
    date.2.str = "2022-03-20",
    date.3.str = "2022-03-21",
    date.4.str = "2022-03-22",
    date.5.str = "2022-03-23",
    mh.out.res.loc.df = 'fwmh.stn.val.12min.df',
    mh.out.res.loc.plot = 'fwmh.stn.val.12min.plot'
){
  
  # Manholes
  
  mh.loc.pol.min <- mh.loc.pol
  mh.loc.pol.min$date.time <- align.time(as.POSIXct(mh.loc.pol.min$date.time), tem.res.in.min.int * 60)
  
  
  #Pollutants concentration applies mean values in a time window
  #This applies when the concentration from two events is combined:Target question
  dw.manholes.minute.cod <- aggregate(ob.cod.mgl ~
                                        format(as.POSIXct(mh.loc.pol.min$date.time), "%Y-%m-%d %H:%M")+ 
                                        mh.loc.pol.min$manhole.id,
                                      data= mh.loc.pol.min,
                                      FUN = mean)%>% as_tibble()
  
  dw.manholes.minute.tss <- aggregate(ob.tss.mgl ~
                                        format(as.POSIXct(mh.loc.pol.min$date.time), "%Y-%m-%d %H:%M")+ 
                                        mh.loc.pol.min$manhole.id,
                                      data= mh.loc.pol.min,
                                      FUN = mean)%>% as_tibble()
  
  #Liters apply the sum of the values in a time window
  #This applies when the total amount of DW production is the target
  dw.manholes.minute.bod <- aggregate(ob.bod.mgl ~ 
                                        format(as.POSIXct(mh.loc.pol.min$date.time), "%Y-%m-%d %H:%M")+ 
                                        mh.loc.pol.min$manhole.id,
                                      data= mh.loc.pol.min,
                                      FUN = 'mean')%>% as_tibble()
  
  #Merged COD TSS LTS by space-time
  mh.out.res.name.df <- inner_join(dw.manholes.minute.cod,dw.manholes.minute.tss)
  mh.out.res.name.df <- inner_join(mh.out.res.name.df,dw.manholes.minute.bod)
  
  colnames(mh.out.res.name.df) <-c("date.time","manhole.id","ob.cod.mgl","ob.tss.mgl","ob.bod.mgl")
  mh.out.res.name.df$date.time <- parse_date_time(mh.out.res.name.df$date.time, orders = c("%Y-%m-%d %H:%M"))
  
  
  # Plotting all results
  
  # mh.out.res.name.plot <- c(
  #   dwplot.list.manhole.1,dwplot.list.manhole.2,dwplot.list.manhole.3,
  #   dwplot.list.manhole.4,dwplot.list.manhole.5)
  
  #Saving results
  assign(mh.out.res.loc.df,mh.out.res.name.df,
         envir = globalenv())
  
  # assign(mh.out.res.loc.plot,mh.out.res.name.plot,
  #        envir = globalenv())
  
  #Plotting
  #htmltools::browsable(htmltools::tagList(mh.out.res.name.plot))
  
}

#> FW 06 min DW- COD.TSS.BOD validation
dwfw.var.spt.resol.processing(
  tem.res.in.min.int = 06,
  mh.loc.pol = fwmh.stn.val.06min,
  date.1.str = "2022-03-19",
  date.2.str = "2022-03-20",
  date.3.str = "2022-03-21",
  date.4.str = "2022-03-22",
  date.5.str = "2022-03-23",
  mh.out.res.loc.df = 'fwmh.stn.val.06min.df',
  mh.out.res.loc.plot = 'fwmh.stn.val.06min.plot')

#htmltools::browsable(htmltools::tagList(fwmh.stn.val.06min.plot))


#> FW 12 min DW- COD.TSS.BOD validation
dwfw.var.spt.resol.processing(
  tem.res.in.min.int = 12,
  mh.loc.pol = fwmh.stn.val.06min,
  date.1.str = "2022-03-19",
  date.2.str = "2022-03-20",
  date.3.str = "2022-03-21",
  date.4.str = "2022-03-22",
  date.5.str = "2022-03-23",
  mh.out.res.loc.df = 'fwmh.stn.val.12min.df',
  mh.out.res.loc.plot = 'fwmh.stn.val.12min.plot')

#htmltools::browsable(htmltools::tagList(fwmh.stn.val.12min.plot))

#> FW 30 min DW- COD.TSS.BOD validation
dwfw.var.spt.resol.processing(
  tem.res.in.min.int = 30,
  mh.loc.pol = fwmh.stn.val.06min,
  date.1.str = "2022-03-19",
  date.2.str = "2022-03-20",
  date.3.str = "2022-03-21",
  date.4.str = "2022-03-22",
  date.5.str = "2022-03-23",
  mh.out.res.loc.df = 'fwmh.stn.val.30min.df',
  mh.out.res.loc.plot = 'fwmh.stn.val.30min.plot')

#htmltools::browsable(htmltools::tagList(fwmh.stn.val.30min.plot))

#> FW 60 min DW- COD.TSS.BOD validation
dwfw.var.spt.resol.processing(
  tem.res.in.min.int = 60,
  mh.loc.pol = fwmh.stn.val.06min,
  date.1.str = "2022-03-19",
  date.2.str = "2022-03-20",
  date.3.str = "2022-03-21",
  date.4.str = "2022-03-22",
  date.5.str = "2022-03-23",
  mh.out.res.loc.df = 'fwmh.stn.val.60min.df',
  mh.out.res.loc.plot = 'fwmh.stn.val.60min.plot')

#htmltools::browsable(htmltools::tagList(fwmh.stn.val.60min.plot))

#> FW 180 min DW- COD.TSS.BOD validation
dwfw.var.spt.resol.processing(
  tem.res.in.min.int = 180,
  mh.loc.pol = fwmh.stn.val.06min,
  date.1.str = "2022-03-19",
  date.2.str = "2022-03-20",
  date.3.str = "2022-03-21",
  date.4.str = "2022-03-22",
  date.5.str = "2022-03-23",
  mh.out.res.loc.df = 'fwmh.stn.val.180min.df',
  mh.out.res.loc.plot = 'fwmh.stn.val.180min.plot')
  #fwmh.stn.val.180min.df$date.time<-fwmh.stn.val.180min.df$date.time -3600
#htmltools::browsable(htmltools::tagList(fwmh.stn.val.180min.plot))

#  > Intersection: Obs v.s. Sim <------------------------ ================

obs.sim.stn.06min <- inner_join(
  fwmh.stn.val.06min.df,sim.mh.wwtp.06min.snt) %>% as_tibble()

obs.sim.stn.12min <- inner_join(
  fwmh.stn.val.12min.df,sim.mh.wwtp.12min.snt) %>% as_tibble()

obs.sim.stn.30min <- inner_join(
  fwmh.stn.val.30min.df,sim.mh.wwtp.30min.snt) %>% as_tibble()

obs.sim.stn.60min <- inner_join(
  fwmh.stn.val.60min.df,sim.mh.wwtp.60min.snt) %>% as_tibble()

obs.sim.stn.180min <- inner_join(
  fwmh.stn.val.180min.df,sim.mh.wwtp.180min.snt) %>% as_tibble()

#Clean unused variables and save memory
# rm(list=ls()[! ls() %in% c(
#   "obs.sim.stn.06min",
#   "obs.sim.stn.12min",
#   "obs.sim.stn.180min",
#   "obs.sim.stn.30min",
#   "obs.sim.stn.60min",
#   "ver.tim"
# )])

#clean memory
#gc()

# > Performance CORRELATIONS: sim v.s. obs <------------------------ ================

#Define calib-validation hours
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

#Tuesday- as calibration & Monday as validation
obs.sim.stn.06min %>%
  filter(between(date.time, dt.val[4,1], dt.val[4,2])) %>%
  .$date.time%>%wday(label=TRUE)

obs.sim.stn.06min %>%
  filter(between(date.time, dt.val[3,1], dt.val[3,2])) %>%
  mutate(.,cal.day = wday(.$date.time,label=TRUE)) %>% .[,c('cal.day')]

obs.sim.stn.06min %>%
  filter(between(date.time, dt.val[4,1], dt.val[4,2])) %>%
  mutate(.,cal.day = wday(.$date.time,label=TRUE)) %>% .[,c('cal.day')]

obs.sim.stn.06min %>%
  filter(between(date.time, dt.val[5,1], dt.val[5,2])) %>%
  mutate(.,cal.day = wday(.$date.time,label=TRUE)) %>% .[,c('cal.day')]

#Correlation for specific spatio-temporal resolutions

#For calibration day
cal.dw.corr.whole <- function(
    tem.res = 60,
    obs.sim.loc.t.resol= obs.sim.stn.60min,
    mh.id = 258,
    sim.pollutat= "cod.mgl",
    obs.pollutat= "ob.cod.mgl")
{
  x<- tibble(ver.tm = {{ver.tim}},
             res.min = tem.res,
             manhole.id =mh.id)
  
  #Tuesday-Calibration day
  a <- obs.sim.loc.t.resol %>%
    filter(between(date.time, dt.val[4,1], dt.val[4,2]))%>%
    filter(manhole.id == mh.id) %>%
    correlation(select =c(obs.pollutat,sim.pollutat)) %>% 
    as_tibble()%>% rename(., r.cal.T=r)
  
  as_tibble(cbind(x,a))
}

#For validation day 1
vald1.dw.corr.whole <- function(
    tem.res = 60,
    obs.sim.loc.t.resol= obs.sim.stn.60min,
    mh.id = 258,
    sim.pollutat= "cod.mgl",
    obs.pollutat= "ob.cod.mgl")
{
  x<- tibble(ver.tm = {{ver.tim}},
             res.min = tem.res,
             manhole.id =mh.id)
  
  #Monday-Validation day
  b <- obs.sim.loc.t.resol %>%
    filter(between(date.time, dt.val[3,1], dt.val[3,2]))%>%
    filter(manhole.id == mh.id) %>%
    correlation(select =c(obs.pollutat,sim.pollutat)) %>%
    as_tibble() %>% rename(., r.val.M=r)
  
  as_tibble(cbind(x,b))
}

#Table of correlation to all spatiotemporal combinations

#For calibration day
tbl.sim.corr.cal.T<- function(
    dw.corr.tbl = paste('corr.tbl.cal.T',{{ver.tim}})){
  
  z<-rbind(
    as_tibble(cal.dw.corr.whole(180,obs.sim.stn.180min,'wwtp',"cod.mgl","ob.cod.mgl")),
    as_tibble(cal.dw.corr.whole(60,obs.sim.stn.60min,'wwtp',"cod.mgl","ob.cod.mgl")),
    as_tibble(cal.dw.corr.whole(30,obs.sim.stn.30min,'wwtp',"cod.mgl","ob.cod.mgl")),
    as_tibble(cal.dw.corr.whole(12,obs.sim.stn.12min,'wwtp',"cod.mgl","ob.cod.mgl")),
    as_tibble(cal.dw.corr.whole(06,obs.sim.stn.06min,'wwtp',"cod.mgl","ob.cod.mgl"))
  )
  
  x<-rbind(
    as_tibble(cal.dw.corr.whole(180,obs.sim.stn.180min,258,"cod.mgl","ob.cod.mgl")),
    as_tibble(cal.dw.corr.whole(60,obs.sim.stn.60min,258,"cod.mgl","ob.cod.mgl")),
    as_tibble(cal.dw.corr.whole(30,obs.sim.stn.30min,258,"cod.mgl","ob.cod.mgl")),
    as_tibble(cal.dw.corr.whole(12,obs.sim.stn.12min,258,"cod.mgl","ob.cod.mgl")),
    as_tibble(cal.dw.corr.whole(06,obs.sim.stn.06min,258,"cod.mgl","ob.cod.mgl"))
  )
  
  c<-rbind(
    as_tibble(cal.dw.corr.whole(180,obs.sim.stn.180min,39,"cod.mgl","ob.cod.mgl")),
    as_tibble(cal.dw.corr.whole(60,obs.sim.stn.30min,39,"cod.mgl","ob.cod.mgl")),
    as_tibble(cal.dw.corr.whole(30,obs.sim.stn.30min,39,"cod.mgl","ob.cod.mgl")),
    as_tibble(cal.dw.corr.whole(12,obs.sim.stn.12min,39,"cod.mgl","ob.cod.mgl")),
    as_tibble(cal.dw.corr.whole(06,obs.sim.stn.06min,39,"cod.mgl","ob.cod.mgl"))
  )
  
  v<-rbind(
    as_tibble(cal.dw.corr.whole(180,obs.sim.stn.180min,'wwtp',"tss.mgl","ob.tss.mgl")),
    as_tibble(cal.dw.corr.whole(60,obs.sim.stn.60min,'wwtp',"tss.mgl","ob.tss.mgl")),
    as_tibble(cal.dw.corr.whole(30,obs.sim.stn.30min,'wwtp',"tss.mgl","ob.tss.mgl")),
    as_tibble(cal.dw.corr.whole(12,obs.sim.stn.12min,'wwtp',"tss.mgl","ob.tss.mgl")),
    as_tibble(cal.dw.corr.whole(06,obs.sim.stn.06min,'wwtp',"tss.mgl","ob.tss.mgl"))
  )
  
  b<-rbind(
    as_tibble(cal.dw.corr.whole(180,obs.sim.stn.180min,258,"tss.mgl","ob.tss.mgl")),
    as_tibble(cal.dw.corr.whole(60,obs.sim.stn.60min,258,"tss.mgl","ob.tss.mgl")),
    as_tibble(cal.dw.corr.whole(30,obs.sim.stn.30min,258,"tss.mgl","ob.tss.mgl")),
    as_tibble(cal.dw.corr.whole(12,obs.sim.stn.12min,258,"tss.mgl","ob.tss.mgl")),
    as_tibble(cal.dw.corr.whole(06,obs.sim.stn.06min,258,"tss.mgl","ob.tss.mgl"))
  )
  
  n<-rbind(
    as_tibble(cal.dw.corr.whole(180,obs.sim.stn.180min,39,"tss.mgl","ob.tss.mgl")),
    as_tibble(cal.dw.corr.whole(60,obs.sim.stn.60min,39,"tss.mgl","ob.tss.mgl")),
    as_tibble(cal.dw.corr.whole(30,obs.sim.stn.30min,39,"tss.mgl","ob.tss.mgl")),
    as_tibble(cal.dw.corr.whole(12,obs.sim.stn.12min,39,"tss.mgl","ob.tss.mgl")),
    as_tibble(cal.dw.corr.whole(06,obs.sim.stn.06min,39,"tss.mgl","ob.tss.mgl"))
  )
  
  dw.results <- as_tibble(rbind(z,x,c,v,b,n))
  
  #Adding to environment
  assign(dw.corr.tbl,dw.results,envir = globalenv())
  #Storing at folder
  #write_csv(dw.results,paste('results/calibration.snt/',{{ver.tim}},'.corr.tbl.cal.T.csv', sep=""))
  #Show results in console
  dw.results
  
}

#For validation day 1
tbl.sim.corr.val.d1<- function(
    dw.corr.tbl = paste('corr.tbl.cal.M',{{ver.tim}})){
  
  z<-rbind(
    as_tibble(vald1.dw.corr.whole(180,obs.sim.stn.180min,'wwtp',"cod.mgl","ob.cod.mgl")),
    as_tibble(vald1.dw.corr.whole(60,obs.sim.stn.60min,'wwtp',"cod.mgl","ob.cod.mgl")),
    as_tibble(vald1.dw.corr.whole(30,obs.sim.stn.30min,'wwtp',"cod.mgl","ob.cod.mgl")),
    as_tibble(vald1.dw.corr.whole(12,obs.sim.stn.12min,'wwtp',"cod.mgl","ob.cod.mgl")),
    as_tibble(vald1.dw.corr.whole(06,obs.sim.stn.06min,'wwtp',"cod.mgl","ob.cod.mgl"))
  )
  
  x<-rbind(
    as_tibble(vald1.dw.corr.whole(180,obs.sim.stn.180min,258,"cod.mgl","ob.cod.mgl")),
    as_tibble(vald1.dw.corr.whole(60,obs.sim.stn.60min,258,"cod.mgl","ob.cod.mgl")),
    as_tibble(vald1.dw.corr.whole(30,obs.sim.stn.30min,258,"cod.mgl","ob.cod.mgl")),
    as_tibble(vald1.dw.corr.whole(12,obs.sim.stn.12min,258,"cod.mgl","ob.cod.mgl")),
    as_tibble(vald1.dw.corr.whole(06,obs.sim.stn.06min,258,"cod.mgl","ob.cod.mgl"))
  )
  
  c<-rbind(
    as_tibble(vald1.dw.corr.whole(180,obs.sim.stn.180min,39,"cod.mgl","ob.cod.mgl")),
    as_tibble(vald1.dw.corr.whole(60,obs.sim.stn.30min,39,"cod.mgl","ob.cod.mgl")),
    as_tibble(vald1.dw.corr.whole(30,obs.sim.stn.30min,39,"cod.mgl","ob.cod.mgl")),
    as_tibble(vald1.dw.corr.whole(12,obs.sim.stn.12min,39,"cod.mgl","ob.cod.mgl")),
    as_tibble(vald1.dw.corr.whole(06,obs.sim.stn.06min,39,"cod.mgl","ob.cod.mgl"))
  )
  
  v<-rbind(
    as_tibble(vald1.dw.corr.whole(180,obs.sim.stn.180min,'wwtp',"tss.mgl","ob.tss.mgl")),
    as_tibble(vald1.dw.corr.whole(60,obs.sim.stn.60min,'wwtp',"tss.mgl","ob.tss.mgl")),
    as_tibble(vald1.dw.corr.whole(30,obs.sim.stn.30min,'wwtp',"tss.mgl","ob.tss.mgl")),
    as_tibble(vald1.dw.corr.whole(12,obs.sim.stn.12min,'wwtp',"tss.mgl","ob.tss.mgl")),
    as_tibble(vald1.dw.corr.whole(06,obs.sim.stn.06min,'wwtp',"tss.mgl","ob.tss.mgl"))
  )
  
  b<-rbind(
    as_tibble(vald1.dw.corr.whole(180,obs.sim.stn.180min,258,"tss.mgl","ob.tss.mgl")),
    as_tibble(vald1.dw.corr.whole(60,obs.sim.stn.60min,258,"tss.mgl","ob.tss.mgl")),
    as_tibble(vald1.dw.corr.whole(30,obs.sim.stn.30min,258,"tss.mgl","ob.tss.mgl")),
    as_tibble(vald1.dw.corr.whole(12,obs.sim.stn.12min,258,"tss.mgl","ob.tss.mgl")),
    as_tibble(vald1.dw.corr.whole(06,obs.sim.stn.06min,258,"tss.mgl","ob.tss.mgl"))
  )
  
  n<-rbind(
    as_tibble(vald1.dw.corr.whole(180,obs.sim.stn.180min,39,"tss.mgl","ob.tss.mgl")),
    as_tibble(vald1.dw.corr.whole(60,obs.sim.stn.60min,39,"tss.mgl","ob.tss.mgl")),
    as_tibble(vald1.dw.corr.whole(30,obs.sim.stn.30min,39,"tss.mgl","ob.tss.mgl")),
    as_tibble(vald1.dw.corr.whole(12,obs.sim.stn.12min,39,"tss.mgl","ob.tss.mgl")),
    as_tibble(vald1.dw.corr.whole(06,obs.sim.stn.06min,39,"tss.mgl","ob.tss.mgl"))
  )
  
  dw.results <- as_tibble(rbind(z,x,c,v,b,n))
  
  #Adding to environment
  assign(dw.corr.tbl,dw.results,envir = globalenv())
  #Storing at folder
  #write_csv(dw.results,paste('results/calibration.snt/',{{ver.tim}},'.corr.tbl.val.d1.csv', sep=""))
  #Show results in console
  dw.results
  
}

#Obtain table of correlations and and store its temporal version

#For calibration day = Tuesday
tbl.sim.corr.cal.T(paste('corr.tbl.cal.d0',{{ver.tim}}))

#For validation day 1
tbl.sim.corr.val.d1(paste('corr.tbl.val.d1',{{ver.tim}}))

# # #  > Patterns validation: sim v.s. obs <------------------------ ================


# Scatterplots correlations 5.days groupby_manhole.id ----

#Define plot fun and export png plots
poll.corr.plot.databy.mhole <- function(
    data = obs.sim.stn.06min,
    tem.res.str = 'Resolution:06 min.',
    obs.pollut = ob.cod.mgl,
    sim.pollut = cod.mgl,
    plot.name = paste({{ver.tim}},'cor.obs.stn.06min.png')){
  
  set.seed(123)
  
  obs.sim.stn.temp.resl.plot <- grouped_ggscatterstats(
    data             = dplyr::filter({{data}},
                                     manhole.id %in% c("wwtp","258","39")),
    x                = {{obs.pollut}},
    y                = {{sim.pollut}},
    grouping.var     = manhole.id,
    annotation.args  = list(title = "Assesing DW simulation: Correlation  Obs v.s. Sim",
                            paste(tem.res.str)),
    plotgrid.args    = list(nrow = 1, ncol = 3),
    ggtheme          = ggplot2::theme_light(),
    ggplot.component = list(
      ggplot2::scale_y_continuous(
        breaks = seq(0, 3600, 250),
        limits = (c(0, 3600))),
      ggplot2::scale_x_continuous(
        breaks = seq(0, 3600, 250),
        limits = (c(0, 3600))),
      theme(axis.text.x = element_text(angle = 90))
    ),
    xfill            = 'chocolate4', ## fill for marginals on the x-axis
    yfill            = 'chocolate'## fill for marginals on the y-axis
  )
  
  # ggsave(
  #   filename = here::here("img", "sim.vs.obs","calibration", plot.name),
  #   plot = obs.sim.stn.temp.resl.plot,
  #   width = 24,
  #   height = 8,
  #   device = "png")
  
  #Adding to environment
  assign('obs.sim.stn.temp.resl.plot',obs.sim.stn.temp.resl.plot,envir = globalenv())
  
}

# # COD corr multiple place and resolutions
poll.corr.plot.databy.mhole(
  obs.sim.stn.06min,'Resolution:06 min.',ob.cod.mgl,cod.mgl,paste({{ver.tim}},'cor.stn.06m.cod.png',sep="."))
poll.corr.plot.databy.mhole(
  obs.sim.stn.12min,'Resolution:12 min.',ob.cod.mgl,cod.mgl,paste({{ver.tim}},'cor.stn.12m.cod.png',sep="."))
poll.corr.plot.databy.mhole(
  obs.sim.stn.30min,'Resolution:30 min.',ob.cod.mgl,cod.mgl,paste({{ver.tim}},'cor.stn.30m.cod.png',sep="."))
poll.corr.plot.databy.mhole(
  obs.sim.stn.60min,'Resolution:60 min.',ob.cod.mgl,cod.mgl,paste({{ver.tim}},'cor.stn.60m.cod.png',sep="."))
poll.corr.plot.databy.mhole(
  obs.sim.stn.180min,'Resolution:180 min.',ob.cod.mgl,cod.mgl,paste({{ver.tim}},'cor.stn.180m.cod.png',sep="."))

# # TSS corr multiple place and resolutions
poll.corr.plot.databy.mhole(
  obs.sim.stn.06min,'Resolution:06 min.',ob.tss.mgl,tss.mgl,paste({{ver.tim}},'cor.stn.06m.tss.png',sep="."))
poll.corr.plot.databy.mhole(
  obs.sim.stn.12min,'Resolution:12 min.',ob.tss.mgl,tss.mgl,paste({{ver.tim}},'cor.stn.12m.tss.png',sep="."))
poll.corr.plot.databy.mhole(
  obs.sim.stn.30min,'Resolution:30 min.',ob.tss.mgl,tss.mgl,paste({{ver.tim}},'cor.stn.30m.tss.png',sep="."))
poll.corr.plot.databy.mhole(
  obs.sim.stn.60min,'Resolution:60 min.',ob.tss.mgl,tss.mgl,paste({{ver.tim}},'cor.stn.60m.tss.png',sep="."))
poll.corr.plot.databy.mhole(
  obs.sim.stn.180min,'Resolution:180 min.',ob.tss.mgl,tss.mgl,paste({{ver.tim}},'cor.stn.180m.tss.png',sep="."))

#  > dygraphs TS sim v.s. obs manholes <------------------------ ================

# Indv.mh.id + Max.Min + Obs.Val plotting functions----

# #COD WWTP
# dwts.dygraph.manhole.cod <- function(
#     data,t.date, poll.sim, poll.obs, poll.sim.ch, poll.obs.ch){
#   
#   data %>%
#     filter(manhole.id == 'wwtp')%>%
#     select(date.time, manhole.id, 
#            {{poll.sim}}, {{poll.obs}},
#            cod.mn,cod.mx)%>%
#     filter(str_detect(date.time,t.date))%>%
#     pivot_wider(names_from = manhole.id,
#                 values_from = c({{poll.sim.ch}},{{poll.obs.ch}},
#                                 cod.mx,cod.mn))%>%
#     xts(.,.$date.time)%>%
#     dygraph(main = paste (wday(t.date,label = TRUE,abbr = FALSE),
#                           "Pollutant ",
#                           {{poll.sim.ch}},
#                           sep=" - "),
#             group = t.date)%>%
#     dyOptions(drawPoints = TRUE, useDataTimezone = TRUE,
#               pointSize = 2)%>%
#     dyHighlight(highlightSeriesOpts = list(strokeWidth = 3),
#                 highlightSeriesBackgroundAlpha = 0.2) %>%
#     dyAxis("y", label = "Concentration in mg/l") %>%
#     dySeries("cod.mgl_wwtp", color = "#543005")%>%
#     dySeries("ob.cod.mgl_wwtp", color = "#003c30")%>%
#     dySeries("cod.mx_wwtp", color = "#e41a1c")%>%
#     dySeries("cod.mn_wwtp", color = "#377eb8")
# }
# 
# #TSS WWTP
# dwts.dygraph.manhole.tss <- function(
#     data,t.date, poll.sim, poll.obs, poll.sim.ch, poll.obs.ch){
#   
#   data %>%
#     filter(manhole.id == 'wwtp')%>%
#     select(date.time, manhole.id, 
#            {{poll.sim}}, {{poll.obs}},
#            tss.mn,tss.mx)%>%
#     filter(str_detect(date.time,t.date))%>%
#     pivot_wider(names_from = manhole.id,
#                 values_from = c({{poll.sim.ch}},{{poll.obs.ch}},
#                                 tss.mx,tss.mn))%>%
#     xts(.,.$date.time)%>%
#     dygraph(main = paste (wday(t.date,label = TRUE,abbr = FALSE),
#                           "Pollutant ",
#                           {{poll.sim.ch}},
#                           sep=" - "),
#             group = t.date)%>%
#     dyOptions(drawPoints = TRUE, useDataTimezone = TRUE,
#               pointSize = 2)%>%
#     dyHighlight(highlightSeriesOpts = list(strokeWidth = 3),
#                 highlightSeriesBackgroundAlpha = 0.2) %>%
#     dyAxis("y", label = "Concentration in mg/l") %>%
#     dySeries("tss.mgl_wwtp", color = "#7f3b08")%>%
#     dySeries("ob.tss.mgl_wwtp", color = "#2d004b")%>%
#     dySeries("tss.mx_wwtp", color = "#e41a1c")%>%
#     dySeries("tss.mn_wwtp", color = "#377eb8")
# }


# run any COD dygraphs (mh.Obs.Val.Max.Min)----
val.days.snt <- c("2022-03-21") #Validation day 1
val.days.snt <- c("2022-03-22") #Calibration day 0

