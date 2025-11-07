sim.mak <-
function( 
        xnew, znew,     # profile geometry: z is matrix, x is vector
        slope.width,    #   width is vector/ numeric            
        np = 4  ,       # number of macropores per unit area
        ml = 0.9 ,      # average vertical length of macropore
        sigl = 0.1 ,    # standard deviations of vertical length
        p.lat = 0.2  ,  # vector: probability for a lateral step in each layer
        side = "both",  # switch: make lateral steps to left or right, or both sides
        x.step = 20,    # stepsize [no of nodes]: minimum seperation of macropores
      ### optional arguments ###
        depth   ,       # vector: depth of layer boundaries, only one layer if NULL
        kmacro,        # hydraulic capacity of macropores in cubic meters per second
                        # , e.g.  kmacro=1.33e-5
        ksmean  ,       # vector: mean hydraulic conductivity of each layer [m/s]
        relfak          # grid for multipliers (e.g. with vertical macropores)

        ){  
  ##
  xsi <- length(xnew)
  eta <- nrow(znew)
  dx.max <- c(diff(xnew)[1], diff(xnew))
  
  side <- substr(side, 1,1)
  side <- switch(side, "b"="both", "B" = "both", "r" = "right", "R" = "right", "l" = "left", "L" = "left", NA)
  
  # one or two layers? - determine range of nodes for simulation
  if(missing(ksmean)) nlayer <- length(p.lat)  else nlayer <- min(length(p.lat), length(ksmean) )
     if(nlayer > 2)   stop("Only two layers possible at the moment!\n") 
                        # not more layers considered for now                
  
      if(missing(depth) | nlayer == 1){ 
          cat("Info: Considering a single layer.\n")
          layer1 <- 1:eta
           if(missing(kmacro) | missing(ksmean)){
                 mfak1 <- rep(2, xsi)
           } else mfak1 <- kmacro/(ksmean[1]*slope.width*dx.max)
      
      } else {
        cat("Info: Considering two different layers.\n")
        if( nlayer != (length(depth) +1)) stop("Length of depth vector not appropriate!\n")
                
            # upper and lower layer limits in node numbers
             layer1 <- which (znew[,1] >= znew[1,1]-depth)
             layer2 <- which (znew[,1] < znew[1,1]-depth)
 
            p.lat2 <- p.lat[2] ; p.lat <- p.lat[1]

          # assign factor for contrast with each layer
          if(missing(kmacro) | missing(ksmean)){   mfak1 <- mfak2 <- rep(2, xsi)
          } else {  mfak1 <- kmacro/(ksmean[1]*slope.width*dx.max)
                    mfak2 <- kmacro/(ksmean[2]*slope.width*dx.max)  }
          }
  
  ## determine nodes with macropores
  
  ###
  # poisson process for number of macropores
    # average number of macropores per pixel
    lam <- np* slope.width * dx.max           
     # random process
     nmac <- rep(0, xsi)        
       j <-  (x.step+1)
       while ( j < (xsi - x.step)) {   # no macros at left and right boundary
          nmac[j] <- rpois(1,lam[j])
            if(nmac[j]>0) { j <- j + x.step  # make x.step after macropores
            } else j <- j+1
        }            
    
    nomac <- nmac==0           # columns without macropores at surface
     
   # matrix of multipliers
    if(missing(relfak))   relfak <- matrix(1, dim(znew)[1], dim(znew)[2])  
    relfak[1,nmac>0] <- nmac[nmac>0]* mfak1[nmac>0]         
    
      #   cdfcon <- rep(0,eta)         # counter for vertical cumulative distribution 

    # length of macropores
    lmac <- rnorm(nmac, mean= ml, sd = sigl)
    lmac[nomac] <- 0
     lmac <- rbind(lmac,lmac)         # second row is counter for deepest row number
    
    for (xi in  which(nmac > 0))      # loop over  macropore nodes             OLD: (xi in seq_along(xnew))  ;     if( nmac[xi] >= 1 ) { 
     { 
       fak <- nmac[xi]* mfak1[xi]         # factor of first layer
         n.depth <- znew[1,xi]-lmac[1,xi]     # depth
         ip <- which(znew[,xi] >= n.depth)  # find nodes within depth of macropore
         ih <- xi                             # counter for lateral position of macropore

         for (zi in ip[-1]) {     ## loop into vertical; first row is in nmac
              
               if( zi %in% layer1) {    # in the upper layer
                 if (runif(1) < p.lat)            
                   {# step to the lateral?
                     if(side == "both")
                      { if(rbinom(1,1, 0.5) > 0 & ih < xsi-1) 
                         {# step to the right , if not near the boundary
                          relfak[zi,ih:(ih+1)] <- fak
                          ih <- ih+1
                        } else {if( ih > 2)
                          # step to the left, if not near the boundary
                          relfak[zi,ih:(ih-1)] <- fak
                          ih <- ih-1  }
                      } else 
                        { if(side =="right" & ih < xsi-1)       # only to the right
                          {# step to the right , if not near the boundary
                            relfak[zi,ih:(ih+1)] <- fak
                            ih <- ih+1
                          }
                          if(side =="left" & ih > 2)       # only to the right
                          {# step to the right , if not near the boundary
                            relfak[zi,ih:(ih-1)] <- fak
                            ih <- ih-1  }
                         }    
                  } else {
                    # digs into vertical direction
                    relfak[zi,ih] <- fak
                    }
                 
                }  # end if layer 1
            
                if(!missing(depth)) {       # second layer?
                if( zi %in% layer2) {    # lower layer
                   fak <- nmac[xi] * mfak2[xi]
                  if (runif(1) < p.lat2)            
                   {# step to the lateral?
                     if(side == "both")
                      { if(rbinom(1,1, 0.5) > 0 & ih < xsi-1) 
                         {# step to the right , if not near the boundary
                          relfak[zi,ih:(ih+1)] <- fak
                          ih <- ih+1
                        } else {if( ih > 2)
                          # step to the left, if not near the boundary
                          relfak[zi,ih:(ih-1)] <- fak
                          ih <- ih-1  }
                      } else 
                        { if(side =="right" & ih < xsi-1)       # only to the right
                          {# step to the right , if not near the boundary
                            relfak[zi,ih:(ih+1)] <- fak
                            ih <- ih+1
                          }
                          if(side =="left" & ih > 2)       # only to the right
                          {# step to the right , if not near the boundary
                            relfak[zi,ih:(ih-1)] <- fak
                            ih <- ih-1  }
                         }
                  } else {
                    # digs into vertical direction
                    relfak[zi,ih] <- fak
                    }
                 
               } # end if in layer2;
                 
            }  #  if 2 layers
         } #end loop over vertical
     
          lmac[2,xi] <- zi
     
    } # end loop over x-nodes
   ###

  cat("Done!\n")
return(list("relfak" = relfak, "lmac" = lmac))
}

