sim.rectmak <-
function(
        xnew, znew,     # profile geometry: z is matrix, x is vector
        slope.width,    #   width is vector/ numeric            
        np = 4  ,       # number of macropores per unit area
        ml = 0.9 ,      # average vertical length of macropore
        sigl= 0.1 ,     # standard deviations of vertical length
        sigh = 0.1,     # standard deviation of horizontal crossing (mean = half length)
        x.step = 20,        # stepsize [no of nodes]: minimum seperation of macropores
      ### optional arguments ###
        kmacro,        # hydraulic capacity of macropores in cubic meters per second
                        # , e.g.  kmacro=1.33e-5
        ksmean  ,       # vector: mean hydraulic conductivity of each layer [m/s]
        relfak          # grid for multipliers (e.g. with vertical macropores)

       ){
  ##
  xsi <- length(xnew)
  eta <- nrow(znew)
  dx.max <- c(diff(xnew)[1], diff(xnew))
   dz.max <- abs(c(diff(znew)[1,1], diff(znew[,1])))
 
  ## determine nodes with macropores

  ###
  # poisson process for number of macropores
    # average number of macropores per pixel
    lam <- np* slope.width * dx.max
     # random process: macropores at surface
     nmac <- rep(0, xsi)
       j <-  (x.step+1)
       while ( j < (xsi - x.step)) {   # no macros at left and right boundary
          nmac[j] <- rpois(1,lam[j])
            if(nmac[j]>0) { j <- j + x.step  # make x.step after macropores
            } else j <- j+1
        }
    nomac <- nmac==0           # columns without macropores at surface

    # random process: length of macropores
    lmac <- rnorm(nmac, mean= ml, sd = sigl)
    lmac[nomac] <- 0
     lmac <- rbind(lmac,lmac)         # second row is counter for deepest row number

       rowmac <- rep(0, xsi)          ## counter for rows with horizontal structures
        
   ## Multipliers
    # vertical factor
     if(missing(kmacro) | missing(ksmean)){
                 mfak1 <- rep(2, xsi)
           } else mfak1 <- kmacro/(ksmean[1]*slope.width*dx.max)
  
     if(any(mfak1 < 1)) warning(
        paste("Some vertical multipliers lower 1! Check ratio kmacro/Ks. Positions:", 
          paste(which(mfak1 < 1) , collapse=", ") ) , call.=F)
                                               
     # horizontal factor below
  
    # matrix of multipliers
    if(missing(relfak))   relfak <- matrix(1, dim(znew)[1], dim(znew)[2])  
    relfak[1 ,nmac>0] <- nmac[nmac>0]* mfak1[nmac>0]

    xx <- which(nmac>0)          ### indices of macros
    
   #
    for(xxi in seq(along=xx)){
         
         xi <- xx[xxi]
         # vertical structure: macropores with simulated lengths
         fak <- nmac[xi]* mfak1[xi]         # vertical factor 
          n.depth <- znew[1,xi]-lmac[1,xi]     # depth
            ip <- which(znew[,xi] >= n.depth)   # find nodes within depth of macropore
         relfak[ip[-1],xi] <- fak
          lmac[2,xi] <- ip[length(ip)]
          
         # horizontal structures
         if( xi > xx[1]){
           # horiz. starts at ~half of length
           h.depth <- znew[1,xi] - rnorm(1,lmac[1,xi]/2, sigh)                                            
           ip <- which.min( abs(h.depth - znew[,xi]) )
          
           # horizontal factor     
          if(missing(kmacro) | missing(ksmean)){
                 mfak2 <- 2   # rep(2, xsi)
           } else mfak2 <- kmacro/(ksmean[1]*mean(slope.width[xx[xxi-1]:xi])*dz.max[ip] ) 
          
          if(mfak2 < 1) warning(paste("Horizontal multipliers lower 1 between" ,(xx[xxi-1]+1), 
                                        "and", (xi-1)), call.=F)
           relfak[ip, (xx[xxi-1]+1):(xi-1)] <- mfak2
            rowmac[(xx[xxi-1]+1):(xi-1)] <- ip
         } 
          }

return(list("relfak" = relfak, "lmac" = lmac, "rowmac" = rowmac))
}

