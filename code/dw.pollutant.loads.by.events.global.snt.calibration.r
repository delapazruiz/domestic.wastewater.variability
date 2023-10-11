#Preparing DW characteristics by event
#References to define DW events loads:

# Friedler, E. and Butler, D. 1996. Quantifying the inherent uncertainty in the quantity and quality of domestic wastewater. Water Science and Technology. 33(2), pp.65–75.
#Rose, C., Parker, A., Jefferson, B., & Cartmell, E. (2015). The characterization of feces and urine: A review of the literature to inform advanced treatment technology. Critical Reviews in Environmental Science and Technology, 45(17), 1827–1879. https://doi.org/10.1080/10643389.2014.1000761
#Almeida, M. C., Butler, D., & Friedler, E. (1999). At-source domestic wastewater quality. Urban Water, 1(1), 49–55. https://doi.org/10.1016/s1462-0758(99)00008-4

#Requirements
library(dplyr)

#Some verification samples.
#ej. 1., cod.poo.max=(1310/3)*(250g(poo.ev)/13(lt))=8399mg/l*event tss =6442
#ej. 2., cod.poo.min=4446.6mg/l*event , tss=2410
#ej. 3., pee.1/9lt =3760/9= 417.7 mg/l

dw.eventloads.fw <- tibble(dw.var = c('cod.mg/l','tss.mg/l','bod.mg/l'),#,'note'
       pee.1 = c(495.81,71.12,147.73), #,'raw.low.con'
       pee.2 = c(3179.64,66.88,1161.41), #,'raw.midium.con'
       pee.3 = c(3759.04,65.53,1359.11), #,'raw.high.con'
       poo.1 = c(696.80,376.15,187.35), #,'raw.3g/1.lt'
       poo.2 = c(782.69,429.44,208.48), #,'raw.3g/1.lt'
       poo.3 = c(1310.21,1005.02,283.35), #,'raw.3g/1.lt'
       poo.4 = c(1213.29,692.91,316.71), #,'raw.3g/1.lt'
       kitchen.1 = c(280.22,244.37,56.25), #,'event'
       kitchen.2 = c(273.47,282.92,45.27), #,'event'
       shower.1 = c(842.67,255.1,267.74),#,'event'
       shower.2 = c(871.3,262.43,277.31),#,'event'
       washingmachine.1 = c(413.82,232.84,112.54),#,'event'
       washbasin.2 = c(162.98,98.52,43.30),#,'event'
       washbasin.1 = c(166.17,95.79,44.56)#'event'
)

dw.eventloads.fw <- dw.eventloads.fw %>%
  mutate(pee.e1 = pee.1/9,
         pee.e2 = pee.2/9,
         pee.e3 = pee.3/9,
         poo.e1 = ((poo.1/3)*(250/13)),
         poo.e2 = ((poo.2/3)*(250/13)),
         poo.e3 = ((poo.3/3)*(250/13)),
         poo.e4 = ((poo.4/3)*(250/13))
  )

#dw.eventloads.fw %>% View()

#Loads in references and sensor measurements (calibrated) ----
#Litters are proposed based on Mexican context
dw.eventloads.papers <- tibble(
       dw.var = c('cod.mg/l','tss.mg/l','lts'),
       pee.min = c(299.4,0.4,9), 
       pee.max = c(842.6,7.9,13), 
       poo.min = c(4599,3333,9),
       poo.max = c(11800,6933,13),
       kitchen.min = c(273,235,1.47),
       kitchen.max = c(1079,720,2.94),
       shower.min = c(280,119,26),
       shower.max = c(871.3,262,33.7),
       washingmachine.min = c(413,120,31),
       washingmachine.max = c(1815,232.8,62),
       washbasin.min = c(166,98.52,0.45),
       washbasin.max = c(400,181,1.36)
       )

# Define min and max DW event loads ----
# Separate young and adults 

 dw.eventloads.adults <- dw.eventloads.papers %>% 
  mutate(pee.min.adu = ((pee.min+pee.max)/2),
         poo.min.adu = ((poo.min+poo.max)/2),
         kitchen.min.adu = ((kitchen.min+kitchen.max)/2),
         shower.min.adu = ((shower.min+shower.max)/2),
         washingmachine.min.adu = ((washingmachine.min+washingmachine.max)/2),
         washbasin.min.adu = ((washbasin.min+washbasin.max)/2)
         ) %>% . [,!(colnames(.) %in% c("pee.min",
                                        'poo.min',
                                        'kitchen.min',
                                        'shower.min',
                                        'washingmachine.min',
                                        'washbasin.min'))]

dw.eventloads.young <- dw.eventloads.papers %>% 
  mutate(pee.max.you = ((pee.max)*.5),
         poo.max.you = ((poo.max)*.5),
         kitchen.max.you = ((kitchen.max)/1),
         shower.max.you = ((shower.max)/1),
         washingmachine.max.you = ((washingmachine.max)/1),
         washbasin.max.you = ((washbasin.max)/1)
         ) %>% . [,!(colnames(.) %in% c("pee.max",
                                        'poo.max',
                                        'kitchen.max',
                                        'shower.max',
                                        'washingmachine.max',
                                        'washbasin.max'))]

#Filter out no significant events from babies
# > wwtp.snt %>% filter(Age == "P_0A2") %>% View()
# > wwtp.snt %>% filter(Age == "P_0A2" & day.n == "Sat") %>% View()

# head(blocks.snt)
# head(manholes.snt)
# head(wwtp.snt)

manholes.snt<- manholes.snt%>% 
  filter(event.typ %in% c("kitchensink","shower") | Age != "P_0A2")

blocks.snt<- blocks.snt%>% 
  filter(event.typ %in% c("kitchensink","shower") | Age != "P_0A2")

# Update cheking

# manholes.snt.filter<- manholes.snt%>% 
#   filter(event.typ %in% c("pee","poo",'washbasin') & Age != "P_0A2")
# 
# blocks.snt.filter<- blocks.snt%>% 
#   filter(event.typ %in% c("pee","poo",'washbasin') & Age != "P_0A2")

# blocks.snt.filter$Age %>%unique() 
# blocks.snt.filter$event.typ %>%unique() 
# blocks.snt.filter %>%
#   filter(Age == 'P_0A2') %>% .$event.typ%>%unique()
# blocks.snt.filter%>% summary()
# 
# 
# manholes.snt.filter$Age %>%unique() 
# manholes.snt.filter$event.typ %>%unique() 
# manholes.snt.filter %>%
#   filter(Age == 'P_0A2') %>% .$event.typ%>%unique()




#Lists of age groups to apply DW event loads
age.adults <- c("P_25A130","P_18A24","P_15A17")
age.youngs   <- c("P_0A2","P_3A5","P_6A11","P_12A14")


#Functions to apply DW event type loads----

p.e.adu <- function(pollu,even.typ){
  dw.eventloads.adults %>% 
    .[.$dw.var== pollu,c(even.typ)] %>% as.numeric()}

p.e.you <- function(pollu,even.typ){
  dw.eventloads.young %>% 
    .[.$dw.var== pollu,c(even.typ)] %>% as.numeric()}

# p.e.adu('tss.mg/l',"shower.max")
# p.e.you('tss.mg/l',"shower.min")
# 
# p.e.adu('tss.mg/l',"kitchen.max")
# p.e.you('tss.mg/l',"kitchen.min")
# 
# p.e.adu('cod.mg/l',"kitchen.max")
# p.e.you('cod.mg/l',"kitchen.min")

# Apply sampled loads to DW events  ----
# respective uniform distributions

# For reproducible outcomes
# Execute seed before running uniform distributions
set.seed(333)

## Adults: Pollution ---- 

#Exploring required 
# head(blocks.snt)
# head(manholes.snt)
# head(wwtp.snt)

# uniform distribution's definition form known min and max values

b.k.snt.pee.adu <- blocks.snt %>%
  filter(.,event.typ == "pee"& Age %in% age.adults)%>%
  mutate(cod.mgl = round(runif(rep(1,nrow(.)),
        p.e.adu('cod.mg/l','pee.min.adu'),
        p.e.adu('cod.mg/l','pee.max')),2))%>%
  mutate(tss.mgl = round(runif(rep(1,nrow(.)),
        p.e.adu('tss.mg/l','pee.min.adu'),
        p.e.adu('tss.mg/l','pee.max')),2))%>%
  mutate(lts = round(runif(rep(1,nrow(.)),
        p.e.adu('lts','pee.min.adu'),
        p.e.adu('lts','pee.max')),2))

b.k.snt.poo.adu <- blocks.snt %>%
  filter(.,event.typ == "poo"& Age %in% age.adults)%>%
  mutate(cod.mgl = round(runif(rep(1,nrow(.)),
                               p.e.adu('cod.mg/l','poo.min.adu'),
                               p.e.adu('cod.mg/l','poo.max')),2))%>%
  mutate(tss.mgl = round(runif(rep(1,nrow(.)),
                               p.e.adu('tss.mg/l','poo.min.adu'),
                               p.e.adu('tss.mg/l','poo.max')),2))%>%
  mutate(lts = round(runif(rep(1,nrow(.)),
                           p.e.adu('lts','poo.min.adu'),
                           p.e.adu('lts','poo.max')),2))

b.k.snt.kitchen.adu <- blocks.snt %>%
  filter(.,event.typ == "kitchensink"& Age %in% age.adults)%>%
  mutate(cod.mgl = round(runif(rep(1,nrow(.)),
                               p.e.adu('cod.mg/l','kitchen.min.adu'),
                               p.e.adu('cod.mg/l','kitchen.max')),2))%>%
  mutate(tss.mgl = round(runif(rep(1,nrow(.)),
                               p.e.adu('tss.mg/l','kitchen.min.adu'),
                               p.e.adu('tss.mg/l','kitchen.max')),2))%>%
  mutate(lts = round(runif(rep(1,nrow(.)),
                           p.e.adu('lts','kitchen.min.adu'),
                           p.e.adu('lts','kitchen.max')),2))

b.k.snt.shower.adu <- blocks.snt %>%
  filter(.,event.typ == "shower"& Age %in% age.adults)%>%
  mutate(cod.mgl = round(runif(rep(1,nrow(.)),
                               p.e.adu('cod.mg/l','shower.min.adu'),
                               p.e.adu('cod.mg/l','shower.max')),2))%>%
  mutate(tss.mgl = round(runif(rep(1,nrow(.)),
                               p.e.adu('tss.mg/l','shower.min.adu'),
                               p.e.adu('tss.mg/l','shower.max')),2))%>%
  mutate(lts = round(runif(rep(1,nrow(.)),
                           p.e.adu('lts','shower.min.adu'),
                           p.e.adu('lts','shower.max')),2))

b.k.snt.washingmachine.adu <- blocks.snt %>%
  filter(.,event.typ == "washingmachine"& Age %in% age.adults)%>%
  mutate(cod.mgl = round(runif(rep(1,nrow(.)),
                               p.e.adu('cod.mg/l','washingmachine.min.adu'),
                               p.e.adu('cod.mg/l','washingmachine.max')),2))%>%
  mutate(tss.mgl = round(runif(rep(1,nrow(.)),
                               p.e.adu('tss.mg/l','washingmachine.min.adu'),
                               p.e.adu('tss.mg/l','washingmachine.max')),2))%>%
  mutate(lts = round(runif(rep(1,nrow(.)),
                           p.e.adu('lts','washingmachine.min.adu'),
                           p.e.adu('lts','washingmachine.max')),2))

b.k.snt.washbasin.adu <- blocks.snt %>%
  filter(.,event.typ == "washbasin"& Age %in% age.adults)%>%
  mutate(cod.mgl = round(runif(rep(1,nrow(.)),
                               p.e.adu('cod.mg/l','washbasin.min.adu'),
                               p.e.adu('cod.mg/l','washbasin.max')),2))%>%
  mutate(tss.mgl = round(runif(rep(1,nrow(.)),
                               p.e.adu('tss.mg/l','washbasin.min.adu'),
                               p.e.adu('tss.mg/l','washbasin.max')),2))%>%
  mutate(lts = round(runif(rep(1,nrow(.)),
                           p.e.adu('lts','washbasin.min.adu'),
                           p.e.adu('lts','washbasin.max')),2))

#Results exploration

# b.k.snt.pee.adu$cod.mgl %>% unique()
# b.k.snt.pee.adu$tss.mgl %>% unique()
# b.k.snt.pee.adu$lts %>% unique()
# b.k.snt.pee.adu %>% View()

## Youngs: Pollution  ----
# uniform distribution's definition form known min and max values

b.k.snt.pee.you <- blocks.snt %>%
  filter(.,event.typ == "pee"& Age %in% age.youngs)%>%
  mutate(cod.mgl = round(runif(rep(1,nrow(.)),
                               p.e.you('cod.mg/l','pee.min'),
                               p.e.you('cod.mg/l','pee.max.you')),2))%>%
  mutate(tss.mgl = round(runif(rep(1,nrow(.)),
                               p.e.you('tss.mg/l','pee.min'),
                               p.e.you('tss.mg/l','pee.max.you')),2))%>%
  mutate(lts = round(runif(rep(1,nrow(.)),
                           p.e.you('lts','pee.min'),
                           p.e.you('lts','pee.max.you')),2))

b.k.snt.poo.you <- blocks.snt %>%
  filter(.,event.typ == "poo"& Age %in% age.youngs)%>%
  mutate(cod.mgl = round(runif(rep(1,nrow(.)),
                               p.e.you('cod.mg/l','poo.min'),
                               p.e.you('cod.mg/l','poo.max.you')),2))%>%
  mutate(tss.mgl = round(runif(rep(1,nrow(.)),
                               p.e.you('tss.mg/l','poo.min'),
                               p.e.you('tss.mg/l','poo.max.you')),2))%>%
  mutate(lts = round(runif(rep(1,nrow(.)),
                           p.e.you('lts','poo.min'),
                           p.e.you('lts','poo.max.you')),2))

b.k.snt.kitchen.you <- blocks.snt %>%
  filter(.,event.typ == "kitchensink"& Age %in% age.youngs)%>%
  mutate(cod.mgl = round(runif(rep(1,nrow(.)),
                               p.e.you('cod.mg/l','kitchen.min'),
                               p.e.you('cod.mg/l','kitchen.max.you')),2))%>%
  mutate(tss.mgl = round(runif(rep(1,nrow(.)),
                               p.e.you('tss.mg/l','kitchen.min'),
                               p.e.you('tss.mg/l','kitchen.max.you')),2))%>%
  mutate(lts = round(runif(rep(1,nrow(.)),
                           p.e.you('lts','kitchen.min'),
                           p.e.you('lts','kitchen.max.you')),2))

b.k.snt.shower.you <- blocks.snt %>%
  filter(.,event.typ == "shower"& Age %in% age.youngs)%>%
  mutate(cod.mgl = round(runif(rep(1,nrow(.)),
                               p.e.you('cod.mg/l','shower.min'),
                               p.e.you('cod.mg/l','shower.max.you')),2))%>%
  mutate(tss.mgl = round(runif(rep(1,nrow(.)),
                               p.e.you('tss.mg/l','shower.min'),
                               p.e.you('tss.mg/l','shower.max.you')),2))%>%
  mutate(lts = round(runif(rep(1,nrow(.)),
                           p.e.you('lts','shower.min'),
                           p.e.you('lts','shower.max.you')),2))

b.k.snt.washingmachine.you <- blocks.snt %>%
  filter(.,event.typ == "washingmachine"& Age %in% age.youngs)%>%
  mutate(cod.mgl = round(runif(rep(1,nrow(.)),
                               p.e.you('cod.mg/l','washingmachine.min'),
                               p.e.you('cod.mg/l','washingmachine.max.you')),2))%>%
  mutate(tss.mgl = round(runif(rep(1,nrow(.)),
                               p.e.you('tss.mg/l','washingmachine.min'),
                               p.e.you('tss.mg/l','washingmachine.max.you')),2))%>%
  mutate(lts = round(runif(rep(1,nrow(.)),
                           p.e.you('lts','washingmachine.min'),
                           p.e.you('lts','washingmachine.max.you')),2))

b.k.snt.washbasin.you <- blocks.snt %>%
  filter(.,event.typ == "washbasin"& Age %in% age.youngs)%>%
  mutate(cod.mgl = round(runif(rep(1,nrow(.)),
                               p.e.you('cod.mg/l','washbasin.min'),
                               p.e.you('cod.mg/l','washbasin.max.you')),2))%>%
  mutate(tss.mgl = round(runif(rep(1,nrow(.)),
                               p.e.you('tss.mg/l','washbasin.min'),
                               p.e.you('tss.mg/l','washbasin.max.you')),2))%>%
  mutate(lts = round(runif(rep(1,nrow(.)),
                           p.e.you('lts','washbasin.min'),
                           p.e.you('lts','washbasin.max.you')),2))


#Results exploration
# b.k.snt.pee.you$cod.mgl %>% unique()
# b.k.snt.pee.you$tss.mgl %>% unique()
# b.k.snt.pee.you$lts %>% unique()
# b.k.snt.pee.you %>% View()

# b.k.snt.kitchen.you %>% select(13:last_col())
# b.k.snt.kitchen.adu %>% select(13:last_col())
# 
# b.k.snt.kitchen.adu$cod.mgl %>% is.na() %>% summary()
# b.k.snt.kitchen.you$tss.mgl %>% is.na() %>% summary()

#rbin: Combining DW pollutants DF ----

blocks.snt.pol <- rbind(
  b.k.snt.kitchen.adu,
  b.k.snt.kitchen.you,
  b.k.snt.pee.adu,
  b.k.snt.pee.you,
  b.k.snt.poo.adu,
  b.k.snt.poo.you,
  b.k.snt.shower.adu,
  b.k.snt.shower.you,
  b.k.snt.washbasin.adu,
  b.k.snt.washbasin.you,
  b.k.snt.washingmachine.adu,
  b.k.snt.washingmachine.you)

#inner_join: Pollutants into manholes ----
manholes.snt.pol <- dplyr::left_join(manholes.snt,
                              blocks.snt.pol,
                              by= c('exp','run','seed','wwp.id') #,'day.n','ind.id','event.typ'
                              )

# manholes.snt.pol%>% select(last_col(2):last_col(1)) %>% summary()
# manholes.snt.pol$cod.mgl %>% is.na() %>% summary()
# manholes.snt.pol$tss.mgl %>% is.na() %>% summary()
# manholes.snt.pol %>% colnames()
# 
# manholes.snt.pol$wwp.id %>% unique()%>% as.data.frame()%>% nrow()
# manholes.snt$wwp.id %>% unique()%>% as.data.frame()%>% nrow()
# 
# manholes.snt.pol$day.n.x %>% unique()%>% as.data.frame()%>% nrow()
# manholes.snt$day.n %>% unique()%>% as.data.frame()%>% nrow()
# 
# blocks.snt.pol$day.n %>% unique()%>% as.data.frame()%>% nrow()
# blocks.snt$day.n %>% unique()%>% as.data.frame()%>% nrow()
# 
# blocks.snt.pol%>% filter(is.na(cod.mgl))%>% .$event.typ %>% unique()
# blocks.snt.pol%>% filter(is.na(cod.mgl))%>% .$day.n %>% unique()
# blocks.snt.pol%>% filter(is.na(cod.mgl))%>% .$run %>% unique()
# blocks.snt.pol%>% filter(is.na(cod.mgl))%>% .$Age %>% unique()
# 
# blocks.snt$wwp.id %>% unique()%>% as.data.frame()%>% nrow()
# blocks.snt.pol$wwp.id %>% unique()%>% as.data.frame()%>% nrow()
# blocks.snt.pol%>% select(last_col(2):last_col()) %>% summary()
# blocks.snt.pol$cod.mgl %>% is.na() %>% summary()
# blocks.snt.pol$tss.mgl %>% is.na() %>% summary()

#Colnames to be removed
mh.drops <- c("ind.id.y","date.time.y","day.n.y","event.typ.y","CVEGEO.x","Sex.y",
              "Age.y","Go_School.y","Go_Work.y","Escolar_grade.y","Escolar_level.y",
              "CVEGEO.y",'CVEGEO')

#Removing listed of colnames
manholes.snt.pol <- manholes.snt.pol%>%
  .[ , !(names(.) %in% mh.drops)]

blocks.snt.pol <- blocks.snt.pol %>%
  .[ , !(names(.) %in% c('CVEGEO.y'))]

#Remove the '.x' suffix in colnames
blocks.snt.pol <- rename_with(
  blocks.snt.pol, ~ gsub(".x", "", .x, fixed = TRUE))

manholes.snt.pol <- rename_with(
  manholes.snt.pol, ~ gsub(".x", "", .x, fixed = TRUE))

#Adjust lt variable

blocks.snt.pol <- rename(blocks.snt.pol, lts.vol=lts)

manholes.snt.pol <- rename(manholes.snt.pol, lts.vol=lts)

# head(blocks.snt.pol)
# head(manholes.snt.pol)

remove(
  b.k.snt.kitchen.adu,b.k.snt.kitchen.you,b.k.snt.pee.adu,b.k.snt.pee.you,
  b.k.snt.poo.adu,b.k.snt.poo.you,b.k.snt.shower.adu,b.k.snt.shower.you,
  b.k.snt.washbasin.adu,b.k.snt.washbasin.you,b.k.snt.washingmachine.adu,
  b.k.snt.washingmachine.you,
  mh.drops,
  age.adults,
  age.youngs,
  p.e.adu,
  p.e.you,
  dw.eventloads.papers,
  dw.eventloads.adults,
  dw.eventloads.young,
  dw.eventloads.fw)










