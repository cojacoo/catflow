sim.pipe <-
function(
        xnew , znew ,   # profile geometry: z is matrix, x is vector
        slope.width,    #   width is vector/ numeric            
        start.depth ,   # depth of starting node
        ml = 5 ,        # average horizontal length of pipe
        sigl ,     # standard deviations of horizontal length
        p.up= 0.1 ,     # prob. for upward step
        p.down=0.1 ,    # prob. for downward step

        x.step = 20 ,   # step to the lateral after changing direction
      ### optional arguments ###
        kmacro ,        # hydraulic capacity of macropores in cubic meters per second
                        # , e.g.  kmacro=1.33e-5
        ksmean ,        # vector: mean hydraulic conductivity of each layer [m/s]
        relfak          # grid for multipliers (e.g. with vertical macropores)
        )
{
  if(missing(sigl)) sigl <- ml/10              # standard deviation defaults to 10% of mean length
  if(sum(p.up, p.down) > 1) warning(paste("Function 'sim.pipe':\t p.up + p.down > 1!"))
  
  dz.max <- abs(c(diff(znew)[1,1], diff(znew[,1])))
  
  xsi <- length(xnew)
  eta <- nrow(znew)
  startn <- eta - findInterval(znew[1,xsi]-start.depth, rev(znew[,xsi]) )   ## starting node
                  ## matches value to rev. index      ## rev: increasing order
              ### eta - rev.index = index

  ## determine nodes with macropores
   # grid for pipe  (multiplier 1)
     if(missing(relfak))   relfak <- matrix(1, dim(znew)[1], dim(znew)[2])  
   # multiplier for node at right side 
     if(missing(kmacro) | missing(ksmean)){
               relfak[startn,xsi] <- 2
        } else relfak[startn,xsi] <- kmacro/(ksmean[1]*dz.max[xsi]*
                                              mean(slope.width[(startn-1):startn]) ) 
        
  ###
  # random process: length of macropores (from right)
     lpip <- rnorm(1, mean= ml, sd = sigl)
     ip <- which(xnew >= (xnew[xsi] - lpip)  )  # find nodes within range of macropore
     
     zn <- startn             # counter for horizontal position
     rowmac <- rep(0,xsi)     # counter for row numbers of macropores
       rowmac[xsi] <- startn
     xi <- xsi-1
     
     while (xi %in% ip ) {  #loop over x-nodes
        
        if(missing(kmacro) | missing(ksmean)){
                 mfak1 <- 2
           } else mfak1 <- kmacro/(ksmean[1]*mean(slope.width[(xi-1):xi])*dz.max[zn] ) 
        
        relfak[zn,xi] <- mfak1
            rowmac[xi] <- zn
        # draw random number
        rh <- runif(1)            
        
        # step up
        if(rh <= p.up & zn > 1) {
                                zn <- zn-1
                                if((xi - x.step)>=1) {
                                            relfak[zn,(xi - x.step):xi] <- mfak1      
                                              rowmac[(xi - x.step):xi] <- zn
                                              xi <- xi - x.step
                                 } else { relfak[zn,1:xi] <- mfak1
                                            rowmac[1:xi] <- zn
                                              xi <- xi - 1}                   
          } else {
        # step down
        if(rh >= (1-p.down) & zn < eta){ 
                                zn <- zn+1
                                if((xi - x.step)>=1) {
                                            relfak[zn,(xi - x.step):xi] <- mfak1 
                                              rowmac[(xi - x.step):xi] <- zn
                                            xi <- xi - x.step 
                                 } else { relfak[zn,1:xi] <- mfak1
                                            rowmac[1:xi] <- zn      
                                              xi <- xi - 1}            
           } else  xi <- xi - 1
        #  horizontal step
        }
      }  
     
return(list("relfak" = relfak, "rowmac" = rowmac, "lpip"=lpip))
}

  