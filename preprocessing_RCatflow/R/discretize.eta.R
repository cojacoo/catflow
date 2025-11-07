discretize.eta <-
function(relfak, endmac, steps=1, max.dist, dimfak, reg=T, top = 1:3 
                                                                    ){
                                                            # index of top rows to include
                                                  # flag for generating regular grid
                                                  #  (using max.dist)
                                            # fraction of dimension to 
                                            # compute missing max.dist
                                  # maximum seperation [no. rows]
                        # stepsize for discretization next to macropore endings
                 # lowest position (row number) of macropores 
          # matrix of multipliers for conductivity

      
  # compute vertical discretization (eta vector); 
  # fine resolution where simulated macropores end, and at surface 
  
   max.n = nrow(relfak)    
  
  if(missing(dimfak)) dimfak <- 0.05
  
  # maximum seperation (number of rows)
   if(missing(max.dist) ) max.dist <- dimfak * max.n      # set to 5% of total size
    
    ## find ends of macropores from endmac (vector of positions from sim.mak() )
   endpoints <- sort(endmac[which(endmac>0)] )
    # refine: include adjacent rows
   endpoints <- sapply(endpoints, function(x) x + -steps:steps)  
   endpoints <- unique(as.vector(endpoints))
     # include first nodes and last row
   endpoints <- sort(unique(c(top,endpoints, max.n)    ))
                                              # jw #  c(top, lb, ...) include layer boundary
   ### discretize gaps in between   
   if(reg & any(diff(endpoints) > max.dist)) {
      left <- endpoints[which(diff(endpoints)>max.dist)]
      right <- endpoints[which(diff(endpoints)>max.dist)+1]
      gap <- cbind(left,right)
       gap <- unlist(apply(gap, 1,                           # minimum 3 points in sequence   , length= max(3, diff(range(x)/max.dist)  )
               function(x) seq(x["left"],x["right"], by= max.dist)))
      endpoints <- unique(sort(c(endpoints, as.integer(gap))))
   } else endpoints <- unique(sort(endpoints))
   
   eta_val <- seq(1,0, length=max.n) 
   
   eta_new <- sort(eta_val[endpoints])
 
return(eta_new)
}

