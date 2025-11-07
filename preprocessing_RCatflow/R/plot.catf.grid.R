plot.catf.grid <-
  ## takes matrices of coordinates and values and plots if plotting = T
function( x = sko, 
          y = hko, 
          val = NULL, 
          sel = NULL,         # take all or selection of columns
          # jet color palette
          pal = colorRampPalette(c("white","#00007F", "blue", "#007FFF", 
                "cyan","#7FFF7F", "yellow", "#FF7F00", "red", 
                "#7F0000"))(256),
          # color for polygon boundaries (NA: not drawing)
          boundcol = 8 ,
          plotting = TRUE,
          plotlab = TRUE,
          plotpoints = FALSE,      
          ...) 
{

# subset 'sel'
if(is.null(sel)) {sko <- x 
                  hko <- y   
} else { sko <- x[,sel]
          hko <- y[,sel] 
         if(!is.null(val)) val <- val[,sel]
        }

# number of nodes
eta <- nrow (sko)
xsi <- ncol(sko)

# boundaries of nodes (at midpoint)
# lateral midpoints
 latg <-  t(apply(sko,1,diff)/2)
   xx <-  cbind(sko[,1], sko[,-ncol(sko)] + latg, sko[,ncol(sko)] )
   
 verg <- t(apply(hko,1,diff)/2)
   yy <- cbind(hko[,1],  hko[,-ncol(hko)] + verg , hko[,ncol(hko)] )

### + vertical midpoints
 lath <- apply(xx,2,diff)/2
  xxx <-  rbind(xx[1,], xx[-nrow(xx),] + lath, xx[nrow(xx),] )
  # xxx <- xxx[nrow(xxx):1,]                                        # correct order  for val
 verh <- apply(yy,2,diff)/2
  yyy <- rbind(yy[1,],  yy[-nrow(yy),] + verh , yy[nrow(yy),] ) 
 #  yyy <- yyy[nrow(yyy):1,]                                        # correct order  for val
# plot
    if(plotting){ 
    plot(sko, hko, t = "n",...) 
       if(is.null(val)){      #no values - just polygons
        for (j in 1:(xsi))  
          for (k in 1:(eta) ){  polygon(c(xxx[c(k,k+1),j], xxx[c(k+1,k),j+1]), 
                                          c(yyy[c(k,k+1),j], yyy[c(k+1,k),j+1]))
                               }
        } else {              #scale values in color space - specific palette
          cols <- round( (val - min(val)) / diff(range(val)) * (length(pal)-1) ) +1
          for (j in 1:(xsi))  
          for (k in 1:(eta) ){  polygon(c(xxx[c(k,k+1),j], xxx[c(k+1,k),j+1]), 
                                          c(yyy[c(k,k+1),j], yyy[c(k+1,k),j+1]), 
                                          col = pal[ cols[k,j] ] ,                
                                          border = boundcol)
                               }
 ## build legend
  if(plotlab){     ## rev for starting with highest
   if(length( unique(as.vector(val)) ) > 4)
    { if(all(nchar(format(unique(as.vector(val)))) ==1 )) 
             {  label <- paste( rev( sort(unique(as.vector(val))) )  )
             } else  label <- paste( rev( sort(quantile(unique(as.vector(val)))) )  )
                      
        label[seq(2,length(label)-1, 2)] <- NA  ## throw out some intermediate values
                      
      legend("topr", label,  
       fill = pal[ rev(floor(quantile(seq_along(pal), probs = seq(0,1,l = length(label)) ))) ]
        , bty = "n"                        
         , y.intersp = 0.5)   
    
    } else { if(all(nchar(format(unique(as.vector(val)))) ==1 )) 
             {  label <- paste( rev( sort(unique(as.vector(val))) )  )
             } else label <- paste( rev( sort(round(unique(as.vector(val)),1)) )  )
            
            legend("topr", label,  
               fill = pal[ rev(floor(quantile(seq_along(pal), probs = seq(0,1,l = length(label)) ))) ]
                , bty = "n"                        
                 , y.intersp = 0.75)   
            }
            
      } # end if(plotlab)  
    } # end else
    ## add nodes as points
    if(plotpoints) points(sko, hko, pch = 20,...)
  } # end if(plotting)
   
   return( invisible(list(pcx = xxx, pcy = yyy)) )
} # end of func   

