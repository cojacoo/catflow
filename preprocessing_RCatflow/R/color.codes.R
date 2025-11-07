color.codes <-       ## color coding  - scale values in color space - specific palette    
function( val, 
          lowercut = 0, uppercut = 1, lencut =  8, # color cuts: lower, upper, length
          colorsForCuts,  # palette               # specify from data - quantiles ?
          plotlab = TRUE   # draw legend?
          ){
         
  cuts <- sort( seq(from = lowercut, to = uppercut, length.out = lencut))
  cuts <- unique(round(cuts,digits = 2))
  
  #Set the colors. One more color then cuts is needed!
  if(missing(colorsForCuts)) colorsForCuts <- c("pink",rev(brewer.pal(length(cuts),"Blues")))
      
  if(plotlab){
   legendtext <- c( paste("<",cuts[1]),
              paste(cuts[-length(cuts)],"-",cuts[-1],sep = " "),
                paste(">",cuts[length(cuts)]) )
    legend("topright", legendtext, pch = 22, pt.bg = colorsForCuts, bty = "n", cex = 0.8)
  }  
  
  colors2 <-  colorsForCuts[findInterval(val,cuts, rightmost.closed = TRUE)+1]

return(colors2)
}

