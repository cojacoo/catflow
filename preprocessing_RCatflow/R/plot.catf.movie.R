plot.catf.movie <-
function( resultmat,               # values and  simulation times -> read.catf.resultmat()
          geof,             # geometry
          sel ,          # selection of columns
          begindate ,   # "%d.%m.%Y %H:%M:%S", TIme object, or NA / NULL
          outputPath ,                # When plotting to file ( SCREENPLOT = FALSE), 
          filename  ,                  # you need to set a path for the pdf file
          SCREENPLOT = TRUE,                    #Plot on screen or files (TRUE/FALSE)
          delayTime = 0.1,                  #Delay time in sec. (for slower/faster plotting)
          ...)                        # lowercut, uppercut, lencut, colorsForCuts, plotlab) 
                                      # for:   color.codes(...)
{
    
# make output directory
if(!SCREENPLOT) if(!file_test("-d", outputPath)) dir.create(outputPath)

if(missing(begindate)) begindate <- NULL    # some default date

if(is.null(begindate) ) {  useTime <- TRUE
 } else  { useTime <- FALSE
           if(timeBased(begindate)) { begindate <- as.POSIXct(begindate) 
           } else {                     begindate <- as.POSIXct(strptime(begindate, "%d.%m.%Y %H:%M:%S")) 
           }
          }

val <- resultmat[[1]]
simtim <- resultmat[[2]]

numbersteps <- length(simtim)

# one single pdf
if(missing(outputPath)) outputPath <- "."
if(missing(filename)) {
        if(!SCREENPLOT) warning("No filename specified! -> Plotting on screen")
        SCREENPLOT <- TRUE
        }
                        
if(!SCREENPLOT) { outfile <- paste(outputPath, "/", filename, ".pdf", sep = "")
                  outfile <-  sub("pdf.pdf", "pdf", outfile)
                  pdf(file = outfile)                               
                  }

ynum <- nrow(geof$hko)
xnum <- ncol(geof$hko)

### polygon representation of nodes
if(missing(sel)) { 
    geom <- node2poly(xv = geof$sko, yv = geof$hko)
} else  { # select columns ('bereich')
    bereich <- sel
    geom <- node2poly(xv = geof$sko, yv = geof$hko, sel = bereich)
    val <- lapply(val, function(x) x[, bereich] )
  }
  
## loop over timesteps    
for (j in 1:numbersteps) {

  if (SCREENPLOT) Sys.sleep(delayTime)
                                                           
  if(useTime) { pic.ID <- paste(simtim[[j]], "s") 
   } else       pic.ID <- format(begindate + simtim[[j]] , "%Y-%m-%d %H:00")
 
  # draw geometry and color coded values -for all nodes
    # empty plot
   plot(range(geom[[1]], na.rm = TRUE), range(geom[[2]], na.rm = TRUE), 
        typ = "n", main = pic.ID, xlab = "hor [m]", ylab = "vert [m]")
  # eventually plot borders of slope geometry (-> geof)
     lines(geof$sko[1, ], geof$hko[1, ], t = "l", lwd = 2, col = 8)
     lines(geof$sko[ynum, ], geof$hko[ynum, ], t = "l", lwd = 2, col = 8)
     lines(geof$sko[, 1], geof$hko[, 1], t = "l", lwd = 2, col = 8)
     lines(geof$sko[, xnum], geof$hko[, xnum], t = "l", lwd = 2, col = 8)

  #if (SCREENPLOT)  bringToTop()
  
  colors2 <- color.codes(val[[j]],   ... )
                                    # lowercut, uppercut, lencut, colorsForCuts, plotlab
  polygon(geom[[1]], geom[[2]], col = colors2, border = NA)

} # end of loop over timesteps

if (! SCREENPLOT) { dev.off()
                    print(paste("Generated", outfile))
                  } 

return(invisible(NULL))  
}

