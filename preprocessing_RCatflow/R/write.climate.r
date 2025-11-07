write.climate <-
function( climadat,
          output.file,
          start.time = "01.01.2004 00:00:00",   # dd.mm.yyyy hh:mm:ss,
          time.unit = "h",                      # d(ay), h(our), m(inute), s(econds)
          
          rBilart = 1 ,                        # specifies whether net radiation is computed 
                                               #  (1), or measured values are to be used (2)
          ref.height = 8 ,                     # reference height wind speed measurement 
          sw0 = -6 ,                           # sw: factors relating short wave radiation
          sw1 = 0.7 ,                          # balance and net radiation, to be calibrated
          sw2 = 2.8e-4 ,                       #  rBil = sw0 + sw1*swrBil + sw2*swrBil^2
          trueb = 1.5 ,                        # trueb: dimming factors, to be calibrated
          truebf = 0.1 ,                       #  against clear sky radiation data
          NA.flag = -999                       # flag to write for NAs
          ) 
{          
 
  ###
  faktor.t <- switch(time.unit, "d" = 86400, "h" = 3600, "m" = 60, "s" = 1)
              # convert  time.unit to seconds
 
  if(is.zoo(climadat)){ clim <- coredata(climadat)
                        tim  <- as.numeric(index(climadat) - start(climadat))/faktor.t
                        climadat <- cbind(tim, clim)
                       }   
  
  climadat[is.na(climadat)] <- NA.flag
  
# header
  zeile1 <- paste(rBilart, rBilart)
   zeile2 <- paste(start.time, ".00", sep = "")
    zeile3 <- paste("#  Startzeit          [", time.unit ,"]->[s],",
                    " wind height, radiation and dimming factors", sep = "")    
    zeile4 <- paste(paste("# Time[", time.unit ,"]", sep = "" ),  "GlobRad",  
                  " NetRad",  "    Temp", "   RelHum",  "   vWind",  " dirWind", sep = "  " )

write(zeile1, output.file)   
 write( c(zeile2 , 
            sapply(c(faktor.t, ref.height, sw0, sw1, sw2, trueb, truebf), 
                   format, nsmall = 1, scientific = -1)
        ), ncolumns = 8, output.file, sep  = "  ", append = T)
 write( zeile3, output.file, append = T)
  write( zeile4, output.file, append = T)
  
 write( t(format(round(climadat, 2), width = c(8,rep(6, 6)), nsmall = 2) ), 
        output.file, ncolumns = 7, sep  = "  ", append = T)

print(paste("Generated climate file '", output.file, "'.",sep = "") )                 

return(invisible())
}

