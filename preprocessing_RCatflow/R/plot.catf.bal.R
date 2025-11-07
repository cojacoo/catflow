plot.catf.bal <-
function(bilanz, interact = TRUE, ylim, stay=F, ...)
{   
  if(is.character(bilanz)) bilanz <- read.catf.balance(bilanz, plottin = FALSE, 
                                          differences=FALSE) 
  
  if(! is.data.frame(bilanz)) stop("'plot.catf.bal': Either a data frame or a file name of a balance file must be given!")
  
  
  Nied <- bilanz[, 14]
  Auffeuchtung <- bilanz[, 5]
  Senken <- bilanz[, 6]
  Unterrand <- bilanz[, 10]
  Rechtrand <- bilanz[, 9]
  Ofa <- bilanz[, 12]
  BodenVerd <- bilanz[, 17]
  Interzep <- bilanz[, 16]
  Transp  <-  bilanz[, 18]
 # Totale <- Nied-Auffeuchtung+Senken+Unterrand+Rechtrand-Ofa-BodenVerd-Interzep  
  Totale <- Nied -Auffeuchtung-Transp+Unterrand+Rechtrand-Ofa-BodenVerd-Interzep  
  if(missing(ylim)) ylim = range(c(bilanz[, c(5, 12, 14, 16, 17)], 
                                    -bilanz[, c(9, 10, 6)], Totale))

  plot(bilanz[, 3]/86400, Nied, typ = "l", , ylab = "[m3]", xlab = "Time [d]", ylim = ylim, ...)
  points(bilanz[, 3]/86400, Ofa, typ = "l", col = "blue")
  points(bilanz[, 3]/86400, -Rechtrand, typ = "l", col = "darkblue", lty = 2)
  points(bilanz[, 3]/86400, -Unterrand, typ = "l", col = "brown")
  points(bilanz[, 3]/86400, Auffeuchtung, typ = "l", col = "lightblue")
  points(bilanz[, 3]/86400, BodenVerd, typ = "l", col = "green")
  lines(bilanz[, 3]/86400, Transp, col = "darkgreen" , lty = 3)
  
  points(bilanz[, 3]/86400, Totale, typ = "l", col = "red", lty = 2) 
  lines(bilanz[,3]/86400, bilanz[,4], col=6)
  legend("topr", c("Precipitation", "Surface runoff", "Right bound. flux", 
                  "Lower bound. flux", "Soil moist.", "Soil evap.", "Transpiration", 
                  "Total bal.","Internal bal."), 
      col = c(1, "blue", "darkblue", "brown", "lightblue", "green", "darkgreen", "red", 6), 
        lty = c(1, 1, 2, rep(1, 3), 3, 2, 1), bty = "n", ncol = 3)        #  , ...
  
  #if(interact) bringToTop(stay=stay)
  
return(invisible(data.frame(time=bilanz[, 3], total = Totale) ) ) 
}
  
