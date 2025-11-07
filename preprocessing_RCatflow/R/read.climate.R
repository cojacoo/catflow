read.climate <-
function(file.nam = "./in/Klima/climate_04.dat",  
          GMT.off = -3600, 
          timzon = "GMT", 
          plotting = TRUE,
          ...)
{  opa <- par(no.readonly = TRUE)
   
   hdr <- readLines(file.nam, n = 3)[-1]
   clim <- read.table(file.nam, skip = 3,...)

    hdr <-  strsplit(hdr, "  ",fix = TRUE)
    hdr[[1]] <- grep("[0-9]",hdr[[1]], value = TRUE) [1:2]  # start date, and time conversion
     hdr[[2]] <- hdr[[2]][grep("[",hdr[[2]], fix = TRUE)]
       hdr[[2]] <- strsplit(hdr[[2]]," -> ", fix = TRUE)[[1]][1]
     
    colnames(clim) <- unlist(strsplit("Time,GlobRad,NetRad,Temp,RelHum,vWind,dirWind",","))

# timeseries object
  if(require(zoo, quietly = TRUE)) {        #
   tim <- as.POSIXct(strptime( hdr[[1]][1], "%d.%m.%Y %H:%M:%S"), tz = timzon) + 
                              GMT.off     + clim[,1] * as.numeric(hdr[[1]][2])
   clim <- zoo(clim[,-1], order.by = tim)
    if(plotting) plot (clim,...)
   }else  if(plotting)  {layout(matrix(1:6,3))
                          par(mar = c(5,4,1.5,2)+0.1) 
                         for (i in 2:7) plot(clim[,1], clim[,i], t = "l", 
                                              xlab = paste("Time", hdr[[2]][1]),
                                              ylab = colnames(clim)[i] ,
                                               ...)
                         }
  par(opa) 
return(invisible(clim))
}

