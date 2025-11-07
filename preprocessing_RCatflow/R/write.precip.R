write.precip <-
function( raindat,
          output.file,
          start.time= "01.01.2004 00:00:00",   # dd.mm.yyyy hh:mm:ss,
          time.unit= "h",                       # d(ay), h(our), m(inute), s(econds)
          faktor.p                             # 1.6667e-006 for [mm/10min]
         ) 
{          
  faktor.t <- switch(time.unit, "d" = 86400, "h" = 3600, "m" = 60, "s" = 1)
              # convert  time.unit to seconds
  
  if(missing(faktor.p)) { faktor.p <-  format(1/faktor.t /1e3 , dig=4) # convert  mm/time.unit to m/s
                            zeile2 <- paste("#  Startzeit      [", time.unit ,"] -> [s]",
                              "  [mm/", time.unit, "] -> [m/s]", sep="")    
   } else   zeile2 <- paste("#  Startzeit      [", time.unit ,"] -> [s]","  [mm/interval] -> [m/s]", sep="")                
  
  if(is.zoo(raindat)) { prec <- coredata(raindat)
                        tim  <- as.numeric(index(raindat) - start(raindat))/faktor.t
                        raindat <- cbind(tim, prec)
   } else              prec <- raindat[,2]  
                
  # Index
    #Differenz zum Vorg?er
    diff1 = c( 1, abs(diff(prec)) )
     
    #Differenz zum nachfolger
    diff2 <- c(abs(diff(prec)), 1)
   
    #     points of interest
    poi <- which(diff1>0 | diff2>0)

  #gew?e Datenpunkte        
  knickdat <- rbind(raindat[poi,1],raindat[poi,2])
  
# header
   zeile1 <- paste(start.time, ".00", sep="")
  
    
 write( c(zeile1 , faktor.t, faktor.p), ncolumns=3, output.file, sep ="  ")
 write( zeile2, output.file, append=T)
  write(format(knickdat, width=c(8,4)), output.file, ncolumns=2, sep ="  ", append=T)
                        
print(paste("Generated precipitation file '", output.file, "'.",sep="") )                 

return(invisible())
}
