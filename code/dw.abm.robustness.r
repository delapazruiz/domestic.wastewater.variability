# Evaluating DW simulation robustness

#Load data. Only two columns input data, row.name and count wd particles
dw.sim.robus<- read_csv("results/dw.sms.abm.snt.2020.rob robust.accumulated.wwps.5d.ok-spreadsheet.csv",
                        col_names = FALSE, col_types= 'i' )%>%
  t() %>% .[-c(1),] %>%as_tibble ()

colnames(dw.sim.robus) <- c("sim.n","dw.par")
dw.sim.robus

#Define cumulative average
dw.sim.robus$acum.avg <- cummean(
  dw.sim.robus$dw.par)

# 70 runs required for robust number of simulations
dw.sim.robus$acum.avg %>% summary()
plot(dw.sim.robus$acum.avg, xlab= 'Number of simulations',ylab= 'Acumulative average: Total DW particales' )

